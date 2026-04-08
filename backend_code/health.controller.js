const pool = require('../config/db');
const { success, fail } = require('../utils/response');

async function healthCheck(req, res) {
  try {
    const [rows] = await pool.query('SELECT 1 AS ok');
    res.json(success({
      service: 'campus-market-backend',
      database: rows[0]?.ok === 1 ? 'connected' : 'unknown'
    }));
  } catch (error) {
    res.status(500).json(fail(`database error: ${error.message}`));
  }
}

module.exports = {
  healthCheck
};
