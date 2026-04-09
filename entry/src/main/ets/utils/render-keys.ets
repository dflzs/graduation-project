import { Announcement, ChatThread, MessageNotification, Order, Product, User } from '../types/domain';

export function buildReminderRenderKey(item: MessageNotification): string {
  return `${item.id}:${item.isRead ? 'read' : 'unread'}`;
}

export function buildThreadRenderKey(thread: ChatThread): string {
  return `${thread.id}:${thread.unreadCount}:${thread.lastMessageAt}`;
}

export function buildOrderRenderKey(order: Order): string {
  return `${order.id}:${order.status}:${order.buyerArrived ? 'buyer-arrived' : 'buyer-pending'}:${order.sellerArrived ? 'seller-arrived' : 'seller-pending'}:${order.reviewed ? 'reviewed' : 'pending-review'}:${order.updatedAt}`;
}

export function buildProductRenderKey(product: Product): string {
  return `${product.id}:${product.status}:${product.price}:${product.locationTag}:${product.updatedAt}`;
}

export function buildProductRowRenderKey(row: Product[]): string {
  return row.map((product: Product) => buildProductRenderKey(product)).join('|');
}

export function buildUserRenderKey(user: User): string {
  return `${user.id}:${user.status}:${user.role}:${user.creditScore}:${user.updatedAt}`;
}

export function buildAnnouncementRenderKey(item: Announcement): string {
  return `${item.id}:${item.updatedAt}:${item.title}`;
}
