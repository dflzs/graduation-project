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
import { canAccessAdmin } from '../services/guard.service';
import { productRepository } from '../repositories/product.repo';
import { userRepository } from '../repositories/user.repo';
import { orderRepository } from '../repositories/order.repo';
import { AuthSession, Product, User } from '../types/domain';

export class DashboardStats {
  userCount: number = 0;
  bannedUserCount: number = 0;
  productCount: number = 0;
  pendingOrderCount: number = 0;
  paidOrderCount: number = 0;
  completedOrderCount: number = 0;
}

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
    const users = userRepository.list();
    const products = productRepository.list().filter((p: Product) => !p.isDeleted);
    const orders = orderRepository.list();
    const stats: DashboardStats = new DashboardStats();
    stats.userCount = users.length;
    stats.bannedUserCount = users.filter((u: User) => u.status === 'banned').length;
    stats.productCount = products.length;
    stats.pendingOrderCount = orders.filter((o) => o.status === 'PENDING_PAYMENT').length;
    stats.paidOrderCount = orders.filter((o) => o.status === 'PAID_SIMULATED').length;
    stats.completedOrderCount = orders.filter((o) => o.status === 'COMPLETED').length;
    return stats;
  }
}

export const appContext: AppContext = new AppContext();
