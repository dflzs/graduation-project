const pool = require('../config/db');
const { success, fail } = require('../utils/response');

async function createProduct(req, res) {
  try {
    const userId = req.user.id;
    const {
      title,
      description,
      price,
      category,
      location_tag,
      cover_image
    } = req.body;

    if (!title || String(title).trim().length < 2) {
      return res.status(400).json(fail('商品标题至少 2 个字符'));
    }

    if (!description || String(description).trim().length < 5) {
      return res.status(400).json(fail('商品描述至少 5 个字符'));
    }

    const amount = Number(price);
    if (Number.isNaN(amount) || amount <= 0) {
      return res.status(400).json(fail('商品价格必须大于 0'));
    }

    if (!category || String(category).trim().length === 0) {
      return res.status(400).json(fail('商品分类不能为空'));
    }

    if (!location_tag || String(location_tag).trim().length === 0) {
      return res.status(400).json(fail('面交地点不能为空'));
    }

    const [result] = await pool.query(
      `INSERT INTO products
      (seller_id, title, description, price, category, location_tag, cover_image, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'pending_review')`,
      [
        userId,
        String(title).trim(),
        String(description).trim(),
        amount,
        String(category).trim(),
        String(location_tag).trim(),
        String(cover_image || '').trim()
      ]
    );

    const [rows] = await pool.query(
      `SELECT
        p.id, p.seller_id, p.title, p.description, p.price, p.category,
        p.location_tag, p.cover_image, p.status, p.created_at, p.updated_at,
        u.nickname AS seller_nickname, u.phone AS seller_phone
      FROM products p
      JOIN users u ON p.seller_id = u.id
      WHERE p.id = ? LIMIT 1`,
      [result.insertId]
    );

    return res.json(success(rows[0], '商品已提交审核'));
  } catch (error) {
    return res.status(500).json(fail(`商品提交审核失败: ${error.message}`));
  }
}

async function listProducts(req, res) {
  try {
    const keyword = String(req.query.keyword || '').trim();
    const category = String(req.query.category || '').trim();
    const status = String(req.query.status || 'on_sale').trim();

    let sql = `
      SELECT
        p.id, p.seller_id, p.title, p.description, p.price, p.category,
        p.location_tag, p.cover_image, p.status, p.created_at, p.updated_at,
        u.nickname AS seller_nickname, u.phone AS seller_phone
      FROM products p
      JOIN users u ON p.seller_id = u.id
      WHERE 1 = 1
    `;
    const params = [];

    if (keyword) {
      sql += ` AND (p.title LIKE ? OR p.description LIKE ?)`;
      params.push(`%${keyword}%`, `%${keyword}%`);
    }

    if (category) {
      sql += ` AND p.category = ?`;
      params.push(category);
    }

    if (status) {
      sql += ` AND p.status = ?`;
      params.push(status);
    }

    sql += ` ORDER BY p.created_at DESC`;

    const [rows] = await pool.query(sql, params);
    return res.json(success(rows, '获取商品列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取商品列表失败: ${error.message}`));
  }
}

async function listMyProducts(req, res) {
  try {
    const userId = req.user.id;

    const [rows] = await pool.query(
      `SELECT
        p.id, p.seller_id, p.title, p.description, p.price, p.category,
        p.location_tag, p.cover_image, p.status, p.created_at, p.updated_at,
        u.nickname AS seller_nickname, u.phone AS seller_phone
      FROM products p
      JOIN users u ON p.seller_id = u.id
      WHERE p.seller_id = ?
      ORDER BY p.created_at DESC`,
      [userId]
    );

    return res.json(success(rows, '获取我发布的商品成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取我发布的商品失败: ${error.message}`));
  }
}

async function getProductDetail(req, res) {
  try {
    const productId = Number(req.params.id);

    if (Number.isNaN(productId) || productId <= 0) {
      return res.status(400).json(fail('商品 id 不合法'));
    }

    const [rows] = await pool.query(
      `SELECT
        p.id, p.seller_id, p.title, p.description, p.price, p.category,
        p.location_tag, p.cover_image, p.status, p.created_at, p.updated_at,
        u.nickname AS seller_nickname, u.phone AS seller_phone
      FROM products p
      JOIN users u ON p.seller_id = u.id
      WHERE p.id = ? LIMIT 1`,
      [productId]
    );

    if (rows.length === 0) {
      return res.status(404).json(fail('商品不存在'));
    }

    return res.json(success(rows[0], '获取商品详情成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取商品详情失败: ${error.message}`));
  }
}

module.exports = {
  createProduct,
  listProducts,
  listMyProducts,
  getProductDetail
};
