import { reviewRepository } from '../repositories/review.repo';
import { userRepository } from '../repositories/user.repo';
import { orderRepository } from '../repositories/order.repo';
import { CreditService } from '../types/service-contracts';
import { Order, OrderStatus, User } from '../types/domain';

export function calculateCreditScore(completedOrderCount: number, avgRating: number): number {
  const normalizedRating: number = Math.max(1, Math.min(5, avgRating));
  const completedBonus: number = Math.min(completedOrderCount, 20);
  const ratingBonus: number = Math.round(normalizedRating * 4);
  return Math.min(100, 60 + completedBonus + ratingBonus);
}

export class CreditServiceImpl implements CreditService {
  recalculateCredit(userId: string): number {
    const user: User | null = userRepository.getById(userId);
    if (!user) {
      return 0;
    }

    const reviews = reviewRepository.listByToUser(userId);
    const avgRating: number = reviews.length > 0
      ? reviews.reduce((sum: number, item) => sum + item.rating, 0) / reviews.length
      : 3;

    const completedOrders: Order[] = orderRepository.listByUser(userId)
      .filter((order: Order) => order.status === OrderStatus.COMPLETED);

    const score: number = calculateCreditScore(completedOrders.length, avgRating);
    user.creditScore = score;
    user.updatedAt = Date.now();
    userRepository.save(user);
    return score;
  }
}

export const creditService: CreditServiceImpl = new CreditServiceImpl();
