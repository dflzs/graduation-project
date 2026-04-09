import { Order, Product } from '../types/domain';

export function isProductOwnedByUser(product: Product | null, userId: string): boolean {
  return !!product && userId.length > 0 && product.sellerId === userId;
}

export function canUserTradeProduct(product: Product | null, userId: string): boolean {
  if (!product) {
    return false;
  }
  return product.status === 'on_sale' && !isProductOwnedByUser(product, userId);
}

export function canUserAccessOrder(order: Order | null, userId: string): boolean {
  return !!order && userId.length > 0 && (order.buyerId === userId || order.sellerId === userId);
}
