const pool = require('../config/db');
const { success, fail } = require('../utils/response');

const GOVERNANCE_ACTION_TYPES = [
  'warning',
  'mute_chat',
  'restrict_trade',
  'temporary_ban',
  'permanent_ban'
];

function ensureAdmin(req, res) {
  if (req.user.role !== 'admin') {
    res.status(403).json(fail('仅管理员可以访问该接口'));
    return false;
  }
  return true;
}

function toGovernanceActionItem(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    source_type: row.source_type,
    source_id: row.source_id,
    action_type: row.action_type,
    reason: row.reason,
    comment: row.comment,
    start_at: row.start_at,
    end_at: row.end_at,
    active: Boolean(row.active),
    created_by: row.created_by,
    created_at: row.created_at,
    updated_at: row.updated_at,
    canceled_at: row.canceled_at,
    canceled_by: row.canceled_by
  };
}

function mapActionTypeToUserStatus(actionType) {
  if (actionType === 'mute_chat') {
    return 'muted';
  }
  if (actionType === 'restrict_trade') {
    return 'restricted';
  }
  if (actionType === 'temporary_ban') {
    return 'suspended';
  }
  if (actionType === 'permanent_ban') {
    return 'banned';
  }
  return 'active';
}

function resolveStatusFromActiveActions(actions) {
  const actionTypes = actions.filter((item) => Boolean(item.active)).map((item) => item.action_type);
  if (actionTypes.includes('permanent_ban')) {
    return 'banned';
  }
  if (actionTypes.includes('temporary_ban')) {
    return 'suspended';
  }
  if (actionTypes.includes('restrict_trade')) {
    return 'restricted';
  }
  if (actionTypes.includes('mute_chat')) {
    return 'muted';
  }
  return 'active';
}

async function fetchActionById(actionId) {
  const [rows] = await pool.query(
    `SELECT
      id, user_id, source_type, source_id, action_type, reason, comment,
      start_at, end_at, active, created_by, created_at, updated_at,
      canceled_at, canceled_by
    FROM governance_actions
    WHERE id = ?
    LIMIT 1`,
    [actionId]
  );
  return rows[0] || null;
}

async function fetchUserById(userId) {
  const [rows] = await pool.query(
    `SELECT id, role, status
     FROM users
     WHERE id = ?
     LIMIT 1`,
    [userId]
  );
  return rows[0] || null;
}

async function listRawActionsByUser(userId) {
  const [rows] = await pool.query(
    `SELECT
      id, user_id, source_type, source_id, action_type, reason, comment,
      start_at, end_at, active, created_by, created_at, updated_at,
      canceled_at, canceled_by
    FROM governance_actions
    WHERE user_id = ?
    ORDER BY created_at DESC, id DESC`,
    [userId]
  );
  return rows;
}

async function updateUserStatusByActiveActions(conn, userId) {
  const [rows] = await conn.query(
    `SELECT action_type, active
     FROM governance_actions
     WHERE user_id = ?`,
    [userId]
  );

  const nextStatus = resolveStatusFromActiveActions(rows);
  await conn.query(
    `UPDATE users
     SET status = ?
     WHERE id = ?`,
    [nextStatus, userId]
  );
}

