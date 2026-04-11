import { Order, Product, User, UserRole } from '../types/domain';

export type MarketplaceAudienceMode = 'guest' | 'trader' | 'admin';

export function getMarketplaceAudienceMode(user: User | null): MarketplaceAudienceMode {
  if (!user) {
    return 'guest';
  }
  return user.role === 'admin' ? 'admin' : 'trader';
}

export function canCurrentUserJoinTrade(user: User | null): boolean {
  return getMarketplaceAudienceMode(user) === 'trader';
}

export function isProductOwnedByUser(product: Product | null, userId: string): boolean {
  return !!product && userId.length > 0 && product.sellerId === userId;
}

export function canUserTradeProduct(product: Product | null, userId: string, userRole: UserRole = 'user'): boolean {
  if (!product) {
    return false;
  }
  if (userRole !== 'user') {
    return false;
  }
  return product.status === 'on_sale' && !isProductOwnedByUser(product, userId);
}

export function canUserAccessOrder(order: Order | null, userId: string): boolean {
  return !!order && userId.length > 0 && (order.buyerId === userId || order.sellerId === userId);
}
