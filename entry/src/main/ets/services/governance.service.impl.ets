import { governanceRepository } from '../repositories/governance.repo';
import { moderationRepository } from '../repositories/moderation.repo';
import { userRepository } from '../repositories/user.repo';
import {
  GovernanceAction,
  GovernanceActionType,
  GovernanceSourceType,
  GovernanceUserSummary,
  OperationResult,
  User,
  UserStatus
} from '../types/domain';
import { GovernanceService } from '../types/service-contracts';
import { newId } from '../utils/id';
import { notificationService } from './notification.service.impl';
import { syncService } from './sync.service.impl';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteGovernanceClient, remoteGovernanceClient } from './governance-remote.client';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from './guard.service';
import { RemoteGovernanceActionPayload, RemoteGovernanceCancelPayload } from '../types/governance-remote';

class GovernanceSession {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

function isActionEffective(action: GovernanceAction): boolean {
  const now = Date.now();
  return action.active && action.startAt <= now && (action.endAt === undefined || action.endAt > now);
}

function collectActiveActionTypes(userId: string): GovernanceActionType[] {
  const unique = new Set<GovernanceActionType>();
  governanceRepository.listActiveByUser(userId).forEach((item: GovernanceAction) => unique.add(item.actionType));
  return Array.from(unique.values());
}

function deriveUserStatusFromActionTypes(actionTypes: GovernanceActionType[]): UserStatus {
  if (actionTypes.includes('permanent_ban')) {
    return 'banned';
  }
  if (actionTypes.includes('temporary_ban')) {
    return 'suspended';
  }
  if (actionTypes.includes('restrict_trade')) {
    return 'restricted';
  }
  if (actionTypes.includes('mute_chat')) {
    return 'muted';
  }
  return 'active';
}

function deriveUserStatusFromActions(actions: GovernanceAction[]): UserStatus {
  const effectiveTypes = actions
    .filter((item: GovernanceAction) => isActionEffective(item))
    .map((item: GovernanceAction) => item.actionType);
  return deriveUserStatusFromActionTypes(effectiveTypes);
}

function buildLocalGovernanceSummary(userId: string): GovernanceUserSummary {
  const records: GovernanceAction[] = governanceRepository.listByUser(userId);
  const latestAction: GovernanceAction | undefined = records.length > 0 ? records[0] : undefined;
  const openCaseCount = moderationRepository.list().filter((item) =>
    item.reportedUserId === userId && item.status !== 'closed'
  ).length;

  return {
    userId,
    activeActionTypes: collectActiveActionTypes(userId),
    latestAction,
    totalActionCount: records.length,
    openCaseCount,
    latestActionAt: latestAction?.updatedAt
  };
}

function buildGovernanceCreatedTitle(actionType: GovernanceActionType): string {
  if (actionType === 'warning') {
    return '平台提醒已记录';
  }
  if (actionType === 'mute_chat') {
    return '聊天限制已生效';
  }
  if (actionType === 'restrict_trade') {
    return '交易限制已生效';
  }
  if (actionType === 'temporary_ban') {
    return '账号临时停用已生效';
  }
  return '账号治理动作已生效';
}

function buildGovernanceCreatedMessage(action: GovernanceAction): string {
  if (action.actionType === 'warning') {
    return '平台已记录一次正式提醒，请及时整改相关行为。';
  }
  if (action.actionType === 'mute_chat') {
    return '平台已对你的聊天能力施加限制，请等待后续处理结果。';
  }
  if (action.actionType === 'restrict_trade') {
    return '平台已暂时限制你的交易能力，请前往治理中心查看详情。';
  }
  if (action.actionType === 'temporary_ban') {
    return '平台已暂时停用你的账号，请前往治理中心查看恢复条件。';
  }
  return '平台已对你的账号执行长期治理动作，请联系平台发起申诉。';
}

function buildUnifiedGovernanceCreatedTitle(actionType: GovernanceActionType): string {
  if (actionType === 'warning') {
    return '平台提醒已记录';
  }
  if (actionType === 'mute_chat') {
    return '聊天限制已生效';
  }
  if (actionType === 'restrict_trade') {
    return '交易限制已生效';
  }
  if (actionType === 'temporary_ban') {
    return '账号临时停用已生效';
  }
  return '账号治理动作已生效';
}

function buildUnifiedGovernanceCreatedMessage(action: GovernanceAction): string {
  if (action.actionType === 'warning') {
    return '平台已记录一次正式提醒，请及时整改相关行为。';
  }
  if (action.actionType === 'mute_chat') {
    return '平台已对你的聊天能力施加限制，请等待后续处理结果。';
  }
  if (action.actionType === 'restrict_trade') {
    return '平台已暂时限制你的交易能力，请前往治理中心查看详情。';
  }
  if (action.actionType === 'temporary_ban') {
    return '平台已暂时停用你的账号，请前往治理中心查看恢复条件。';
  }
  return '平台已对你的账号执行长期治理动作，请联系平台发起申诉。';
}

function buildUnifiedGovernanceCanceledTitle(actionType: GovernanceActionType): string {
  if (actionType === 'warning') {
    return '平台提醒已归档';
  }
  if (actionType === 'mute_chat') {
    return '聊天限制已解除';
  }
  if (actionType === 'restrict_trade') {
    return '交易限制已解除';
  }
  if (actionType === 'temporary_ban') {
    return '账号停用已解除';
  }
  return '账号治理动作已解除';
}

function buildUnifiedGovernanceCanceledMessage(action: GovernanceAction): string {
  if (action.actionType === 'warning') {
    return '平台已解除当前治理动作，历史提醒记录仍会保留在治理中心。';
  }
  if (action.actionType === 'mute_chat') {
    return '平台已解除当前治理动作，你的聊天能力会按最新账号状态恢复。请留意治理中心中的后续说明。';
  }
  if (action.actionType === 'restrict_trade') {
    return '平台已解除当前治理动作，交易入口会按最新账号状态恢复开放。请留意治理中心中的后续说明。';
  }
  if (action.actionType === 'temporary_ban') {
    return '平台已解除当前治理动作，账号会按最新治理状态恢复使用。请留意治理中心中的后续说明。';
  }
  return '平台已解除当前治理动作，治理中心会同步展示最新处理结果与恢复条件。';
}

export class GovernanceServiceImpl implements GovernanceService {
  private readonly remoteClient: RemoteGovernanceClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteGovernanceClient = remoteGovernanceClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  async createAction(
    userId: string,
    sourceType: GovernanceSourceType,
    sourceId: string,
    actionType: GovernanceActionType,
    reason: string,
    comment: string,
    startAt: number,
    endAt?: number
  ): Promise<OperationResult<GovernanceAction>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminActionDeniedMessage(this.stateService.getCurrentUser()) };
    }
    if (reason.trim().length === 0) {
      return { ok: false, message: '请先填写治理原因' };
    }

    const payload = new RemoteGovernanceActionPayload(
      userId,
      sourceType,
      sourceId,
      actionType,
      reason.trim(),
      comment.trim(),
      startAt,
      endAt,
      session.user.id
    );
    const remoteResult = await this.remoteClient.createAction(session.token, payload);
    if (remoteResult.ok && remoteResult.data) {
      const persisted = this.persist(remoteResult.data);
      this.afterActionCreated(persisted);
      return {
        ok: true,
        message: '治理动作创建成功',
        data: persisted
      };
    }

    const now = Date.now();
    const localRecord: GovernanceAction = {
      id: newId('governance'),
      userId,
      sourceType,
      sourceId,
      actionType,
      reason: reason.trim(),
      comment: comment.trim(),
      startAt,
      endAt,
      active: true,
      createdBy: session.user.id,
      createdAt: now,
      updatedAt: now
    };
    const persisted = this.persist(localRecord);
    this.afterActionCreated(persisted);
    return {
      ok: true,
      message: '治理动作创建成功',
      data: persisted
    };
  }

  async listActions(): Promise<OperationResult<GovernanceAction[]>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminAccessDeniedMessage(this.stateService.getCurrentUser()) };
    }

    const remoteResult = await this.remoteClient.listActions(session.token);
    if (remoteResult.ok && remoteResult.data) {
      governanceRepository.replaceAll(remoteResult.data);
      this.reconcilePersistedUserStatuses();
      return {
        ok: true,
        message: remoteResult.message,
        data: governanceRepository.list()
      };
    }

    this.reconcilePersistedUserStatuses();
    return {
      ok: true,
      message: governanceRepository.list().length > 0 ? '已使用本地治理动作缓存' : remoteResult.message,
      data: governanceRepository.list()
    };
  }

  async listActionsByUser(userId: string): Promise<OperationResult<GovernanceAction[]>> {
    const session = this.resolveViewerSession(userId);
    if (!session) {
      return { ok: false, message: '当前账号无权查看该治理历史' };
    }

    const remoteResult = await this.remoteClient.listActionsByUser(session.token, userId);
    if (remoteResult.ok && remoteResult.data) {
      governanceRepository.replaceByUser(userId, remoteResult.data);
      this.syncUserStatusFromGovernance(userId);
      return {
        ok: true,
        message: remoteResult.message,
        data: governanceRepository.listByUser(userId)
      };
    }

    this.syncUserStatusFromGovernance(userId);
    return {
      ok: true,
      message: governanceRepository.listByUser(userId).length > 0 ? '已使用本地治理动作缓存' : remoteResult.message,
      data: governanceRepository.listByUser(userId)
    };
  }

  async cancelAction(actionId: string, comment: string): Promise<OperationResult<GovernanceAction>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminActionDeniedMessage(this.stateService.getCurrentUser()) };
    }

    const existing = governanceRepository.getById(actionId);
    const payload = new RemoteGovernanceCancelPayload(session.user.id, comment.trim());
    const remoteResult = await this.remoteClient.cancelAction(session.token, actionId, payload);
    if (remoteResult.ok && remoteResult.data) {
      const persisted = this.persist(remoteResult.data);
      this.afterActionCanceled(persisted);
      return {
        ok: true,
        message: '治理动作已解除',
        data: persisted
      };
      return {
        ok: true,
        message: '治理动作已解除',
        data: persisted
      };
    }
    if (!existing) {
      return { ok: false, message: remoteResult.message.length > 0 ? remoteResult.message : '未找到对应治理动作' };
    }

    const canceledAt = Date.now();
    const persisted = this.persist({
      id: existing.id,
      userId: existing.userId,
      sourceType: existing.sourceType,
      sourceId: existing.sourceId,
      actionType: existing.actionType,
      reason: existing.reason,
      comment: comment.trim().length > 0 ? comment.trim() : existing.comment,
      startAt: existing.startAt,
      endAt: existing.endAt,
      active: false,
      createdBy: existing.createdBy,
      createdAt: existing.createdAt,
      updatedAt: canceledAt,
      canceledAt,
      canceledBy: session.user.id
    });
    this.afterActionCanceled(persisted);
    return {
      ok: true,
      message: '治理动作已解除',
      data: persisted
    };
    return {
      ok: true,
      message: '治理动作已取消',
      data: persisted
    };
  }

  async getUserSummary(userId: string): Promise<OperationResult<GovernanceUserSummary>> {
    const session = this.resolveViewerSession(userId);
    if (!session) {
      return { ok: false, message: '当前账号无权查看该治理摘要' };
    }

    const remoteResult = await this.remoteClient.getUserSummary(session.token, userId);
    if (remoteResult.ok && remoteResult.data) {
      if (remoteResult.data.latestAction) {
        this.persist(remoteResult.data.latestAction);
      }
      this.syncUserStatusFromActionTypes(userId, remoteResult.data.activeActionTypes);
      return {
        ok: true,
        message: remoteResult.message,
        data: remoteResult.data
      };
    }

    this.syncUserStatusFromGovernance(userId);
    return {
      ok: true,
      message: '已使用本地治理摘要缓存',
      data: buildLocalGovernanceSummary(userId)
    };
  }

  private persist(record: GovernanceAction): GovernanceAction {
    return governanceRepository.save(record);
  }

  private afterActionCreated(record: GovernanceAction): void {
    if (record.sourceType === 'moderation') {
      const moderationRecord = moderationRepository.getById(record.sourceId);
      if (moderationRecord) {
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
          status: moderationRecord.status,
          priority: moderationRecord.priority,
          assignedAdminId: moderationRecord.assignedAdminId,
          adminComment: moderationRecord.adminComment,
          resolutionCode: moderationRecord.resolutionCode,
          governanceActionId: record.id,
          reviewedBy: moderationRecord.reviewedBy,
          reviewedAt: moderationRecord.reviewedAt,
          closedAt: moderationRecord.closedAt,
          createdAt: moderationRecord.createdAt,
          updatedAt: Math.max(moderationRecord.updatedAt, record.updatedAt)
        });
        syncService.publish({
          key: 'moderation:changed',
          value: moderationRecord.id,
          updatedAt: record.updatedAt
        });
      }
    }

    notificationService.create(
      record.userId,
      'system_notice',
      buildUnifiedGovernanceCreatedTitle(record.actionType),
      buildUnifiedGovernanceCreatedMessage(record),
      record.id
    );
    this.syncUserStatusFromGovernance(record.userId);
    this.publishGovernanceChanged(record.id);
  }

  private afterActionCanceled(record: GovernanceAction): void {
    notificationService.create(
      record.userId,
      'system_notice',
      buildUnifiedGovernanceCanceledTitle(record.actionType),
      buildUnifiedGovernanceCanceledMessage(record),
      record.id
    );
    this.syncUserStatusFromGovernance(record.userId);
    this.publishGovernanceChanged(record.id);
  }

  private publishGovernanceChanged(actionId: string): void {
    syncService.publish({
      key: 'governance:changed',
      value: actionId,
      updatedAt: Date.now()
    });
  }

  private syncUserStatusFromGovernance(userId: string): void {
    const existingUser = userRepository.getById(userId);
    if (!existingUser || existingUser.role === 'admin') {
      return;
    }

    const nextStatus = deriveUserStatusFromActions(governanceRepository.listByUser(userId));
    if (existingUser.status !== nextStatus) {
      userRepository.updateStatus(userId, nextStatus);
    }
  }

  private syncUserStatusFromActionTypes(userId: string, actionTypes: GovernanceActionType[]): void {
    const existingUser = userRepository.getById(userId);
    if (!existingUser || existingUser.role === 'admin') {
      return;
    }

    const nextStatus = deriveUserStatusFromActionTypes(actionTypes);
    if (existingUser.status !== nextStatus) {
      userRepository.updateStatus(userId, nextStatus);
    }
  }

  private reconcilePersistedUserStatuses(): void {
    const userIds = new Set<string>();
    governanceRepository.list().forEach((item: GovernanceAction) => userIds.add(item.userId));
    userIds.forEach((userId: string) => this.syncUserStatusFromGovernance(userId));
  }

  private resolveAdminSession(): GovernanceSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const user = this.stateService.getCurrentUser();
    const token = this.stateService.getToken();
    if (!user || user.role !== 'admin' || user.status !== 'active' || token.length === 0) {
      return null;
    }
    return new GovernanceSession(token, user);
  }

  private resolveViewerSession(userId: string): GovernanceSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const user = this.stateService.getCurrentUser();
    const token = this.stateService.getToken();
    if (!user || token.length === 0) {
      return null;
    }
    if (user.role === 'admin' && user.status === 'active') {
      return new GovernanceSession(token, user);
    }
    if (user.id !== userId) {
      return null;
    }
    return new GovernanceSession(token, user);
  }
}

export const governanceService: GovernanceService = new GovernanceServiceImpl();
