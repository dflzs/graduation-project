const { success, fail } = require('../utils/response');
const {
  validateCampusProfileInput,
  validateVerificationSubmissionInput,
  validateVerificationReviewInput,
  validateTradeLocationInput
} = require('./campus.validation');
const {
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
} = require('./campus.store');

function ensureAdmin(req, res) {
  if (req.user.role !== 'admin') {
    res.status(403).json(fail('只有管理员可以访问该接口'));
    return false;
  }
  return true;
}

function normalizeString(value) {
  return String(value || '').trim();
}

function normalizeNullableString(value) {
  const normalized = normalizeString(value);
  return normalized.length > 0 ? normalized : null;
}

function normalizeDisplayOrder(value) {
  const amount = Number(value);
  if (!Number.isInteger(amount) || amount < 0) {
    return 0;
  }
  return amount;
}

function normalizeBoolean(value, defaultValue) {
  if (value === undefined || value === null) {
    return defaultValue;
  }
  if (typeof value === 'boolean') {
    return value;
  }

  const normalized = normalizeString(value).toLowerCase();
  if (normalized === 'true' || normalized === '1') {
    return true;
  }
  if (normalized === 'false' || normalized === '0') {
    return false;
  }
  return defaultValue;
}

function createId(prefix, explicitId) {
  const normalized = normalizeString(explicitId);
  if (normalized.length > 0) {
    return normalized;
  }

  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
}

function createCampusIdFromName(schoolId, campusName) {
  const encoded = Buffer.from(campusName, 'utf8').toString('hex').slice(0, 32);
  return `campus_${schoolId}_${encoded}`;
}

async function ensureSchoolExists(schoolId) {
  if (!schoolId) {
    return null;
  }
  return getSchoolById(schoolId);
}

async function ensureCampusExists(campusId) {
  if (!campusId) {
    return null;
  }
  return getCampusById(campusId);
}

async function resolveCampusSelection(schoolId, campusId, campusName) {
  if (campusId) {
    const campus = await ensureCampusExists(campusId);
    if (!campus || !Boolean(campus.is_enabled) || campus.school_id !== schoolId) {
      return {
        ok: false,
        message: '校区不存在、已停用或不属于当前学校'
      };
    }
    return {
      ok: true,
      data: campus
    };
  }

  const normalizedCampusName = normalizeString(campusName);
  if (normalizedCampusName.length === 0) {
    return {
      ok: false,
      message: '校区不能为空'
    };
  }

  const existingCampus = await findCampusBySchoolAndName(schoolId, normalizedCampusName);
  if (existingCampus) {
    if (!Boolean(existingCampus.is_enabled)) {
      return {
        ok: false,
        message: '校区已停用，请联系管理员处理'
      };
    }
    return {
      ok: true,
      data: existingCampus
    };
  }

  const createdCampus = await upsertCampus({
    id: createCampusIdFromName(schoolId, normalizedCampusName),
    schoolId,
    name: normalizedCampusName,
    shortName: null,
    displayOrder: 9999,
    isEnabled: true
  });

  return {
    ok: true,
    data: createdCampus
  };
}

async function ensureLocationGroupExists(groupId) {
  if (!groupId) {
    return null;
  }
  return getLocationGroupById(groupId);
}

