import { localDb } from '../data/db/local-db';
import { Order, OrderStatus } from '../types/domain';

export class OrderRepository {
  list(): Order[] {
    return localDb.getOrders();
  }

  getById(orderId: string): Order | null {
    const order: Order | undefined = localDb.getOrders().find((o: Order) => o.id === orderId);
    return order ?? null;
  }

  listByBuyer(buyerId: string): Order[] {
    return localDb.getOrders()
      .filter((o: Order) => o.buyerId === buyerId)
      .sort((a: Order, b: Order) => b.createdAt - a.createdAt);
  }

  listBySeller(sellerId: string): Order[] {
    return localDb.getOrders()
      .filter((o: Order) => o.sellerId === sellerId)
      .sort((a: Order, b: Order) => b.createdAt - a.createdAt);
  }

  listByUser(userId: string): Order[] {
    return localDb.getOrders()
      .filter((o: Order) => o.buyerId === userId || o.sellerId === userId)
      .sort((a: Order, b: Order) => b.createdAt - a.createdAt);
  }

  listByUserAndStatus(userId: string, status: OrderStatus): Order[] {
    return localDb.getOrders().filter((o: Order) => (o.buyerId === userId || o.sellerId === userId) && o.status === status);
  }

  findLatestByTradeContext(productId: string, buyerId: string, sellerId: string): Order | null {
    const matched = localDb.getOrders()
      .filter((order: Order) =>
        order.productId === productId
        && order.buyerId === buyerId
        && order.sellerId === sellerId
      )
      .sort((a: Order, b: Order) => b.updatedAt - a.updatedAt);
    return matched.length > 0 ? matched[0] : null;
  }

  findLatestByProductAndUser(productId: string, userId: string): Order | null {
    const matched = localDb.getOrders()
      .filter((order: Order) =>
        order.productId === productId
        && (order.buyerId === userId || order.sellerId === userId)
      )
      .sort((a: Order, b: Order) => b.updatedAt - a.updatedAt);
    return matched.length > 0 ? matched[0] : null;
  }

  findLatestActiveByProductAndBuyer(productId: string, buyerId: string): Order | null {
    const matched = localDb.getOrders()
      .filter((order: Order) =>
        order.productId === productId
        && order.buyerId === buyerId
        && (order.status === OrderStatus.PENDING_PAYMENT
          || order.status === OrderStatus.PAID_SIMULATED
          || order.status === OrderStatus.READY_HANDOVER)
      )
      .sort((a: Order, b: Order) => b.updatedAt - a.updatedAt);
    return matched.length > 0 ? matched[0] : null;
  }

  save(order: Order): Order {
    const orders: Order[] = localDb.getOrders();
    const index: number = orders.findIndex((o: Order) => o.id === order.id);
    if (index >= 0) {
      orders[index] = order;
    } else {
      orders.push(order);
    }
    localDb.setOrders(orders);
    return order;
  }
}

export const orderRepository: OrderRepository = new OrderRepository();
