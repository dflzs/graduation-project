import { governanceRepository } from '../repositories/governance.repo';
import { userRepository } from '../repositories/user.repo';
import { GovernanceAction, GovernanceActionType, OperationResult, User, UserStatus } from '../types/domain';
import { AdminUserService, GovernanceService } from '../types/service-contracts';
import { canAccessAdmin, getAdminActionDeniedMessage } from './guard.service';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteAdminUserClient, remoteAdminUserClient } from './admin-user-remote.client';
import { RemoteAdminUserItem, RemoteAdminUserStatusPayload } from '../types/admin-user-remote';
import { governanceService } from './governance.service.impl';
import { syncService } from './sync.service.impl';

class AdminUserSession {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

const STATUS_GOVERNANCE_ACTION_TYPES: GovernanceActionType[] = [
  'mute_chat',
  'restrict_trade',
  'temporary_ban',
  'permanent_ban'
];

function parseTimestamp(value: string | number): number {
  if (typeof value === 'number') {
    return value;
  }
  const timestamp = Date.parse(value);
  return Number.isNaN(timestamp) ? Date.now() : timestamp;
}

function mapRemoteUserStatus(status: string): UserStatus {
  if (status === 'restricted' || status === 'muted' || status === 'suspended' || status === 'banned') {
    return status;
  }
  return 'active';
}

function mapStatusToGovernanceActionType(status: UserStatus): GovernanceActionType | null {
  if (status === 'restricted') {
    return 'restrict_trade';
  }
  if (status === 'muted') {
    return 'mute_chat';
  }
  if (status === 'suspended') {
    return 'temporary_ban';
  }
  if (status === 'banned') {
    return 'permanent_ban';
  }
  return null;
}

function isStatusDrivenGovernanceAction(actionType: GovernanceActionType): boolean {
  return STATUS_GOVERNANCE_ACTION_TYPES.includes(actionType);
}

export class AdminUserServiceImpl implements AdminUserService {
  private readonly remoteClient: RemoteAdminUserClient;
  private readonly stateService: AuthStateService;
  private readonly governance: GovernanceService;

  constructor(
    remoteClient: RemoteAdminUserClient = remoteAdminUserClient,
    stateService: AuthStateService = authStateService,
    governance: GovernanceService = governanceService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
    this.governance = governance;
  }

