const assert = require('assert');
const {
  VERIFICATION_STATUSES,
  VERIFICATION_METHODS,
  validateCampusProfileInput,
  validateVerificationSubmissionInput,
  validateVerificationReviewInput,
  validateTradeLocationInput
} = require('./campus.validation');

function run() {
  assert.strictEqual(VERIFICATION_STATUSES.includes('VERIFIED'), true);
  assert.strictEqual(VERIFICATION_METHODS.includes('MANUAL_STUDENT_CARD'), true);

  const validProfile = validateCampusProfileInput({
    school_id: 'school-hnrku',
    campus_id: 'campus-main',
    student_no: '2024123456',
    grade_year: 2024,
    college_name: '信息学院',
    major_name: '软件工程'
  });
  assert.strictEqual(validProfile.ok, true);

  const validProfileWithManualCampus = validateCampusProfileInput({
    school_id: 'school-hnu',
    campus_name: '南校区',
    student_no: '2024123456',
    grade_year: 2024,
    college_name: '信息学院',
    major_name: '计算机科学与技术'
  });
  assert.strictEqual(validProfileWithManualCampus.ok, true);

  const invalidProfile = validateCampusProfileInput({
    school_id: '',
    campus_id: 'campus-main',
    student_no: '12'
  });
  assert.strictEqual(invalidProfile.ok, false);

  const validSubmission = validateVerificationSubmissionInput({
    school_id: 'school-hnrku',
    campus_id: 'campus-main',
    student_no: '2024123456',
    verification_method: 'MANUAL_STUDENT_CARD',
    material_urls: ['https://example.com/student-card.png']
  });
  assert.strictEqual(validSubmission.ok, true);

  const validSubmissionWithManualCampus = validateVerificationSubmissionInput({
    school_id: 'school-hnu',
    campus_name: '主校区',
    student_no: '2024123456',
    verification_method: 'MANUAL_STUDENT_CARD',
    material_urls: ['https://example.com/student-card.png']
  });
  assert.strictEqual(validSubmissionWithManualCampus.ok, true);

  const invalidSubmission = validateVerificationSubmissionInput({
    school_id: 'school-hnrku',
    campus_id: 'campus-main',
    student_no: '2024123456',
    verification_method: 'MANUAL_STUDENT_CARD',
    material_urls: []
  });
  assert.strictEqual(invalidSubmission.ok, false);

  const validReview = validateVerificationReviewInput({
    status: 'REJECTED',
    review_comment: '材料模糊',
    reject_reason: '请重新上传清晰学生证'
  });
  assert.strictEqual(validReview.ok, true);

  const invalidReview = validateVerificationReviewInput({
    status: 'REJECTED',
    review_comment: '',
    reject_reason: ''
  });
  assert.strictEqual(invalidReview.ok, false);

  const validLocation = validateTradeLocationInput({
    school_id: 'school-hnrku',
    campus_id: 'campus-main',
    group_id: 'group-library',
    name: '图书馆大厅',
    recommended_categories: ['教材书籍'],
    sort_order: 1
  });
  assert.strictEqual(validLocation.ok, true);

  const invalidLocation = validateTradeLocationInput({
    school_id: 'school-hnrku',
    campus_id: 'campus-main',
    group_id: 'group-library',
    name: '',
    recommended_categories: [],
    sort_order: -1
  });
  assert.strictEqual(invalidLocation.ok, false);

  console.log('campus.validation.test.js passed');
}

run();
