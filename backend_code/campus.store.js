const pool = require('../config/db');

/*
 * Data ownership in this module:
 * - schools
 * - campuses
 * - location_groups
 * - trade_locations
 * - student_verifications
 * - users campus identity projection fields
 */

function parseJsonArray(value) {
  if (!value) {
    return [];
  }

  if (Array.isArray(value)) {
    return value;
  }

  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    return [];
  }
}

function mapTradeLocationRow(row) {
  return {
    id: row.id,
    school_id: row.school_id,
    campus_id: row.campus_id,
    group_id: row.group_id,
    group_name: row.group_name || null,
    name: row.name,
    alias: row.alias,
    description: row.description,
    safety_tips: row.safety_tips,
    recommended_categories: parseJsonArray(row.recommended_categories),
    sort_order: Number(row.sort_order || 0),
    is_hot: Boolean(row.is_hot),
    is_enabled: Boolean(row.is_enabled),
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

async function getSchoolById(schoolId) {
  const [rows] = await pool.query(
    `SELECT id, name, short_name, province_name, city_name, display_order, is_enabled, created_at, updated_at
     FROM schools
     WHERE id = ?
     LIMIT 1`,
    [schoolId]
  );
  return rows[0] || null;
}

async function getCampusById(campusId) {
  const [rows] = await pool.query(
    `SELECT id, school_id, name, short_name, display_order, is_enabled, created_at, updated_at
     FROM campuses
     WHERE id = ?
     LIMIT 1`,
    [campusId]
  );
  return rows[0] || null;
}

async function findCampusBySchoolAndName(schoolId, campusName) {
  const [rows] = await pool.query(
    `SELECT id, school_id, name, short_name, display_order, is_enabled, created_at, updated_at
     FROM campuses
     WHERE school_id = ?
       AND (name = ? OR short_name = ?)
     ORDER BY display_order ASC, created_at ASC
     LIMIT 1`,
    [schoolId, campusName, campusName]
  );
  return rows[0] || null;
}

async function getLocationGroupById(groupId) {
  const [rows] = await pool.query(
    `SELECT id, school_id, campus_id, name, description, display_order, is_enabled, created_at, updated_at
     FROM location_groups
     WHERE id = ?
     LIMIT 1`,
    [groupId]
  );
  return rows[0] || null;
}

async function getTradeLocationById(locationId) {
  const [rows] = await pool.query(
    `SELECT
       tl.id, tl.school_id, tl.campus_id, tl.group_id, lg.name AS group_name,
       tl.name, tl.alias, tl.description, tl.safety_tips, tl.recommended_categories,
       tl.sort_order, tl.is_hot, tl.is_enabled, tl.created_at, tl.updated_at
     FROM trade_locations tl
     JOIN location_groups lg ON tl.group_id = lg.id
     WHERE tl.id = ?
     LIMIT 1`,
    [locationId]
  );
  if (rows.length === 0) {
    return null;
  }
  return mapTradeLocationRow(rows[0]);
}

async function listSchools(includeDisabled) {
  let sql = `
    SELECT id, name, short_name, province_name, city_name, display_order, is_enabled, created_at, updated_at
    FROM schools
  `;
  const params = [];

  if (!includeDisabled) {
    sql += ` WHERE is_enabled = 1`;
  }

  sql += ` ORDER BY display_order ASC, created_at ASC`;
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function listCampuses(options) {
  const schoolId = String(options?.schoolId || '').trim();
  const includeDisabled = Boolean(options?.includeDisabled);

  let sql = `
    SELECT id, school_id, name, short_name, display_order, is_enabled, created_at, updated_at
    FROM campuses
    WHERE 1 = 1
  `;
  const params = [];

  if (schoolId) {
    sql += ` AND school_id = ?`;
    params.push(schoolId);
  }
  if (!includeDisabled) {
    sql += ` AND is_enabled = 1`;
  }

  sql += ` ORDER BY display_order ASC, created_at ASC`;
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function listLocationGroups(options) {
  const schoolId = String(options?.schoolId || '').trim();
  const campusId = String(options?.campusId || '').trim();
  const includeDisabled = Boolean(options?.includeDisabled);

  let sql = `
    SELECT id, school_id, campus_id, name, description, display_order, is_enabled, created_at, updated_at
    FROM location_groups
    WHERE 1 = 1
  `;
  const params = [];

  if (schoolId) {
    sql += ` AND school_id = ?`;
    params.push(schoolId);
  }
  if (campusId) {
    sql += ` AND campus_id = ?`;
    params.push(campusId);
  }
  if (!includeDisabled) {
    sql += ` AND is_enabled = 1`;
  }

  sql += ` ORDER BY display_order ASC, created_at ASC`;
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function listTradeLocations(options) {
  const schoolId = String(options?.schoolId || '').trim();
  const campusId = String(options?.campusId || '').trim();
  const groupId = String(options?.groupId || '').trim();
  const category = String(options?.category || '').trim();
  const includeDisabled = Boolean(options?.includeDisabled);

  let sql = `
    SELECT
      tl.id, tl.school_id, tl.campus_id, tl.group_id, lg.name AS group_name,
      tl.name, tl.alias, tl.description, tl.safety_tips, tl.recommended_categories,
      tl.sort_order, tl.is_hot, tl.is_enabled, tl.created_at, tl.updated_at
    FROM trade_locations tl
    JOIN location_groups lg ON tl.group_id = lg.id
    WHERE 1 = 1
  `;
  const params = [];

  if (schoolId) {
    sql += ` AND tl.school_id = ?`;
    params.push(schoolId);
  }
  if (campusId) {
    sql += ` AND tl.campus_id = ?`;
    params.push(campusId);
  }
  if (groupId) {
    sql += ` AND tl.group_id = ?`;
    params.push(groupId);
  }
  if (!includeDisabled) {
    sql += ` AND tl.is_enabled = 1`;
  }

  sql += ` ORDER BY tl.is_hot DESC, tl.sort_order ASC, tl.created_at ASC`;

  const [rows] = await pool.query(sql, params);
  const mapped = rows.map(mapTradeLocationRow);

  if (!category) {
    return mapped;
  }

  return mapped.filter((item) => item.recommended_categories.includes(category));
}

async function fetchUserCampusProfile(userId) {
  const [rows] = await pool.query(
    `SELECT
       u.id, u.school_id, s.name AS school_name, u.campus_id, c.name AS campus_name,
       u.student_no, u.grade_year, u.college_name, u.major_name,
       u.verification_status, u.verification_method, u.verified_at,
       u.verification_rejected_reason, u.verification_updated_at,
       u.completed_order_count, u.report_count, u.last_active_at
     FROM users u
     LEFT JOIN schools s ON u.school_id = s.id
     LEFT JOIN campuses c ON u.campus_id = c.id
     WHERE u.id = ?
     LIMIT 1`,
    [userId]
  );
  return rows[0] || null;
}

async function updateUserCampusProfile(userId, input) {
  await pool.query(
    `UPDATE users
     SET school_id = ?, campus_id = ?, student_no = ?, grade_year = ?, college_name = ?, major_name = ?,
         verification_updated_at = NOW()
     WHERE id = ?`,
    [
      input.schoolId,
      input.campusId,
      input.studentNo,
      input.gradeYear,
      input.collegeName,
      input.majorName,
      userId
    ]
  );

  return fetchUserCampusProfile(userId);
}

async function fetchLatestVerificationByUser(userId) {
  const [rows] = await pool.query(
    `SELECT
       sv.id, sv.user_id, sv.school_id, s.name AS school_name, sv.campus_id, c.name AS campus_name,
       sv.student_no, sv.grade_year, sv.college_name, sv.major_name,
       sv.verification_method, sv.material_urls, sv.status, sv.review_comment,
       sv.reject_reason, sv.reviewed_by, reviewer.nickname AS reviewed_by_nickname,
       sv.reviewed_at, sv.created_at, sv.updated_at
     FROM student_verifications sv
     LEFT JOIN schools s ON sv.school_id = s.id
     LEFT JOIN campuses c ON sv.campus_id = c.id
     LEFT JOIN users reviewer ON sv.reviewed_by = reviewer.id
     WHERE sv.user_id = ?
     ORDER BY sv.created_at DESC
     LIMIT 1`,
    [userId]
  );

  if (rows.length === 0) {
    return null;
  }

  return {
    ...rows[0],
    material_urls: parseJsonArray(rows[0].material_urls)
  };
}

async function createVerificationApplication(userId, input) {
  await pool.query(
    `INSERT INTO student_verifications
     (id, user_id, school_id, campus_id, student_no, grade_year, college_name, major_name,
      verification_method, material_urls, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING_REVIEW')`,
    [
      input.id,
      userId,
      input.schoolId,
      input.campusId,
      input.studentNo,
      input.gradeYear,
      input.collegeName,
      input.majorName,
      input.verificationMethod,
      JSON.stringify(input.materialUrls)
    ]
  );

  await pool.query(
    `UPDATE users
     SET school_id = ?, campus_id = ?, student_no = ?, grade_year = ?, college_name = ?, major_name = ?,
         verification_status = 'PENDING_REVIEW', verification_method = ?, verified_at = NULL,
         verification_rejected_reason = NULL, verification_updated_at = NOW()
     WHERE id = ?`,
    [
      input.schoolId,
      input.campusId,
      input.studentNo,
      input.gradeYear,
      input.collegeName,
      input.majorName,
      input.verificationMethod,
      userId
    ]
  );

  return fetchLatestVerificationByUser(userId);
}

async function listVerificationApplications(options) {
  const status = String(options?.status || '').trim();
  const schoolId = String(options?.schoolId || '').trim();
  const campusId = String(options?.campusId || '').trim();

  let sql = `
    SELECT
      sv.id, sv.user_id, applicant.nickname AS applicant_nickname, applicant.phone AS applicant_phone,
      sv.school_id, s.name AS school_name, sv.campus_id, c.name AS campus_name,
      sv.student_no, sv.grade_year, sv.college_name, sv.major_name,
      sv.verification_method, sv.material_urls, sv.status, sv.review_comment,
      sv.reject_reason, sv.reviewed_by, reviewer.nickname AS reviewed_by_nickname,
      sv.reviewed_at, sv.created_at, sv.updated_at
    FROM student_verifications sv
    JOIN users applicant ON sv.user_id = applicant.id
    LEFT JOIN schools s ON sv.school_id = s.id
    LEFT JOIN campuses c ON sv.campus_id = c.id
    LEFT JOIN users reviewer ON sv.reviewed_by = reviewer.id
    WHERE 1 = 1
  `;
  const params = [];

  if (status) {
    sql += ` AND sv.status = ?`;
    params.push(status);
  }
  if (schoolId) {
    sql += ` AND sv.school_id = ?`;
    params.push(schoolId);
  }
  if (campusId) {
    sql += ` AND sv.campus_id = ?`;
    params.push(campusId);
  }

  sql += ` ORDER BY CASE WHEN sv.status = 'PENDING_REVIEW' THEN 0 ELSE 1 END, sv.created_at DESC`;

  const [rows] = await pool.query(sql, params);
  return rows.map((row) => ({
    ...row,
    material_urls: parseJsonArray(row.material_urls)
  }));
}

async function getVerificationById(verificationId) {
  const [rows] = await pool.query(
    `SELECT id, user_id, school_id, campus_id, student_no, grade_year, college_name, major_name, verification_method, status
     FROM student_verifications
     WHERE id = ?
     LIMIT 1`,
    [verificationId]
  );
  return rows[0] || null;
}

async function reviewVerificationApplication(verificationId, review, reviewerId) {
  const record = await getVerificationById(verificationId);
  if (!record) {
    return null;
  }

  await pool.query(
    `UPDATE student_verifications
     SET status = ?, review_comment = ?, reject_reason = ?, reviewed_by = ?, reviewed_at = NOW()
     WHERE id = ?`,
    [
      review.status,
      review.reviewComment,
      review.rejectReason || null,
      reviewerId,
      verificationId
    ]
  );

  await pool.query(
    `UPDATE users
     SET school_id = ?, campus_id = ?, student_no = ?, grade_year = ?, college_name = ?, major_name = ?,
         verification_status = ?, verification_method = ?, verified_at = ?, verification_rejected_reason = ?,
         verification_updated_at = NOW()
     WHERE id = ?`,
    [
      record.school_id,
      record.campus_id,
      record.student_no,
      record.grade_year,
      record.college_name,
      record.major_name,
      review.status,
      record.verification_method,
      review.status === 'VERIFIED' ? new Date() : null,
      review.status === 'REJECTED' ? review.rejectReason : null,
      record.user_id
    ]
  );

  return fetchLatestVerificationByUser(record.user_id);
}

async function upsertSchool(input) {
  await pool.query(
    `INSERT INTO schools
     (id, name, short_name, province_name, city_name, display_order, is_enabled)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       name = VALUES(name),
       short_name = VALUES(short_name),
       province_name = VALUES(province_name),
       city_name = VALUES(city_name),
       display_order = VALUES(display_order),
       is_enabled = VALUES(is_enabled)`,
    [
      input.id,
      input.name,
      input.shortName,
      input.provinceName,
      input.cityName,
      input.displayOrder,
      input.isEnabled ? 1 : 0
    ]
  );

  return getSchoolById(input.id);
}

async function upsertCampus(input) {
  await pool.query(
    `INSERT INTO campuses
     (id, school_id, name, short_name, display_order, is_enabled)
     VALUES (?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       school_id = VALUES(school_id),
       name = VALUES(name),
       short_name = VALUES(short_name),
       display_order = VALUES(display_order),
       is_enabled = VALUES(is_enabled)`,
    [
      input.id,
      input.schoolId,
      input.name,
      input.shortName,
      input.displayOrder,
      input.isEnabled ? 1 : 0
    ]
  );

  return getCampusById(input.id);
}

async function upsertLocationGroup(input) {
  await pool.query(
    `INSERT INTO location_groups
     (id, school_id, campus_id, name, description, display_order, is_enabled)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       school_id = VALUES(school_id),
       campus_id = VALUES(campus_id),
       name = VALUES(name),
       description = VALUES(description),
       display_order = VALUES(display_order),
       is_enabled = VALUES(is_enabled)`,
    [
      input.id,
      input.schoolId,
      input.campusId,
      input.name,
      input.description,
      input.displayOrder,
      input.isEnabled ? 1 : 0
    ]
  );

  return getLocationGroupById(input.id);
}

async function upsertTradeLocation(input) {
  await pool.query(
    `INSERT INTO trade_locations
     (id, school_id, campus_id, group_id, name, alias, description, safety_tips,
      recommended_categories, sort_order, is_hot, is_enabled)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       school_id = VALUES(school_id),
       campus_id = VALUES(campus_id),
       group_id = VALUES(group_id),
       name = VALUES(name),
       alias = VALUES(alias),
       description = VALUES(description),
       safety_tips = VALUES(safety_tips),
       recommended_categories = VALUES(recommended_categories),
       sort_order = VALUES(sort_order),
       is_hot = VALUES(is_hot),
       is_enabled = VALUES(is_enabled)`,
    [
      input.id,
      input.schoolId,
      input.campusId,
      input.groupId,
      input.name,
      input.alias,
      input.description,
      input.safetyTips,
      JSON.stringify(input.recommendedCategories),
      input.sortOrder,
      input.isHot ? 1 : 0,
      input.isEnabled ? 1 : 0
    ]
  );

  return getTradeLocationById(input.id);
}

async function updateTradeLocationStatus(locationId, isEnabled) {
  await pool.query(
    `UPDATE trade_locations
     SET is_enabled = ?
     WHERE id = ?`,
    [isEnabled ? 1 : 0, locationId]
  );

  return getTradeLocationById(locationId);
}

module.exports = {
  getSchoolById,
  getCampusById,
  findCampusBySchoolAndName,
  getLocationGroupById,
  getTradeLocationById,
  listSchools,
  listCampuses,
  listLocationGroups,
  listTradeLocations,
  fetchUserCampusProfile,
  updateUserCampusProfile,
  fetchLatestVerificationByUser,
  createVerificationApplication,
  listVerificationApplications,
  getVerificationById,
  reviewVerificationApplication,
  upsertSchool,
  upsertCampus,
  upsertLocationGroup,
  upsertTradeLocation,
  updateTradeLocationStatus
};
