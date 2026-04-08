const pool = require('../config/db');
const { success, fail } = require('../utils/response');

function generateOrderNo() {
  return `CM${Date.now()}${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`;
}

async function appendOrderLog(conn, orderId, operatorId, action, remark = '') {
  await conn.query(
    `INSERT INTO order_logs (order_id, operator_id, action, remark)
     VALUES (?, ?, ?, ?)`,
    [orderId, operatorId, action, remark]
  );
}

async function fetchOrderDetail(conn, orderId) {
  const [rows] = await conn.query(
    `SELECT
      o.id, o.order_no, o.product_id, o.buyer_id, o.seller_id, o.amount,
      o.address, o.location_tag, o.pay_type, o.status, o.buyer_arrived,
      o.seller_arrived, o.created_at, o.updated_at,
      p.title AS product_title,
      p.cover_image,
      buyer.nickname AS buyer_nickname,
      seller.nickname AS seller_nickname
    FROM orders o
    JOIN products p ON o.product_id = p.id
    JOIN users buyer ON o.buyer_id = buyer.id
    JOIN users seller ON o.seller_id = seller.id
    WHERE o.id = ?
    LIMIT 1`,
    [orderId]
  );

  return rows[0] || null;
}

async function createOrder(req, res) {
  const conn = await pool.getConnection();
  try {
    const buyerId = req.user.id;
    const productId = Number(req.body.product_id);
    const address = String(req.body.address || '').trim();
    const locationTag = String(req.body.location_tag || '').trim();

    if (Number.isNaN(productId) || productId <= 0) {
      return res.status(400).json(fail('商品 id 不合法'));
    }

    if (!address) {
      return res.status(400).json(fail('收货地址或面交说明不能为空'));
    }

    if (!locationTag) {
      return res.status(400).json(fail('面交地点不能为空'));
    }

    await conn.beginTransaction();

    const [productRows] = await conn.query(
      `SELECT id, seller_id, title, price, status
       FROM products
       WHERE id = ?
       LIMIT 1`,
      [productId]
    );

    if (productRows.length === 0) {
      await conn.rollback();
      return res.status(404).json(fail('商品不存在'));
    }

    const product = productRows[0];

    if (Number(product.seller_id) === Number(buyerId)) {
      await conn.rollback();
      return res.status(400).json(fail('不能购买自己发布的商品'));
    }

    if (product.status !== 'on_sale') {
      await conn.rollback();
      return res.status(400).json(fail('商品当前不可购买'));
    }

    const orderNo = generateOrderNo();
    const [result] = await conn.query(
      `INSERT INTO orders
      (order_no, product_id, buyer_id, seller_id, amount, address, location_tag, pay_type, status, buyer_arrived, seller_arrived)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'simulated', 'pending_payment', 0, 0)`,
      [
        orderNo,
        product.id,
        buyerId,
        product.seller_id,
        product.price,
        address,
        locationTag
      ]
    );

    await conn.query(
      `UPDATE products SET status = 'locked' WHERE id = ?`,
      [product.id]
    );

    await appendOrderLog(conn, result.insertId, buyerId, 'create', '买家创建订单，商品进入交易中');
    await conn.commit();

    const detail = await fetchOrderDetail(conn, result.insertId);
    return res.json(success(detail, '下单成功，商品已进入交易中'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`下单失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function listOrders(req, res) {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(
      `SELECT
        o.id, o.order_no, o.product_id, o.buyer_id, o.seller_id, o.amount,
        o.address, o.location_tag, o.pay_type, o.status, o.buyer_arrived,
        o.seller_arrived, o.created_at, o.updated_at,
        p.title AS product_title,
        p.cover_image,
        buyer.nickname AS buyer_nickname,
        seller.nickname AS seller_nickname
      FROM orders o
      JOIN products p ON o.product_id = p.id
      JOIN users buyer ON o.buyer_id = buyer.id
      JOIN users seller ON o.seller_id = seller.id
      WHERE o.buyer_id = ? OR o.seller_id = ?
      ORDER BY o.created_at DESC`,
      [userId, userId]
    );

    return res.json(success(rows, '获取订单列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取订单列表失败: ${error.message}`));
  }
}

