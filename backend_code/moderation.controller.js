const pool = require('../config/db');
const { success, fail } = require('../utils/response');

const MODERATION_STATUSES = [
  'pending',
  'triaging',
  'awaiting_evidence',
  'in_review',
  'resolved_valid',
  'resolved_rejected',
  'resolved_partial',
  'appealed',
  'appeal_reviewing',
  'closed'
];
const MODERATION_PRIORITIES = ['low', 'medium', 'high', 'urgent'];
const POSITIVE_REPORT_STATUSES = ['resolved_valid', 'resolved_partial'];

function ensureAdmin(req, res) {
  if (req.user.role !== 'admin') {
    res.status(403).json(fail('仅管理员可以访问该接口'));
    return false;
  }
  return true;
}

function toDbTimestamp(value) {
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === 'string' || typeof value === 'number') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  return null;
}

function parseEvidenceItems(value) {
  if (Array.isArray(value)) {
    return value.filter((item) => typeof item === 'string' && item.trim().length > 0).map((item) => item.trim());
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) {
        return parsed.filter((item) => typeof item === 'string' && item.trim().length > 0).map((item) => item.trim());
      }
    } catch (_error) {
    }
  }
  return [];
}

function toModerationItem(row) {
  return {
    id: row.id,
    reporter_id: row.reporter_id,
    target_type: row.target_type,
    target_id: row.target_id,
    reported_user_id: row.reported_user_id,
    related_order_id: row.related_order_id,
    related_product_id: row.related_product_id,
    related_thread_id: row.related_thread_id,
    category: row.category,
    reason: row.reason,
    description: row.description,
    evidence_items: parseEvidenceItems(row.evidence_items),
    status: row.status,
    priority: row.priority,
    assigned_admin_id: row.assigned_admin_id,
    admin_comment: row.admin_comment,
    resolution_code: row.resolution_code,
    governance_action_id: row.governance_action_id,
    reviewed_by: row.reviewed_by,
    reviewed_at: row.reviewed_at,
    closed_at: row.closed_at,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

async function fetchModerationRecordById(recordId) {
  const [rows] = await pool.query(
    `SELECT
      id, reporter_id, target_type, target_id, reported_user_id,
      related_order_id, related_product_id, related_thread_id,
      category, reason, description, evidence_items, status, priority,
      assigned_admin_id, admin_comment, resolution_code, governance_action_id,
      reviewed_by, reviewed_at, closed_at, created_at, updated_at
    FROM moderation_records
    WHERE id = ?
    LIMIT 1`,
    [recordId]
  );
  return rows[0] || null;
}

async function fetchProductTarget(productId) {
  const [rows] = await pool.query(
    `SELECT id, seller_id, category, is_deleted
     FROM products
     WHERE id = ?
     LIMIT 1`,
    [productId]
  );
  return rows[0] || null;
}

async function fetchUserTarget(userId) {
  const [rows] = await pool.query(
    `SELECT id, role
     FROM users
     WHERE id = ?
     LIMIT 1`,
    [userId]
  );
  return rows[0] || null;
}

async function fetchOrderTarget(orderId) {
  const [rows] = await pool.query(
    `SELECT id, buyer_id, seller_id, product_id, status
     FROM orders
     WHERE id = ?
     LIMIT 1`,
    [orderId]
  );
  return rows[0] || null;
}

async function fetchConversationTarget(conversationId) {
  const [rows] = await pool.query(
    `SELECT id, order_id, product_id, buyer_id, seller_id
     FROM conversations
     WHERE id = ?
     LIMIT 1`,
    [conversationId]
  );
  return rows[0] || null;
}

function buildResolutionCode(status) {
  if (status === 'resolved_valid' || status === 'resolved_rejected' || status === 'resolved_partial') {
    return status;
  }
  if (status === 'closed') {
    return 'closed';
  }
  return null;
}

async function syncReportedUserReportCount(conn, record, previousStatus, nextStatus) {
  if (!record.reported_user_id) {
    return;
  }

  const wasPositive = POSITIVE_REPORT_STATUSES.includes(previousStatus);
  const isPositive = POSITIVE_REPORT_STATUSES.includes(nextStatus);
  if (wasPositive === isPositive) {
    return;
  }

  if (isPositive) {
    await conn.query(
      `UPDATE users
       SET report_count = report_count + 1
       WHERE id = ?`,
      [record.reported_user_id]
    );
    return;
  }

  await conn.query(
    `UPDATE users
     SET report_count = GREATEST(report_count - 1, 0)
     WHERE id = ?`,
    [record.reported_user_id]
  );
}

async function resolveTargetMetadata(targetType, targetId, reporterId) {
  if (targetType === 'product_report') {
    const product = await fetchProductTarget(targetId);
    if (!product || Number(product.is_deleted) === 1) {
      return { error: '商品不存在' };
    }
    if (Number(product.seller_id) === Number(reporterId)) {
      return { error: '不能举报自己发布的商品' };
    }
    return {
      reportedUserId: product.seller_id,
      relatedProductId: product.id,
      category: product.category || 'product',
      priority: 'medium'
    };
  }

  if (targetType === 'user_report') {
    const user = await fetchUserTarget(targetId);
    if (!user) {
      return { error: '被举报用户不存在' };
    }
    if (Number(user.id) === Number(reporterId)) {
      return { error: '不能举报自己' };
    }
    if (user.role === 'admin') {
      return { error: '不能举报管理员账号' };
    }
    return {
      reportedUserId: user.id,
      category: 'user',
      priority: 'medium'
    };
  }

  if (targetType === 'order_complaint') {
    const order = await fetchOrderTarget(targetId);
    if (!order) {
      return { error: '订单不存在' };
    }
    if (Number(order.buyer_id) !== Number(reporterId) && Number(order.seller_id) !== Number(reporterId)) {
      return { error: '仅订单参与方可以投诉该订单' };
    }
    return {
      reportedUserId: Number(order.buyer_id) === Number(reporterId) ? order.seller_id : order.buyer_id,
      relatedOrderId: order.id,
      relatedProductId: order.product_id,
      category: 'order_dispute',
      priority: 'high'
    };
  }

  if (targetType === 'chat_report') {
    const conversation = await fetchConversationTarget(targetId);
    if (!conversation) {
      return { error: '会话不存在' };
    }
    if (Number(conversation.buyer_id) !== Number(reporterId) && Number(conversation.seller_id) !== Number(reporterId)) {
      return { error: '仅会话参与方可以举报该会话' };
    }
    return {
      reportedUserId: Number(conversation.buyer_id) === Number(reporterId)
        ? conversation.seller_id
        : conversation.buyer_id,
      relatedOrderId: conversation.order_id,
      relatedProductId: conversation.product_id,
      relatedThreadId: conversation.id,
      category: 'chat_safety',
      priority: 'high'
    };
  }

  return { error: '举报目标类型暂不支持' };
}

async function submitRecord(req, res) {
  const conn = await pool.getConnection();
  try {
    const reporterId = req.user.id;
    const targetType = String(req.body.target_type || '').trim();
    const targetId = Number(req.body.target_id);
    const reason = String(req.body.reason || '').trim();
    const description = String(req.body.description || '').trim();

    if (!['product_report', 'user_report', 'order_complaint', 'chat_report'].includes(targetType)) {
      return res.status(400).json(fail('举报目标类型不合法'));
    }
    if (Number.isNaN(targetId) || targetId <= 0) {
      return res.status(400).json(fail('举报目标 id 不合法'));
    }
    if (reason.length === 0) {
      return res.status(400).json(fail('请先填写举报或投诉原因'));
    }
    if (description.length < 4) {
      return res.status(400).json(fail('请补充更具体的情况说明'));
    }

    const targetMetadata = await resolveTargetMetadata(targetType, targetId, reporterId);
    if (targetMetadata.error) {
      return res.status(400).json(fail(targetMetadata.error));
    }

    await conn.beginTransaction();
    const [result] = await conn.query(
      `INSERT INTO moderation_records (
        reporter_id, target_type, target_id, reported_user_id,
        related_order_id, related_product_id, related_thread_id,
        category, reason, description, evidence_items, status, priority
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)`,
      [
        reporterId,
        targetType,
        targetId,
        targetMetadata.reportedUserId || null,
        targetMetadata.relatedOrderId || null,
        targetMetadata.relatedProductId || null,
        targetMetadata.relatedThreadId || null,
        targetMetadata.category || null,
        reason,
        description,
        JSON.stringify([]),
        targetMetadata.priority && MODERATION_PRIORITIES.includes(targetMetadata.priority)
          ? targetMetadata.priority
          : 'medium'
      ]
    );
    await conn.commit();

    const record = await fetchModerationRecordById(result.insertId);
    return res.json(success(toModerationItem(record), '举报提交成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`提交举报失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function listMyRecords(req, res) {
  try {
    const reporterId = req.user.id;
    const [rows] = await pool.query(
      `SELECT
        id, reporter_id, target_type, target_id, reported_user_id,
        related_order_id, related_product_id, related_thread_id,
        category, reason, description, evidence_items, status, priority,
        assigned_admin_id, admin_comment, resolution_code, governance_action_id,
        reviewed_by, reviewed_at, closed_at, created_at, updated_at
      FROM moderation_records
      WHERE reporter_id = ?
      ORDER BY created_at DESC, id DESC`,
      [reporterId]
    );

    return res.json(success(rows.map(toModerationItem), '获取我的治理记录成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取我的治理记录失败: ${error.message}`));
  }
}

async function getRecordDetail(req, res) {
  try {
    const recordId = Number(req.params.id);
    if (Number.isNaN(recordId) || recordId <= 0) {
      return res.status(400).json(fail('治理记录 id 不合法'));
    }

    const record = await fetchModerationRecordById(recordId);
    if (!record) {
      return res.status(404).json(fail('治理记录不存在'));
    }

    const isAdmin = req.user.role === 'admin';
    if (!isAdmin && Number(record.reporter_id) !== Number(req.user.id)) {
      return res.status(403).json(fail('无权查看该治理记录'));
    }

    return res.json(success(toModerationItem(record), '获取治理记录详情成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取治理记录详情失败: ${error.message}`));
  }
}

async function listRecords(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const status = String(req.query.status || '').trim();
    let sql = `SELECT
      id, reporter_id, target_type, target_id, reported_user_id,
      related_order_id, related_product_id, related_thread_id,
      category, reason, description, evidence_items, status, priority,
      assigned_admin_id, admin_comment, resolution_code, governance_action_id,
      reviewed_by, reviewed_at, closed_at, created_at, updated_at
    FROM moderation_records`;
    const params = [];

    if (status.length > 0) {
      if (!MODERATION_STATUSES.includes(status)) {
        return res.status(400).json(fail('治理记录状态不合法'));
      }
      sql += ' WHERE status = ?';
      params.push(status);
    }

    sql += ' ORDER BY created_at DESC, id DESC';
    const [rows] = await pool.query(sql, params);
    return res.json(success(rows.map(toModerationItem), '获取举报审核列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取举报审核列表失败: ${error.message}`));
  }
}

async function reviewRecord(req, res) {
  const conn = await pool.getConnection();
  try {
    if (!ensureAdmin(req, res)) return;

    const recordId = Number(req.params.id);
    const status = String(req.body.status || '').trim();
    const adminComment = String(req.body.admin_comment || '').trim();

    if (Number.isNaN(recordId) || recordId <= 0) {
      return res.status(400).json(fail('治理记录 id 不合法'));
    }
    if (!MODERATION_STATUSES.includes(status) || status === 'pending') {
      return res.status(400).json(fail('治理记录状态不合法'));
    }

    const existing = await fetchModerationRecordById(recordId);
    if (!existing) {
      return res.status(404).json(fail('治理记录不存在'));
    }

    await conn.beginTransaction();
    const reviewedAt = new Date();
    const closedAt = status === 'closed' ? reviewedAt : toDbTimestamp(existing.closed_at);
    const resolutionCode = buildResolutionCode(status);

    await conn.query(
      `UPDATE moderation_records
       SET status = ?, assigned_admin_id = ?, admin_comment = ?, resolution_code = ?,
           reviewed_by = ?, reviewed_at = ?, closed_at = ?, updated_at = NOW()
       WHERE id = ?`,
      [
        status,
        req.user.id,
        adminComment || null,
        resolutionCode,
        req.user.id,
        reviewedAt,
        closedAt,
        recordId
      ]
    );

    await syncReportedUserReportCount(conn, existing, existing.status, status);
    await conn.commit();

    const record = await fetchModerationRecordById(recordId);
    return res.json(success(toModerationItem(record), '举报审核成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`举报审核失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

module.exports = {
  submitRecord,
  listMyRecords,
  getRecordDetail,
  listRecords,
  reviewRecord
};
