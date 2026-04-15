import { moderationRepository } from '../repositories/moderation.repo';
import { chatRepository } from '../repositories/chat.repo';
import { orderRepository } from '../repositories/order.repo';
import { productRepository } from '../repositories/product.repo';
import { userRepository } from '../repositories/user.repo';
import {
  GovernanceActionType,
  ModerationRecord,
  ModerationStatus,
  OperationResult,
  User
} from '../types/domain';
import { GovernanceService, ModerationService } from '../types/service-contracts';
import { newId } from '../utils/id';
import { canCurrentUserJoinTrade } from '../utils/trade-guard';
import { buildModerationRecoveryGuidance, buildModerationResultSummary } from '../utils/governance-resolution-copy';
import { AuthStateService, authStateService } from './auth-state.service';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from './guard.service';
import { RemoteModerationClient, remoteModerationClient } from './moderation-remote.client';
import { RemoteModerationReviewPayload, RemoteModerationSubmitPayload } from '../types/moderation-remote';
import { syncService } from './sync.service.impl';
import { notificationService } from './notification.service.impl';
import { governanceService } from './governance.service.impl';

class ModerationSession {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

class ModerationSubmitMetadata {
  reportedUserId?: string = undefined;
  relatedOrderId?: string = undefined;
  relatedProductId?: string = undefined;
  relatedThreadId?: string = undefined;
  category?: string = undefined;
  priority?: 'low' | 'medium' | 'high' | 'urgent' = undefined;
}

function getOrderComplaintDeniedMessage(user: User | null): string {
  if (!user) {
    return '请先登录后再继续';
  }
  if (user.role === 'admin') {
    return '管理员账号不支持提交订单投诉';
  }
  if (user.status !== 'active') {
    return '该账号已被停用，无法提交订单投诉';
  }
  return '';
}

function getChatReportDeniedMessage(user: User | null): string {
  if (!user) {
    return '请先登录后再继续';
  }
  if (user.role === 'admin') {
    return '管理员账号不支持提交会话举报';
  }
  if (user.status !== 'active') {
    return '该账号已被停用，无法提交会话举报';
  }
  return '';
}

function getGeneralReportDeniedMessage(user: User | null): string {
  if (!user) {
    return '请先登录后再继续';
  }
  if (user.role === 'admin') {
    return '管理员账号不支持提交举报';
  }
  if (user.status !== 'active') {
    return '该账号已被停用，无法提交举报';
  }
  return '';
}

function buildModerationLifecycleMessage(status: ModerationStatus): string {
  if (status === 'triaging') {
    return '举报已进入人工分诊';
  }
  if (status === 'awaiting_evidence') {
    return '举报已转为补证中';
  }
  if (status === 'in_review') {
    return '举报已进入审核中';
  }
  if (status === 'resolved_valid') {
    return '举报已判定成立';
  }
  if (status === 'resolved_rejected') {
    return '举报已判定不成立';
  }
  if (status === 'resolved_partial') {
    return '举报已完成部分成立判定';
  }
  if (status === 'appealed') {
    return '举报已进入申诉阶段';
  }
  if (status === 'appeal_reviewing') {
    return '举报申诉正在复核';
  }
  if (status === 'closed') {
    return '举报案件已正式结案';
  }
  return '举报状态已更新';
}

function buildModerationOutcomeTitle(record: ModerationRecord): string {
  if (record.targetType === 'chat_report') {
    return '会话举报处理结果已更新';
  }
  if (record.targetType === 'order_complaint') {
    return '订单投诉处理结果已更新';
  }
  if (record.targetType === 'product_report') {
    return '商品举报处理结果已更新';
  }
  return '用户举报处理结果已更新';
}

export class ModerationServiceImpl implements ModerationService {
  private readonly remoteClient: RemoteModerationClient;
  private readonly stateService: AuthStateService;
  private readonly governance: GovernanceService;

  constructor(
    remoteClient: RemoteModerationClient = remoteModerationClient,
    stateService: AuthStateService = authStateService,
    governance: GovernanceService = governanceService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
    this.governance = governance;
  }

