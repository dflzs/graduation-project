import { Order, OrderStatus } from '../types/domain';

export type HomeProductTradeAction = 'chat' | 'order' | 'detail';

export function buildHomeProductConversationHint(hasThread: boolean): string {
  return hasThread ? '已沟通，可继续联系卖家。' : '';
}

export function buildHomeProductOwnerConversationHint(counterpartyName: string): string {
  const buyerName = normalizeCounterpartyName(counterpartyName);
  return `已有买家沟通 · 当前买家：${buyerName}`;
}

export function buildHomeProductConversationActionLabel(): string {
  return '继续沟通';
}

export function buildHomeProductTradeHint(
  order: Order | null,
  viewerId: string,
  counterpartyName: string,
  isOwner: boolean,
  hasThread: boolean
): string {
  if (!order) {
    if (!hasThread) {
      return '';
    }
    return isOwner
      ? buildHomeProductOwnerConversationHint(counterpartyName)
      : buildHomeProductConversationHint(true);
  }

  if (isOwner) {
    const buyerName = normalizeCounterpartyName(counterpartyName);
    if (order.status === OrderStatus.COMPLETED) {
      return `最近交易已完成 · 最近买家：${buyerName}`;
    }
    if (order.status === OrderStatus.CANCELED) {
      return `最近交易已结束 · 最近买家：${buyerName}`;
    }
    return `已有当前交易 · 当前买家：${buyerName}`;
  }

  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return viewerId === order.buyerId ? '已有当前交易，待完成支付。' : '已有当前交易，待买家完成支付。';
  }
  if (order.status === OrderStatus.COMPLETED) {
    return '最近交易已完成，可回看沟通记录。';
  }
  if (order.status === OrderStatus.CANCELED) {
    return '上次交易已结束，可重新确认是否继续购买。';
  }
  return '已有当前交易，可继续确认面交安排。';
}

export function buildHomeProductTradeActionLabel(
  order: Order | null,
  viewerId: string,
  hasThread: boolean
): string {
  if (!order) {
    return hasThread ? '继续沟通' : '详情 >';
  }
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return viewerId === order.buyerId ? '去支付' : '看支付';
  }
  if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELED) {
    return hasThread ? '查看聊天记录' : '看订单';
  }
  return hasThread ? '继续沟通' : '看订单';
}

export function resolveHomeProductTradeAction(
  order: Order | null,
  viewerId: string,
  hasThread: boolean
): HomeProductTradeAction {
  if (!order) {
    return hasThread ? 'chat' : 'detail';
  }
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return 'order';
  }
  if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELED) {
    return hasThread ? 'chat' : 'order';
  }
  return hasThread ? 'chat' : 'order';
}

function normalizeCounterpartyName(counterpartyName: string): string {
  return counterpartyName.trim().length > 0 ? counterpartyName.trim() : '校园用户';
}
