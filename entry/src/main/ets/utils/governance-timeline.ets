import { AppealRecord, ModerationRecord, ModerationStatus } from '../types/domain';
import { buildAppealResultSummary, buildModerationResultSummary } from './governance-resolution-copy';

export type GovernanceTimelineState = 'done' | 'current' | 'todo';

export interface GovernanceTimelineStep {
  key: string;
  label: string;
  helper: string;
  state: GovernanceTimelineState;
}

function buildStep(
  key: string,
  label: string,
  helper: string,
  state: GovernanceTimelineState
): GovernanceTimelineStep {
  return { key, label, helper, state };
}

function hasOpenAppeal(appeals: AppealRecord[]): boolean {
  return appeals.some((item: AppealRecord) => item.status === 'pending' || item.status === 'in_review');
}

function hasReviewedAppeal(appeals: AppealRecord[]): boolean {
  return appeals.some((item: AppealRecord) =>
    item.status === 'accepted' || item.status === 'rejected' || item.status === 'closed'
  );
}

function getLatestAppeal(appeals: AppealRecord[]): AppealRecord | null {
  if (appeals.length === 0) {
    return null;
  }
  return appeals.slice().sort((left: AppealRecord, right: AppealRecord) => right.updatedAt - left.updatedAt)[0];
}

function getIntakeState(status: ModerationStatus): GovernanceTimelineState {
  if (status === 'pending') {
    return 'todo';
  }
  return 'done';
}

function getEvidenceState(status: ModerationStatus): GovernanceTimelineState {
  if (status === 'awaiting_evidence') {
    return 'current';
  }
  if (status === 'pending' || status === 'triaging') {
    return 'todo';
  }
  return 'done';
}

function getDecisionState(status: ModerationStatus): GovernanceTimelineState {
  if (status === 'resolved_valid' || status === 'resolved_rejected' || status === 'resolved_partial') {
    return 'current';
  }
  if (status === 'appealed' || status === 'appeal_reviewing' || status === 'closed') {
    return 'done';
  }
  return 'todo';
}

function getAppealState(status: ModerationStatus, relatedAppeals: AppealRecord[]): GovernanceTimelineState {
  if (status === 'appealed' || status === 'appeal_reviewing') {
    return 'current';
  }
  if (status === 'closed' && (hasOpenAppeal(relatedAppeals) || hasReviewedAppeal(relatedAppeals))) {
    return 'done';
  }
  return 'todo';
}

export function buildModerationTimelineSteps(
  record: ModerationRecord,
  relatedAppeals: AppealRecord[]
): GovernanceTimelineStep[] {
  const intakeState: GovernanceTimelineState = getIntakeState(record.status);
  const evidenceState: GovernanceTimelineState = getEvidenceState(record.status);
  const decisionState: GovernanceTimelineState = getDecisionState(record.status);
  const appealState: GovernanceTimelineState = getAppealState(record.status, relatedAppeals);

  return [
    buildStep('submitted', '已提交', '平台已经收到你的举报或投诉', 'done'),
    buildStep('intake', '平台受理', '平台正在核对对象、时间线与基础材料', intakeState),
    buildStep('evidence', '补充材料', '如有需要，平台会在这个阶段要求补充证据', evidenceState),
    buildStep('decision', '平台结论', '平台会形成初步处理意见或调查结论', decisionState),
    buildStep('appeal', '申诉复核', '如你对结论有异议，可进入申诉复核阶段', appealState)
  ];
}

export function buildGovernanceCenterTimelineLabel(
  record: ModerationRecord,
  relatedAppeals: AppealRecord[]
): string {
  const latestAppeal = getLatestAppeal(relatedAppeals);
  if (record.status === 'appealed' || record.status === 'appeal_reviewing' || hasOpenAppeal(relatedAppeals)) {
    return buildAppealResultSummary(latestAppeal?.status ?? 'in_review');
  }
  return buildModerationResultSummary(record.status, record.targetType);
}

export function buildAppealTimelineSteps(record: AppealRecord): GovernanceTimelineStep[] {
  const reviewState: GovernanceTimelineState =
    record.status === 'pending' ? 'todo' : 'done';
  let outcomeState: GovernanceTimelineState = 'todo';
  if (record.status === 'accepted' || record.status === 'rejected') {
    outcomeState = 'current';
  } else if (record.status === 'closed') {
    outcomeState = 'done';
  }

  return [
    buildStep('appeal_submitted', '申诉已提交', '平台已经收到你的申诉说明与补充材料', 'done'),
    buildStep('appeal_review', '平台复核', '平台正在重新核对案件事实与原处理结论', reviewState),
    buildStep('appeal_outcome', '申诉结果', '平台会给出申诉处理结果并同步后续动作', outcomeState)
  ];
}

export function buildAppealTimelineSummary(record: AppealRecord): string {
  return buildAppealResultSummary(record.status);
}
