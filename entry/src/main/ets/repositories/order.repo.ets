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
