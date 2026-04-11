import { StudentVerification, User, VerificationStatus } from '../types/domain';

export class ProfileVerificationLifecyclePresentation {
  shouldShowSnapshot: boolean;
  snapshotTitle: string;
  snapshotStatusText: string;
  snapshotCampusSummary: string;
  snapshotAcademicSummary: string;
  draftHelperText: string;
  reviewHintText: string;
  materialCountText: string;

  constructor(
    shouldShowSnapshot: boolean,
    snapshotTitle: string,
    snapshotStatusText: string,
    snapshotCampusSummary: string,
    snapshotAcademicSummary: string,
    draftHelperText: string,
    reviewHintText: string,
    materialCountText: string
  ) {
    this.shouldShowSnapshot = shouldShowSnapshot;
    this.snapshotTitle = snapshotTitle;
    this.snapshotStatusText = snapshotStatusText;
    this.snapshotCampusSummary = snapshotCampusSummary;
    this.snapshotAcademicSummary = snapshotAcademicSummary;
    this.draftHelperText = draftHelperText;
    this.reviewHintText = reviewHintText;
    this.materialCountText = materialCountText;
  }
}

export class VerificationEditorPresentation {
  canEdit: boolean;
  canSubmit: boolean;
  submitButtonLabel: string;
  lockedHintText: string;

  constructor(
    canEdit: boolean,
    canSubmit: boolean,
    submitButtonLabel: string,
    lockedHintText: string
  ) {
    this.canEdit = canEdit;
    this.canSubmit = canSubmit;
    this.submitButtonLabel = submitButtonLabel;
    this.lockedHintText = lockedHintText;
  }
}

function buildFallbackText(value: string | undefined, fallback: string): string {
  if (value && value.trim().length > 0) {
    return value.trim();
  }
  return fallback;
}

export function resolveDisplayedVerificationStatus(user: User | null): VerificationStatus {
  const rawStatus = user?.verificationStatus ?? VerificationStatus.UNVERIFIED;
  if (rawStatus !== VerificationStatus.VERIFIED) {
    return rawStatus;
  }

  const verifiedAt = user?.verifiedAt;
  if (verifiedAt === undefined || verifiedAt <= 0) {
    return VerificationStatus.UNVERIFIED;
  }

  const verificationUpdatedAt = user?.verificationUpdatedAt;
  if (verificationUpdatedAt !== undefined && verificationUpdatedAt > verifiedAt) {
    return VerificationStatus.UNVERIFIED;
  }

  return VerificationStatus.VERIFIED;
}

export function buildVerificationCampusSummary(verification: StudentVerification): string {
  return buildVerificationCampusSummaryFromTexts(verification.schoolName, verification.campusName);
}

export function buildVerificationCampusSummaryFromTexts(schoolName?: string, campusName?: string): string {
  const resolvedSchoolName = buildFallbackText(schoolName, '\u5b66\u6821\u672a\u8bbe\u7f6e');
  const resolvedCampusName = buildFallbackText(campusName, '\u6821\u533a\u672a\u8bbe\u7f6e');
  return `${resolvedSchoolName} / ${resolvedCampusName}`;
}

export function buildVerificationAcademicSummary(verification: StudentVerification): string {
  return buildVerificationAcademicSummaryFromValues(
    verification.collegeName,
    verification.majorName,
    verification.gradeYear
  );
}

export function buildVerificationAcademicSummaryFromValues(
  collegeName?: string,
  majorName?: string,
  gradeYear?: number
): string {
  const resolvedCollegeName = buildFallbackText(collegeName, '\u9662\u7cfb\u672a\u8bbe\u7f6e');
  const resolvedMajorName = buildFallbackText(majorName, '\u4e13\u4e1a\u672a\u8bbe\u7f6e');
  const gradeText = gradeYear !== undefined && gradeYear > 0
    ? `${gradeYear}`
    : '\u5e74\u7ea7\u672a\u8bbe\u7f6e';
  return `${resolvedCollegeName} / ${resolvedMajorName} / ${gradeText}`;
}

function buildVerificationSnapshotTitle(status: VerificationStatus): string {
  if (status === VerificationStatus.VERIFIED) {
    return '\u6700\u8fd1\u901a\u8fc7\u5feb\u7167';
  }
  if (status === VerificationStatus.REJECTED) {
    return '\u4e0a\u6b21\u9a73\u56de\u5feb\u7167';
  }
  if (status === VerificationStatus.PENDING_REVIEW) {
    return '\u5f53\u524d\u5ba1\u6838\u5feb\u7167';
  }
  return '\u6700\u8fd1\u63d0\u4ea4\u5feb\u7167';
}

