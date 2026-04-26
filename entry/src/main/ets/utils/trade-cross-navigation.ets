export type TradeLinkedProductContext = 'chat' | 'order';

export function buildTradeLinkedProductActionLabel(): string {
  return '查看商品详情';
}

export function buildTradeLinkedProductCompactActionLabel(): string {
  return '看商品';
}

export function buildTradeLinkedProductPrompt(context: TradeLinkedProductContext): string {
  if (context === 'chat') {
    return '需要重新确认商品图片、成色和发布说明时，可回到商品详情继续查看。';
  }
  return '如需再次核对商品发布说明、图片和地点标签，可回到商品详情查看。';
}
