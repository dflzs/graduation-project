import { Order, OrderStatus } from '../types/domain';

export type TradeProgressInlineAction = 'pay' | 'arrive' | 'complete' | 'detail';

export function buildTradeProgressStatusDescription(order: Order, viewerId: string): string {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return viewerId === order.buyerId
      ? '商品已为本次订单锁定，请先完成模拟支付，再继续安排线下面交。'
      : '订单已创建，商品已进入交易中，等待买家完成模拟支付。';
  }
  if (order.status === OrderStatus.PAID_SIMULATED) {
    return '双方到达约定地点后，订单会自动进入待交接状态。';
  }
  if (order.status === OrderStatus.READY_HANDOVER) {
    return '双方均已到场，可以现场完成商品验收与交接。';
  }
  if (order.status === OrderStatus.COMPLETED) {
    return order.reviewed
      ? '本次交易已完成，你仍可以回看商品信息、聊天记录和本次评价。'
      : '交易已完成，你仍可以补充评价，并回看商品信息和聊天记录。';
  }
  return '订单已取消，这次交易已结束，你仍可以回看商品信息和原有沟通记录。';
}

export function buildTradeProgressNextStep(order: Order, viewerId: string): string {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return viewerId === order.buyerId
      ? '下一步建议：完成模拟支付后，和卖家确认面交时间。'
      : '下一步建议：等待买家支付后，再确认面交安排。';
  }
  if (order.status === OrderStatus.PAID_SIMULATED) {
    return '下一步建议：双方按约定到达面交地点，系统会记录到场状态。';
  }
  if (order.status === OrderStatus.READY_HANDOVER) {
    if (order.buyerArrived && !order.sellerArrived) {
      return viewerId === order.buyerId
        ? '下一步建议：你已到场，等待卖家到达后，当面验货并完成交接。'
        : '下一步建议：尽快到达约定地点，与买家完成现场交接。';
    }
    if (!order.buyerArrived && order.sellerArrived) {
      return viewerId === order.sellerId
        ? '下一步建议：你已到场，等待买家到达后，再确认商品交接。'
        : '下一步建议：确认卖家到场后，当面验货并完成交接。';
    }
    return '下一步建议：现场确认商品无误后，完成本次交易。';
  }
  if (order.status === OrderStatus.COMPLETED) {
    return order.reviewed ? '本次订单已全部处理完毕。' : '下一步建议：补充评价，完善这次交易记录。';
  }
  return '本次订单已结束，无需继续履约操作；如仍有需要，可回看聊天记录和商品信息。';
}

export function buildTradeProgressArrivalSummary(order: Order): string {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return '到场进展：待支付完成后，再进入面交到场确认。';
  }
  if (order.buyerArrived && order.sellerArrived) {
    return '到场进展：双方均已到达。';
  }
  if (order.buyerArrived) {
    return '到场进展：买家已到达，卖家未到达。';
  }
  if (order.sellerArrived) {
    return '到场进展：卖家已到达，买家未到达。';
  }
  return '到场进展：双方尚未到达。';
}

export function buildTradeProgressActionLabel(order: Order, viewerId: string): string {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return viewerId === order.buyerId ? '去订单详情完成支付' : '查看订单支付状态';
  }
  if (order.status === OrderStatus.COMPLETED && !order.reviewed) {
    return '去订单详情补充评价';
  }
  return '查看订单详情';
}

export function resolveTradeProgressInlineAction(order: Order, viewerId: string): TradeProgressInlineAction {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return viewerId === order.buyerId ? 'pay' : 'detail';
  }
  if (order.status === OrderStatus.PAID_SIMULATED) {
    return hasViewerArrived(order, viewerId) ? 'detail' : 'arrive';
  }
  if (order.status === OrderStatus.READY_HANDOVER) {
    if (!hasViewerArrived(order, viewerId)) {
      return 'arrive';
    }
    return order.buyerArrived && order.sellerArrived ? 'complete' : 'detail';
  }
  return 'detail';
}

export function buildTradeProgressInlineActionLabel(order: Order, viewerId: string): string {
  const action = resolveTradeProgressInlineAction(order, viewerId);
  if (action === 'pay') {
    return '完成模拟支付';
  }
  if (action === 'arrive') {
    return '确认我已到达';
  }
  if (action === 'complete') {
    return '确认完成交易';
  }
  return '查看订单详情';
}

