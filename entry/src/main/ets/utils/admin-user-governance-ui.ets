import { GovernanceAction, GovernanceActionType, GovernanceUserSummary, UserStatus } from '../types/domain';
import { formatTime } from './time';

export interface AdminUserStatusPresentation {
  label: string;
  textColor: string;
  backgroundColor: string;
}

export interface AdminUserGovernanceSummaryPresentation {
  tone: 'calm' | 'warning';
  title: string;
  description: string;
  badges: string[];
}

export interface AdminUserGovernanceActionPresentation {
  title: string;
  detail: string;
  tone: 'neutral' | 'warning' | 'danger';
  cancelLabel: string;
}

export function getGovernanceActionLabel(actionType: GovernanceActionType): string {
  if (actionType === 'warning') {
    return '平台提醒';
  }
  if (actionType === 'mute_chat') {
    return '聊天禁言';
  }
  if (actionType === 'restrict_trade') {
    return '限制交易';
  }
  if (actionType === 'temporary_ban') {
    return '暂停账号';
  }
  return '长期封禁';
}

function getActionTone(actionType: GovernanceActionType): 'neutral' | 'warning' | 'danger' {
  if (actionType === 'warning') {
    return 'neutral';
  }
  if (actionType === 'mute_chat' || actionType === 'restrict_trade') {
    return 'warning';
  }
  return 'danger';
}

function buildActionTimeText(action: GovernanceAction): string {
  if (action.endAt !== undefined) {
    return `${formatTime(action.startAt)} 至 ${formatTime(action.endAt)}`;
  }
  return `${formatTime(action.startAt)} 生效`;
}

export function buildAdminUserGovernanceActionPresentation(
  action: GovernanceAction
): AdminUserGovernanceActionPresentation {
  const detailParts: string[] = [buildActionTimeText(action), `原因：${action.reason}`];
  if (action.comment && action.comment.trim().length > 0) {
    detailParts.push(`备注：${action.comment.trim()}`);
  }
  return {
    title: getGovernanceActionLabel(action.actionType),
    detail: detailParts.join('；'),
    tone: getActionTone(action.actionType),
    cancelLabel: `解除${getGovernanceActionLabel(action.actionType)}`
  };
}

export function buildAdminUserStatusPresentation(status: UserStatus): AdminUserStatusPresentation {
  if (status === 'muted') {
    return {
      label: '已禁言',
      textColor: '#8A5A13',
      backgroundColor: '#F8F0DF'
    };
  }
  if (status === 'restricted') {
    return {
      label: '已限制交易',
      textColor: '#B8643C',
      backgroundColor: '#F4E6DE'
    };
  }
  if (status === 'suspended') {
    return {
      label: '已暂停',
      textColor: '#9B3F3F',
      backgroundColor: '#F8E8E8'
    };
  }
  if (status === 'banned') {
    return {
      label: '已封禁',
      textColor: '#8B2432',
      backgroundColor: '#F5E0E4'
    };
  }
  return {
    label: '正常',
    textColor: '#237B46',
    backgroundColor: '#E8F5EA'
  };
}

export function getAdminUserNextStatusActions(status: UserStatus): UserStatus[] {
  if (status === 'active') {
    return ['restricted', 'muted', 'suspended', 'banned'];
  }
  return ['active'];
}

export function getAdminUserStatusActionLabel(status: UserStatus): string {
  if (status === 'restricted') {
    return '限制交易';
  }
  if (status === 'muted') {
    return '聊天禁言';
  }
  if (status === 'suspended') {
    return '暂停账号';
  }
  if (status === 'banned') {
    return '封禁账号';
  }
  return '恢复正常';
}

export function buildAdminUserGovernanceSummaryPresentation(
  summary: GovernanceUserSummary
): AdminUserGovernanceSummaryPresentation {
  if (summary.activeActionTypes.length === 0) {
    return {
      tone: 'calm',
      title: '当前没有生效中的治理动作',
      description: `累计治理 ${summary.totalActionCount} 次，未结案件 ${summary.openCaseCount} 条。`,
      badges: []
    };
  }

  const badges = summary.activeActionTypes.map((actionType: GovernanceActionType) =>
    getGovernanceActionLabel(actionType)
  );
  const latestReason = summary.latestAction?.reason ?? '请在治理工作台查看最近处理原因。';

  return {
    tone: 'warning',
    title: `当前生效：${badges.join('、')}`,
    description: `累计治理 ${summary.totalActionCount} 次，未结案件 ${summary.openCaseCount} 条。最近原因：${latestReason}`,
    badges
  };
}
