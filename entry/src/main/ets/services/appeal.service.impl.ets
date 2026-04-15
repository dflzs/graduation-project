import { appealRepository } from '../repositories/appeal.repo';
import { moderationRepository } from '../repositories/moderation.repo';
import { RemoteAppealReviewPayload, RemoteAppealSubmitPayload } from '../types/appeal-remote';
import { AppealService } from '../types/service-contracts';
import {
  AppealEligibility,
  AppealRecord,
  AppealStatus,
  ModerationRecord,
  ModerationStatus,
  OperationResult,
  User
} from '../types/domain';
import { newId } from '../utils/id';
import { notificationService } from './notification.service.impl';
import { syncService } from './sync.service.impl';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteAppealClient, remoteAppealClient } from './appeal-remote.client';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from './guard.service';
import { buildAppealNextStepGuidance, buildAppealResultSummary } from '../utils/governance-resolution-copy';

class AppealSession {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

function isAppealEligibleModerationStatus(status: ModerationStatus): boolean {
  return status === 'resolved_valid' || status === 'resolved_rejected' || status === 'resolved_partial';
}

function buildAppealReviewTitle(status: AppealStatus): string {
  if (status === 'accepted') {
    return '申诉结果已更新';
  }
  if (status === 'rejected') {
    return '申诉结果已更新';
  }
  if (status === 'closed') {
    return '申诉已结案';
  }
  return '申诉状态已更新';
}

function buildAppealReviewMessage(status: AppealStatus): string {
  if (status === 'accepted') {
    return '平台已接受本次申诉，案件会进入后续复核处理。';
  }
  if (status === 'rejected') {
    return '平台已驳回本次申诉，当前处理结论维持不变。';
  }
  if (status === 'closed') {
    return '本次申诉已经完成处理并正式结案。';
  }
  return '本次申诉状态已更新。';
}

function buildUnifiedAppealReviewMessage(status: AppealStatus): string {
  return `${buildAppealResultSummary(status)} ${buildAppealNextStepGuidance(status)}`;
}

function buildUnifiedAppealReviewTitle(status: AppealStatus): string {
  if (status === 'closed') {
    return '申诉已结案';
  }
  return '申诉结果已更新';
}

export class AppealServiceImpl implements AppealService {
  private readonly remoteClient: RemoteAppealClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteAppealClient = remoteAppealClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  async checkAppealEligibility(
    moderationRecordId: string,
    appellantId: string
  ): Promise<OperationResult<AppealEligibility>> {
    const session = this.resolveUserSession();
    if (!session) {
      return { ok: false, message: '请先登录后再继续' };
    }
    if (session.user.id !== appellantId) {
      return { ok: false, message: '仅支持当前登录用户发起申诉' };
    }

    const moderationRecord = moderationRepository.getById(moderationRecordId);
    if (!moderationRecord) {
      return { ok: false, message: '对应治理记录不存在' };
    }
    if (moderationRecord.reporterId !== appellantId) {
      return {
        ok: true,
        message: '当前账号不是该治理记录的提交方',
        data: {
          moderationRecordId,
          appellantId,
          eligible: false,
          reason: '只有该举报或投诉的提交方才能发起申诉'
        }
      };
    }
    if (!isAppealEligibleModerationStatus(moderationRecord.status)) {
      return {
        ok: true,
        message: '当前处理阶段暂不支持发起申诉',
        data: {
          moderationRecordId,
          appellantId,
          eligible: false,
          reason: '只有已形成处理结论的治理记录才允许发起申诉'
        }
      };
    }

    const existingAppeal = appealRepository.listByModerationRecord(moderationRecordId)
      .find((record: AppealRecord) => record.status !== 'closed');
    if (existingAppeal) {
      return {
        ok: true,
        message: '该治理记录已有进行中的申诉',
        data: {
          moderationRecordId,
          appellantId,
          eligible: false,
          reason: '当前治理记录已有进行中的申诉，无需重复提交',
          existingAppealId: existingAppeal.id
        }
      };
    }

    return {
      ok: true,
      message: '当前结论允许发起申诉',
      data: {
        moderationRecordId,
        appellantId,
        eligible: true,
        reason: '当前结论允许发起一次申诉'
      }
    };
  }