async function listSchoolsHandler(req, res) {
  try {
    const includeDisabled = req.user?.role === 'admin' && normalizeBoolean(req.query.include_disabled, false);
    const rows = await listSchools(includeDisabled);
    return res.json(success(rows, '获取学校列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取学校列表失败: ${error.message}`));
  }
}

async function listCampusesHandler(req, res) {
  try {
    const includeDisabled = req.user?.role === 'admin' && normalizeBoolean(req.query.include_disabled, false);
    const rows = await listCampuses({
      schoolId: req.query.school_id,
      includeDisabled
    });
    return res.json(success(rows, '获取校区列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取校区列表失败: ${error.message}`));
  }
}

async function listLocationGroupsHandler(req, res) {
  try {
    const includeDisabled = req.user?.role === 'admin' && normalizeBoolean(req.query.include_disabled, false);
    const rows = await listLocationGroups({
      schoolId: req.query.school_id,
      campusId: req.query.campus_id,
      includeDisabled
    });
    return res.json(success(rows, '获取地点分组成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取地点分组失败: ${error.message}`));
  }
}

async function listTradeLocationsHandler(req, res) {
  try {
    const includeDisabled = req.user?.role === 'admin' && normalizeBoolean(req.query.include_disabled, false);
    const rows = await listTradeLocations({
      schoolId: req.query.school_id,
      campusId: req.query.campus_id,
      groupId: req.query.group_id,
      category: req.query.category,
      includeDisabled
    });
    return res.json(success(rows, '获取交易地点成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取交易地点失败: ${error.message}`));
  }
}

async function getMyCampusProfile(req, res) {
  try {
    const profile = await fetchUserCampusProfile(req.user.id);
    if (!profile) {
      return res.status(404).json(fail('当前用户不存在'));
    }
    return res.json(success(profile, '获取校园资料成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取校园资料失败: ${error.message}`));
  }
}

async function updateMyCampusProfileHandler(req, res) {
  try {
    const validation = validateCampusProfileInput(req.body);
    if (!validation.ok) {
      return res.status(400).json(fail(validation.message));
    }

    const school = await ensureSchoolExists(validation.data.schoolId);
    if (!school || !Boolean(school.is_enabled)) {
      return res.status(400).json(fail('学校不存在或已停用'));
    }

    const campusResolution = await resolveCampusSelection(
      validation.data.schoolId,
      validation.data.campusId,
      validation.data.campusName
    );
    if (!campusResolution.ok || !campusResolution.data) {
      return res.status(400).json(fail(campusResolution.message));
    }
    validation.data.campusId = campusResolution.data.id;

    const profile = await updateUserCampusProfile(req.user.id, validation.data);
    return res.json(success(profile, '更新校园资料成功'));
  } catch (error) {
    return res.status(500).json(fail(`更新校园资料失败: ${error.message}`));
  }
}

async function getMyVerification(req, res) {
  try {
    const verification = await fetchLatestVerificationByUser(req.user.id);
    if (!verification) {
      return res.json(success(null, '当前没有认证记录'));
    }
    return res.json(success(verification, '获取认证状态成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取认证状态失败: ${error.message}`));
  }
}

async function submitVerification(req, res) {
  try {
    const validation = validateVerificationSubmissionInput(req.body);
    if (!validation.ok) {
      return res.status(400).json(fail(validation.message));
    }

    const school = await ensureSchoolExists(validation.data.schoolId);
    if (!school || !Boolean(school.is_enabled)) {
      return res.status(400).json(fail('学校不存在或已停用'));
    }

    const campusResolution = await resolveCampusSelection(
      validation.data.schoolId,
      validation.data.campusId,
      validation.data.campusName
    );
    if (!campusResolution.ok || !campusResolution.data) {
      return res.status(400).json(fail(campusResolution.message));
    }
    validation.data.campusId = campusResolution.data.id;

    const latest = await fetchLatestVerificationByUser(req.user.id);
    if (latest && latest.status === 'PENDING_REVIEW') {
      return res.status(400).json(fail('当前已有待审核的认证申请，请等待审核结果'));
    }

    const record = await createVerificationApplication(req.user.id, {
      ...validation.data,
      id: createId('verify', req.body.id)
    });

    return res.json(success(record, '提交学生认证申请成功'));
  } catch (error) {
    return res.status(500).json(fail(`提交学生认证申请失败: ${error.message}`));
  }
}

async function listVerificationApplicationsHandler(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const rows = await listVerificationApplications({
      status: req.query.status,
      schoolId: req.query.school_id,
      campusId: req.query.campus_id
    });

    return res.json(success(rows, '获取认证申请列表成功'));
  } catch (error) {
    return res.status(500).json(fail(`获取认证申请列表失败: ${error.message}`));
  }
}

async function reviewVerificationHandler(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const verificationId = normalizeString(req.params.id);
    if (verificationId.length === 0) {
      return res.status(400).json(fail('认证申请 id 不合法'));
    }

    const validation = validateVerificationReviewInput(req.body);
    if (!validation.ok) {
      return res.status(400).json(fail(validation.message));
    }

    const current = await getVerificationById(verificationId);
    if (!current) {
      return res.status(404).json(fail('认证申请不存在'));
    }
    if (current.status !== 'PENDING_REVIEW') {
      return res.status(400).json(fail('只有待审核的认证申请才可以处理'));
    }

    const result = await reviewVerificationApplication(
      verificationId,
      validation.data,
      req.user.id
    );
    return res.json(success(result, validation.data.status === 'VERIFIED' ? '认证审核通过' : '认证审核已完成'));
  } catch (error) {
    return res.status(500).json(fail(`审核认证申请失败: ${error.message}`));
  }
}

async function upsertSchoolHandler(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const id = createId('school', req.body.id ?? req.query.id);
    const name = normalizeString(req.body.name);
    const shortName = normalizeNullableString(req.body.short_name);
    const provinceName = normalizeNullableString(req.body.province_name);
    const cityName = normalizeNullableString(req.body.city_name);
    const displayOrder = normalizeDisplayOrder(req.body.display_order);
    const isEnabled = normalizeBoolean(req.body.is_enabled, true);

    if (name.length < 2) {
      return res.status(400).json(fail('学校名称至少 2 个字符'));
    }

    const school = await upsertSchool({
      id,
      name,
      shortName,
      provinceName,
      cityName,
      displayOrder,
      isEnabled
    });

    return res.json(success(school, '学校配置保存成功'));
  } catch (error) {
    return res.status(500).json(fail(`学校配置保存失败: ${error.message}`));
  }
}

async function upsertCampusHandler(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const id = createId('campus', req.body.id ?? req.query.id);
    const schoolId = normalizeString(req.body.school_id);
    const name = normalizeString(req.body.name);
    const shortName = normalizeNullableString(req.body.short_name);
    const displayOrder = normalizeDisplayOrder(req.body.display_order);
    const isEnabled = normalizeBoolean(req.body.is_enabled, true);

    if (name.length < 2) {
      return res.status(400).json(fail('校区名称至少 2 个字符'));
    }

    const school = await ensureSchoolExists(schoolId);
    if (!school) {
      return res.status(400).json(fail('学校不存在'));
    }

    const campus = await upsertCampus({
      id,
      schoolId,
      name,
      shortName,
      displayOrder,
      isEnabled
    });

    return res.json(success(campus, '校区配置保存成功'));
  } catch (error) {
    return res.status(500).json(fail(`校区配置保存失败: ${error.message}`));
  }
}

async function upsertLocationGroupHandler(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const id = createId('location_group', req.body.id ?? req.query.id);
    const schoolId = normalizeString(req.body.school_id);
    const campusId = normalizeString(req.body.campus_id);
    const name = normalizeString(req.body.name);
    const description = normalizeNullableString(req.body.description);
    const displayOrder = normalizeDisplayOrder(req.body.display_order);
    const isEnabled = normalizeBoolean(req.body.is_enabled, true);

    if (name.length < 2) {
      return res.status(400).json(fail('地点分组名称至少 2 个字符'));
    }

    const school = await ensureSchoolExists(schoolId);
    if (!school) {
      return res.status(400).json(fail('学校不存在'));
    }

    const campus = await ensureCampusExists(campusId);
    if (!campus || campus.school_id !== schoolId) {
      return res.status(400).json(fail('校区不存在或不属于当前学校'));
    }

    const group = await upsertLocationGroup({
      id,
      schoolId,
      campusId,
      name,
      description,
      displayOrder,
      isEnabled
    });

    return res.json(success(group, '地点分组保存成功'));
  } catch (error) {
    return res.status(500).json(fail(`地点分组保存失败: ${error.message}`));
  }
}

async function upsertTradeLocationHandler(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const validation = validateTradeLocationInput(req.body);
    if (!validation.ok) {
      return res.status(400).json(fail(validation.message));
    }

    const school = await ensureSchoolExists(validation.data.schoolId);
    if (!school) {
      return res.status(400).json(fail('学校不存在'));
    }

    const campus = await ensureCampusExists(validation.data.campusId);
    if (!campus || campus.school_id !== validation.data.schoolId) {
      return res.status(400).json(fail('校区不存在或不属于当前学校'));
    }

    const group = await ensureLocationGroupExists(validation.data.groupId);
    if (!group || group.school_id !== validation.data.schoolId || group.campus_id !== validation.data.campusId) {
      return res.status(400).json(fail('地点分组不存在或不属于当前校区'));
    }

    const location = await upsertTradeLocation({
      ...validation.data,
      id: createId('trade_location', req.body.id ?? req.query.id)
    });

    return res.json(success(location, '交易地点保存成功'));
  } catch (error) {
    return res.status(500).json(fail(`交易地点保存失败: ${error.message}`));
  }
}

async function updateTradeLocationStatusHandler(req, res) {
  try {
    if (!ensureAdmin(req, res)) return;

    const locationId = normalizeString(req.params.id);
    if (locationId.length === 0) {
      return res.status(400).json(fail('交易地点 id 不合法'));
    }

    const current = await getTradeLocationById(locationId);
    if (!current) {
      return res.status(404).json(fail('交易地点不存在'));
    }

    const isEnabled = normalizeBoolean(req.body.is_enabled, true);
    const updated = await updateTradeLocationStatus(locationId, isEnabled);
    return res.json(success(updated, isEnabled ? '交易地点已启用' : '交易地点已停用'));
  } catch (error) {
    return res.status(500).json(fail(`更新交易地点状态失败: ${error.message}`));
  }
}

module.exports = {
  listSchools: listSchoolsHandler,
  listCampuses: listCampusesHandler,
  listLocationGroups: listLocationGroupsHandler,
  listTradeLocations: listTradeLocationsHandler,
  getMyCampusProfile,
  updateMyCampusProfile: updateMyCampusProfileHandler,
  getMyVerification,
  submitVerification,
  listVerificationApplications: listVerificationApplicationsHandler,
  reviewVerification: reviewVerificationHandler,
  upsertSchool: upsertSchoolHandler,
  upsertCampus: upsertCampusHandler,
  upsertLocationGroup: upsertLocationGroupHandler,
  upsertTradeLocation: upsertTradeLocationHandler,
  updateTradeLocationStatus: updateTradeLocationStatusHandler
};
