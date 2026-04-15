const pool = require('../config/db');
const { success, fail } = require('../utils/response');

const ALLOWED_USER_STATUSES = ['active', 'restricted', 'muted', 'suspended', 'banned'];

function ensureAdmin(req, res) {
  if (req.user.role !== 'admin') {
    res.status(403).json(fail('只有管理员可以访问该接口'));
    return false;
  }
  return true;
}

function getStatusUpdateMessage(status) {
  if (status === 'active') {
    return '用户已恢复为正常状态';
  }
  if (status === 'restricted') {
    return '用户已设置为限制交易';
  }
  if (status === 'muted') {
    return '用户已设置为聊天禁言';
  }
  if (status === 'suspended') {
    return '用户已设置为暂时停用';
  }
  return '用户封禁成功';
}

async function queryProductById(productId) {
  const [rows] = await pool.query(
    `SELECT
      p.id, p.seller_id, p.title, p.description, p.price, p.category,
      p.location_tag, p.cover_image, p.status, p.created_at, p.updated_at,
      u.nickname AS seller_nickname,
      u.phone AS seller_phone
    FROM products p
    JOIN users u ON p.seller_id = u.id
    WHERE p.id = ?
    LIMIT 1`,
    [productId]
  );
  return rows[0] || null;
}

async function dashboard(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const [[userCountRow]] = await pool.query('SELECT COUNT(*) AS total FROM users');
    const [[productCountRow]] = await pool.query('SELECT COUNT(*) AS total FROM products');
    const [[orderCountRow]] = await pool.query('SELECT COUNT(*) AS total FROM orders');
    const [[completedOrderCountRow]] = await pool.query(
      `SELECT COUNT(*) AS total FROM orders WHERE status = 'completed'`
    );
    const [[announcementCountRow]] = await pool.query(
      `SELECT COUNT(*) AS total FROM announcements WHERE is_deleted = 0`
    );

    return res.json(success({
      user_count: userCountRow.total,
      product_count: productCountRow.total,
      order_count: orderCountRow.total,
      completed_order_count: completedOrderCountRow.total,
      announcement_count: announcementCountRow.total
    }, '获取后台概况成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取后台概况失败: ${error.message}`));
  }
}

async function listUsers(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const [rows] = await pool.query(
      `SELECT
        id, phone, nickname, avatar, role, status, credit_score,
        created_at, updated_at
      FROM users
      ORDER BY created_at DESC`
    );

    return res.json(success(rows, '获取用户列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取用户列表失败: ${error.message}`));
  }
}

async function updateUserStatus(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const userId = Number(req.params.id);
    const status = String(req.body.status || '').trim();

    if (Number.isNaN(userId) || userId <= 0) {
      return res.status(400).json(fail('用户 id 不合法'));
    }

    if (!ALLOWED_USER_STATUSES.includes(status)) {
      return res.status(400).json(fail('用户状态不在允许范围内'));
    }

    const [rows] = await pool.query(
      `SELECT id, role, status FROM users WHERE id = ? LIMIT 1`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json(fail('用户不存在'));
    }

    const user = rows[0];
    if (user.role === 'admin') {
      return res.status(400).json(fail('不能修改管理员账号状态'));
    }

    await pool.query(
      `UPDATE users SET status = ? WHERE id = ?`,
      [status, userId]
    );

    const [updatedRows] = await pool.query(
      `SELECT
        id, phone, nickname, avatar, role, status, credit_score,
        created_at, updated_at
      FROM users
      WHERE id = ?
      LIMIT 1`,
      [userId]
    );

    return res.json(success(updatedRows[0], getStatusUpdateMessage(status)));
  } catch (error) {
    return res.status(500).json(fail(`更新用户状态失败: ${error.message}`));
  }
}

async function listProducts(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const [rows] = await pool.query(
      `SELECT
        p.id, p.seller_id, p.title, p.description, p.price, p.category,
        p.location_tag, p.cover_image, p.status, p.created_at, p.updated_at,
        u.nickname AS seller_nickname,
        u.phone AS seller_phone
      FROM products p
      JOIN users u ON p.seller_id = u.id
      ORDER BY p.created_at DESC`
    );

    return res.json(success(rows, '获取商品列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取商品列表失败: ${error.message}`));
  }
}

async function approveProduct(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const productId = Number(req.params.id);
    if (Number.isNaN(productId) || productId <= 0) {
      return res.status(400).json(fail('商品 id 不合法'));
    }

    const product = await queryProductById(productId);
    if (!product) {
      return res.status(404).json(fail('商品不存在'));
    }

    await pool.query(`UPDATE products SET status = 'on_sale' WHERE id = ?`, [productId]);
    const updatedProduct = await queryProductById(productId);
    return res.json(success(updatedProduct, '商品审核通过'));
  } catch (error) {
    return res.status(500).json(fail(`商品审核通过失败: ${error.message}`));
  }
}

async function rejectProduct(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const productId = Number(req.params.id);
    if (Number.isNaN(productId) || productId <= 0) {
      return res.status(400).json(fail('商品 id 不合法'));
    }

    const product = await queryProductById(productId);
    if (!product) {
      return res.status(404).json(fail('商品不存在'));
    }

    await pool.query(`UPDATE products SET status = 'rejected' WHERE id = ?`, [productId]);
    const updatedProduct = await queryProductById(productId);
    return res.json(success(updatedProduct, '商品已驳回'));
  } catch (error) {
    return res.status(500).json(fail(`商品驳回失败: ${error.message}`));
  }
}

async function forceOffShelfProduct(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const productId = Number(req.params.id);
    if (Number.isNaN(productId) || productId <= 0) {
      return res.status(400).json(fail('商品 id 不合法'));
    }

    const product = await queryProductById(productId);
    if (!product) {
      return res.status(404).json(fail('商品不存在'));
    }

    await pool.query(`UPDATE products SET status = 'off_shelf' WHERE id = ?`, [productId]);
    const updatedProduct = await queryProductById(productId);
    return res.json(success(updatedProduct, '商品强制下架成功'));
  } catch (error) {
    return res.status(500).json(fail(`商品强制下架失败: ${error.message}`));
  }
}

module.exports = {
  dashboard,
  listUsers,
  updateUserStatus,
  listProducts,
  approveProduct,
  rejectProduct,
  forceOffShelfProduct
};
