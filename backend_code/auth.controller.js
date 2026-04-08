const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const { success, fail } = require('../utils/response');
const { signToken } = require('../utils/jwt');
const {
  issueRegisterCode,
  verifyRegisterCode,
  consumeRegisterTicket
} = require('./register-verification.store');

const SHOW_DEBUG_CODE = process.env.NODE_ENV !== 'production';

function validatePhone(phone) {
  return /^1\d{10}$/.test(String(phone || '').trim());
}

function validateCode(code) {
  return /^\d{6}$/.test(String(code || '').trim());
}

async function sendRegisterCode(req, res) {
  try {
    const { phone } = req.body;

    if (!validatePhone(phone)) {
      return res.status(400).json(fail('请输入正确的手机号。'));
    }

    const [exists] = await pool.query(
      'SELECT id FROM users WHERE phone = ? LIMIT 1',
      [phone]
    );

    if (exists.length > 0) {
      return res.status(400).json(fail('该手机号已注册。'));
    }

    const debugCode = issueRegisterCode(phone);
    const responseData = { phone };
    if (SHOW_DEBUG_CODE) {
      console.info(`[RegisterCode] phone=${phone} debugCode=${debugCode}`);
      responseData.debugCode = debugCode;
    }

    return res.json(success(responseData, '注册验证码已发送'));
  } catch (error) {
    return res.status(500).json(fail(`发送验证码失败: ${error.message}`));
  }
}

async function verifyRegisterCodeHandler(req, res) {
  try {
    const { phone, code } = req.body;

    if (!validatePhone(phone)) {
      return res.status(400).json(fail('请输入正确的手机号。'));
    }
    if (!validateCode(code)) {
      return res.status(400).json(fail('请输入 6 位验证码。'));
    }

    const result = verifyRegisterCode(phone, code);
    if (!result.ok) {
      return res.status(400).json(fail(result.message));
    }

    return res.json(success(result.data, '验证码校验成功'));
  } catch (error) {
    return res.status(500).json(fail(`校验验证码失败: ${error.message}`));
  }
}

async function register(req, res) {
  try {
    const { phone, registerTicket, password, nickname } = req.body;

    if (!validatePhone(phone)) {
      return res.status(400).json(fail('请输入正确的手机号。'));
    }
    if (!registerTicket || String(registerTicket).trim().length === 0) {
      return res.status(400).json(fail('注册凭证无效，请重新验证手机号。'));
    }
    if (!password || String(password).trim().length < 6) {
      return res.status(400).json(fail('密码长度不能少于 6 位。'));
    }
    if (!nickname || String(nickname).trim().length < 2) {
      return res.status(400).json(fail('昵称长度不能少于 2 位。'));
    }

    const ticketResult = consumeRegisterTicket(phone, String(registerTicket).trim());
    if (!ticketResult.ok) {
      return res.status(400).json(fail(ticketResult.message));
    }

    const [exists] = await pool.query(
      'SELECT id FROM users WHERE phone = ? LIMIT 1',
      [phone]
    );

    if (exists.length > 0) {
      return res.status(400).json(fail('该手机号已注册。'));
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      `INSERT INTO users (phone, password_hash, nickname, role, status, credit_score)
       VALUES (?, ?, ?, 'user', 'active', 60)`,
      [phone, passwordHash, nickname]
    );

    const [rows] = await pool.query(
      `SELECT id, phone, nickname, avatar, role, status, credit_score, created_at, updated_at
       FROM users WHERE id = ? LIMIT 1`,
      [result.insertId]
    );

    const user = rows[0];
    const token = signToken({
      id: user.id,
      phone: user.phone,
      role: user.role
    });

    return res.json(success({ token, user }, '注册成功'));
  } catch (error) {
    return res.status(500).json(fail(`注册失败: ${error.message}`));
  }
}

