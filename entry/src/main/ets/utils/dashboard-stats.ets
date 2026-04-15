import { announcementRepository } from '../repositories/announcement.repo';
import { governanceRepository } from '../repositories/governance.repo';
import { moderationRepository } from '../repositories/moderation.repo';
import { orderRepository } from '../repositories/order.repo';
import { productRepository } from '../repositories/product.repo';
import { userRepository } from '../repositories/user.repo';
import { Order, Product, User, VerificationStatus } from '../types/domain';
import { DashboardStats } from '../types/dashboard-stats';
import { resolveDisplayedVerificationStatus } from './campus-verification-lifecycle-ui';

export function buildLocalDashboardStats(): DashboardStats {
  const users = userRepository.list();
  const traderUsers = users.filter((u: User) => u.role === 'user');
  const products = productRepository.list().filter((p: Product) => !p.isDeleted);
  const orders = orderRepository.list();
  const announcements = announcementRepository.list().filter((item) => !item.isDeleted);
  const stats: DashboardStats = new DashboardStats();
  stats.userCount = users.length;
  stats.bannedUserCount = users
    .filter((u: User) => u.status === 'restricted' || u.status === 'suspended' || u.status === 'banned')
    .length;
  stats.pendingVerificationCount = traderUsers
    .filter((u: User) => resolveDisplayedVerificationStatus(u) === VerificationStatus.PENDING_REVIEW).length;
  stats.verifiedUserCount = traderUsers
    .filter((u: User) => resolveDisplayedVerificationStatus(u) === VerificationStatus.VERIFIED).length;
  stats.productCount = products.length;
  stats.orderCount = orders.length;
  stats.announcementCount = announcements.length;
  stats.pendingOrderCount = orders.filter((o: Order) => o.status === 'PENDING_PAYMENT').length;
  stats.paidOrderCount = orders.filter((o: Order) => o.status === 'PAID_SIMULATED').length;
  stats.completedOrderCount = orders.filter((o: Order) => o.status === 'COMPLETED').length;
  stats.activeGovernanceCount = governanceRepository.list().filter((item) => item.active).length;
  stats.openModerationCaseCount = moderationRepository.list().filter((item) => item.status !== 'closed').length;
  return stats;
}
