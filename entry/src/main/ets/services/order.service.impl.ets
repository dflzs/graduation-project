import { orderRepository } from '../repositories/order.repo';
import { productRepository } from '../repositories/product.repo';
import { reviewRepository } from '../repositories/review.repo';
import { OrderService } from '../types/service-contracts';
import { OperationResult, Order, OrderStatus, Product, Review } from '../types/domain';
import { moveOrderStatus, canEnterReadyHandover } from './order-state-machine';
import { newId } from '../utils/id';
import { creditService } from './credit.service.impl';
import { syncService } from './sync.service.impl';
import { notificationService } from './notification.service.impl';

export class OrderServiceImpl implements OrderService {
  private publishProductFeedChanged(status: string): void {
    syncService.publish({
      key: 'products:changed',
      value: status,
      updatedAt: Date.now()
    });
  }

  private publishOrdersChanged(status: string): void {
    syncService.publish({
      key: 'orders:changed',
      value: status,
      updatedAt: Date.now()
    });
  }

  createOrder(buyerId: string, productId: string, address: string): OperationResult<Order> {
    if (address.trim().length === 0) {
      return { ok: false, message: '请填写收货地址或面交地点' };
    }

    const product: Product | null = productRepository.getById(productId);
    if (!product || product.isDeleted || product.status !== 'on_sale') {
      return { ok: false, message: '商品不可购买' };
    }
    if (product.sellerId === buyerId) {
      return { ok: false, message: '不能购买自己发布的商品' };
    }

    const now: number = Date.now();
    const order: Order = {
      id: newId('order'),
      productId: product.id,
      buyerId,
      sellerId: product.sellerId,
      amount: product.price,
      address,
      locationTag: product.locationTag,
      payType: 'simulated',
      status: OrderStatus.PENDING_PAYMENT,
      buyerArrived: false,
      sellerArrived: false,
      reviewed: false,
      createdAt: now,
      updatedAt: now
    };

    orderRepository.save(order);
    const lockedProduct: Product | null = productRepository.updateStatus(product.id, 'locked');
    syncService.publish({ key: `order:${order.id}:status`, value: order.status, updatedAt: order.updatedAt });
    this.publishOrdersChanged(order.status);
    if (lockedProduct) {
      syncService.publish({ key: `product:${lockedProduct.id}:status`, value: lockedProduct.status, updatedAt: lockedProduct.updatedAt });
      this.publishProductFeedChanged(lockedProduct.status);
    }
    notificationService.notifyOrderCreated(buyerId, product.title, order.id);

    return { ok: true, message: '下单成功，商品已进入交易中', data: order };
  }

  simulatePay(orderId: string, operatorId: string): OperationResult<Order> {
    const order: Order | null = orderRepository.getById(orderId);
    if (!order) {
      return { ok: false, message: '订单不存在' };
    }
    if (order.buyerId !== operatorId) {
      return { ok: false, message: '仅买家可支付' };
    }

    const moved = moveOrderStatus(order, OrderStatus.PAID_SIMULATED);
    if (!moved.ok || !moved.data) {
      return moved;
    }

    orderRepository.save(order);
    syncService.publish({ key: `order:${order.id}:status`, value: order.status, updatedAt: order.updatedAt });
    this.publishOrdersChanged(order.status);
    return { ok: true, message: '模拟支付成功', data: order };
  }

  cancelOrder(orderId: string, operatorId: string): OperationResult<Order> {
    const order: Order | null = orderRepository.getById(orderId);
    if (!order) {
      return { ok: false, message: '订单不存在' };
    }
    if (order.buyerId !== operatorId) {
      return { ok: false, message: '仅买家可取消' };
    }

    const moved = moveOrderStatus(order, OrderStatus.CANCELED);
    if (!moved.ok || !moved.data) {
      return moved;
    }

    orderRepository.save(order);
    const restoredProduct: Product | null = productRepository.updateStatus(order.productId, 'on_sale');
    syncService.publish({ key: `order:${order.id}:status`, value: order.status, updatedAt: order.updatedAt });
    this.publishOrdersChanged(order.status);
    if (restoredProduct) {
      syncService.publish({ key: `product:${restoredProduct.id}:status`, value: restoredProduct.status, updatedAt: restoredProduct.updatedAt });
      this.publishProductFeedChanged(restoredProduct.status);
    }
    notificationService.notifyOrderCanceled(order.buyerId, restoredProduct?.title ?? '该商品', order.id);
    return { ok: true, message: '订单已取消，商品已恢复在售', data: order };
  }