function buildVerificationStatusText(status: VerificationStatus): string {
  if (status === VerificationStatus.VERIFIED) {
    return '\u5df2\u901a\u8fc7';
  }
  if (status === VerificationStatus.REJECTED) {
    return '\u5df2\u9a73\u56de';
  }
  if (status === VerificationStatus.SUSPENDED) {
    return '\u5df2\u6682\u505c';
  }
  if (status === VerificationStatus.UNVERIFIED) {
    return '\u672a\u8ba4\u8bc1';
  }
  return '\u5f85\u5ba1\u6838';
}

function buildDraftHelperText(status: VerificationStatus): string {
  if (status === VerificationStatus.VERIFIED) {
    return '\u5f53\u524d\u516c\u5f00\u5c55\u793a\u7684\u6821\u56ed\u53ef\u4fe1\u8eab\u4efd\uff0c\u4ee5\u4e0a\u4e00\u6b21\u901a\u8fc7\u5ba1\u6838\u7684\u5feb\u7167\u4e3a\u51c6\u3002\u82e5\u8d44\u6599\u6709\u53d8\u52a8\uff0c\u8bf7\u66f4\u65b0\u540e\u91cd\u65b0\u63d0\u4ea4\u8ba4\u8bc1\u3002';
  }
  if (status === VerificationStatus.REJECTED) {
    return '\u8bf7\u6839\u636e\u9a73\u56de\u539f\u56e0\u4fee\u6539\u8d44\u6599\u548c\u6750\u6599\u540e\u91cd\u65b0\u63d0\u4ea4\u3002\u5f53\u524d\u6b63\u5728\u7f16\u8f91\u7684\u8d44\u6599\u4e0d\u4f1a\u81ea\u52a8\u8986\u76d6\u4e0a\u4e00\u6761\u9a73\u56de\u8bb0\u5f55\u3002';
  }
  if (status === VerificationStatus.PENDING_REVIEW) {
    return '\u4f60\u73b0\u5728\u7f16\u8f91\u7684\u662f\u4e2a\u4eba\u8d44\u6599\uff0c\u5f53\u524d\u6b63\u5728\u7f16\u8f91\u7684\u8d44\u6599\u4e0d\u4f1a\u5f71\u54cd\u672c\u6b21\u5ba1\u6838\u3002\u5982\u9700\u6309\u65b0\u8d44\u6599\u5ba1\u6838\uff0c\u8bf7\u5728\u672c\u6b21\u5ba1\u6838\u7ed3\u675f\u540e\u91cd\u65b0\u63d0\u4ea4\u3002';
  }
  return '\u6821\u56ed\u8d44\u6599\u548c\u5b66\u751f\u8ba4\u8bc1\u7533\u8bf7\u5206\u5f00\u7ba1\u7406\u3002\u8d44\u6599\u4fdd\u5b58\u540e\u4e0d\u4f1a\u81ea\u52a8\u751f\u6210\u5ba1\u6838\uff0c\u4ecd\u9700\u624b\u52a8\u63d0\u4ea4\u5b66\u751f\u8ba4\u8bc1\u3002';
}

function buildReviewHintText(user: User | null, verification: StudentVerification): string {
  if (verification.status === VerificationStatus.REJECTED) {
    const rejectReason = buildFallbackText(verification.rejectReason ?? user?.verificationRejectedReason, '');
    return rejectReason.length > 0
      ? `\u9a73\u56de\u539f\u56e0\uff1a${rejectReason}`
      : '\u4e0a\u6b21\u7533\u8bf7\u5df2\u88ab\u9a73\u56de\uff0c\u8bf7\u6309\u8981\u6c42\u4fee\u6b63\u540e\u91cd\u65b0\u63d0\u4ea4\u3002';
  }
  if (verification.status === VerificationStatus.VERIFIED) {
    return '\u8fd9\u4efd\u5feb\u7167\u5df2\u901a\u8fc7\u5ba1\u6838\uff0c\u5e76\u7528\u4e8e\u524d\u53f0\u516c\u5f00\u8eab\u4efd\u5c55\u793a\u3002';
  }
  if (verification.status === VerificationStatus.PENDING_REVIEW) {
    return '\u7ba1\u7406\u5458\u6b63\u5728\u6838\u9a8c\u8fd9\u4efd\u63d0\u4ea4\u5feb\u7167\uff0c\u5ba1\u6838\u7ed3\u679c\u4f1a\u540c\u6b65\u66f4\u65b0\u5230\u4f60\u7684\u6821\u56ed\u53ef\u4fe1\u8eab\u4efd\u3002';
  }
  return '\u5f53\u524d\u5feb\u7167\u4ec5\u7528\u4e8e\u8bb0\u5f55\u6700\u8fd1\u4e00\u6b21\u63d0\u4ea4\u7684\u8ba4\u8bc1\u4fe1\u606f\u3002';
}