async function getOrderDetail(req, res) {
  try {
    const userId = req.user.id;
    const orderId = Number(req.params.id);

    if (Number.isNaN(orderId) || orderId <= 0) {
      return res.status(400).json(fail('订单 id 不合法'));
    }

    const order = await fetchOrderDetail(pool, orderId);
    if (!order) {
      return res.status(404).json(fail('订单不存在'));
    }

    if (Number(order.buyer_id) !== Number(userId) && Number(order.seller_id) !== Number(userId)) {
      return res.status(403).json(fail('无权查看该订单'));
    }

    return res.json(success(order, '获取订单详情成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取订单详情失败: ${error.message}`));
  }
}

async function simulatePay(req, res) {
  const conn = await pool.getConnection();
  try {
    const userId = req.user.id;
    const orderId = Number(req.params.id);

    if (Number.isNaN(orderId) || orderId <= 0) {
      return res.status(400).json(fail('订单 id 不合法'));
    }

    await conn.beginTransaction();

    const [rows] = await conn.query(
      `SELECT id, buyer_id, seller_id, product_id, status
       FROM orders
       WHERE id = ?
       LIMIT 1`,
      [orderId]
    );

    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json(fail('订单不存在'));
    }

    const order = rows[0];

    if (Number(order.buyer_id) !== Number(userId)) {
      await conn.rollback();
      return res.status(403).json(fail('只有买家可以支付订单'));
    }

    if (order.status !== 'pending_payment') {
      await conn.rollback();
      return res.status(400).json(fail('当前订单状态不可支付'));
    }

    await conn.query(
      `UPDATE orders SET status = 'paid' WHERE id = ?`,
      [orderId]
    );

    await appendOrderLog(conn, orderId, userId, 'pay', '买家完成模拟支付');
    await conn.commit();

    const detail = await fetchOrderDetail(conn, orderId);
    return res.json(success(detail, '模拟支付成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`模拟支付失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function cancelOrder(req, res) {
  const conn = await pool.getConnection();
  try {
    const userId = req.user.id;
    const orderId = Number(req.params.id);

    if (Number.isNaN(orderId) || orderId <= 0) {
      return res.status(400).json(fail('订单 id 不合法'));
    }

    await conn.beginTransaction();

    const [rows] = await conn.query(
      `SELECT id, buyer_id, seller_id, product_id, status
       FROM orders
       WHERE id = ?
       LIMIT 1`,
      [orderId]
    );

    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json(fail('订单不存在'));
    }

    const order = rows[0];

    if (Number(order.buyer_id) !== Number(userId)) {
      await conn.rollback();
      return res.status(403).json(fail('只有买家可以取消订单'));
    }

    if (order.status !== 'pending_payment') {
      await conn.rollback();
      return res.status(400).json(fail('当前订单状态不可取消'));
    }

    await conn.query(
      `UPDATE orders SET status = 'canceled' WHERE id = ?`,
      [orderId]
    );

    await conn.query(
      `UPDATE products SET status = 'on_sale' WHERE id = ? AND status = 'locked'`,
      [order.product_id]
    );

    await appendOrderLog(conn, orderId, userId, 'cancel', '买家取消订单，商品恢复在售');
    await conn.commit();

    const detail = await fetchOrderDetail(conn, orderId);
    return res.json(success(detail, '订单已取消，商品已恢复在售'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`取消订单失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function markArrived(req, res) {
  const conn = await pool.getConnection();
  try {
    const userId = req.user.id;
    const orderId = Number(req.params.id);

    if (Number.isNaN(orderId) || orderId <= 0) {
      return res.status(400).json(fail('订单 id 不合法'));
    }

    await conn.beginTransaction();

    const [rows] = await conn.query(
      `SELECT id, buyer_id, seller_id, status, buyer_arrived, seller_arrived
       FROM orders
       WHERE id = ?
       LIMIT 1`,
      [orderId]
    );

    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json(fail('订单不存在'));
    }

    const order = rows[0];

    if (Number(order.buyer_id) !== Number(userId) && Number(order.seller_id) !== Number(userId)) {
      await conn.rollback();
      return res.status(403).json(fail('仅交易双方可以确认到达'));
    }

    if (order.status !== 'paid' && order.status !== 'ready_handover') {
      await conn.rollback();
      return res.status(400).json(fail('当前订单状态不可确认到达'));
    }

    let buyerArrived = Number(order.buyer_arrived);
    let sellerArrived = Number(order.seller_arrived);

    if (Number(order.buyer_id) === Number(userId)) {
      buyerArrived = 1;
    }

    if (Number(order.seller_id) === Number(userId)) {
      sellerArrived = 1;
    }

    const nextStatus = buyerArrived === 1 && sellerArrived === 1 ? 'ready_handover' : order.status;

    await conn.query(
      `UPDATE orders
       SET buyer_arrived = ?, seller_arrived = ?, status = ?
       WHERE id = ?`,
      [buyerArrived, sellerArrived, nextStatus, orderId]
    );

    await appendOrderLog(conn, orderId, userId, 'arrive', '用户确认已到达面交地点');
    await conn.commit();

    const detail = await fetchOrderDetail(conn, orderId);
    return res.json(success(detail, '到达状态更新成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`确认到达失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function completeOrder(req, res) {
  const conn = await pool.getConnection();
  try {
    const userId = req.user.id;
    const orderId = Number(req.params.id);

    if (Number.isNaN(orderId) || orderId <= 0) {
      return res.status(400).json(fail('订单 id 不合法'));
    }

    await conn.beginTransaction();

    const [rows] = await conn.query(
      `SELECT id, buyer_id, seller_id, product_id, status, buyer_arrived, seller_arrived
       FROM orders
       WHERE id = ?
       LIMIT 1`,
      [orderId]
    );

    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json(fail('订单不存在'));
    }

    const order = rows[0];

    if (Number(order.buyer_id) !== Number(userId) && Number(order.seller_id) !== Number(userId)) {
      await conn.rollback();
      return res.status(403).json(fail('仅交易双方可以完成订单'));
    }

    if (order.status !== 'ready_handover') {
      await conn.rollback();
      return res.status(400).json(fail('只有双方都到达后才能完成订单'));
    }

    await conn.query(
      `UPDATE orders SET status = 'completed' WHERE id = ?`,
      [orderId]
    );

    await conn.query(
      `UPDATE products SET status = 'sold' WHERE id = ?`,
      [order.product_id]
    );

    await appendOrderLog(conn, orderId, userId, 'complete', '订单已完成，商品售出');
    await conn.commit();

    const detail = await fetchOrderDetail(conn, orderId);
    return res.json(success(detail, '订单完成成功'));
  } catch (error) {
    await conn.rollback();
    return res.status(500).json(fail(`完成订单失败: ${error.message}`));
  } finally {
    conn.release();
  }
}

async function listOrderLogs(req, res) {
  try {
    const userId = req.user.id;
    const orderId = Number(req.params.id);

    if (Number.isNaN(orderId) || orderId <= 0) {
      return res.status(400).json(fail('订单 id 不合法'));
    }

    const [orderRows] = await pool.query(
      `SELECT id, buyer_id, seller_id
       FROM orders
       WHERE id = ?
       LIMIT 1`,
      [orderId]
    );

    if (orderRows.length === 0) {
      return res.status(404).json(fail('订单不存在'));
    }

    const order = orderRows[0];
    if (Number(order.buyer_id) !== Number(userId) && Number(order.seller_id) !== Number(userId)) {
      return res.status(403).json(fail('无权查看订单日志'));
    }

    const [rows] = await pool.query(
      `SELECT
        ol.id, ol.order_id, ol.operator_id, ol.action, ol.remark, ol.created_at,
        u.nickname AS operator_nickname
      FROM order_logs ol
      JOIN users u ON ol.operator_id = u.id
      WHERE ol.order_id = ?
      ORDER BY ol.created_at ASC, ol.id ASC`,
      [orderId]
    );

    return res.json(success(rows, '获取订单日志成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取订单日志失败: ${error.message}`));
  }
}

module.exports = {
  createOrder,
  listOrders,
  getOrderDetail,
  simulatePay,
  cancelOrder,
  markArrived,
  completeOrder,
  listOrderLogs
};
