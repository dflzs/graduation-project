import { authService } from '../services/auth.service.impl';
import { productService } from '../services/product.service.impl';
import { orderService } from '../services/order.service.impl';
import { cartService } from '../services/cart.service.impl';
import { announcementService } from '../services/announcement.service.impl';
import { creditService } from '../services/credit.service.impl';
import { syncService } from '../services/sync.service.impl';
import { notificationService } from '../services/notification.service.impl';
import { chatService } from '../services/chat.service.impl';
import { campusService } from '../services/campus.service.impl';
import { adminDashboardService } from '../services/admin-dashboard.service.impl';
import { adminProductService } from '../services/admin-product.service.impl';
import { adminUserService } from '../services/admin-user.service.impl';
import { marketplaceProductService } from '../services/marketplace-product.service.impl';
import { moderationService } from '../services/moderation.service.impl';
import { appealService } from '../services/appeal.service.impl';
import { governanceService } from '../services/governance.service.impl';
import { canAccessAdmin } from '../services/guard.service';
import { AuthSession, Product, User } from '../types/domain';
import { DashboardStats } from '../types/dashboard-stats';
import { buildLocalDashboardStats } from '../utils/dashboard-stats';

export class AppContext {
  readonly auth = authService;
  readonly product = productService;
  readonly order = orderService;
  readonly cart = cartService;
  readonly announcement = announcementService;
  readonly credit = creditService;
  readonly sync = syncService;
  readonly notification = notificationService;
  readonly chat = chatService;
  readonly campus = campusService;
  readonly adminDashboard = adminDashboardService;
  readonly adminProducts = adminProductService;
  readonly adminUsers = adminUserService;
  readonly marketplaceProducts = marketplaceProductService;
  readonly moderation = moderationService;
  readonly appeal = appealService;
  readonly governance = governanceService;

  getSession(): AuthSession | null {
    return this.auth.restoreSession();
  }

  getCurrentUser(): User | null {
    return this.getSession()?.currentUser ?? null;
  }

  requireLogin(): boolean {
    return this.getCurrentUser() !== null;
  }

  isAdmin(): boolean {
    return canAccessAdmin(this.getCurrentUser());
  }

  logout(): void {
    this.auth.logout();
  }

  listPublicProducts(keyword: string = '', category: string = '全部'): Product[] {
    return this.product.listProducts({ keyword, category, status: 'on_sale' });
  }

  getDashboardStats(): DashboardStats {
    return buildLocalDashboardStats();
  }
}

export const appContext: AppContext = new AppContext();
