import { ModerationTargetType } from '../types/domain';

export type SubmitModerationValidationKind = 'login' | 'reason' | 'description';
export type SubmitAppealValidationKind = 'login' | 'eligibility' | 'reason' | 'description';

export function buildSubmitModerationPageTitle(targetType: ModerationTargetType): string {
  if (targetType === 'chat_report') {
    return '提交会话举报';
  }
  if (targetType === 'product_report') {
    return '提交商品举报';
  }
  if (targetType === 'user_report') {
    return '提交用户举报';
  }
  return '提交订单投诉';
}

export function buildSubmitModerationReasonSuggestions(targetType: ModerationTargetType): string[] {
  if (targetType === 'chat_report') {
    return ['言语骚扰辱骂', '恶意引导站外交易', '疑似诈骗'];
  }
  if (targetType === 'product_report') {
    return ['疑似虚假宣传', '疑似违禁商品', '商品信息涉嫌误导'];
  }
  if (targetType === 'user_report') {
    return ['疑似恶意引流', '疑似骚扰他人', '疑似违规倒卖'];
  }
  return ['爽约未到场', '商品与描述不符', '交易中存在争议'];
}

export function buildSubmitModerationReasonPlaceholder(): string {
  return '也可以直接填写原因';
}

export function buildSubmitModerationReasonLabel(): string {
  return '请选择问题类型';
}

export function buildSubmitModerationDescriptionLabel(): string {
  return '请补充情况说明';
}

export function buildSubmitModerationDescriptionPlaceholder(): string {
  return '尽量说明具体场景、对方行为、关键时间点，以及你希望平台关注的问题。';
}

export function buildSubmitModerationValidationMessage(kind: SubmitModerationValidationKind): string {
  if (kind === 'reason') {
    return '请先选择或填写原因';
  }
  if (kind === 'description') {
    return '请补充更具体的情况说明';
  }
  return '请先登录后再继续';
}

export function buildSubmitModerationButtonLabel(isSubmitting: boolean): string {
  return isSubmitting ? '提交中...' : '提交';
}

export function buildSubmitAppealPageHeading(): string {
  return '提交申诉';
}

export function buildSubmitAppealDefaultTitle(): string {
  return '对当前治理结论有异议，可补充新的事实说明和证据线索。';
}

export function buildSubmitAppealDefaultReason(): string {
  return '对处理结论有异议';
}

export function buildSubmitAppealReasonPlaceholder(): string {
  return '例如：存在新的聊天截图或时间线证据';
}

export function buildSubmitAppealReasonLabel(): string {
  return '申诉原因';
}

export function buildSubmitAppealDescriptionLabel(): string {
  return '申诉说明';
}

export function buildSubmitAppealDescriptionPlaceholder(): string {
  return '请补充新的事实说明、关键时间点、补证线索，以及希望平台重新核查的部分。';
}

export function buildSubmitAppealValidationMessage(kind: SubmitAppealValidationKind): string {
  if (kind === 'eligibility') {
    return '当前治理记录暂不支持发起申诉';
  }
  if (kind === 'reason') {
    return '请先填写申诉原因';
  }
  if (kind === 'description') {
    return '请补充更具体的申诉说明';
  }
  return '请先登录后再继续';
}

export function buildSubmitAppealButtonLabel(isSubmitting: boolean): string {
  return isSubmitting ? '提交中...' : '提交申诉';
}

export function buildModerationEntryTitle(targetType: ModerationTargetType): string {
  if (targetType === 'chat_report') {
    return '会话举报';
  }
  if (targetType === 'product_report') {
    return '商品举报';
  }
  if (targetType === 'user_report') {
    return '用户举报';
  }
  return '订单投诉';
}

export function buildModerationEntryDescription(targetType: ModerationTargetType, subjectLabel?: string): string {
  if (targetType === 'chat_report') {
    return '如果这段沟通存在骚扰、恶意引流或疑似诈骗等情况，可以提交举报，平台会进入人工处理。';
  }
  if (targetType === 'product_report') {
    return '如果该商品存在虚假描述、违禁风险或明显误导信息，可以提交举报，平台会进入人工处理。';
  }
  if (targetType === 'user_report') {
    const target = subjectLabel ?? '用户';
    return `如果这位${target}存在恶意引流、骚扰他人或违规倒卖等情况，可以提交举报，平台会进入人工处理。`;
  }
  return '如果这笔订单存在沟通失约、到场纠纷或异常交易情况，可以提交投诉，平台会进入人工处理。';
}

export function buildModerationEntryActionLabel(targetType: ModerationTargetType, subjectLabel?: string): string {
  if (targetType === 'chat_report') {
    return '举报会话';
  }
  if (targetType === 'product_report') {
    return '举报商品';
  }
  if (targetType === 'user_report') {
    return `举报${subjectLabel ?? '用户'}`;
  }
  return '提交投诉';
}

export function buildModerationTargetFallbackTitle(targetType: ModerationTargetType, subjectLabel?: string): string {
  if (targetType === 'chat_report') {
    return '当前会话';
  }
  if (targetType === 'product_report') {
    return '当前商品';
  }
  if (targetType === 'user_report') {
    return `当前${subjectLabel ?? '用户'}`;
  }
  return '当前订单';
}

export function buildSubmitModerationTargetTitle(targetType: ModerationTargetType, title: string): string {
  const normalizedTitle = title.trim();
  if (normalizedTitle.length > 0) {
    return normalizedTitle;
  }
  return buildModerationTargetFallbackTitle(targetType);
}