  markArrived(orderId: string, operatorId: string): OperationResult<Order> {
    const order: Order | null = orderRepository.getById(orderId);
    if (!order) {
      return { ok: false, message: '订单不存在' };
    }

    if (operatorId === order.buyerId) {
      order.buyerArrived = true;
    } else if (operatorId === order.sellerId) {
      order.sellerArrived = true;
    } else {
      return { ok: false, message: '仅交易双方可确认到达' };
    }

    order.updatedAt = Date.now();
    if (canEnterReadyHandover(order)) {
      order.status = OrderStatus.READY_HANDOVER;
    }

    orderRepository.save(order);
    syncService.publish({
      key: `order:${order.id}:arrival`,
      value: JSON.stringify({ buyerArrived: order.buyerArrived, sellerArrived: order.sellerArrived }),
      updatedAt: order.updatedAt
    });
    syncService.publish({ key: `order:${order.id}:status`, value: order.status, updatedAt: order.updatedAt });
    this.publishOrdersChanged(order.status);

    return { ok: true, message: '到达状态已更新', data: order };
  }

  completeOrder(orderId: string, operatorId: string): OperationResult<Order> {
    const order: Order | null = orderRepository.getById(orderId);
    if (!order) {
      return { ok: false, message: '订单不存在' };
    }
    if (operatorId !== order.buyerId && operatorId !== order.sellerId) {
      return { ok: false, message: '仅交易双方可完结订单' };
    }

    const moved = moveOrderStatus(order, OrderStatus.COMPLETED);
    if (!moved.ok || !moved.data) {
      return moved;
    }

    orderRepository.save(order);
    const soldProduct: Product | null = productRepository.updateStatus(order.productId, 'sold');
    syncService.publish({ key: `order:${order.id}:status`, value: order.status, updatedAt: order.updatedAt });
    this.publishOrdersChanged(order.status);
    if (soldProduct) {
      syncService.publish({ key: `product:${soldProduct.id}:status`, value: soldProduct.status, updatedAt: soldProduct.updatedAt });
      this.publishProductFeedChanged(soldProduct.status);
    }
    notificationService.notifyOrderCompleted(order.buyerId, soldProduct?.title ?? '该商品', order.id);
    notificationService.notifyOrderCompleted(order.sellerId, soldProduct?.title ?? '该商品', order.id);
    return { ok: true, message: '订单已完成', data: order };
  }

  addReview(orderId: string, fromUserId: string, rating: number, tag: string, comment: string): OperationResult<Review> {
    const order: Order | null = orderRepository.getById(orderId);
    if (!order) {
      return { ok: false, message: '订单不存在' };
    }
    if (order.status !== OrderStatus.COMPLETED) {
      return { ok: false, message: '仅已完成订单可评价' };
    }
    if (order.reviewed) {
      return { ok: false, message: '该订单已评价' };
    }
    if (fromUserId !== order.buyerId && fromUserId !== order.sellerId) {
      return { ok: false, message: '仅交易双方可评价' };
    }

    const toUserId: string = fromUserId === order.buyerId ? order.sellerId : order.buyerId;
    const normalizedRating: number = Math.max(1, Math.min(5, rating));

    const review: Review = {
      id: newId('review'),
      orderId,
      fromUserId,
      toUserId,
      rating: normalizedRating,
      tag: tag.trim().length > 0 ? tag : '默认标签',
      comment: comment.trim().length > 0 ? comment : '交易完成，默认好评',
      createdAt: Date.now()
    };

    reviewRepository.save(review);
    order.reviewed = true;
    order.updatedAt = Date.now();
    orderRepository.save(order);
    this.publishOrdersChanged(order.status);

    creditService.recalculateCredit(toUserId);
    return { ok: true, message: '评价成功', data: review };
  }
}

export const orderService: OrderServiceImpl = new OrderServiceImpl();
