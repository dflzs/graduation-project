import { GovernanceAction, GovernanceActionType, GovernanceUserSummary } from '../types/domain';
import { buildGovernanceRecoveryCondition } from './governance-resolution-copy';
import { formatTime } from './time';

export type GovernanceSummaryTone = 'calm' | 'warning';

export interface GovernanceSummaryPresentation {
  tone: GovernanceSummaryTone;
  title: string;
  description: string;
  badges: string[];
}

export interface GovernanceActiveActionPresentation {
  title: string;
  detail: string;
  hint: string;
  tone: GovernanceSummaryTone;
}

function getActionBadgeLabel(actionType: GovernanceActionType): string {
  if (actionType === 'warning') {
    return '平台提醒';
  }
  if (actionType === 'mute_chat') {
    return '互动受限';
  }
  if (actionType === 'restrict_trade') {
    return '交易受限';
  }
  if (actionType === 'temporary_ban') {
    return '账号暂时停用';
  }
  return '账号长期停用';
}

function getPublicActionTitle(actionType: GovernanceActionType): string {
  if (actionType === 'warning') {
    return '近期收到平台提醒';
  }
  if (actionType === 'mute_chat') {
    return '当前存在互动限制';
  }
  if (actionType === 'restrict_trade') {
    return '当前交易权限受限';
  }
  if (actionType === 'temporary_ban') {
    return '当前账号暂时停用';
  }
  return '当前账号存在长期限制';
}

function getPublicActionHint(actionType: GovernanceActionType): string {
  const recoveryText = buildGovernanceRecoveryCondition(actionType);
  if (actionType === 'warning') {
    return recoveryText;
  }
  if (actionType === 'mute_chat') {
    return `你仍可查看历史记录，但新互动能力会受到限制。${recoveryText}`;
  }
  if (actionType === 'restrict_trade') {
    return `交易入口会受到限制，可在治理中心跟进处理结果或申诉。${recoveryText}`;
  }
  if (actionType === 'temporary_ban') {
    return `账号恢复前，你将只能查看治理进度与已有记录。${recoveryText}`;
  }
  return recoveryText;
}

function buildActionTimeText(action: GovernanceAction): string {
  if (action.endAt !== undefined) {
    return `${formatTime(action.startAt)} 至 ${formatTime(action.endAt)}`;
  }
  return `${formatTime(action.startAt)} 起生效`;
}

export function buildGovernanceSummaryPresentation(summary: GovernanceUserSummary): GovernanceSummaryPresentation {
  if (summary.activeActionTypes.length === 0) {
    return {
      tone: 'calm',
      title: '当前没有生效中的治理限制',
      description: summary.totalActionCount > 0
        ? '历史治理记录仍会保留在治理中心，便于你随时回看处理经过。'
        : '当前账号状态正常，如后续有举报、投诉或申诉处理，也会在这里持续同步。',
      badges: []
    };
  }

  const badges: string[] = summary.activeActionTypes.map((actionType: GovernanceActionType) =>
    getActionBadgeLabel(actionType)
  );
  const latestReason = summary.latestAction?.reason ?? '请查看治理中心中的最新处理说明';

  return {
    tone: 'warning',
    title: `当前账号存在 ${summary.activeActionTypes.length} 项生效中的治理限制`,
    description: `最近一次治理原因：${latestReason}`,
    badges
  };
}

export function buildGovernanceActiveActionPresentation(
  action: GovernanceAction
): GovernanceActiveActionPresentation {
  const reasonText = action.reason.trim().length > 0 ? action.reason.trim() : '请查看平台处理说明';
  return {
    title: getPublicActionTitle(action.actionType),
    detail: `${buildActionTimeText(action)}；原因：${reasonText}`,
    hint: getPublicActionHint(action.actionType),
    tone: action.actionType === 'warning' ? 'calm' : 'warning'
  };
}
