const pool = require('../config/db');
const { success, fail } = require('../utils/response');

const APPEAL_STATUSES = ['pending', 'in_review', 'accepted', 'rejected', 'closed'];
const ELIGIBLE_MODERATION_STATUSES = ['resolved_valid', 'resolved_rejected', 'resolved_partial'];

function ensureAdmin(req, res) {
  if (req.user.role !== 'admin') {
    res.status(403).json(fail('仅管理员可以访问该接口'));
    return false;
  }
  return true;
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

function toAppealItem(row) {
  return {
    id: row.id,
    moderation_record_id: row.moderation_record_id,
    appellant_id: row.appellant_id,
    reason: row.reason,
    description: row.description,
    evidence_items: parseEvidenceItems(row.evidence_items),
    status: row.status,
    reviewed_by: row.reviewed_by,
    review_comment: row.review_comment,
    reviewed_at: row.reviewed_at,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

async function fetchAppealById(appealId) {
  const [rows] = await pool.query(
    `SELECT
      id, moderation_record_id, appellant_id, reason, description, evidence_items,
      status, reviewed_by, review_comment, reviewed_at, created_at, updated_at
    FROM appeals
    WHERE id = ?
    LIMIT 1`,
    [appealId]
  );
  return rows[0] || null;
}

async function fetchModerationRecord(recordId) {
  const [rows] = await pool.query(
    `SELECT
      id, reporter_id, status, closed_at
    FROM moderation_records
    WHERE id = ?
    LIMIT 1`,
    [recordId]
  );
  return rows[0] || null;
}

async function fetchOpenAppealByModerationRecord(recordId) {
  const [rows] = await pool.query(
    `SELECT id, status
     FROM appeals
     WHERE moderation_record_id = ? AND status <> 'closed'
     ORDER BY created_at DESC, id DESC
     LIMIT 1`,
    [recordId]
  );
  return rows[0] || null;
}

async function markModerationAppealed(conn, moderationRecordId) {
  await conn.query(
    `UPDATE moderation_records
     SET status = 'appealed', updated_at = NOW()
     WHERE id = ?`,
    [moderationRecordId]
  );
}

async function applyModerationFollowUp(conn, appeal, nextStatus) {
  let moderationStatus = null;
  let closedAt = null;

  if (nextStatus === 'accepted' || nextStatus === 'rejected' || nextStatus === 'in_review') {
    moderationStatus = 'appeal_reviewing';
  } else if (nextStatus === 'closed') {
    moderationStatus = 'closed';
    closedAt = new Date();
  }

  if (!moderationStatus) {
    return;
  }

  await conn.query(
    `UPDATE moderation_records
     SET status = ?, closed_at = ?, updated_at = NOW()
     WHERE id = ?`,
    [moderationStatus, closedAt, appeal.moderation_record_id]
  );
}

async function submitAppeal(req, res) {
  const conn = await pool.getConnection();
  try {
    const appellantId = req.user.id;
    const moderationRecordId = Number(req.body.moderation_record_id);
    const reason = String(req.body.reason || '').trim();
    const description = String(req.body.description || '').trim();
    const evidenceItems = parseEvidenceItems(req.body.evidence_items);

    if (Number.isNaN(moderationRecordId) || moderationRecordId <= 0) {
      return res.status(400).json(fail('治理记录 id 不合法'));
    }
    if (reason.length === 0) {
      return res.status(400).json(fail('请先填写申诉原因'));
    }
    if (description.length < 4) {
      return res.status(400).json(fail('请补充更具体的申诉说明'));
    }

    const moderationRecord = await fetchModerationRecord(moderationRecordId);
    if (!moderationRecord) {
      return res.status(404).json(fail('对应治理记录不存在'));
    }
    if (Number(moderationRecord.reporter_id) !== Number(appellantId)) {
      return res.status(403).json(fail('只有该治理记录的提交方才能发起申诉'));
    }
    if (!ELIGIBLE_MODERATION_STATUSES.includes(moderationRecord.status)) {
      return res.status(400).json(fail('当前处理阶段暂不支持发起申诉'));
    }

    const existingAppeal = await fetchOpenAppealByModerationRecord(moderationRecordId);
    if (existingAppeal) {
      return res.status(400).json(fail('当前治理记录已有进行中的申诉，请勿重复提交'));
    }

    await conn.beginTransaction();
    const [result] = await conn.query(
      `INSERT INTO appeals (
        moderation_record_id, appellant_id, reason, description, evidence_items, status
      ) VALUES (?, ?, ?, ?, ?, 'pending')`,
      [
        moderationRecordId,
        appellantId,
        reason,
        description,
        JSON.stringify(evidenceItems)
      ]
    );

    await markModerationAppealed(conn, moderationRecordId);
    await conn.commit();

    const appeal = await fetchAppealById(result.insertId);
    return res.json(success(toAppealItem(appeal), '申诉提交成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`提交申诉失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function listMyAppeals(req, res) {
  try {
    const appellantId = req.user.id;
    const [rows] = await pool.query(
      `SELECT
        id, moderation_record_id, appellant_id, reason, description, evidence_items,
        status, reviewed_by, review_comment, reviewed_at, created_at, updated_at
      FROM appeals
      WHERE appellant_id = ?
      ORDER BY created_at DESC, id DESC`,
      [appellantId]
    );

    return res.json(success(rows.map(toAppealItem), '获取我的申诉成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取我的申诉失败: ${error.message}`));
  }
}

async function listAppeals(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const status = String(req.query.status || '').trim();
    let sql = `SELECT
      id, moderation_record_id, appellant_id, reason, description, evidence_items,
      status, reviewed_by, review_comment, reviewed_at, created_at, updated_at
    FROM appeals`;
    const params = [];

    if (status.length > 0) {
      if (!APPEAL_STATUSES.includes(status)) {
        return res.status(400).json(fail('申诉状态不合法'));
      }
      sql += ' WHERE status = ?';
      params.push(status);
    }

    sql += ' ORDER BY created_at DESC, id DESC';
    const [rows] = await pool.query(sql, params);
    return res.json(success(rows.map(toAppealItem), '获取后台申诉成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取后台申诉失败: ${error.message}`));
  }
}

async function reviewAppeal(req, res) {
  const conn = await pool.getConnection();
  try {
    if (!ensureAdmin(req, res)) return;

    const appealId = Number(req.params.id);
    const status = String(req.body.status || '').trim();
    const reviewComment = String(req.body.review_comment || '').trim();

    if (Number.isNaN(appealId) || appealId <= 0) {
      return res.status(400).json(fail('申诉 id 不合法'));
    }
    if (!APPEAL_STATUSES.includes(status) || status === 'pending') {
      return res.status(400).json(fail('申诉状态不合法'));
    }

    const existingAppeal = await fetchAppealById(appealId);
    if (!existingAppeal) {
      return res.status(404).json(fail('申诉记录不存在'));
    }

    await conn.beginTransaction();
    await conn.query(
      `UPDATE appeals
       SET status = ?, reviewed_by = ?, review_comment = ?, reviewed_at = NOW(), updated_at = NOW()
       WHERE id = ?`,
      [status, req.user.id, reviewComment || null, appealId]
    );

    await applyModerationFollowUp(conn, existingAppeal, status);
    await conn.commit();

    const appeal = await fetchAppealById(appealId);
    return res.json(success(toAppealItem(appeal), '申诉审核成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`申诉审核失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

module.exports = {
  submitAppeal,
  listMyAppeals,
  listAppeals,
  reviewAppeal
};
