import { AppealStatus } from '../types/domain';

export interface AdminModerationLoadingCopy {
  title: string;
  description: string;
}

export interface AdminModerationSummaryCardCopy {
  label: string;
  helper: string;
}

export interface AdminModerationEmptyStateCopy {
  title: string;
  description: string;
}

export type AdminModerationSummaryCardKind =
  | 'moderation'
  | 'appeal'
  | 'open_moderation'
  | 'open_appeal';

export type AdminModerationDetailKind = 'moderation' | 'appeal';
export type AdminModerationBadgeKind = 'moderation' | 'appeal';
export type AdminModerationListMetaKind = 'moderation' | 'appeal';
export type AdminModerationFactKind =
  | 'target_type'
  | 'status'
  | 'priority'
  | 'target_id'
  | 'reporter'
  | 'reported_user'
  | 'evidence_count'
  | 'submitted_at'
  | 'appeal_status'
  | 'linked_record'
  | 'appellant'
  | 'updated_at';

export function buildAdminModerationPageTitle(): string {
  return '举报处理';
}

export function buildAdminModerationHeaderDescription(): string {
  return '按待处理、补充材料、申诉复核、已结案四个队列统一推进商品举报、用户举报、订单投诉与申诉处理。';
}

export function buildAdminModerationLoadingCopy(): AdminModerationLoadingCopy {
  return {
    title: '正在同步治理记录',
    description: '平台正在拉取最新的举报、投诉、申诉与结案状态。'
  };
}

export function buildAdminModerationErrorTitle(): string {
  return '治理记录加载失败';
}

export function buildAdminModerationSummaryCardCopy(
  kind: AdminModerationSummaryCardKind
): AdminModerationSummaryCardCopy {
  if (kind === 'appeal') {
    return { label: '申诉记录', helper: '复核案件' };
  }
  if (kind === 'open_moderation') {
    return { label: '未结案件', helper: '持续跟进' };
  }
  if (kind === 'open_appeal') {
    return { label: '申诉处理中', helper: '等待复核' };
  }
  return { label: '治理记录', helper: '举报与投诉' };
}

export function buildAdminModerationDetailTitle(kind: AdminModerationDetailKind): string {
  if (kind === 'appeal') {
    return '申诉复核详情';
  }
  return '治理详情';
}

export function buildAdminModerationDetailIntro(kind: AdminModerationDetailKind): string {
  if (kind === 'appeal') {
    return '这里集中处理已经发起申诉的案件，给出接受、驳回或结案结论。';
  }
  return '这里集中查看当前队列中的举报、投诉与处理信息，并推进分诊、补证、判定或结案。';
}

export function buildAdminModerationCommentPlaceholder(kind: AdminModerationDetailKind): string {
  if (kind === 'appeal') {
    return '填写申诉复核备注，说明接受、驳回或结案依据。';
  }
  return '填写处理备注，说明分诊判断、补证要求或结论依据。留空时会使用平台默认说明。';
}

export function buildAdminModerationEmptyState(
  queueLabel: string,
  description: string
): AdminModerationEmptyStateCopy {
  return {
    title: `${queueLabel}暂无记录`,
    description
  };
}

export function buildAdminModerationBadgeLabel(kind: AdminModerationBadgeKind): string {
  if (kind === 'appeal') {
    return '申诉记录';
  }
  return '治理记录';
}

export function buildAdminModerationRecordTitle(label: string, reason: string): string {
  const summary = reason.trim();
  if (summary.length === 0) {
    return label;
  }
  return `${label}：${summary}`;
}

export function buildAdminModerationRecordDescription(description: string): string {
  const normalized = description.trim();
  if (normalized.length > 0) {
    return normalized;
  }
  return '当前记录暂无补充说明，可结合事实区和处理结论继续判断。';
}

export function buildAdminModerationFactLabel(kind: AdminModerationFactKind): string {
  if (kind === 'status') {
    return '当前状态';
  }
  if (kind === 'priority') {
    return '优先级';
  }
  if (kind === 'target_id') {
    return '目标 ID';
  }
  if (kind === 'reporter') {
    return '举报人';
  }
  if (kind === 'reported_user') {
    return '被举报用户';
  }
  if (kind === 'evidence_count') {
    return '证据数量';
  }
  if (kind === 'submitted_at') {
    return '提交时间';
  }
  if (kind === 'appeal_status') {
    return '申诉状态';
  }
  if (kind === 'linked_record') {
    return '关联治理记录';
  }
  if (kind === 'appellant') {
    return '申诉人';
  }
  if (kind === 'updated_at') {
    return '最近更新';
  }
  return '记录类型';
}

export function buildAdminModerationFactValue(kind: AdminModerationFactKind, value: string | number): string {
  if (kind === 'evidence_count') {
    return `${value} 份`;
  }
  return `${value}`;
}

export function buildAdminModerationReferenceValue(primaryText: string, referenceId: string): string {
  const primary = primaryText.trim();
  const ref = referenceId.trim();
  if (primary.length > 0 && ref.length > 0) {
    return `${primary} · ${ref}`;
  }
  if (primary.length > 0) {
    return primary;
  }
  return ref;
}

export function buildAdminModerationTargetReferenceValue(summaryText: string, targetId: string): string {
  return buildAdminModerationReferenceValue(summaryText, targetId);
}

export function buildAdminModerationLinkedRecordReferenceValue(recordTitle: string, recordId: string): string {
  return buildAdminModerationReferenceValue(recordTitle, recordId);
}

export function buildAdminModerationGuidanceTitle(kind: AdminModerationDetailKind): string {
  if (kind === 'appeal') {
    return '申诉结论与后续说明';
  }
  return '处理结论与恢复条件';
}

export function buildAdminModerationReviewCommentText(comment: string): string {
  return `当前处理备注：${comment}`;
}

export function buildAdminModerationLinkedRecordMeta(recordId: string): string {
  return `关联治理记录 ${recordId}`;
}

export function buildAdminModerationUpdatedMeta(updatedText: string): string {
  return `更新时间 ${updatedText}`;
}

export function buildAdminModerationListMetaSummary(
  kind: AdminModerationListMetaKind,
  updatedText: string,
  recordId?: string
): string {
  if (kind === 'appeal' && recordId !== undefined && recordId.length > 0) {
    return `${buildAdminModerationLinkedRecordMeta(recordId)} / ${buildAdminModerationUpdatedMeta(updatedText)}`;
  }
  return buildAdminModerationUpdatedMeta(updatedText);
}

export function buildAdminModerationSelectionToast(kind: AdminModerationDetailKind): string {
  if (kind === 'appeal') {
    return '请先选择一条申诉记录';
  }
  return '请先选择一条治理记录';
}

export function getAdminModerationAppealStatusLabel(status: AppealStatus): string {
  if (status === 'in_review') {
    return '复核中';
  }
  if (status === 'accepted') {
    return '申诉成立';
  }
  if (status === 'rejected') {
    return '申诉驳回';
  }
  if (status === 'closed') {
    return '已结案';
  }
  return '待处理';
}
