import { AppealRecord, AppealStatus, ModerationRecord, ModerationStatus } from '../types/domain';

export type AppealReviewAction = 'accept' | 'reject' | 'close';

function isAppealOpen(status: AppealStatus): boolean {
  return status === 'pending' || status === 'in_review';
}

function isAppealEligibleModerationStatus(status: ModerationStatus): boolean {
  return status === 'resolved_valid' || status === 'resolved_rejected' || status === 'resolved_partial';
}

export function canSubmitAppealForModerationRecord(
  record: ModerationRecord,
  relatedAppeals: AppealRecord[]
): boolean {
  if (!isAppealEligibleModerationStatus(record.status)) {
    return false;
  }
  return !relatedAppeals.some((appeal: AppealRecord) => isAppealOpen(appeal.status));
}

export function getAppealReviewActions(status: AppealStatus): AppealReviewAction[] {
  if (status === 'pending' || status === 'in_review') {
    return ['accept', 'reject', 'close'];
  }
  if (status === 'accepted' || status === 'rejected') {
    return ['close'];
  }
  return [];
}

export function getAppealReviewActionLabel(action: AppealReviewAction): string {
  if (action === 'accept') {
    return '接受申诉';
  }
  if (action === 'reject') {
    return '驳回申诉';
  }
  return '申诉结案';
}
