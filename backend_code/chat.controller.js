const pool = require('../config/db');
const { success, fail } = require('../utils/response');

async function createConversation(req, res) {
  try {
    const buyerId = req.user.id;
    const productId = Number(req.body.product_id);
    const orderId = req.body.order_id ? Number(req.body.order_id) : null;

    if (Number.isNaN(productId) || productId <= 0) {
      return res.status(400).json(fail('商品 id 不合法'));
    }

    const [productRows] = await pool.query(
      `SELECT id, seller_id, title
       FROM products
       WHERE id = ?
       LIMIT 1`,
      [productId]
    );

    if (productRows.length === 0) {
      return res.status(404).json(fail('商品不存在'));
    }

    const product = productRows[0];
    const sellerId = Number(product.seller_id);

    if (sellerId === Number(buyerId)) {
      return res.status(400).json(fail('不能和自己发起会话'));
    }

    const [exists] = await pool.query(
      `SELECT id, product_id, order_id, buyer_id, seller_id, last_message, last_message_at, created_at
       FROM conversations
       WHERE product_id = ? AND buyer_id = ? AND seller_id = ?
       LIMIT 1`,
      [productId, buyerId, sellerId]
    );

    if (exists.length > 0) {
      return res.json(success(exists[0], '会话已存在'));
    }

    const [result] = await pool.query(
      `INSERT INTO conversations
      (product_id, order_id, buyer_id, seller_id, last_message, last_message_at)
      VALUES (?, ?, ?, ?, '', NULL)`,
      [productId, orderId, buyerId, sellerId]
    );

    const [rows] = await pool.query(
      `SELECT id, product_id, order_id, buyer_id, seller_id, last_message, last_message_at, created_at
       FROM conversations
       WHERE id = ?
       LIMIT 1`,
      [result.insertId]
    );

    return res.json(success(rows[0], '创建会话成功'));
  } catch (error) {
    return res.status(500).json(fail(`创建会话失败: ${error.message}`));
  }
}

async function listConversations(req, res) {
  try {
    const userId = req.user.id;

    const [rows] = await pool.query(
      `SELECT
        c.id, c.product_id, c.order_id, c.buyer_id, c.seller_id,
        c.last_message, c.last_message_at, c.created_at,
        p.title AS product_title,
        buyer.nickname AS buyer_nickname,
        seller.nickname AS seller_nickname,
        (
          SELECT COUNT(*)
          FROM chat_messages cm
          WHERE cm.conversation_id = c.id
            AND cm.to_user_id = ?
            AND cm.is_read = 0
        ) AS unread_count
      FROM conversations c
      LEFT JOIN products p ON c.product_id = p.id
      JOIN users buyer ON c.buyer_id = buyer.id
      JOIN users seller ON c.seller_id = seller.id
      WHERE c.buyer_id = ? OR c.seller_id = ?
      ORDER BY c.last_message_at DESC, c.created_at DESC`,
      [userId, userId, userId]
    );

    return res.json(success(rows, '获取会话列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取会话列表失败: ${error.message}`));
  }
}

async function getMessages(req, res) {
  try {
    const userId = req.user.id;
    const conversationId = Number(req.params.id);

    if (Number.isNaN(conversationId) || conversationId <= 0) {
      return res.status(400).json(fail('会话 id 不合法'));
    }

    const [convRows] = await pool.query(
      `SELECT id, buyer_id, seller_id
       FROM conversations
       WHERE id = ?
       LIMIT 1`,
      [conversationId]
    );

    if (convRows.length === 0) {
      return res.status(404).json(fail('会话不存在'));
    }

    const conv = convRows[0];
    if (Number(conv.buyer_id) !== Number(userId) && Number(conv.seller_id) !== Number(userId)) {
      return res.status(403).json(fail('无权查看该会话'));
    }

    await pool.query(
      `UPDATE chat_messages
       SET is_read = 1
       WHERE conversation_id = ? AND to_user_id = ? AND is_read = 0`,
      [conversationId, userId]
    );

    const [rows] = await pool.query(
      `SELECT
        cm.id, cm.conversation_id, cm.from_user_id, cm.to_user_id,
        cm.content, cm.is_read, cm.created_at,
        fu.nickname AS from_nickname,
        tu.nickname AS to_nickname
      FROM chat_messages cm
      JOIN users fu ON cm.from_user_id = fu.id
      JOIN users tu ON cm.to_user_id = tu.id
      WHERE cm.conversation_id = ?
      ORDER BY cm.created_at ASC`,
      [conversationId]
    );

    return res.json(success(rows, '获取聊天记录成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取聊天记录失败: ${error.message}`));
  }
}

async function sendMessage(req, res) {
  const conn = await pool.getConnection();
  try {
    const fromUserId = req.user.id;
    const conversationId = Number(req.params.id);
    const content = String(req.body.content || '').trim();

    if (Number.isNaN(conversationId) || conversationId <= 0) {
      return res.status(400).json(fail('会话 id 不合法'));
    }

    if (!content) {
      return res.status(400).json(fail('消息内容不能为空'));
    }

    const [convRows] = await conn.query(
      `SELECT id, buyer_id, seller_id
       FROM conversations
       WHERE id = ?
       LIMIT 1`,
      [conversationId]
    );

    if (convRows.length === 0) {
      return res.status(404).json(fail('会话不存在'));
    }

    const conv = convRows[0];
    if (Number(conv.buyer_id) !== Number(fromUserId) && Number(conv.seller_id) !== Number(fromUserId)) {
      return res.status(403).json(fail('无权向该会话发送消息'));
    }

    const toUserId = Number(conv.buyer_id) === Number(fromUserId)
      ? Number(conv.seller_id)
      : Number(conv.buyer_id);

    await conn.beginTransaction();

    const [result] = await conn.query(
      `INSERT INTO chat_messages
      (conversation_id, from_user_id, to_user_id, content, is_read)
      VALUES (?, ?, ?, ?, 0)`,
      [conversationId, fromUserId, toUserId, content]
    );

    await conn.query(
      `UPDATE conversations
       SET last_message = ?, last_message_at = NOW()
       WHERE id = ?`,
      [content, conversationId]
    );

    await conn.commit();

    const [rows] = await conn.query(
      `SELECT
        cm.id, cm.conversation_id, cm.from_user_id, cm.to_user_id,
        cm.content, cm.is_read, cm.created_at,
        fu.nickname AS from_nickname,
        tu.nickname AS to_nickname
      FROM chat_messages cm
      JOIN users fu ON cm.from_user_id = fu.id
      JOIN users tu ON cm.to_user_id = tu.id
      WHERE cm.id = ?
      LIMIT 1`,
      [result.insertId]
    );

    return res.json(success(rows[0], '发送消息成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`发送消息失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

module.exports = {
  createConversation,
  listConversations,
  getMessages,
  sendMessage
};