export function buildTradeProgressListStatusSummary(order: Order): string {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return '订单已创建，等待买家完成模拟支付。';
  }
  if (order.status === OrderStatus.PAID_SIMULATED) {
    return '已完成模拟支付，等待双方到达约定地点。';
  }
  if (order.status === OrderStatus.READY_HANDOVER) {
    return '双方都已到场，可以准备现场交接商品。';
  }
  if (order.status === OrderStatus.COMPLETED) {
    return order.reviewed ? '交易与评价都已完成，可回顾本次交易记录。' : '交易已完成，仍可补充本次评价。';
  }
  return '订单已取消，本次交易已经结束，可回看原有沟通记录。';
}

export function buildTradeProgressListPrimaryActionText(order: Order): string {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return '去处理支付';
  }
  if (order.status === OrderStatus.PAID_SIMULATED) {
    return '查看到场状态';
  }
  if (order.status === OrderStatus.READY_HANDOVER) {
    return '去确认交接';
  }
  if (order.status === OrderStatus.COMPLETED) {
    return order.reviewed ? '查看评价详情' : '去补充评价';
  }
  return '查看订单详情';
}

export function buildTradeProgressListArrivalMeta(order: Order): string {
  if (order.status === OrderStatus.COMPLETED) {
    return '到场情况：双方均已完成本次面交。';
  }
  if (order.status === OrderStatus.CANCELED) {
    return '履约状态：本次交易已取消，未再继续面交。';
  }
  return `到达状态：买家${order.buyerArrived ? '已到达' : '未到达'} / 卖家${order.sellerArrived ? '已到达' : '未到达'}`;
}

export function buildOrderConversationActionLabel(order: Order): string {
  if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELED) {
    return '查看聊天记录';
  }
  return '继续沟通';
}

export function buildOrderConversationPrompt(order: Order): string {
  if (order.status === OrderStatus.COMPLETED) {
    return '这次交易已完成，你仍可以回看聊天记录、商品信息和评价内容。';
  }
  if (order.status === OrderStatus.CANCELED) {
    return '这次交易已取消，你仍可以回看聊天记录和商品信息，必要时再重新确认是否继续交易。';
  }
  return '如果还需要确认到场位置、见面时间或临时变更，可以继续在聊天里同步。';
}

export function buildChatConversationSubtitle(order: Order | null): string {
  if (!order) {
    return '围绕当前商品继续沟通时间、地点和交易细节。';
  }
  if (order.status === OrderStatus.COMPLETED) {
    return '这次交易已完成，你仍可以回看商品信息、聊天记录和本次交易记录。';
  }
  if (order.status === OrderStatus.CANCELED) {
    return '这次交易已结束，你仍可以回看原有沟通记录和商品信息。';
  }
  return '围绕当前商品继续沟通时间、地点和交易细节。';
}

export function buildMessageThreadTradeSnapshot(order: Order): string {
  if (order.status === OrderStatus.COMPLETED) {
    return '当前订单：已完成 · 可回顾本次交易记录与评价内容。';
  }
  if (order.status === OrderStatus.CANCELED) {
    return '当前订单：已取消 · 可回看原有沟通记录。';
  }
  return `当前订单：${buildStatusLabel(order.status)} · ${buildTradeProgressArrivalSummary(order)}`;
}

export function buildMessageThreadOrderActionLabel(order: Order, viewerId: string): string {
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    return viewerId === order.buyerId ? '去支付' : '看支付';
  }
  if (order.status === OrderStatus.COMPLETED && !order.reviewed) {
    return '去评价';
  }
  return '看订单';
}

export function buildChatTradeProgressSectionTitle(order: Order): string {
  if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELED) {
    return '最近交易记录';
  }
  return '交易进展';
}

export function buildProductTradeResumeTitle(order: Order | null, hasThread: boolean): string {
  if (order) {
    if (order.status === OrderStatus.COMPLETED) {
      return '你已完成本商品交易';
    }
    if (order.status === OrderStatus.CANCELED) {
      return '这次商品交易已结束';
    }
    return '你已发起本商品交易';
  }
  return hasThread ? '你已和卖家建立沟通' : '';
}

export function buildProductTradeResumeSectionTitle(order: Order | null): string {
  if (order && (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELED)) {
    return '最近交易记录';
  }
  return '当前交易进展';
}

