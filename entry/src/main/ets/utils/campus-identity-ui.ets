import { Campus, School, StudentVerification, User, VerificationMethod, VerificationStatus } from '../types/domain';
import { resolveDisplayedVerificationStatus } from './campus-verification-lifecycle-ui';

export class CampusIdentityPresentation {
  badgeText: string;
  badgeTextColor: string;
  badgeBackgroundColor: string;
  summaryText: string;
  helperText: string;
  actionLabel: string;
  rejectReasonText: string;

  constructor(
    badgeText: string,
    badgeTextColor: string,
    badgeBackgroundColor: string,
    summaryText: string,
    helperText: string,
    actionLabel: string,
    rejectReasonText: string = ''
  ) {
    this.badgeText = badgeText;
    this.badgeTextColor = badgeTextColor;
    this.badgeBackgroundColor = badgeBackgroundColor;
    this.summaryText = summaryText;
    this.helperText = helperText;
    this.actionLabel = actionLabel;
    this.rejectReasonText = rejectReasonText;
  }
}

export class CampusVerificationMethodOption {
  method: VerificationMethod;
  label: string;
  hint: string;

  constructor(method: VerificationMethod, label: string, hint: string) {
    this.method = method;
    this.label = label;
    this.hint = hint;
  }
}

export class CampusVerificationDraftInput {
  schoolId: string;
  campusId: string;
  campusName: string;
  studentNo: string;
  gradeYear?: number;
  collegeName?: string;
  majorName?: string;
  verificationMethod: VerificationMethod;
  materialUrls: string[];

  constructor(
    schoolId: string,
    campusId: string,
    campusName: string,
    studentNo: string,
    verificationMethod: VerificationMethod,
    materialUrls: string[],
    gradeYear?: number,
    collegeName?: string,
    majorName?: string
  ) {
    this.schoolId = schoolId;
    this.campusId = campusId;
    this.campusName = campusName;
    this.studentNo = studentNo;
    this.verificationMethod = verificationMethod;
    this.materialUrls = materialUrls;
    this.gradeYear = gradeYear;
    this.collegeName = collegeName;
    this.majorName = majorName;
  }
}

function buildCampusSummary(user: User | null): string {
  if (!user) {
    return '\u767b\u5f55\u540e\u5b8c\u5584\u5b66\u6821\u3001\u6821\u533a\u548c\u5b66\u751f\u8eab\u4efd\u4fe1\u606f\u3002';
  }

  const summaryParts: string[] = [];
  if (user.schoolName && user.schoolName.length > 0) {
    summaryParts.push(user.schoolName);
  }
  if (user.campusName && user.campusName.length > 0) {
    summaryParts.push(user.campusName);
  }
  if (user.collegeName && user.collegeName.length > 0) {
    summaryParts.push(user.collegeName);
  }
  if (user.majorName && user.majorName.length > 0) {
    summaryParts.push(user.majorName);
  }

  if (summaryParts.length > 0) {
    return summaryParts.join(' / ');
  }
  return '\u6682\u672a\u8865\u9f50\u6821\u56ed\u8d44\u6599\uff0c\u5efa\u8bae\u5148\u5b8c\u6210\u5b66\u6821\u3001\u6821\u533a\u548c\u5b66\u53f7\u4fe1\u606f\u3002';
}

export function buildCampusIdentityPresentation(user: User | null): CampusIdentityPresentation {
  const summaryText = buildCampusSummary(user);
  const status = resolveDisplayedVerificationStatus(user);

  if (status === VerificationStatus.VERIFIED) {
    return new CampusIdentityPresentation(
      '\u5df2\u8ba4\u8bc1',
      '#237B46',
      '#E8F5EA',
      summaryText,
      `\u5df2\u901a\u8fc7\u5b66\u751f\u8eab\u4efd\u8ba4\u8bc1\uff0c\u5df2\u5b8c\u6210\u4ea4\u6613 ${user?.completedOrderCount ?? 0} \u7b14\u3002`,
      '\u66f4\u65b0\u6821\u56ed\u8d44\u6599'
    );
  }

  if (status === VerificationStatus.PENDING_REVIEW) {
    return new CampusIdentityPresentation(
      '\u5f85\u5ba1\u6838',
      '#A86B00',
      '#F5EBDD',
      summaryText,
      '\u5e73\u53f0\u6b63\u5728\u6838\u9a8c\u4f60\u7684\u5b66\u751f\u8eab\u4efd\uff0c\u8bf7\u8010\u5fc3\u7b49\u5f85\u5ba1\u6838\u7ed3\u679c\u3002',
      '\u67e5\u770b\u5df2\u63d0\u4ea4\u8d44\u6599'
    );
  }

  if (status === VerificationStatus.REJECTED) {
    return new CampusIdentityPresentation(
      '\u5df2\u9a73\u56de',
      '#B8643C',
      '#F4E6DE',
      summaryText,
      '\u8ba4\u8bc1\u8d44\u6599\u672a\u901a\u8fc7\u5ba1\u6838\uff0c\u8bf7\u6839\u636e\u9a73\u56de\u539f\u56e0\u8c03\u6574\u540e\u91cd\u65b0\u63d0\u4ea4\u3002',
      '\u91cd\u65b0\u63d0\u4ea4\u8ba4\u8bc1',
      user?.verificationRejectedReason
        ? `\u9a73\u56de\u539f\u56e0\uff1a${user.verificationRejectedReason}`
        : ''
    );
  }

  if (status === VerificationStatus.SUSPENDED) {
    return new CampusIdentityPresentation(
      '\u5df2\u6682\u505c',
      '#B8643C',
      '#F4E6DE',
      summaryText,
      '\u5f53\u524d\u8ba4\u8bc1\u8d44\u683c\u5df2\u88ab\u6682\u505c\uff0c\u8bf7\u5148\u8054\u7cfb\u7ba1\u7406\u5458\u5904\u7406\u540e\u518d\u7ee7\u7eed\u4ea4\u6613\u3002',
      '\u8054\u7cfb\u7ba1\u7406\u5458\u5904\u7406'
    );
  }

  return new CampusIdentityPresentation(
    '\u672a\u8ba4\u8bc1',
    '#5E5851',
    '#F1EEEA',
    summaryText,
    '\u5b8c\u6210\u6821\u56ed\u8d44\u6599\u548c\u5b66\u751f\u8ba4\u8bc1\u540e\uff0c\u5546\u54c1\u8be6\u60c5\u548c\u4ea4\u6613\u9875\u9762\u4f1a\u5c55\u793a\u4f60\u7684\u6821\u5185\u53ef\u4fe1\u8eab\u4efd\u3002',
    '\u5b8c\u5584\u6821\u56ed\u8d44\u6599'
  );
}