  async submitProductReport(
    productId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>> {
    const session = this.resolveSession();
    const deniedMessage = getGeneralReportDeniedMessage(session?.user ?? this.stateService.getCurrentUser());
    if (!session || deniedMessage.length > 0 || !canCurrentUserJoinTrade(session.user)) {
      return { ok: false, message: deniedMessage };
    }
    if (session.user.id !== reporterId) {
      return { ok: false, message: '仅支持当前登录用户提交商品举报' };
    }

    const targetProduct = productRepository.getById(productId);
    if (!targetProduct || targetProduct.isDeleted) {
      return { ok: false, message: '商品不存在' };
    }
    if (targetProduct.sellerId === reporterId) {
      return { ok: false, message: '不能举报自己发布的商品' };
    }

    return this.submitRecord(
      'product_report',
      productId,
      reason,
      description,
      session,
      '商品举报提交成功',
      {
        relatedProductId: targetProduct.id,
        reportedUserId: targetProduct.sellerId
      }
    );
  }

  async submitUserReport(
    userId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>> {
    const session = this.resolveSession();
    const deniedMessage = getGeneralReportDeniedMessage(session?.user ?? this.stateService.getCurrentUser());
    if (!session || deniedMessage.length > 0 || !canCurrentUserJoinTrade(session.user)) {
      return { ok: false, message: deniedMessage };
    }
    if (session.user.id !== reporterId) {
      return { ok: false, message: '仅支持当前登录用户提交用户举报' };
    }
    if (userId === reporterId) {
      return { ok: false, message: '不能举报自己' };
    }

    const targetUser = userRepository.getById(userId);
    if (!targetUser) {
      return { ok: false, message: '被举报用户不存在' };
    }

    return this.submitRecord(
      'user_report',
      userId,
      reason,
      description,
      session,
      '用户举报提交成功',
      {
        reportedUserId: targetUser.id
      }
    );
  }

  async submitOrderComplaint(
    orderId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>> {
    const session = this.resolveSession();
    const deniedMessage = getOrderComplaintDeniedMessage(session?.user ?? this.stateService.getCurrentUser());
    if (!session || deniedMessage.length > 0 || !canCurrentUserJoinTrade(session.user)) {
      return { ok: false, message: deniedMessage };
    }
    if (session.user.id !== reporterId) {
      return { ok: false, message: '仅支持当前登录用户提交订单投诉' };
    }

    const targetOrder = orderRepository.getById(orderId);
    if (!targetOrder) {
      return { ok: false, message: '订单不存在' };
    }
    if (targetOrder.buyerId !== reporterId && targetOrder.sellerId !== reporterId) {
      return { ok: false, message: '仅订单参与方可投诉该订单' };
    }

    return this.submitRecord(
      'order_complaint',
      orderId,
      reason,
      description,
      session,
      '订单投诉提交成功'
    );
  }

  async submitChatReport(
    threadId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>> {
    const session = this.resolveSession();
    const deniedMessage = getChatReportDeniedMessage(session?.user ?? this.stateService.getCurrentUser());
    if (!session || deniedMessage.length > 0 || !canCurrentUserJoinTrade(session.user)) {
      return { ok: false, message: deniedMessage };
    }
    if (session.user.id !== reporterId) {
      return { ok: false, message: '仅支持当前登录用户提交会话举报' };
    }

    const targetThread = chatRepository.getThreadById(threadId);
    if (!targetThread) {
      return { ok: false, message: '会话不存在' };
    }
    if (targetThread.buyerId !== reporterId && targetThread.sellerId !== reporterId) {
      return { ok: false, message: '仅会话参与方可举报该会话' };
    }

    return this.submitRecord(
      'chat_report',
      threadId,
      reason,
      description,
      session,
      '会话举报提交成功'
    );
  }

  async listMyModerationRecords(reporterId: string): Promise<OperationResult<ModerationRecord[]>> {
    const session = this.resolveSession();
    if (!session) {
      return { ok: false, message: '请先登录后再继续' };
    }
    if (session.user.id !== reporterId) {
      return { ok: false, message: '仅支持查看当前登录用户自己的治理记录' };
    }

    const remoteResult = await this.remoteClient.listMyRecords(session.token);
    if (remoteResult.ok && remoteResult.data) {
      remoteResult.data.forEach((record: ModerationRecord) => {
        this.persist(record);
      });
      return {
        ok: true,
        message: remoteResult.message,
        data: moderationRepository.list().filter((item: ModerationRecord) => item.reporterId === reporterId)
      };
    }

    const localItems = moderationRepository.list().filter((item: ModerationRecord) => item.reporterId === reporterId);
    return {
      ok: true,
      message: localItems.length > 0 ? '已使用本地治理记录缓存' : remoteResult.message,
      data: localItems
    };
  }

  async listModerationRecords(status?: ModerationStatus): Promise<OperationResult<ModerationRecord[]>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminAccessDeniedMessage(this.stateService.getCurrentUser()) };
    }

    const remoteResult = await this.remoteClient.listRecords(session.token, status);
    if (remoteResult.ok && remoteResult.data) {
      moderationRepository.replaceAll(remoteResult.data);
      return {
        ok: true,
        message: remoteResult.message,
        data: status ? moderationRepository.listByStatus(status) : moderationRepository.list()
      };
    }

    const localItems = status ? moderationRepository.listByStatus(status) : moderationRepository.list();
    return {
      ok: true,
      message: localItems.length > 0 ? '已使用本地举报审核缓存' : remoteResult.message,
      data: localItems
    };
  }

  async triageModerationRecord(recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>> {
    return this.transitionModerationRecord(recordId, 'triaging', adminComment);
  }

  async requestModerationEvidence(recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>> {
    return this.transitionModerationRecord(recordId, 'awaiting_evidence', adminComment);
  }

  async closeModerationRecord(recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>> {
    return this.transitionModerationRecord(recordId, 'closed', adminComment);
  }

  async reviewModerationRecord(
    recordId: string,
    status: ModerationStatus,
    adminComment: string
  ): Promise<OperationResult<ModerationRecord>> {
    return this.transitionModerationRecord(recordId, status, adminComment);
  }

  async reviewModerationRecordWithGovernance(
    recordId: string,
    status: ModerationStatus,
    adminComment: string,
    governanceActionType?: GovernanceActionType
  ): Promise<OperationResult<ModerationRecord>> {
    const reviewResult = await this.transitionModerationRecord(recordId, status, adminComment);
    if (!reviewResult.ok || !reviewResult.data) {
      return reviewResult;
    }
    if (!governanceActionType || (status !== 'resolved_valid' && status !== 'resolved_partial')) {
      return reviewResult;
    }
    return this.attachGovernanceAction(reviewResult.data, governanceActionType, adminComment, reviewResult.message);
  }

  private async submitRecord(
    targetType: 'product_report' | 'user_report' | 'order_complaint' | 'chat_report',
    targetId: string,
    reason: string,
    description: string,
    session: ModerationSession,
    fallbackMessage: string,
    metadata?: ModerationSubmitMetadata
  ): Promise<OperationResult<ModerationRecord>> {
    if (reason.trim().length === 0) {
      return { ok: false, message: '请先填写举报或投诉原因' };
    }
    if (description.trim().length < 4) {
      return { ok: false, message: '请补充更具体的情况说明' };
    }

    const remoteResult = await this.remoteClient.submitRecord(
      session.token,
      new RemoteModerationSubmitPayload(targetType, targetId, reason.trim(), description.trim())
    );
    if (remoteResult.ok && remoteResult.data) {
      return {
        ok: true,
        message: remoteResult.message,
        data: this.persist(remoteResult.data)
      };
    }

    const now = Date.now();
    const localRecord: ModerationRecord = {
      id: newId('moderation'),
      reporterId: session.user.id,
      targetType,
      targetId,
      reportedUserId: metadata?.reportedUserId,
      relatedOrderId: metadata?.relatedOrderId,
      relatedProductId: metadata?.relatedProductId,
      relatedThreadId: metadata?.relatedThreadId,
      category: metadata?.category,
      reason: reason.trim(),
      description: description.trim(),
      evidenceItems: [],
      status: 'pending',
      priority: metadata?.priority ?? 'medium',
      createdAt: now,
      updatedAt: now
    };
    return {
      ok: true,
      message: fallbackMessage,
      data: this.persist(localRecord)
    };
  }

  private async transitionModerationRecord(
    recordId: string,
    status: ModerationStatus,
    adminComment: string
  ): Promise<OperationResult<ModerationRecord>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminActionDeniedMessage(this.stateService.getCurrentUser()) };
    }

    const remoteResult = await this.requestLifecycleTransition(session.token, recordId, status, adminComment);
    if (remoteResult.ok && remoteResult.data) {
      const persisted = this.persist(remoteResult.data);
      this.notifyReporterOfReview(persisted);
      return {
        ok: true,
        message: buildModerationResultSummary(persisted.status, persisted.targetType),
        data: persisted
      };
    }

    const existing = moderationRepository.getById(recordId);
    if (!existing) {
      return { ok: false, message: remoteResult.message };
    }

    const now = Date.now();
    const updated: ModerationRecord = {
      id: existing.id,
      reporterId: existing.reporterId,
      targetType: existing.targetType,
      targetId: existing.targetId,
      reportedUserId: existing.reportedUserId,
      relatedOrderId: existing.relatedOrderId,
      relatedProductId: existing.relatedProductId,
      relatedThreadId: existing.relatedThreadId,
      category: existing.category,
      reason: existing.reason,
      description: existing.description,
      evidenceItems: existing.evidenceItems,
      status,
      priority: existing.priority,
      assignedAdminId: existing.assignedAdminId ?? session.user.id,
      adminComment,
      resolutionCode: existing.resolutionCode,
      governanceActionId: existing.governanceActionId,
      reviewedBy: session.user.id,
      reviewedAt: now,
      createdAt: existing.createdAt,
      closedAt: status === 'closed' ? now : existing.closedAt,
      updatedAt: now
    };
    const persisted = this.persist(updated);
    this.notifyReporterOfReview(persisted);
    return {
      ok: true,
      message: buildModerationResultSummary(persisted.status, persisted.targetType),
      data: persisted
    };
  }

  private async attachGovernanceAction(
    record: ModerationRecord,
    governanceActionType: GovernanceActionType,
    adminComment: string,
    baseMessage: string
  ): Promise<OperationResult<ModerationRecord>> {
    if (!record.reportedUserId || record.reportedUserId.trim().length === 0) {
      return {
        ok: true,
        message: `${baseMessage}，但当前案件未关联具体用户，未创建治理动作`,
        data: record
      };
    }

    const governanceResult = await this.governance.createAction(
      record.reportedUserId,
      'moderation',
      record.id,
      governanceActionType,
      record.reason,
      adminComment.trim().length > 0 ? adminComment.trim() : buildModerationLifecycleMessage(record.status),
      record.reviewedAt ?? Date.now()
    );

    if (!governanceResult.ok) {
      return {
        ok: true,
        message: `${baseMessage}，但治理动作创建失败：${governanceResult.message}`,
        data: moderationRepository.getById(record.id) ?? record
      };
    }

    return {
      ok: true,
      message: `${baseMessage}，并已联动治理动作`,
      data: moderationRepository.getById(record.id) ?? record
    };
  }

  private async requestLifecycleTransition(
    token: string,
    recordId: string,
    status: ModerationStatus,
    adminComment: string
  ): Promise<OperationResult<ModerationRecord>> {
    if (status === 'triaging') {
      return this.remoteClient.triageRecord(token, recordId, adminComment);
    }
    if (status === 'awaiting_evidence') {
      return this.remoteClient.requestEvidence(token, recordId, adminComment);
    }
    if (status === 'closed') {
      return this.remoteClient.closeRecord(token, recordId, adminComment);
    }
    return this.remoteClient.reviewRecord(token, recordId, new RemoteModerationReviewPayload(status, adminComment));
  }

  private persist(record: ModerationRecord): ModerationRecord {
    const persisted = moderationRepository.save(record);
    syncService.publish({
      key: 'moderation:changed',
      value: persisted.id,
      updatedAt: persisted.updatedAt
    });
    return persisted;
  }

  private notifyReporterOfReview(record: ModerationRecord): void {
    if (record.status === 'pending' || record.reporterId.trim().length === 0) {
      return;
    }

    const detail = record.adminComment && record.adminComment.trim().length > 0
      ? `处理备注：${record.adminComment.trim()}`
      : '平台已同步更新这次案件的处理说明。';

    notificationService.create(
      record.reporterId,
      'system_notice',
      buildModerationOutcomeTitle(record),
      `${buildModerationResultSummary(record.status, record.targetType)} ${buildModerationRecoveryGuidance(record.status, record.targetType)} ${detail}`,
      record.id
    );
  }

  private resolveSession(): ModerationSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser) {
      return null;
    }
    return new ModerationSession(this.stateService.getToken(), currentUser);
  }

  private resolveAdminSession(): ModerationSession | null {
    const session = this.resolveSession();
    if (!session || session.user.role !== 'admin' || session.user.status !== 'active') {
      return null;
    }
    return session;
  }
}

export const moderationService: ModerationServiceImpl = new ModerationServiceImpl();