  async submitAppeal(
    moderationRecordId: string,
    appellantId: string,
    reason: string,
    description: string,
    evidenceItems: string[] = []
  ): Promise<OperationResult<AppealRecord>> {
    const session = this.resolveUserSession();
    if (!session) {
      return { ok: false, message: '请先登录后再继续' };
    }

    const eligibility = await this.checkAppealEligibility(moderationRecordId, appellantId);
    if (!eligibility.ok) {
      return { ok: false, message: eligibility.message };
    }
    if (!eligibility.data?.eligible) {
      return { ok: false, message: eligibility.data?.reason ?? eligibility.message };
    }
    if (reason.trim().length === 0) {
      return { ok: false, message: '请先填写申诉原因' };
    }
    if (description.trim().length < 4) {
      return { ok: false, message: '请补充更具体的申诉说明' };
    }

    const remoteResult = await this.remoteClient.submitAppeal(
      session.token,
      new RemoteAppealSubmitPayload(moderationRecordId, reason.trim(), description.trim(), evidenceItems)
    );
    if (remoteResult.ok && remoteResult.data) {
      const persisted = this.persist(remoteResult.data);
      this.markModerationAppealed(moderationRecordId);
      return {
        ok: true,
        message: remoteResult.message,
        data: persisted
      };
    }

    const now = Date.now();
    const localRecord: AppealRecord = {
      id: newId('appeal'),
      moderationRecordId,
      appellantId,
      reason: reason.trim(),
      description: description.trim(),
      evidenceItems,
      status: 'pending',
      createdAt: now,
      updatedAt: now
    };
    const persisted = this.persist(localRecord);
    this.markModerationAppealed(moderationRecordId);
    return {
      ok: true,
      message: '申诉提交成功',
      data: persisted
    };
  }

  async listMyAppeals(appellantId: string): Promise<OperationResult<AppealRecord[]>> {
    const session = this.resolveUserSession();
    if (!session) {
      return { ok: false, message: '请先登录后再继续' };
    }
    if (session.user.id !== appellantId) {
      return { ok: false, message: '仅支持查看当前登录用户自己的申诉' };
    }

    const remoteResult = await this.remoteClient.listMyAppeals(session.token);
    if (remoteResult.ok && remoteResult.data) {
      remoteResult.data.forEach((record: AppealRecord) => {
        this.persist(record);
      });
      return {
        ok: true,
        message: remoteResult.message,
        data: appealRepository.listByAppellant(appellantId)
      };
    }

    const localItems = appealRepository.listByAppellant(appellantId);
    return {
      ok: true,
      message: localItems.length > 0 ? '已使用本地申诉缓存' : remoteResult.message,
      data: localItems
    };
  }