async function createAction(req, res) {
  const conn = await pool.getConnection();
  try {
    if (!ensureAdmin(req, res)) return;

    const userId = Number(req.body.user_id);
    const sourceType = String(req.body.source_type || '').trim();
    const sourceId = String(req.body.source_id || '').trim();
    const actionType = String(req.body.action_type || '').trim();
    const reason = String(req.body.reason || '').trim();
    const comment = String(req.body.comment || '').trim();
    const startAt = new Date(Number(req.body.start_at) || Date.now());
    const endAtRaw = req.body.end_at;
    const endAt = endAtRaw !== undefined && endAtRaw !== null && String(endAtRaw).length > 0
      ? new Date(Number(endAtRaw))
      : null;
    const createdBy = Number(req.body.created_by || req.user.id);

    if (Number.isNaN(userId) || userId <= 0) {
      return res.status(400).json(fail('治理用户 id 不合法'));
    }
    if (!['moderation', 'manual_admin'].includes(sourceType)) {
      return res.status(400).json(fail('治理来源类型不合法'));
    }
    if (sourceId.length === 0) {
      return res.status(400).json(fail('治理来源 id 不能为空'));
    }
    if (!GOVERNANCE_ACTION_TYPES.includes(actionType)) {
      return res.status(400).json(fail('治理动作类型不合法'));
    }
    if (reason.length === 0) {
      return res.status(400).json(fail('请先填写治理原因'));
    }

    const user = await fetchUserById(userId);
    if (!user) {
      return res.status(404).json(fail('治理用户不存在'));
    }
    if (user.role === 'admin') {
      return res.status(400).json(fail('不能对管理员账号创建治理动作'));
    }

    await conn.beginTransaction();
    const [result] = await conn.query(
      `INSERT INTO governance_actions (
        user_id, source_type, source_id, action_type, reason, comment,
        start_at, end_at, active, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)`,
      [
        userId,
        sourceType,
        sourceId,
        actionType,
        reason,
        comment || null,
        startAt,
        endAt,
        createdBy
      ]
    );

    if (actionType !== 'warning') {
      await conn.query(
        `UPDATE users
         SET status = ?
         WHERE id = ?`,
        [mapActionTypeToUserStatus(actionType), userId]
      );
    }

    await conn.commit();
    const action = await fetchActionById(result.insertId);
    return res.json(success(toGovernanceActionItem(action), '治理动作创建成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`治理动作创建失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function listActions(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const [rows] = await pool.query(
      `SELECT
        id, user_id, source_type, source_id, action_type, reason, comment,
        start_at, end_at, active, created_by, created_at, updated_at,
        canceled_at, canceled_by
      FROM governance_actions
      ORDER BY created_at DESC, id DESC`
    );

    return res.json(success(rows.map(toGovernanceActionItem), '获取治理动作列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取治理动作列表失败: ${error.message}`));
  }
}

async function listUserActions(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const userId = Number(req.params.id);
    if (Number.isNaN(userId) || userId <= 0) {
      return res.status(400).json(fail('治理用户 id 不合法'));
    }

    const rows = await listRawActionsByUser(userId);
    return res.json(success(rows.map(toGovernanceActionItem), '获取用户治理动作成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取用户治理动作失败: ${error.message}`));
  }
}

async function cancelAction(req, res) {
  const conn = await pool.getConnection();
  try {
    if (!ensureAdmin(req, res)) return;

    const actionId = Number(req.params.id);
    const canceledBy = Number(req.body.canceled_by || req.user.id);
    const comment = String(req.body.comment || '').trim();

    if (Number.isNaN(actionId) || actionId <= 0) {
      return res.status(400).json(fail('治理动作 id 不合法'));
    }

    const action = await fetchActionById(actionId);
    if (!action) {
      return res.status(404).json(fail('治理动作不存在'));
    }
    if (!Boolean(action.active)) {
      return res.status(400).json(fail('治理动作已取消或失效'));
    }

    await conn.beginTransaction();
    await conn.query(
      `UPDATE governance_actions
       SET active = 0, canceled_at = NOW(), canceled_by = ?, comment = ?, updated_at = NOW()
       WHERE id = ?`,
      [canceledBy, comment || action.comment || null, actionId]
    );

    await updateUserStatusByActiveActions(conn, action.user_id);
    await conn.commit();

    const updatedAction = await fetchActionById(actionId);
    return res.json(success(toGovernanceActionItem(updatedAction), '治理动作已取消'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`取消治理动作失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function getUserSummary(req, res) {
  try {
    const userId = Number(req.params.id);
    if (Number.isNaN(userId) || userId <= 0) {
      return res.status(400).json(fail('治理用户 id 不合法'));
    }

    const canView = req.user.role === 'admin' || Number(req.user.id) === userId;
    if (!canView) {
      return res.status(403).json(fail('当前账号无权查看该治理摘要'));
    }

    const rows = await listRawActionsByUser(userId);
    const activeActions = rows.filter((item) => Boolean(item.active));
    const latestAction = rows.length > 0 ? rows[0] : null;
    const [[openCaseRow]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM moderation_records
       WHERE reported_user_id = ? AND status <> 'closed'`,
      [userId]
    );

    return res.json(success({
      user_id: userId,
      active_action_types: activeActions.map((item) => item.action_type),
      latest_action: latestAction ? toGovernanceActionItem(latestAction) : undefined,
      total_action_count: rows.length,
      open_case_count: openCaseRow.total,
      latest_action_at: latestAction ? latestAction.updated_at : undefined
    }, '获取治理摘要成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取治理摘要失败: ${error.message}`));
  }
}

module.exports = {
  createAction,
  listActions,
  listUserActions,
  cancelAction,
  getUserSummary
};