export function getCampusVerificationMethodOptions(): CampusVerificationMethodOption[] {
  return [
    new CampusVerificationMethodOption(
      'MANUAL_STUDENT_CARD',
      '\u5b66\u751f\u8bc1',
      '\u9002\u5408\u63d0\u4ea4\u5b66\u751f\u8bc1\u6216\u5b66\u751f\u8eab\u4efd\u8bc1\u660e\u7167\u7247\u3002'
    ),
    new CampusVerificationMethodOption(
      'MANUAL_CAMPUS_CARD',
      '\u6821\u56ed\u5361',
      '\u9002\u5408\u63d0\u4ea4\u6821\u56ed\u4e00\u5361\u901a\u3001\u6821\u56ed\u8eab\u4efd\u5361\u6216\u6821\u5185\u901a\u884c\u8bc1\u660e\u3002'
    ),
    new CampusVerificationMethodOption(
      'MANUAL_ENROLLMENT_PROOF',
      '\u5728\u8bfb\u8bc1\u660e',
      '\u9002\u5408\u63d0\u4ea4\u5f55\u53d6\u901a\u77e5\u4e66\u3001\u5728\u8bfb\u8bc1\u660e\u6216\u5b66\u4fe1\u7f51\u622a\u56fe\u3002'
    )
  ];
}

export function getCampusVerificationMethodLabel(method: VerificationMethod): string {
  const matched = getCampusVerificationMethodOptions()
    .find((item: CampusVerificationMethodOption) => item.method === method);
  return matched ? matched.label : '\u8eab\u4efd\u6750\u6599';
}

export function validateCampusVerificationDraft(input: CampusVerificationDraftInput): string {
  if (input.schoolId.trim().length === 0 || input.campusName.trim().length === 0) {
    return '\u8bf7\u5148\u9009\u5b9a\u5b66\u6821\u548c\u6821\u533a';
  }
  if (input.studentNo.trim().length < 6) {
    return '\u8bf7\u5148\u586b\u5199\u6b63\u786e\u7684\u5b66\u53f7';
  }
  if (input.materialUrls.length === 0 || input.materialUrls[0].trim().length === 0) {
    return '\u8bf7\u5148\u4e0a\u4f20\u6216\u7c98\u8d34\u4e00\u4efd\u8ba4\u8bc1\u6750\u6599';
  }
  return '';
}

export function buildCampusVerificationDraft(user: User, input: CampusVerificationDraftInput): StudentVerification {
  const now = Date.now();
  return {
    id: `verification-draft-${user.id}`,
    userId: user.id,
    schoolId: input.schoolId,
    campusId: input.campusId,
    campusName: input.campusName,
    studentNo: input.studentNo.trim(),
    gradeYear: input.gradeYear,
    collegeName: input.collegeName,
    majorName: input.majorName,
    verificationMethod: input.verificationMethod,
    materialUrls: input.materialUrls,
    status: VerificationStatus.PENDING_REVIEW,
    submittedAt: now,
    updatedAt: now
  };
}

export function pickDefaultSchool(schools: School[]): School | null {
  const enabledSchools = schools.filter((item: School) => item.isEnabled);
  if (enabledSchools.length === 0) {
    return schools.length > 0 ? schools[0] : null;
  }

  enabledSchools.sort((left: School, right: School) => left.sortOrder - right.sortOrder);
  return enabledSchools[0];
}

export function pickDefaultCampus(campuses: Campus[]): Campus | null {
  const enabledCampuses = campuses.filter((item: Campus) => item.isEnabled);
  if (enabledCampuses.length === 0) {
    return campuses.length > 0 ? campuses[0] : null;
  }

  const mainCampus = enabledCampuses.find((item: Campus) => item.isMainCampus);
  if (mainCampus) {
    return mainCampus;
  }

  enabledCampuses.sort((left: Campus, right: Campus) => left.sortOrder - right.sortOrder);
  return enabledCampuses[0];
}

export function resolveCampusForSchoolSelection(
  campuses: Campus[],
  schoolId: string,
  currentCampusId?: string
): Campus | null {
  const matchedCampuses = campuses.filter((item: Campus) => item.schoolId === schoolId);
  if (matchedCampuses.length === 0) {
    return null;
  }
  if (currentCampusId && currentCampusId.length > 0) {
    const matchedCurrent = matchedCampuses.find((item: Campus) => item.id === currentCampusId);
    if (matchedCurrent) {
      return matchedCurrent;
    }
  }
  return pickDefaultCampus(matchedCampuses);
}
