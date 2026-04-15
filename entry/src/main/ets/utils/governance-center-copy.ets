import { AppealStatus, ModerationStatus, ModerationTargetType } from '../types/domain';

export type GovernanceCenterSection = 'actions' | 'moderation' | 'appeals';
export type GovernanceCenterTimelineKind = 'moderation' | 'appeal';
export type GovernanceCenterSummaryCardKind =
  | 'moderation'
  | 'open_case'
  | 'appeal'
  | 'open_appeal'
  | 'active_action';

export interface GovernanceCenterSummaryCardCopy {
  label: string;
  helper: string;
}

export interface GovernanceCenterEmptyStateCopy {
  title: string;
  description: string;
}

export function getGovernanceCenterTargetLabel(targetType: ModerationTargetType): string {
  if (targetType === 'product_report') {
    return '商品举报';
  }
  if (targetType === 'user_report') {
    return '用户举报';
  }
  if (targetType === 'chat_report') {
    return '会话举报';
  }
  return '订单投诉';
}

export function getGovernanceCenterModerationStatusLabel(status: ModerationStatus): string {
  if (status === 'triaging') {
    return '待分诊';
  }
  if (status === 'awaiting_evidence') {
    return '待补充材料';
  }
  if (status === 'in_review') {
    return '审核中';
  }
  if (status === 'resolved_valid') {
    return '已判定成立';
  }
  if (status === 'resolved_partial') {
    return '已判定部分成立';
  }
  if (status === 'resolved_rejected') {
    return '已判定驳回';
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

export function getGovernanceCenterAppealStatusLabel(status: AppealStatus): string {
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
    return '申诉已结案';
  }
  return '待处理';
}

export function buildGovernanceCenterAppealSubmitTitle(reason: string): string {
  return `针对“${reason}”补充新的说明和证据后，可在这里提交申诉。`;
}

export function buildGovernanceCenterPageTitle(): string {
  return '治理中心';
}

export function buildGovernanceCenterEntryActionLabel(mode: 'guest' | 'admin' | 'restricted' | 'trader'): string {
  if (mode === 'guest') {
    return '去登录';
  }
  if (mode === 'admin') {
    return '进入后台治理台';
  }
  return '查看治理中心';
}

export function buildGovernanceCenterSectionTitle(section: GovernanceCenterSection): string {
  if (section === 'actions') {
    return '当前生效限制';
  }
  if (section === 'appeals') {
    return '申诉记录';
  }
  return '举报与投诉';
}

export function buildGovernanceCenterTimelineTitle(kind: GovernanceCenterTimelineKind): string {
  if (kind === 'appeal') {
    return '申诉进度';
  }
  return '处理进度';
}

export function buildGovernanceCenterSummaryCardCopy(
  kind: GovernanceCenterSummaryCardKind
): GovernanceCenterSummaryCardCopy {
  if (kind === 'moderation') {
    return { label: '举报与投诉', helper: '历史记录' };
  }
  if (kind === 'open_case') {
    return { label: '未结案件', helper: '持续跟进' };
  }
  if (kind === 'appeal') {
    return { label: '申诉记录', helper: '复核进度' };
  }
  if (kind === 'open_appeal') {
    return { label: '处理中申诉', helper: '等待结果' };
  }
  return { label: '生效中动作', helper: '当前仍在影响账号能力' };
}

export function buildGovernanceCenterLoadingCopy(): GovernanceCenterEmptyStateCopy {
  return {
    title: '正在同步治理记录',
    description: '平台正在拉取你的举报、投诉、申诉和治理状态。'
  };
}

export function buildGovernanceCenterErrorTitle(): string {
  return '治理记录加载失败';
}

export function buildGovernanceCenterAppealEmptyState(): GovernanceCenterEmptyStateCopy {
  return {
    title: '当前还没有申诉记录',
    description: '当你对平台结论有异议并提交申诉后，复核进度会显示在这里。'
  };
}

export function buildGovernanceCenterAppealBadgeLabel(): string {
  return '申诉记录';
}

export function buildGovernanceCenterReviewCommentPrefix(): string {
  return '处理备注：';
}

export function buildGovernanceCenterReviewCommentText(comment: string): string {
  return `${buildGovernanceCenterReviewCommentPrefix()}${comment}`;
}

export function buildGovernanceCenterSubmittedMeta(createdAtText: string, updatedAtText: string): string {
  return `提交于 ${createdAtText} / 最近更新 ${updatedAtText}`;
}

export function buildGovernanceCenterAppealButtonLabel(): string {
  return '发起申诉';
}