  private resolveAdminSession(): AdminUserSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || !canAccessAdmin(currentUser)) {
      return null;
    }
    return new AdminUserSession(this.stateService.getToken(), currentUser);
  }

  private canRequestRemoteAdmin(currentUser: User): boolean {
    return /^\d+$/.test(currentUser.id.trim());
  }

  private mapRemoteUser(existingUser: User | null, item: RemoteAdminUserItem): User {
    const now = Date.now();
    if (!existingUser) {
      return {
        id: String(item.id),
        phone: item.phone,
        nickname: item.nickname || `用户${item.phone.slice(-4)}`,
        avatar: item.avatar || '',
        role: item.role === 'admin' ? 'admin' : 'user',
        status: mapRemoteUserStatus(item.status),
        creditScore: item.credit_score,
        remoteUserId: String(item.id),
        createdAt: parseTimestamp(item.created_at),
        updatedAt: parseTimestamp(item.updated_at) || now
      };
    }

    return {
      id: String(item.id),
      phone: item.phone || existingUser.phone,
      nickname: item.nickname || existingUser.nickname,
      avatar: item.avatar ?? existingUser.avatar,
      role: item.role === 'admin' ? 'admin' : existingUser.role,
      status: mapRemoteUserStatus(item.status),
      creditScore: item.credit_score ?? existingUser.creditScore,
      remoteUserId: String(item.id),
      remoteSalt: existingUser.remoteSalt,
      passwordConfigured: existingUser.passwordConfigured,
      schoolId: existingUser.schoolId,
      schoolName: existingUser.schoolName,
      campusId: existingUser.campusId,
      campusName: existingUser.campusName,
      studentNo: existingUser.studentNo,
      gradeYear: existingUser.gradeYear,
      collegeName: existingUser.collegeName,
      majorName: existingUser.majorName,
      verificationStatus: existingUser.verificationStatus,
      verificationMethod: existingUser.verificationMethod,
      verifiedAt: existingUser.verifiedAt,
      verificationRejectedReason: existingUser.verificationRejectedReason,
      verificationUpdatedAt: existingUser.verificationUpdatedAt,
      completedOrderCount: existingUser.completedOrderCount,
      reportCount: existingUser.reportCount,
      lastActiveAt: existingUser.lastActiveAt,
      createdAt: existingUser.createdAt,
      updatedAt: parseTimestamp(item.updated_at) || now
    };
  }

  private persistRemoteStatusUser(user: User): User {
    const persisted = userRepository.save(user);
    syncService.publish({
      key: 'admin:user-status-changed',
      value: persisted.id,
      updatedAt: persisted.updatedAt
    });
    return persisted;
  }

  async listUsers(): Promise<OperationResult<User[]>> {
    const session = this.resolveAdminSession();
    const localUsers = userRepository.list().sort((a: User, b: User) => b.createdAt - a.createdAt);
    if (!session || !this.canRequestRemoteAdmin(session.user)) {
      return { ok: true, message: '获取用户列表成功', data: localUsers };
    }

    const remoteResult = await this.remoteClient.listUsers(session.token);
    if (remoteResult.ok && remoteResult.data) {
      const users = remoteResult.data
        .map((item: RemoteAdminUserItem) => {
          const existing = userRepository.getById(String(item.id)) ?? userRepository.getByPhone(item.phone);
          const merged = this.mapRemoteUser(existing, item);
          userRepository.save(merged);
          return merged;
        })
        .sort((a: User, b: User) => b.createdAt - a.createdAt);
      return {
        ok: true,
        message: remoteResult.message,
        data: users
      };
    }

    return {
      ok: true,
      message: localUsers.length > 0 ? '已使用本地用户缓存' : remoteResult.message,
      data: localUsers
    };
  }

  async updateUserStatus(userId: string, status: UserStatus): Promise<OperationResult<User>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminActionDeniedMessage(this.stateService.getCurrentUser()) };
    }

    if (!this.canRequestRemoteAdmin(session.user) || !/^\d+$/.test(userId.trim())) {
      const localUpdated = userRepository.updateStatus(userId, status);
      if (!localUpdated) {
        return { ok: false, message: '用户不存在' };
      }
      await this.syncGovernanceActionsForStatus(localUpdated.id, status);
      return {
        ok: true,
        message: this.buildStatusUpdateMessage(status),
        data: localUpdated
      };
    }

    const remoteResult = await this.remoteClient.updateUserStatus(
      session.token,
      userId,
      new RemoteAdminUserStatusPayload(status)
    );
    if (remoteResult.ok && remoteResult.data) {
      const existing = userRepository.getById(String(remoteResult.data.id)) ?? userRepository.getByPhone(remoteResult.data.phone);
      const merged = this.mapRemoteUser(existing, remoteResult.data);
      const persisted = this.persistRemoteStatusUser(merged);
      await this.syncGovernanceActionsForStatus(persisted.id, status);
      return {
        ok: true,
        message: remoteResult.message,
        data: persisted
      };
    }

    const localUpdated = userRepository.updateStatus(userId, status);
    if (!localUpdated) {
      return { ok: false, message: remoteResult.message };
    }
    await this.syncGovernanceActionsForStatus(localUpdated.id, status);
    return {
      ok: true,
      message: this.buildStatusUpdateMessage(status),
      data: localUpdated
    };
  }

  private async syncGovernanceActionsForStatus(userId: string, status: UserStatus): Promise<void> {
    const snapshotLocalActions = governanceRepository.listByUser(userId);
    const listResult = await this.governance.listActionsByUser(userId);
    const remoteActions = listResult.ok ? (listResult.data ?? []) : [];
    const latestLocalActions = governanceRepository.listByUser(userId);
    const actions = remoteActions.length > 0
      ? remoteActions
      : (snapshotLocalActions.length > 0 ? snapshotLocalActions : latestLocalActions);
    const activeStatusActions = actions.filter((item: GovernanceAction) =>
      item.active && isStatusDrivenGovernanceAction(item.actionType)
    );
    const targetActionType = mapStatusToGovernanceActionType(status);

    for (let index = 0; index < activeStatusActions.length; index++) {
      const action = activeStatusActions[index];
      if (targetActionType === null || action.actionType !== targetActionType) {
        await this.governance.cancelAction(action.id, this.buildGovernanceCancelComment(status));
      }
    }

    if (targetActionType === null) {
      return;
    }

    const latestActiveActions = governanceRepository.listActiveByUser(userId).filter((item: GovernanceAction) =>
      isStatusDrivenGovernanceAction(item.actionType)
    );
    if (latestActiveActions.some((item: GovernanceAction) => item.actionType === targetActionType)) {
      return;
    }

    const now = Date.now();
    await this.governance.createAction(
      userId,
      'manual_admin',
      `admin-status:${userId}:${status}:${now}`,
      targetActionType,
      '后台用户治理调整',
      this.buildGovernanceCreateComment(status),
      now
    );
  }

  private buildStatusUpdateMessage(status: UserStatus): string {
    if (status === 'active') {
      return '已恢复为正常状态';
    }
    if (status === 'muted') {
      return '已设置为禁言状态';
    }
    if (status === 'restricted') {
      return '已限制该用户的交易能力';
    }
    if (status === 'suspended') {
      return '已暂停该用户账号';
    }
    return '已封禁该用户';
  }

  private buildGovernanceCreateComment(status: UserStatus): string {
    if (status === 'muted') {
      return '后台用户治理已设置为聊天禁言';
    }
    if (status === 'restricted') {
      return '后台用户治理已设置为限制交易';
    }
    if (status === 'suspended') {
      return '后台用户治理已设置为暂停账号';
    }
    return '后台用户治理已设置为封禁账号';
  }

  private buildGovernanceCancelComment(status: UserStatus): string {
    if (status === 'active') {
      return '后台用户治理已恢复正常状态';
    }
    return `后台用户治理已切换为 ${this.buildStatusUpdateMessage(status)}`;
  }
}

export const adminUserService: AdminUserServiceImpl = new AdminUserServiceImpl();