export function buildProductTradeResumeDescription(order: Order | null, hasThread: boolean, viewerId: string): string {
  if (order) {
    if (order.status === OrderStatus.COMPLETED) {
      return order.reviewed
        ? '这次交易已完成，你仍可以回看商品信息、聊天记录和评价内容。'
        : '这次交易已完成，你仍可以补充评价，并回看商品信息和聊天记录。';
    }
    if (order.status === OrderStatus.CANCELED) {
      return '这次交易已取消，你仍可以回看商品信息和聊天记录；如需再次购买，可重新和卖家确认。';
    }
    return `${buildTradeProgressListStatusSummary(order)} ${buildTradeProgressNextStep(order, viewerId)}`;
  }
  if (hasThread) {
    return '你已经和卖家建立沟通，可继续确认商品细节、面交时间和交易安排。';
  }
  return '';
}

export function buildProductTradeResumePrimaryActionLabel(order: Order | null, viewerId: string): string {
  if (!order) {
    return '查看当前订单';
  }
  return buildTradeProgressActionLabel(order, viewerId);
}

export function buildProductTradeResumeSecondaryActionLabel(order: Order | null, hasThread: boolean): string {
  if (!hasThread) {
    return '查看当前订单';
  }
  if (!order) {
    return '继续沟通';
  }
  return buildOrderConversationActionLabel(order);
}

export function buildSellerPublishedTradeSummary(order: Order): string {
  if (order.status === OrderStatus.CANCELED) {
    return '订单已取消，本次交易已经结束，可回看原有沟通记录。';
  }
  return `${buildTradeProgressListStatusSummary(order)} ${buildTradeProgressArrivalSummary(order)}`;
}

export function buildSellerPublishedTradeSectionTitle(order: Order): string {
  if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELED) {
    return '最近交易记录';
  }
  return '当前交易进展';
}

export function buildSellerPublishedTradePrimaryActionLabel(order: Order): string {
  return buildMessageThreadOrderActionLabel(order, order.sellerId);
}

export function buildSellerPublishedTradeSecondaryActionLabel(order: Order, hasThread: boolean): string {
  if (!hasThread) {
    return '查看订单详情';
  }
  return buildOrderConversationActionLabel(order);
}

export function buildSellerTradeCounterpartyText(counterpartyName: string): string {
  return `当前买家：${counterpartyName.length > 0 ? counterpartyName : '校园用户'}`;
}

export function buildSellerOwnedProductTradeResumeTitle(order: Order | null, hasThread: boolean): string {
  if (order) {
    if (order.status === OrderStatus.COMPLETED) {
      return '当前商品最近一笔交易已完成';
    }
    if (order.status === OrderStatus.CANCELED) {
      return '当前商品最近一笔交易已结束';
    }
    return '当前商品已有进行中的交易';
  }
  return hasThread ? '已有买家发起沟通' : '';
}

export function buildSellerOwnedProductTradeResumeDescription(order: Order | null): string {
  if (!order) {
    return '已有买家围绕这件商品发起沟通，可继续确认面交细节和交易安排。';
  }
  if (order.status === OrderStatus.COMPLETED) {
    return '这次交易已完成，你仍可以回看商品信息、聊天记录和本次交易记录。';
  }
  if (order.status === OrderStatus.CANCELED) {
    return '这次交易已取消，你仍可以回看商品信息和聊天记录；如需继续转卖，可等待新的买家沟通。';
  }
  return buildSellerPublishedTradeSummary(order);
}

export function buildSellerOwnedProductTradeResumePrimaryActionLabel(order: Order): string {
  return buildSellerPublishedTradePrimaryActionLabel(order);
}

export function buildSellerOwnedProductTradeResumeSecondaryActionLabel(order: Order | null, hasThread: boolean): string {
  if (!order) {
    return hasThread ? '继续沟通' : '查看商品详情';
  }
  return buildSellerPublishedTradeSecondaryActionLabel(order, hasThread);
}

function buildStatusLabel(status: OrderStatus): string {
  if (status === OrderStatus.PENDING_PAYMENT) {
    return '待支付';
  }
  if (status === OrderStatus.PAID_SIMULATED) {
    return '待到场';
  }
  if (status === OrderStatus.READY_HANDOVER) {
    return '待交接';
  }
  if (status === OrderStatus.COMPLETED) {
    return '已完成';
  }
  return '已取消';
}

function hasViewerArrived(order: Order, viewerId: string): boolean {
  if (viewerId === order.buyerId) {
    return order.buyerArrived;
  }
  if (viewerId === order.sellerId) {
    return order.sellerArrived;
  }
  return false;
}
