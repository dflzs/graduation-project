import { Order, OrderStatus, OperationResult } from '../types/domain';

export function canTransition(current: OrderStatus, target: OrderStatus): boolean {
  if (current === OrderStatus.PENDING_PAYMENT && target === OrderStatus.PAID_SIMULATED) {
    return true;
  }
  if (current === OrderStatus.PENDING_PAYMENT && target === OrderStatus.CANCELED) {
    return true;
  }
  if (current === OrderStatus.READY_HANDOVER && target === OrderStatus.COMPLETED) {
    return true;
  }
  return false;
}

export function moveOrderStatus(order: Order, target: OrderStatus): OperationResult<Order> {
  if (!canTransition(order.status, target)) {
    return {
      ok: false,
      message: `非法状态迁移: ${order.status} -> ${target}`
    };
  }
  order.status = target;
  order.updatedAt = Date.now();
  return {
    ok: true,
    message: '状态迁移成功',
    data: order
  };
}

export function canEnterReadyHandover(order: Order): boolean {
  return order.status === OrderStatus.PAID_SIMULATED && order.buyerArrived && order.sellerArrived;
}
