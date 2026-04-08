const pool = require('../config/db');
const { success, fail } = require('../utils/response');

async function listAnnouncements(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT
        a.id, a.title, a.content, a.publisher_id, a.is_deleted,
        a.created_at, a.updated_at,
        u.nickname AS publisher_nickname
      FROM announcements a
      JOIN users u ON a.publisher_id = u.id
      WHERE a.is_deleted = 0
      ORDER BY a.created_at DESC`
    );

    return res.json(success(rows, '获取公告列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取公告列表失败: ${error.message}`));
  }
}

async function getAnnouncementDetail(req, res) {
  try {
    const id = Number(req.params.id);

    if (Number.isNaN(id) || id <= 0) {
      return res.status(400).json(fail('公告 id 不合法'));
    }

    const [rows] = await pool.query(
      `SELECT
        a.id, a.title, a.content, a.publisher_id, a.is_deleted,
        a.created_at, a.updated_at,
        u.nickname AS publisher_nickname
      FROM announcements a
      JOIN users u ON a.publisher_id = u.id
      WHERE a.id = ? AND a.is_deleted = 0
      LIMIT 1`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json(fail('公告不存在'));
    }

    return res.json(success(rows[0], '获取公告详情成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取公告详情失败: ${error.message}`));
  }
}

async function createAnnouncement(req, res) {
  try {
    const publisherId = req.user.id;
    const role = req.user.role;
    const title = String(req.body.title || '').trim();
    const content = String(req.body.content || '').trim();

    if (role !== 'admin') {
      return res.status(403).json(fail('只有管理员可以发布公告'));
    }

    if (!title || title.length < 2) {
      return res.status(400).json(fail('公告标题至少 2 个字符'));
    }

    if (!content || content.length < 5) {
      return res.status(400).json(fail('公告内容至少 5 个字符'));
    }

    const [result] = await pool.query(
      `INSERT INTO announcements (title, content, publisher_id, is_deleted)
       VALUES (?, ?, ?, 0)`,
      [title, content, publisherId]
    );

    const [rows] = await pool.query(
      `SELECT
        a.id, a.title, a.content, a.publisher_id, a.is_deleted,
        a.created_at, a.updated_at,
        u.nickname AS publisher_nickname
      FROM announcements a
      JOIN users u ON a.publisher_id = u.id
      WHERE a.id = ?
      LIMIT 1`,
      [result.insertId]
    );

    return res.json(success(rows[0], '公告发布成功'));
  } catch (error) {
    return res.status(500).json(fail(`公告发布失败: ${error.message}`));
  }
}

async function deleteAnnouncement(req, res) {
  try {
    const operatorRole = req.user.role;
    const id = Number(req.params.id);

    if (operatorRole !== 'admin') {
      return res.status(403).json(fail('只有管理员可以删除公告'));
    }

    if (Number.isNaN(id) || id <= 0) {
      return res.status(400).json(fail('公告 id 不合法'));
    }

    const [exists] = await pool.query(
      `SELECT id FROM announcements WHERE id = ? AND is_deleted = 0 LIMIT 1`,
      [id]
    );

    if (exists.length === 0) {
      return res.status(404).json(fail('公告不存在'));
    }

    await pool.query(
      `UPDATE announcements SET is_deleted = 1 WHERE id = ?`,
      [id]
    );

    return res.json(success(null, '公告删除成功'));
  } catch (error) {
    return res.status(500).json(fail(`公告删除失败: ${error.message}`));
  }
}

module.exports = {
  listAnnouncements,
  getAnnouncementDetail,
  createAnnouncement,
  deleteAnnouncement
};
