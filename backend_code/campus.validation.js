const VERIFICATION_STATUSES = [
  'UNVERIFIED',
  'PENDING_REVIEW',
  'VERIFIED',
  'REJECTED',
  'SUSPENDED'
];

const REVIEWABLE_VERIFICATION_STATUSES = [
  'VERIFIED',
  'REJECTED',
  'SUSPENDED'
];

const VERIFICATION_METHODS = [
  'MANUAL_STUDENT_CARD',
  'MANUAL_CAMPUS_CARD',
  'MANUAL_ENROLLMENT_PROOF',
  'FUTURE_SSO'
];

function ok(data) {
  return {
    ok: true,
    data
  };
}

function fail(message) {
  return {
    ok: false,
    message
  };
}

function normalizeString(value) {
  return String(value || '').trim();
}

function normalizeNullableString(value) {
  const normalized = normalizeString(value);
  return normalized.length > 0 ? normalized : null;
}

function normalizeYear(value) {
  if (value === undefined || value === null || String(value).trim().length === 0) {
    return null;
  }

  const year = Number(value);
  if (!Number.isInteger(year) || year < 2000 || year > 2100) {
    return null;
  }
  return year;
}

function normalizeCategories(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => normalizeString(item))
    .filter((item) => item.length > 0);
}

function normalizeMaterialUrls(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => normalizeString(item))
    .filter((item) => /^https?:\/\//.test(item) || item.startsWith('/uploads/'));
}

function validateStudentNo(studentNo) {
  return /^[A-Za-z0-9_-]{6,32}$/.test(studentNo);
}

function validateCampusProfileInput(input) {
  const schoolId = normalizeString(input?.school_id);
  const campusId = normalizeString(input?.campus_id);
  const campusName = normalizeString(input?.campus_name);
  const studentNo = normalizeString(input?.student_no);
  const gradeYear = normalizeYear(input?.grade_year);
  const collegeName = normalizeNullableString(input?.college_name);
  const majorName = normalizeNullableString(input?.major_name);

  if (schoolId.length === 0) {
    return fail('学校不能为空');
  }
  if (campusId.length === 0 && campusName.length === 0) {
    return fail('校区不能为空');
  }
  if (!validateStudentNo(studentNo)) {
    return fail('学号格式不正确');
  }

  return ok({
    schoolId,
    campusId,
    campusName,
    studentNo,
    gradeYear,
    collegeName,
    majorName
  });
}

function validateVerificationSubmissionInput(input) {
  const profile = validateCampusProfileInput(input);
  if (!profile.ok) {
    return profile;
  }

  const verificationMethod = normalizeString(input?.verification_method);
  const materialUrls = normalizeMaterialUrls(input?.material_urls);

  if (!VERIFICATION_METHODS.includes(verificationMethod)) {
    return fail('认证方式不支持');
  }
  if (materialUrls.length === 0) {
    return fail('请至少上传一份认证材料');
  }

  return ok({
    ...profile.data,
    verificationMethod,
    materialUrls
  });
}

function validateVerificationReviewInput(input) {
  const status = normalizeString(input?.status);
  const reviewComment = normalizeString(input?.review_comment);
  const rejectReason = normalizeString(input?.reject_reason);

  if (!REVIEWABLE_VERIFICATION_STATUSES.includes(status)) {
    return fail('审核状态不支持');
  }
  if (reviewComment.length === 0) {
    return fail('审核说明不能为空');
  }
  if (status === 'REJECTED' && rejectReason.length === 0) {
    return fail('驳回时必须填写驳回原因');
  }

  return ok({
    status,
    reviewComment,
    rejectReason
  });
}

function validateTradeLocationInput(input) {
  const schoolId = normalizeString(input?.school_id);
  const campusId = normalizeString(input?.campus_id);
  const groupId = normalizeString(input?.group_id);
  const name = normalizeString(input?.name);
  const alias = normalizeNullableString(input?.alias);
  const description = normalizeNullableString(input?.description);
  const safetyTips = normalizeNullableString(input?.safety_tips);
  const recommendedCategories = normalizeCategories(input?.recommended_categories);
  const sortOrder = Number(input?.sort_order);
  const isHot = Boolean(input?.is_hot);
  const isEnabled = input?.is_enabled === undefined ? true : Boolean(input?.is_enabled);

  if (schoolId.length === 0) {
    return fail('学校不能为空');
  }
  if (campusId.length === 0) {
    return fail('校区不能为空');
  }
  if (groupId.length === 0) {
    return fail('地点分组不能为空');
  }
  if (name.length < 2) {
    return fail('交易点名称至少 2 个字符');
  }
  if (recommendedCategories.length === 0) {
    return fail('请至少配置一个推荐类目');
  }
  if (!Number.isInteger(sortOrder) || sortOrder < 0) {
    return fail('排序值必须是大于等于 0 的整数');
  }

  return ok({
    schoolId,
    campusId,
    groupId,
    name,
    alias,
    description,
    safetyTips,
    recommendedCategories,
    sortOrder,
    isHot,
    isEnabled
  });
}

module.exports = {
  VERIFICATION_STATUSES,
  REVIEWABLE_VERIFICATION_STATUSES,
  VERIFICATION_METHODS,
  validateCampusProfileInput,
  validateVerificationSubmissionInput,
  validateVerificationReviewInput,
  validateTradeLocationInput
};
