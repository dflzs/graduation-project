import { AppealStatus, GovernanceActionType, ModerationStatus, ModerationTargetType } from '../types/domain';

function getRecommendedGovernanceAction(
  targetType: ModerationTargetType,
  status: ModerationStatus
): GovernanceActionType | undefined {
  if (status === 'resolved_partial') {
    return 'warning';
  }
  if (status !== 'resolved_valid') {
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

export function buildGovernanceRecoveryCondition(actionType: GovernanceActionType): string {
  if (actionType === 'warning') {
    return '按平台提醒完成整改后，后续将以新增行为记录继续评估。';
  }
  if (actionType === 'mute_chat') {
    return '限制到期或平台完成复核后，聊天能力会恢复正常。';
  }
  if (actionType === 'restrict_trade') {
    return '治理动作解除或复核通过后，交易入口会恢复开放。';
  }
  if (actionType === 'temporary_ban') {
    return '待平台复核结束或停用期满后，账号才会恢复使用。';
  }
  return '如对长期限制有异议，可在治理中心继续提交申诉说明。';
}

export function buildModerationResultSummary(
  status: ModerationStatus,
  targetType: ModerationTargetType
): string {
  if (status === 'triaging') {
    return `平台已开始分诊这条${targetType === 'order_complaint' ? '投诉' : '举报'}，正在核对相关材料。`;
  }
  if (status === 'awaiting_evidence') {
    return '平台需要补充更完整的截图、订单或沟通材料后再继续判断。';
  }
  if (status === 'resolved_valid') {
    return '平台已核实案件成立，并会按结论继续采取治理措施。';
  }
  if (status === 'resolved_partial') {
    return '平台已核实案件部分成立，会保留处理结论并采取保守治理措施。';
  }
  if (status === 'resolved_rejected') {
    return '现有材料暂不足以支持案件成立，当前结论为驳回。';
  }
  if (status === 'appealed') {
    return '案件已进入申诉阶段，平台会继续复核已有结论。';
  }
  if (status === 'appeal_reviewing') {
    return '平台正在结合申诉材料重新复核案件结论。';
  }
  if (status === 'closed') {
    return '案件已完成处理并正式结案归档。';
  }
  return '平台已收到案件，等待进入后续处理流程。';
}

export function buildModerationRecoveryGuidance(
  status: ModerationStatus,
  targetType: ModerationTargetType
): string {
  const actionType = getRecommendedGovernanceAction(targetType, status);
  if (actionType) {
    return buildGovernanceRecoveryCondition(actionType);
  }
  if (status === 'awaiting_evidence') {
    return '补充材料越完整，平台越容易尽快完成下一步判断。';
  }
  if (status === 'resolved_rejected') {
    return '如果后续获得新的关键证据，仍可重新提交案件或发起申诉。';
  }
  if (status === 'appealed' || status === 'appeal_reviewing') {
    return '请在治理中心持续关注复核结果，并及时补充新的说明或证据。';
  }
  if (status === 'closed') {
    return '结案后历史记录仍会保留，便于后续追溯处理经过。';
  }
  return '后续进展会继续同步到治理中心和系统通知。';
}

export function buildAppealResultSummary(status: AppealStatus): string {
  if (status === 'accepted') {
    return '平台已接受本次申诉，案件会进入进一步复核与纠偏处理。';
  }
  if (status === 'rejected') {
    return '平台已驳回本次申诉，当前治理结论维持不变。';
  }
  if (status === 'closed') {
    return '本次申诉复核已完成，案件已正式结案。';
  }
  if (status === 'in_review') {
    return '平台正在复核这次申诉，后续会同步处理结果。';
  }
  return '申诉已提交，等待平台开始复核。';
}

export function buildAppealNextStepGuidance(status: AppealStatus): string {
  if (status === 'accepted') {
    return '你可以继续在治理中心查看案件纠偏进展和后续治理结果。';
  }
  if (status === 'rejected') {
    return '若仍有新的关键证据，可在后续补充说明中继续沟通。';
  }
  if (status === 'closed') {
    return '结案后历史申诉记录仍会保留，便于随时回看。';
  }
  return '复核期间请保持联系方式畅通，并留意系统通知。';
}

export type DefaultModerationAdminAction =
  'triage'
  | 'request_evidence'
  | 'resolve_valid'
  | 'resolve_partial'
  | 'resolve_rejected'
  | 'close';

export type DefaultAppealAdminAction = 'accept' | 'reject' | 'close';

export function buildDefaultModerationAdminComment(
  action: DefaultModerationAdminAction,
  targetType: ModerationTargetType
): string {
  if (action === 'triage') {
    return buildModerationResultSummary('triaging', targetType);
  }
  if (action === 'request_evidence') {
    return buildModerationResultSummary('awaiting_evidence', targetType);
  }
  if (action === 'resolve_valid') {
    return buildModerationResultSummary('resolved_valid', targetType);
  }
  if (action === 'resolve_partial') {
    return buildModerationResultSummary('resolved_partial', targetType);
  }
  if (action === 'resolve_rejected') {
    return buildModerationResultSummary('resolved_rejected', targetType);
  }
  return buildModerationResultSummary('closed', targetType);
}

export function buildDefaultAppealReviewComment(action: DefaultAppealAdminAction): string {
  if (action === 'accept') {
    return buildAppealResultSummary('accepted');
  }
  if (action === 'reject') {
    return buildAppealResultSummary('rejected');
  }
  return buildAppealResultSummary('closed');
}
