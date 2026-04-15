import {
  GovernanceActionType,
  ModerationPriority,
  ModerationRecord,
  ModerationStatus,
  ModerationTargetType
} from '../types/domain';

export enum AdminModerationQueue {
  PENDING = 'pending',
  AWAITING_EVIDENCE = 'awaiting_evidence',
  APPEAL = 'appeal',
  CLOSED = 'closed'
}

export type AdminModerationAction =
  | 'triage'
  | 'request_evidence'
  | 'resolve_valid'
  | 'resolve_partial'
  | 'resolve_rejected'
  | 'close';

function resolveQueue(status: ModerationStatus): AdminModerationQueue {
  if (status === 'awaiting_evidence') {
    return AdminModerationQueue.AWAITING_EVIDENCE;
  }
  if (status === 'appealed' || status === 'appeal_reviewing') {
    return AdminModerationQueue.APPEAL;
  }
  if (status === 'closed') {
    return AdminModerationQueue.CLOSED;
  }
  return AdminModerationQueue.PENDING;
}

export function buildAdminModerationQueueSummary(
  records: ModerationRecord[]
): Map<AdminModerationQueue, ModerationRecord[]> {
  const summary = new Map<AdminModerationQueue, ModerationRecord[]>();
  summary.set(AdminModerationQueue.PENDING, []);
  summary.set(AdminModerationQueue.AWAITING_EVIDENCE, []);
  summary.set(AdminModerationQueue.APPEAL, []);
  summary.set(AdminModerationQueue.CLOSED, []);

  records.forEach((record: ModerationRecord) => {
    const queue = resolveQueue(record.status);
    const queueRecords = summary.get(queue) ?? [];
    queueRecords.push(record);
    queueRecords.sort((left: ModerationRecord, right: ModerationRecord) => right.updatedAt - left.updatedAt);
    summary.set(queue, queueRecords);
  });

  return summary;
}

export function getAdminModerationQueueLabel(queue: AdminModerationQueue): string {
  if (queue === AdminModerationQueue.AWAITING_EVIDENCE) {
    return '补充材料';
  }
  if (queue === AdminModerationQueue.APPEAL) {
    return '申诉复核';
  }
  if (queue === AdminModerationQueue.CLOSED) {
    return '已结案';
  }
  return '待处理';
}

export function getAdminModerationQueueDescription(queue: AdminModerationQueue): string {
  if (queue === AdminModerationQueue.AWAITING_EVIDENCE) {
    return '集中处理仍在等待补充截图、订单细节或聊天证据的案件。';
  }
  if (queue === AdminModerationQueue.APPEAL) {
    return '集中查看已经进入申诉复核阶段的案件，避免结论长期悬而未决。';
  }
  if (queue === AdminModerationQueue.CLOSED) {
    return '归档已经形成最终结论并完成后续沟通的治理记录。';
  }
  return '集中推进新进入平台的举报、投诉和仍在处理中案件。';
}

export function getAdminModerationStatusLabel(status: ModerationStatus): string {
  if (status === 'triaging') {
    return '分诊中';
  }
  if (status === 'awaiting_evidence') {
    return '待补充材料';
  }
  if (status === 'in_review') {
    return '审核中';
  }
  if (status === 'resolved_valid') {
    return '判定成立';
  }
  if (status === 'resolved_rejected') {
    return '判定驳回';
  }
  if (status === 'resolved_partial') {
    return '部分成立';
  }
  if (status === 'appealed') {
    return '已发起申诉';
  }
  if (status === 'appeal_reviewing') {
    return '申诉复核中';
  }
  if (status === 'closed') {
    return '已结案';
  }
  return '待处理';
}

export function getAdminModerationTargetLabel(targetType: ModerationTargetType): string {
  if (targetType === 'chat_report') {
    return '会话举报';
  }
  if (targetType === 'order_complaint') {
    return '订单投诉';
  }
  if (targetType === 'product_report') {
    return '商品举报';
  }
  return '用户举报';
}

export function getAdminModerationPriorityLabel(priority: ModerationPriority | undefined): string {
  if (priority === 'urgent') {
    return '紧急';
  }
  if (priority === 'high') {
    return '高优先级';
  }
  if (priority === 'low') {
    return '低优先级';
  }
  return '中优先级';
}

export function getAdminModerationAvailableActions(status: ModerationStatus): AdminModerationAction[] {
  if (status === 'pending') {
    return ['triage', 'resolve_valid', 'resolve_partial', 'resolve_rejected'];
  }
  if (status === 'triaging' || status === 'in_review' || status === 'awaiting_evidence') {
    return ['request_evidence', 'resolve_valid', 'resolve_partial', 'resolve_rejected'];
  }
  if (status === 'appealed' || status === 'appeal_reviewing') {
    return ['resolve_valid', 'resolve_partial', 'resolve_rejected', 'close'];
  }
  if (status === 'resolved_valid' || status === 'resolved_rejected' || status === 'resolved_partial') {
    return ['close'];
  }
  return [];
}

export function getAdminModerationActionLabel(action: AdminModerationAction): string {
  if (action === 'triage') {
    return '进入分诊';
  }
  if (action === 'request_evidence') {
    return '请求补充材料';
  }
  if (action === 'resolve_valid') {
    return '判定成立';
  }
  if (action === 'resolve_partial') {
    return '部分成立';
  }
  if (action === 'resolve_rejected') {
    return '判定驳回';
  }
  return '结案归档';
}

export function getAdminModerationRecommendedGovernanceAction(
  targetType: ModerationTargetType,
  action: AdminModerationAction
): GovernanceActionType | undefined {
  if (action === 'resolve_partial') {
    return 'warning';
  }
  if (action !== 'resolve_valid') {
    return undefined;
  }
  if (targetType === 'chat_report') {
    return 'mute_chat';
  }
  if (targetType === 'order_complaint' || targetType === 'product_report') {
    return 'restrict_trade';
  }
  return 'warning';
}

export function buildAdminModerationRecordMetaSummary(record: ModerationRecord): string {
  const parts: string[] = [
    getAdminModerationTargetLabel(record.targetType),
    getAdminModerationPriorityLabel(record.priority)
  ];

  if (record.evidenceItems && record.evidenceItems.length > 0) {
    parts.push(`证据 ${record.evidenceItems.length} 份`);
  } else {
    parts.push('待补证据');
  }

  parts.push(`目标 ${record.targetId}`);
  return parts.join(' / ');
}