export function buildProfileVerificationLifecyclePresentation(
  user: User | null,
  verification: StudentVerification | null
): ProfileVerificationLifecyclePresentation {
  const displayedStatus = resolveDisplayedVerificationStatus(user);
  if (!verification) {
    return new ProfileVerificationLifecyclePresentation(
      false,
      '',
      buildVerificationStatusText(displayedStatus),
      '',
      '',
      '\u6821\u56ed\u8d44\u6599\u548c\u5b66\u751f\u8ba4\u8bc1\u7533\u8bf7\u5206\u5f00\u7ba1\u7406\u3002\u5148\u4fdd\u5b58\u8d44\u6599\uff0c\u518d\u63d0\u4ea4\u5b66\u751f\u8ba4\u8bc1\uff0c\u5ba1\u6838\u901a\u8fc7\u540e\u624d\u4f1a\u5c55\u793a\u6821\u56ed\u53ef\u4fe1\u8eab\u4efd\u3002',
      '',
      ''
    );
  }

  return new ProfileVerificationLifecyclePresentation(
    true,
    buildVerificationSnapshotTitle(verification.status),
    buildVerificationStatusText(verification.status),
    buildVerificationCampusSummary(verification),
    buildVerificationAcademicSummary(verification),
    buildDraftHelperText(verification.status),
    buildReviewHintText(user, verification),
    `\u5df2\u63d0\u4ea4\u6750\u6599 ${verification.materialUrls.length} \u4efd`
  );
}

export function buildVerificationEditorPresentation(
  status?: VerificationStatus | null
): VerificationEditorPresentation {
  if (status === undefined || status === null || status === VerificationStatus.UNVERIFIED) {
    return new VerificationEditorPresentation(
      true,
      true,
      '\u63d0\u4ea4\u5b66\u751f\u8eab\u4efd\u8ba4\u8bc1',
      ''
    );
  }

  if (status === VerificationStatus.REJECTED) {
    return new VerificationEditorPresentation(
      true,
      true,
      '\u91cd\u65b0\u63d0\u4ea4\u5b66\u751f\u8eab\u4efd\u8ba4\u8bc1',
      ''
    );
  }

  if (status === VerificationStatus.PENDING_REVIEW) {
    return new VerificationEditorPresentation(
      false,
      false,
      '\u8d44\u6599\u5df2\u63d0\u4ea4\uff0c\u7b49\u5f85\u5ba1\u6838',
      '\u5f53\u524d\u7533\u8bf7\u5df2\u8fdb\u5165\u5ba1\u6838\u961f\u5217\uff0c\u5ba1\u6838\u5b8c\u6210\u524d\u4e0d\u80fd\u4fee\u6539\u672c\u6b21\u63d0\u4ea4\u5185\u5bb9\u3002'
    );
  }

  if (status === VerificationStatus.VERIFIED) {
    return new VerificationEditorPresentation(
      false,
      false,
      '\u8ba4\u8bc1\u5df2\u901a\u8fc7',
      '\u5f53\u524d\u516c\u5f00\u8eab\u4efd\u5df2\u901a\u8fc7\u5ba1\u6838\u3002\u82e5\u8d44\u6599\u6709\u53d8\u5316\uff0c\u8bf7\u5148\u66f4\u65b0\u6821\u56ed\u8d44\u6599\uff0c\u518d\u5728\u540e\u7eed\u91cd\u65b0\u53d1\u8d77\u8ba4\u8bc1\u3002'
    );
  }

  return new VerificationEditorPresentation(
    false,
    false,
    '\u8ba4\u8bc1\u5df2\u6682\u505c',
    '\u5f53\u524d\u8ba4\u8bc1\u8d44\u683c\u5df2\u6682\u505c\uff0c\u8bf7\u5148\u8054\u7cfb\u7ba1\u7406\u5458\u5904\u7406\u540e\u518d\u7ee7\u7eed\u63d0\u4ea4\u3002'
  );
}
