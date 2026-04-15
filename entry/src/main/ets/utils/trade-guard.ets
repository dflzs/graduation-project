import { Order, Product, User, UserRole, UserStatus } from '../types/domain';

export type MarketplaceAudienceMode = 'guest' | 'trader' | 'admin' | 'restricted';
export type TradeEntryAction = 'cart' | 'order' | 'chat';
export type TradeReadonlyContext = 'chat' | 'order';
export type TradeRecordContext = 'chat' | 'order';

export function getMarketplaceAudienceMode(user: User | null): MarketplaceAudienceMode {
  if (!user) {
    return 'guest';
  }
  if (user.status === 'restricted' || user.status === 'suspended' || user.status === 'banned') {
    return 'restricted';
  }
  return user.role === 'admin' ? 'admin' : 'trader';
}

export function canCurrentUserJoinTrade(user: User | null): boolean {
  return user !== null && user.role === 'user' && (user.status === 'active' || user.status === 'muted');
}

export function canCurrentUserOperateTrade(user: User | null): boolean {
  return canCurrentUserJoinTrade(user);
}

export function canCurrentUserSendTradeMessage(user: User | null): boolean {
  return user !== null && user.role === 'user' && user.status === 'active';
}

export function canViewTradeHistory(user: User | null): boolean {
  return user !== null && user.role === 'user';
}

export function canAccessTradeRecord(user: User | null, participantIds: string[]): boolean {
  if (!canViewTradeHistory(user) || !user) {
    return false;
  }
  return participantIds.includes(user.id);
}

export function shouldTreatTradeRecordAsAccessDenied(
  user: User | null,
  hasRecord: boolean,
  canAccessRecord: boolean
): boolean {
  if (!user) {
    return true;
  }
  if (!hasRecord) {
    return false;
  }
  return !canAccessRecord;
}

export function getTradeRecordUnavailableTitle(
  context: TradeRecordContext,
  user: User | null,
  accessDenied: boolean
): string {
  if (!accessDenied) {
    return context === 'order' ? '未找到订单信息' : '会话暂时不可用';
  }
  if (!user) {
    return context === 'order' ? '请先登录后查看订单' : '请先登录后查看会话';
  }
  if (user.role === 'admin') {
    return user.status === 'active' ? '管理员账号不参与普通交易' : '当前管理员账号已被停用';
  }
  return context === 'order' ? '无权查看该订单' : '无权查看该会话';
}

export function getTradeRecordUnavailableDescription(
  context: TradeRecordContext,
  user: User | null,
  accessDenied: boolean
): string {
  if (!accessDenied) {
    return context === 'order'
      ? '请返回订单列表重新进入详情页，或确认订单是否已经不再可见。'
      : '当前会话不存在、已失效，或已经不再对当前账号可见。';
  }
  if (!user) {
    return context === 'order'
      ? '登录后可查看你参与过的订单详情、交易进度和历史记录。'
      : '登录后可查看你参与过的商品沟通记录和历史消息。';
  }
  if (user.role === 'admin') {
    return user.status === 'active'
      ? '当前账号仅用于后台治理，不提供普通商品沟通记录查看。'
      : '当前管理员账号已被停用，无法继续查看普通交易记录。';
  }
  return context === 'order'
    ? '这笔订单不属于当前账号，请返回订单列表查看你自己的交易记录。'
    : '当前会话不属于当前账号，请返回消息页查看你自己的沟通记录。';
}

export function getTradeAccessDeniedMessage(user: User | null, adminMessage: string, bannedMessage: string): string {
  if (!user) {
    return '请先登录后再继续';
  }
  if (user.role === 'admin') {
    return adminMessage;
  }
  if (user.status === 'muted') {
    return '当前账号已被禁言，无法发送新的交易消息';
  }
  if (user.status !== 'active') {
    return bannedMessage;
  }
  return '';
}

export function isProductOwnedByUser(product: Product | null, userId: string): boolean {
  return !!product && userId.length > 0 && product.sellerId === userId;
}

export function getTradeEntryDeniedMessage(user: User | null, action: TradeEntryAction): string {
  if (action === 'cart') {
    return getTradeAccessDeniedMessage(user, '管理员账号不支持加入购物车', '该账号已被停用，无法加入购物车');
  }
  if (action === 'order') {
    return getTradeAccessDeniedMessage(user, '管理员账号不支持下单', '该账号已被停用，无法下单');
  }
  return getTradeAccessDeniedMessage(user, '管理员账号不支持发起商品沟通', '该账号已被停用，无法发起商品沟通');
}

export function getTradeReadOnlyHint(user: User | null, context: TradeReadonlyContext): string {
  if (canCurrentUserOperateTrade(user)) {
    return '';
  }
  if (context === 'chat') {
    return '账号当前受限，当前仅可查看历史沟通记录，不能继续发送新的交易消息。';
  }
  return '账号当前受限，当前仅可查看订单记录，不能继续支付、取消、确认到场、完结或评价。';
}

function getProductStatusTradeHint(status: string): string {
  if (status === 'pending_review') {
    return '商品正在审核中，暂时不会在首页对外展示';
  }
  if (status === 'on_sale') {
    return '商品可正常加入购物车并下单';
  }
  if (status === 'locked') {
    return '商品已进入交易中，暂时不可被其他用户购买';
  }
  if (status === 'sold') {
    return '商品已售出，当前仅可浏览';
  }
  if (status === 'off_shelf') {
    return '商品已下架，当前不可购买';
  }
  if (status === 'rejected') {
    return '商品审核未通过，请修改后重新提交';
  }
  return '商品状态暂不支持交易';
}

export function getProductDetailTradeHint(product: Product | null, user: User | null): string {
  if (!product) {
    return '商品状态暂不支持交易';
  }
  if (product.status !== 'on_sale') {
    return getProductStatusTradeHint(product.status);
  }
  if (!user) {
    return '登录后可联系卖家、加入购物车并下单';
  }
  if (user.status === 'restricted' || user.status === 'suspended' || user.status === 'banned') {
    return '账号当前受限，仅可浏览商品信息，无法继续沟通或下单';
  }
  if (user.status === 'muted') {
    return '账号当前已被禁言，可继续下单，但暂时不能发起新的商品沟通';
  }
  if (user.role === 'admin') {
    return '管理员账号仅可浏览商品信息，不参与普通交易';
  }
  return getProductStatusTradeHint(product.status);
}

export function canUserTradeProduct(
  product: Product | null,
  userId: string,
  userRole: UserRole = 'user',
  userStatus: UserStatus = 'active'
): boolean {
  if (!product) {
    return false;
  }
  if (userId.length === 0) {
    return false;
  }
  if (userRole !== 'user') {
    return false;
  }
  if (userStatus !== 'active' && userStatus !== 'muted') {
    return false;
  }
  return product.status === 'on_sale' && !isProductOwnedByUser(product, userId);
}

export function canShowProductDetailContactAction(product: Product | null, user: User | null): boolean {
  if (!product || !user) {
    return false;
  }
  if (!canCurrentUserSendTradeMessage(user)) {
    return false;
  }
  return !isProductOwnedByUser(product, user.id);
}

export function canUserAccessOrder(order: Order | null, userId: string): boolean {
  return !!order && userId.length > 0 && (order.buyerId === userId || order.sellerId === userId);
}
