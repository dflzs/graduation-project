import { User, VerificationStatus } from '../types/domain';
import { resolveDisplayedVerificationStatus } from './campus-verification-lifecycle-ui';

export class CampusTrustPresentation {
  badgeText: string;
  badgeTextColor: string;
  badgeBackgroundColor: string;
  headline: string;
  summary: string;
  helperText: string;
  isTrusted: boolean;

  constructor(
    badgeText: string,
    badgeTextColor: string,
    badgeBackgroundColor: string,
    headline: string,
    summary: string,
    helperText: string,
    isTrusted: boolean
  ) {
    this.badgeText = badgeText;
    this.badgeTextColor = badgeTextColor;
    this.badgeBackgroundColor = badgeBackgroundColor;
    this.headline = headline;
    this.summary = summary;
    this.helperText = helperText;
    this.isTrusted = isTrusted;
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

export function buildPublicCampusTrustPresentation(user: User | null): CampusTrustPresentation {
  const status = resolveDisplayedVerificationStatus(user);
  const summary = buildTrustSummary(user);

  if (status === VerificationStatus.VERIFIED) {
    return new CampusTrustPresentation(
      '已认证',
      '#237B46',
      '#E8F5EA',
      '校园可信身份',
      summary,
      '平台已完成学生身份认证，交易时仍建议核验商品实物与面交信息。',
      true
    );
  }

  if (status === VerificationStatus.PENDING_REVIEW) {
    return new CampusTrustPresentation(
      '审核中',
      '#A86B00',
      '#F5EBDD',
      '校园身份审核中',
      summary,
      '对方已提交校园认证申请，审核完成前不作为正式校验凭据。',
      false
    );
  }

  return new CampusTrustPresentation(
    '待确认',
    '#5E5851',
    '#F1EEEA',
    '校园身份待确认',
    summary,
    '对方暂未完成校园认证，交易前建议在聊天中确认学校、校区与面交地点。',
    false
  );
}
