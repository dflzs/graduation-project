import { StudentVerification, VerificationStatus } from '../types/domain';

class VerificationGroups {
  pending: StudentVerification[];
  approved: StudentVerification[];
  rejected: StudentVerification[];

  constructor(
    pending: StudentVerification[] = [],
    approved: StudentVerification[] = [],
    rejected: StudentVerification[] = []
  ) {
    this.pending = pending;
    this.approved = approved;
    this.rejected = rejected;
  }
}

function isNewerVerification(next: StudentVerification, current: StudentVerification): boolean {
  if (next.submittedAt !== current.submittedAt) {
    return next.submittedAt > current.submittedAt;
  }
  return next.updatedAt > current.updatedAt;
}

function normalizeVerificationStatus(value: VerificationStatus): string {
  return `${value}`.trim().toUpperCase();
}

function isPendingReviewStatus(status: string): boolean {
  return status === VerificationStatus.PENDING_REVIEW
    || status === 'PENDING'
    || status === 'UNDER_REVIEW'
    || status === 'TO_REVIEW';
}

function isApprovedStatus(status: string): boolean {
  return status === VerificationStatus.VERIFIED
    || status === 'APPROVED'
    || status === 'PASSED';
}

function isRejectedStatus(status: string): boolean {
  return status === VerificationStatus.REJECTED
    || status === VerificationStatus.SUSPENDED
    || status === VerificationStatus.UNVERIFIED
    || status === 'DENIED'
    || status === 'FAILED';
}

export function pickLatestVerificationByUser(items: StudentVerification[]): StudentVerification[] {
  const byUser: Map<string, StudentVerification> = new Map();
  items.forEach((item: StudentVerification) => {
    const userKey = `${item.userId ?? ''}`.trim();
    const key = userKey.length > 0 ? userKey : item.id;
    const existing = byUser.get(key);
    if (!existing || isNewerVerification(item, existing)) {
      byUser.set(key, item);
    }
  });

  return Array.from(byUser.values()).sort((left: StudentVerification, right: StudentVerification) => {
    if (left.submittedAt !== right.submittedAt) {
      return right.submittedAt - left.submittedAt;
    }
    return right.updatedAt - left.updatedAt;
  });
}

export function groupVerificationByReviewTab(items: StudentVerification[]): VerificationGroups {
  const latest = pickLatestVerificationByUser(items);
  const pending: StudentVerification[] = [];
  const approved: StudentVerification[] = [];
  const rejected: StudentVerification[] = [];

  latest.forEach((item: StudentVerification) => {
    const status = normalizeVerificationStatus(item.status);
    if (isPendingReviewStatus(status)) {
      pending.push(item);
      return;
    }
    if (isApprovedStatus(status)) {
      approved.push(item);
      return;
    }
    if (isRejectedStatus(status)) {
      rejected.push(item);
      return;
    }
    pending.push(item);
  });

  return new VerificationGroups(pending, approved, rejected);
}

export function getVerificationMaterialPreviewUrls(item: StudentVerification, maxCount: number = 3): string[] {
  return item.materialUrls
    .map((url: string) => url.trim())
    .filter((url: string) => url.length > 0)
    .slice(0, maxCount);
}
