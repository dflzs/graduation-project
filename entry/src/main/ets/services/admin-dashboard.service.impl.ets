import { OperationResult, User } from '../types/domain';
import { DashboardStats } from '../types/dashboard-stats';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteAdminDashboardClient, remoteAdminDashboardClient } from './admin-dashboard-remote.client';
import { RemoteAdminDashboardItem } from '../types/admin-dashboard-remote';
import { canAccessAdmin } from './guard.service';
import { buildLocalDashboardStats } from '../utils/dashboard-stats';

class AdminDashboardSession {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

export class AdminDashboardServiceImpl {
  private readonly remoteClient: RemoteAdminDashboardClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteAdminDashboardClient = remoteAdminDashboardClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  private resolveAdminSession(): AdminDashboardSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || !canAccessAdmin(currentUser)) {
      return null;
    }
    return new AdminDashboardSession(this.stateService.getToken(), currentUser);
  }

  private canRequestRemoteDashboard(currentUser: User): boolean {
    return /^\d+$/.test(currentUser.id.trim());
  }

  private mergeRemoteStats(localStats: DashboardStats, item: RemoteAdminDashboardItem): DashboardStats {
    const stats: DashboardStats = new DashboardStats();
    stats.userCount = item.user_count;
    stats.bannedUserCount = localStats.bannedUserCount;
    stats.pendingVerificationCount = localStats.pendingVerificationCount;
    stats.verifiedUserCount = localStats.verifiedUserCount;
    stats.productCount = item.product_count;
    stats.orderCount = item.order_count;
    stats.announcementCount = item.announcement_count;
    stats.pendingOrderCount = localStats.pendingOrderCount;
    stats.paidOrderCount = localStats.paidOrderCount;
    stats.completedOrderCount = item.completed_order_count;
    stats.activeGovernanceCount = localStats.activeGovernanceCount;
    stats.openModerationCaseCount = localStats.openModerationCaseCount;
    return stats;
  }

  async getStats(): Promise<OperationResult<DashboardStats>> {
    const localStats = buildLocalDashboardStats();
    const session = this.resolveAdminSession();
    if (!session || !this.canRequestRemoteDashboard(session.user)) {
      return { ok: true, message: '\u83b7\u53d6\u540e\u53f0\u6982\u89c8\u6210\u529f', data: localStats };
    }

    const remoteResult = await this.remoteClient.getDashboard(session.token);
    if (remoteResult.ok && remoteResult.data) {
      return {
        ok: true,
        message: remoteResult.message,
        data: this.mergeRemoteStats(localStats, remoteResult.data)
      };
    }

    return {
      ok: true,
      message: '\u5df2\u4f7f\u7528\u672c\u5730\u540e\u53f0\u7edf\u8ba1\u7f13\u5b58',
      data: localStats
    };
  }
}

export const adminDashboardService: AdminDashboardServiceImpl = new AdminDashboardServiceImpl();