  async listAppeals(status?: AppealStatus): Promise<OperationResult<AppealRecord[]>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminAccessDeniedMessage(this.stateService.getCurrentUser()) };
    }

    const remoteResult = await this.remoteClient.listAppeals(session.token, status);
    if (remoteResult.ok && remoteResult.data) {
      appealRepository.replaceAll(remoteResult.data);
      return {
        ok: true,
        message: remoteResult.message,
        data: status ? appealRepository.listByStatus(status) : appealRepository.list()
      };
    }

    const localItems = status ? appealRepository.listByStatus(status) : appealRepository.list();
    return {
      ok: true,
      message: localItems.length > 0 ? '已使用本地申诉缓存' : remoteResult.message,
      data: localItems
    };
  }

  async reviewAppeal(
    appealId: string,
    status: AppealStatus,
    reviewComment: string
  ): Promise<OperationResult<AppealRecord>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminActionDeniedMessage(this.stateService.getCurrentUser()) };
    }

    const remoteResult = await this.remoteClient.reviewAppeal(
      session.token,
      appealId,
      new RemoteAppealReviewPayload(status, reviewComment)
    );
    if (remoteResult.ok && remoteResult.data) {
      const persisted = this.persist(remoteResult.data);
      this.applyModerationFollowUp(persisted);
      this.notifyAppellant(persisted);
      return {
        ok: true,
        message: buildUnifiedAppealReviewMessage(persisted.status),
        data: persisted
      };
    }

    const existing = appealRepository.getById(appealId);
    if (!existing) {
      return { ok: false, message: remoteResult.message };
    }

    const now = Date.now();
    const updated: AppealRecord = {
      id: existing.id,
      moderationRecordId: existing.moderationRecordId,
      appellantId: existing.appellantId,
      reason: existing.reason,
      description: existing.description,
      evidenceItems: existing.evidenceItems,
      status,
      reviewedBy: session.user.id,
      reviewComment,
      reviewedAt: now,
      createdAt: existing.createdAt,
      updatedAt: now
    };
    const persisted = this.persist(updated);
    this.applyModerationFollowUp(persisted);
    this.notifyAppellant(persisted);
    return {
      ok: true,
      message: buildUnifiedAppealReviewMessage(status),
      data: persisted
    };
  }

  private persist(record: AppealRecord): AppealRecord {
    const persisted = appealRepository.save(record);
    syncService.publish({
      key: 'appeals:changed',
      value: persisted.id,
      updatedAt: persisted.updatedAt
    });
    return persisted;
  }

  private markModerationAppealed(moderationRecordId: string): void {
    const moderationRecord = moderationRepository.getById(moderationRecordId);
    if (!moderationRecord) {
      return;
    }
    moderationRepository.save({
      id: moderationRecord.id,
      reporterId: moderationRecord.reporterId,
      targetType: moderationRecord.targetType,
      targetId: moderationRecord.targetId,
      reportedUserId: moderationRecord.reportedUserId,
      relatedOrderId: moderationRecord.relatedOrderId,
      relatedProductId: moderationRecord.relatedProductId,
      relatedThreadId: moderationRecord.relatedThreadId,
      category: moderationRecord.category,
      reason: moderationRecord.reason,
      description: moderationRecord.description,
      evidenceItems: moderationRecord.evidenceItems,
      status: 'appealed',
      priority: moderationRecord.priority,
      assignedAdminId: moderationRecord.assignedAdminId,
      adminComment: moderationRecord.adminComment,
      resolutionCode: moderationRecord.resolutionCode,
      governanceActionId: moderationRecord.governanceActionId,
      reviewedBy: moderationRecord.reviewedBy,
      reviewedAt: moderationRecord.reviewedAt,
      closedAt: moderationRecord.closedAt,
      createdAt: moderationRecord.createdAt,
      updatedAt: Date.now()
    });
    syncService.publish({
      key: 'moderation:changed',
      value: moderationRecordId,
      updatedAt: Date.now()
    });
  }

  private applyModerationFollowUp(appeal: AppealRecord): void {
    const moderationRecord = moderationRepository.getById(appeal.moderationRecordId);
    if (!moderationRecord) {
      return;
    }
    let nextStatus: ModerationStatus = moderationRecord.status;
    if (appeal.status === 'accepted' || appeal.status === 'rejected' || appeal.status === 'in_review') {
      nextStatus = 'appeal_reviewing';
    }
    if (appeal.status === 'closed') {
      nextStatus = 'closed';
    }
    moderationRepository.save({
      id: moderationRecord.id,
      reporterId: moderationRecord.reporterId,
      targetType: moderationRecord.targetType,
      targetId: moderationRecord.targetId,
      reportedUserId: moderationRecord.reportedUserId,
      relatedOrderId: moderationRecord.relatedOrderId,
      relatedProductId: moderationRecord.relatedProductId,
      relatedThreadId: moderationRecord.relatedThreadId,
      category: moderationRecord.category,
      reason: moderationRecord.reason,
      description: moderationRecord.description,
      evidenceItems: moderationRecord.evidenceItems,
      status: nextStatus,
      priority: moderationRecord.priority,
      assignedAdminId: moderationRecord.assignedAdminId,
      adminComment: moderationRecord.adminComment,
      resolutionCode: moderationRecord.resolutionCode,
      governanceActionId: moderationRecord.governanceActionId,
      reviewedBy: moderationRecord.reviewedBy,
      reviewedAt: moderationRecord.reviewedAt,
      closedAt: nextStatus === 'closed' ? Date.now() : moderationRecord.closedAt,
      createdAt: moderationRecord.createdAt,
      updatedAt: Date.now()
    });
    syncService.publish({
      key: 'moderation:changed',
      value: moderationRecord.id,
      updatedAt: Date.now()
    });
  }

  private notifyAppellant(record: AppealRecord): void {
    const detailText = record.reviewComment && record.reviewComment.length > 0
      ? `处理备注：${record.reviewComment}`
      : '平台已同步更新这次申诉的处理说明。';
    notificationService.create(
      record.appellantId,
      'system_notice',
      buildUnifiedAppealReviewTitle(record.status),
      `${buildUnifiedAppealReviewMessage(record.status)} ${detailText}`,
      record.id
    );
  }

  private resolveSession(): AppealSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser) {
      return null;
    }
    return new AppealSession(this.stateService.getToken(), currentUser);
  }

  private resolveUserSession(): AppealSession | null {
    const session = this.resolveSession();
    if (!session || session.user.role !== 'user') {
      return null;
    }
    return session;
  }

  private resolveAdminSession(): AppealSession | null {
    const session = this.resolveSession();
    if (!session || session.user.role !== 'admin' || session.user.status !== 'active') {
      return null;
    }
    return session;
  }
}

export const appealService: AppealServiceImpl = new AppealServiceImpl();
