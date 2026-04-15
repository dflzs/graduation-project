import { governanceRepository } from '../repositories/governance.repo';
import { GovernanceActionType, User, VerificationStatus } from '../types/domain';
import { resolveDisplayedVerificationStatus } from './campus-verification-lifecycle-ui';

export type CampusTrustTone = 'calm' | 'caution' | 'warning';

export class CampusTrustPresentation {
  badgeText: string;
  badgeTextColor: string;
  badgeBackgroundColor: string;
  headline: string;
  summary: string;
  helperText: string;
  isTrusted: boolean;
  trustTags: string[];
  riskText: string;
  tone: CampusTrustTone;
  riskLabel: string;

  constructor(
    badgeText: string,
    badgeTextColor: string,
    badgeBackgroundColor: string,
    headline: string,
    summary: string,
    helperText: string,
    isTrusted: boolean,
    trustTags: string[],
    riskText: string,
    tone: CampusTrustTone,
    riskLabel: string
  ) {
    this.badgeText = badgeText;
    this.badgeTextColor = badgeTextColor;
    this.badgeBackgroundColor = badgeBackgroundColor;
    this.headline = headline;
    this.summary = summary;
    this.helperText = helperText;
    this.isTrusted = isTrusted;
    this.trustTags = trustTags;
    this.riskText = riskText;
    this.tone = tone;
    this.riskLabel = riskLabel;
  }
}

export class CampusTrustListSnippet {
  badgeText: string;
  riskLabel: string;
  tone: CampusTrustTone;
  tags: string[];
  hasMoreTags: boolean;

  constructor(
    badgeText: string,
    riskLabel: string,
    tone: CampusTrustTone,
    tags: string[],
    hasMoreTags: boolean
  ) {
    this.badgeText = badgeText;
    this.riskLabel = riskLabel;
    this.tone = tone;
    this.tags = tags;
    this.hasMoreTags = hasMoreTags;
  }
}

export class CampusTrustTonePalette {
  surfaceBackgroundColor: string;
  riskBadgeTextColor: string;
  riskBadgeBackgroundColor: string;
  tagTextColor: string;
  tagBackgroundColor: string;

  constructor(
    surfaceBackgroundColor: string,
    riskBadgeTextColor: string,
    riskBadgeBackgroundColor: string,
    tagTextColor: string,
    tagBackgroundColor: string
  ) {
    this.surfaceBackgroundColor = surfaceBackgroundColor;
    this.riskBadgeTextColor = riskBadgeTextColor;
    this.riskBadgeBackgroundColor = riskBadgeBackgroundColor;
    this.tagTextColor = tagTextColor;
    this.tagBackgroundColor = tagBackgroundColor;
  }
}

class PublicGovernanceSignal {
  tags: string[];
  riskText: string;
  tone: CampusTrustTone | null;

  constructor(tags: string[], riskText: string, tone: CampusTrustTone | null) {
    this.tags = tags;
    this.riskText = riskText;
    this.tone = tone;
  }
}

function buildTrustSummary(user: User | null): string {
  if (!user) {
    return '暂未获取到对方的校园资料';
  }

  const parts: string[] = [];
  if (user.schoolName && user.schoolName.trim().length > 0) {
    parts.push(user.schoolName.trim());
  }
  if (user.campusName && user.campusName.trim().length > 0) {
    parts.push(user.campusName.trim());
  }
  if (user.collegeName && user.collegeName.trim().length > 0) {
    parts.push(user.collegeName.trim());
  }
  if (user.majorName && user.majorName.trim().length > 0) {
    parts.push(user.majorName.trim());
  }

  if (parts.length > 0) {
    return parts.join(' / ');
  }
  return '对方暂未完善公开校园资料';
}

function listActiveGovernanceActionTypes(user: User | null): GovernanceActionType[] {
  if (!user) {
    return [];
  }

  return governanceRepository.listActiveByUser(user.id)
    .map((item) => item.actionType)
    .filter((value: GovernanceActionType, index: number, array: GovernanceActionType[]) => array.indexOf(value) === index);
}

function buildPublicGovernanceSignal(actionTypes: GovernanceActionType[]): PublicGovernanceSignal {
  const hasTradeRestriction = actionTypes.includes('restrict_trade')
    || actionTypes.includes('temporary_ban')
    || actionTypes.includes('permanent_ban');
  if (hasTradeRestriction) {
    return new PublicGovernanceSignal(
      ['交易权限受限'],
      '该账号当前存在平台治理限制，部分交易能力已受限，交易前请进一步确认商品状态、面交安排与履约风险。',
      'warning'
    );
  }

  if (actionTypes.includes('mute_chat')) {
    return new PublicGovernanceSignal(
      ['当前存在平台限制'],
      '该账号当前存在平台限制，部分互动能力可能受到影响，建议优先通过订单记录和平台流程确认交易安排。',
      'caution'
    );
  }

  if (actionTypes.includes('warning')) {
    return new PublicGovernanceSignal(
      ['近期收到平台提醒'],
      '该账号近期收到平台提醒，建议在沟通中进一步确认商品状态、面交地点与履约约定。',
      'caution'
    );
  }

  return new PublicGovernanceSignal([], '该账号当前没有生效中的平台治理限制。', null);
}