async function loginByPassword(req, res) {
  try {
    const { phone, password } = req.body;

    if (!validatePhone(phone)) {
      return res.status(400).json(fail('请输入正确的手机号。'));
    }
    if (!password || String(password).trim().length < 6) {
      return res.status(400).json(fail('密码长度不能少于 6 位。'));
    }

    const [rows] = await pool.query(
      `SELECT id, phone, password_hash, nickname, avatar, role, status, credit_score, created_at, updated_at
       FROM users WHERE phone = ? LIMIT 1`,
      [phone]
    );

    if (rows.length === 0) {
      return res.status(404).json(fail('用户不存在。'));
    }

    const user = rows[0];
    if (user.status !== 'active') {
      return res.status(403).json(fail('账号已被封禁。'));
    }

    const matched = await bcrypt.compare(password, user.password_hash);
    if (!matched) {
      return res.status(400).json(fail('密码错误。'));
    }

    const token = signToken({
      id: user.id,
      phone: user.phone,
      role: user.role
    });

    delete user.password_hash;
    return res.json(success({ token, user }, '登录成功'));
  } catch (error) {
    return res.status(500).json(fail(`登录失败: ${error.message}`));
  }
}

async function me(req, res) {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(
      `SELECT id, phone, nickname, avatar, role, status, credit_score, created_at, updated_at
       FROM users WHERE id = ? LIMIT 1`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json(fail('用户不存在。'));
    }

    return res.json(success(rows[0], '获取当前用户成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取用户信息失败: ${error.message}`));
  }
}

async function updateMe(req, res) {
  try {
    const userId = req.user.id;
    const nickname = String(req.body?.nickname || '').trim();
    const avatar = String(req.body?.avatar || '').trim();

    if (nickname.length > 0 && nickname.length < 2) {
      return res.status(400).json(fail('昵称长度不能少于 2 个字。'));
    }
    if (avatar.length > 0 && !/^https?:\/\//.test(avatar) && !avatar.startsWith('/uploads/')) {
      return res.status(400).json(fail('头像地址格式不正确。'));
    }

    const updates = [];
    const values = [];

    if (nickname.length > 0) {
      updates.push('nickname = ?');
      values.push(nickname);
    }
    if (avatar.length > 0) {
      updates.push('avatar = ?');
      values.push(avatar);
    }

    if (updates.length === 0) {
      return res.status(400).json(fail('至少需要提交一项可更新的资料。'));
    }

    values.push(userId);
    await pool.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
      values
    );

    const [rows] = await pool.query(
      `SELECT id, phone, nickname, avatar, role, status, credit_score, created_at, updated_at
       FROM users WHERE id = ? LIMIT 1`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json(fail('用户不存在。'));
    }

    return res.json(success(rows[0], '个人资料更新成功'));
  } catch (error) {
    return res.status(500).json(fail(`更新个人资料失败: ${error.message}`));
  }
}

async function seedAdmin(req, res) {
  try {
    const phone = '19900000000';
    const nickname = '系统管理员';
    const plainPassword = 'Admin@2026';

    const [exists] = await pool.query(
      'SELECT id FROM users WHERE phone = ? LIMIT 1',
      [phone]
    );

    if (exists.length > 0) {
      return res.json(success({ phone, password: plainPassword }, '管理员账户已存在'));
    }

    const passwordHash = await bcrypt.hash(plainPassword, 10);
    await pool.query(
      `INSERT INTO users (phone, password_hash, nickname, role, status, credit_score)
       VALUES (?, ?, ?, 'admin', 'active', 100)`,
      [phone, passwordHash, nickname]
    );

    return res.json(success({ phone, password: plainPassword }, '管理员账户初始化成功'));
  } catch (error) {
    return res.status(500).json(fail(`初始化管理员失败: ${error.message}`));
  }
}

module.exports = {
  sendRegisterCode,
  verifyRegisterCode: verifyRegisterCodeHandler,
  register,
  loginByPassword,
  me,
  updateMe,
  seedAdmin
};