function buildTrustTags(user: User | null, governanceSignal: PublicGovernanceSignal): string[] {
  if (!user) {
    return [];
  }

  const tags: string[] = [];
  if ((user.completedOrderCount ?? 0) > 0) {
    tags.push(`完成 ${user.completedOrderCount ?? 0} 笔交易`);
  }
  if ((user.reportCount ?? 0) > 0) {
    tags.push(`历史纠纷 ${user.reportCount ?? 0} 次`);
  }
  if (governanceSignal.tags.length > 0) {
    governanceSignal.tags.forEach((tag: string) => tags.push(tag));
  } else {
    tags.push('当前无生效治理限制');
  }
  return tags;
}

function buildRiskText(user: User | null, governanceSignal: PublicGovernanceSignal): string {
  if (!user) {
    return '交易前仍建议通过聊天确认商品细节、面交地点和身份信息。';
  }
  if (governanceSignal.tags.length > 0) {
    return governanceSignal.riskText;
  }
  if ((user.reportCount ?? 0) > 0) {
    return '该账号存在历史纠纷记录，建议在聊天中明确验货、面交与履约规则。';
  }
  return governanceSignal.riskText;
}

function resolveTrustTone(
  status: VerificationStatus,
  user: User | null,
  governanceSignal: PublicGovernanceSignal
): CampusTrustTone {
  if (governanceSignal.tone !== null) {
    return governanceSignal.tone;
  }
  if (status !== VerificationStatus.VERIFIED || (user?.reportCount ?? 0) > 0) {
    return 'caution';
  }
  return 'calm';
}

function buildRiskLabel(tone: CampusTrustTone): string {
  if (tone === 'warning') {
    return '高风险';
  }
  if (tone === 'caution') {
    return '需确认';
  }
  return '低风险';
}

export function buildPublicCampusTrustPresentation(user: User | null): CampusTrustPresentation {
  const status = resolveDisplayedVerificationStatus(user);
  const summary = buildTrustSummary(user);
  const activeGovernanceActionTypes = listActiveGovernanceActionTypes(user);
  const governanceSignal = buildPublicGovernanceSignal(activeGovernanceActionTypes);
  const trustTags = buildTrustTags(user, governanceSignal);
  const riskText = buildRiskText(user, governanceSignal);
  const tone = resolveTrustTone(status, user, governanceSignal);
  const riskLabel = buildRiskLabel(tone);

  if (status === VerificationStatus.VERIFIED) {
    return new CampusTrustPresentation(
      '已认证',
      '#237B46',
      '#E8F5EA',
      '校园可信身份',
      summary,
      '平台已完成学生身份认证，交易时仍建议核验商品实物与面交信息。',
      activeGovernanceActionTypes.length === 0,
      trustTags,
      riskText,
      tone,
      riskLabel
    );
  }

  if (status === VerificationStatus.PENDING_REVIEW) {
    return new CampusTrustPresentation(
      '审核中',
      '#A86B00',
      '#F5EBDD',
      '校园身份审核中',
      summary,
      '对方已提交校园认证申请，审核完成前不作为正式核验凭据。',
      false,
      trustTags,
      riskText,
      tone,
      riskLabel
    );
  }

  return new CampusTrustPresentation(
    '待确认',
    '#5E5851',
    '#F1EEEA',
    '校园身份待确认',
    summary,
    '对方暂未完成校园认证，交易前建议在聊天中确认学校、校区与面交地点。',
    false,
    trustTags,
    riskText,
    tone,
    riskLabel
  );
}

export function buildCampusTrustListSnippet(user: User | null, maxTags: number = 2): CampusTrustListSnippet {
  const presentation = buildPublicCampusTrustPresentation(user);
  const resolvedMaxTags = maxTags > 0 ? maxTags : 1;
  const tags: string[] = presentation.trustTags.slice(0, resolvedMaxTags);
  return new CampusTrustListSnippet(
    presentation.badgeText,
    presentation.riskLabel,
    presentation.tone,
    tags,
    presentation.trustTags.length > tags.length
  );
}

export function buildCampusTrustTonePalette(tone: CampusTrustTone): CampusTrustTonePalette {
  if (tone === 'warning') {
    return new CampusTrustTonePalette(
      '#FFF5EE',
      '#B8643C',
      '#FBE7DE',
      '#A05A2C',
      '#FBE7DE'
    );
  }
  if (tone === 'caution') {
    return new CampusTrustTonePalette(
      '#FFF9F0',
      '#A86B00',
      '#F8F0DF',
      '#7A5A24',
      '#F8F0DF'
    );
  }
  return new CampusTrustTonePalette(
    '#F7F4EF',
    '#237B46',
    '#E8F5EA',
    '#237B46',
    '#EEF6F1'
  );
}
