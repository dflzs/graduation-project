import { orderRepository } from '../repositories/order.repo';
import { productRepository } from '../repositories/product.repo';
import { reviewRepository } from '../repositories/review.repo';
import { userRepository } from '../repositories/user.repo';
import { OrderService } from '../types/service-contracts';
import { OperationResult, Order, OrderStatus, Product, Review } from '../types/domain';
import { moveOrderStatus, canEnterReadyHandover } from './order-state-machine';
import { newId } from '../utils/id';
import { creditService } from './credit.service.impl';
import { syncService } from './sync.service.impl';
import { notificationService } from './notification.service.impl';
import { canCurrentUserJoinTrade, canViewTradeHistory, getTradeAccessDeniedMessage } from '../utils/trade-guard';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteCreateOrderPayload } from '../types/order-remote';
import { RemoteOrderClient, remoteOrderClient } from './order-remote.client';

export class OrderServiceImpl implements OrderService {
  private readonly remoteClient: RemoteOrderClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteOrderClient = remoteOrderClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  private ensureTradeOperator(
    userId: string,
    adminMessage: string,
    bannedMessage: string
  ): OperationResult<null> {
    const user = userRepository.getById(userId);
    if (!canCurrentUserJoinTrade(user)) {
      return {
        ok: false,
        message: getTradeAccessDeniedMessage(user, adminMessage, bannedMessage)
      };
    }
    return { ok: true, message: '', data: null };
  }

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

  private resolveRemoteCreateToken(buyerId: string): string {
    if (!this.stateService.isLoggedIn()) {
      return '';
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.id !== buyerId) {
      return '';
    }
    return this.stateService.getToken();
  }

  private resolveRemoteReadToken(userId: string): string {
    if (!this.stateService.isLoggedIn()) {
      return '';
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.id !== userId || currentUser.status !== 'active' || !canViewTradeHistory(currentUser)) {
      return '';
    }
    return this.stateService.getToken();
  }

  private resolveRemoteActionToken(operatorId: string): string {
    if (!this.stateService.isLoggedIn()) {
      return '';
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.id !== operatorId || !canCurrentUserJoinTrade(currentUser)) {
      return '';
    }
    return this.stateService.getToken();
  }

  private canRequestRemoteOrderDetail(orderId: string): boolean {
    return /^\d+$/.test(orderId.trim());
  }

  private canRequestRemoteOrderMutation(orderId: string): boolean {
    return /^\d+$/.test(orderId.trim());
  }

  private hydrateRemoteReadOrder(order: Order): Order {
    const localOrder = orderRepository.getById(order.id);
    const product = productRepository.getById(order.productId);
    const hydratedOrder: Order = {
      id: order.id,
      productId: order.productId,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      amount: order.amount,
      address: order.address,
      locationTag: order.locationTag,
      schoolId: order.schoolId ?? localOrder?.schoolId ?? product?.schoolId,
      schoolName: order.schoolName ?? localOrder?.schoolName ?? product?.schoolName,
      campusId: order.campusId ?? localOrder?.campusId ?? product?.campusId,
      campusName: order.campusName ?? localOrder?.campusName ?? product?.campusName,
      locationGroupId: order.locationGroupId ?? localOrder?.locationGroupId ?? product?.locationGroupId,
      locationGroupName: order.locationGroupName ?? localOrder?.locationGroupName ?? product?.locationGroupName,
      tradeLocationId: order.tradeLocationId ?? localOrder?.tradeLocationId ?? product?.tradeLocationId,
      tradeLocationName: order.tradeLocationName ?? localOrder?.tradeLocationName ?? product?.tradeLocationName,
      locationSafetyTips: order.locationSafetyTips ?? localOrder?.locationSafetyTips ?? product?.locationSafetyTips,
      payType: order.payType,
      status: order.status,
      buyerArrived: order.buyerArrived,
      sellerArrived: order.sellerArrived,
      reviewed: order.reviewed,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt
    };
    return orderRepository.save(hydratedOrder);
  }

  private finalizeCreatedOrder(order: Order, productTitle?: string, successMessage?: string): OperationResult<Order> {
    const persistedOrder = orderRepository.save(order);
    const lockedProduct: Product | null = productRepository.updateStatus(order.productId, 'locked');
    syncService.publish({ key: `order:${persistedOrder.id}:status`, value: persistedOrder.status, updatedAt: persistedOrder.updatedAt });
    this.publishOrdersChanged(persistedOrder.status);
    if (lockedProduct) {
      syncService.publish({
        key: `product:${lockedProduct.id}:status`,
        value: lockedProduct.status,
        updatedAt: lockedProduct.updatedAt
      });
      this.publishProductFeedChanged(lockedProduct.status);
    }
    notificationService.notifyOrderCreated(
      persistedOrder.buyerId,
      productTitle ?? productRepository.getById(persistedOrder.productId)?.title ?? '该商品',
      persistedOrder.id
    );

    return {
      ok: true,
      message: successMessage && successMessage.trim().length > 0 ? successMessage : '下单成功，商品已进入交易中',
      data: persistedOrder
    };
  }

  private syncRemoteMutatedOrder(order: Order, successMessage: string, notifyType?: 'cancel' | 'complete'): OperationResult<Order> {
    const previousOrder = orderRepository.getById(order.id);
    const persistedOrder = this.hydrateRemoteReadOrder(order);
    let nextProductStatus: 'locked' | 'on_sale' | 'sold' = 'locked';
    if (persistedOrder.status === OrderStatus.CANCELED) {
      nextProductStatus = 'on_sale';
    } else if (persistedOrder.status === OrderStatus.COMPLETED) {
      nextProductStatus = 'sold';
    }

    const relatedProduct = productRepository.updateStatus(persistedOrder.productId, nextProductStatus);
    if (previousOrder
      && (previousOrder.buyerArrived !== persistedOrder.buyerArrived
        || previousOrder.sellerArrived !== persistedOrder.sellerArrived)) {
      syncService.publish({
        key: `order:${persistedOrder.id}:arrival`,
        value: JSON.stringify({
          buyerArrived: persistedOrder.buyerArrived,
          sellerArrived: persistedOrder.sellerArrived
        }),
        updatedAt: persistedOrder.updatedAt
      });
    }

    syncService.publish({
      key: `order:${persistedOrder.id}:status`,
      value: persistedOrder.status,
      updatedAt: persistedOrder.updatedAt
    });
    this.publishOrdersChanged(persistedOrder.status);

    if (relatedProduct) {
      syncService.publish({
        key: `product:${relatedProduct.id}:status`,
        value: relatedProduct.status,
        updatedAt: relatedProduct.updatedAt
      });
      this.publishProductFeedChanged(relatedProduct.status);
    }

    const productTitle = productRepository.getById(persistedOrder.productId)?.title ?? '该商品';
    if (notifyType === 'cancel') {
      notificationService.notifyOrderCanceled(persistedOrder.buyerId, productTitle, persistedOrder.id);
    } else if (notifyType === 'complete') {
      notificationService.notifyOrderCompleted(persistedOrder.buyerId, productTitle, persistedOrder.id);
      notificationService.notifyOrderCompleted(persistedOrder.sellerId, productTitle, persistedOrder.id);
    }

    return { ok: true, message: successMessage, data: persistedOrder };
  }

  private localSimulatePay(orderId: string, operatorId: string): OperationResult<Order> {
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

  private localCancelOrder(orderId: string, operatorId: string): OperationResult<Order> {
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

  private localMarkArrived(orderId: string, operatorId: string): OperationResult<Order> {
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

  private localCompleteOrder(orderId: string, operatorId: string): OperationResult<Order> {
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

  private createLocalOrderResult(buyerId: string, product: Product, address: string): OperationResult<Order> {
    const now: number = Date.now();
    const order: Order = {
      id: newId('order'),
      productId: product.id,
      buyerId,
      sellerId: product.sellerId,
      amount: product.price,
      address,
      locationTag: product.locationTag,
      schoolId: product.schoolId,
      schoolName: product.schoolName,
      campusId: product.campusId,
      campusName: product.campusName,
      locationGroupId: product.locationGroupId,
      locationGroupName: product.locationGroupName,
      tradeLocationId: product.tradeLocationId,
      tradeLocationName: product.tradeLocationName,
      locationSafetyTips: product.locationSafetyTips,
      payType: 'simulated',
      status: OrderStatus.PENDING_PAYMENT,
      buyerArrived: false,
      sellerArrived: false,
      reviewed: false,
      createdAt: now,
      updatedAt: now
    };

    return this.finalizeCreatedOrder(order, product.title, '下单成功，商品已进入交易中');
  }

  private reuseExistingActiveOrder(productId: string, buyerId: string): OperationResult<Order> | null {
    const existingOrder = orderRepository.findLatestActiveByProductAndBuyer(productId, buyerId);
    if (!existingOrder) {
      return null;
    }
    return {
      ok: true,
      message: '你已对该商品创建订单，已为你恢复到当前交易',
      data: existingOrder
    };
  }

  async createOrder(buyerId: string, productId: string, address: string): Promise<OperationResult<Order>> {
    if (address.trim().length === 0) {
      return { ok: false, message: '请填写收货地址或面交地点' };
    }

    const buyer = userRepository.getById(buyerId);
    if (!canCurrentUserJoinTrade(buyer)) {
      return {
        ok: false,
        message: getTradeAccessDeniedMessage(buyer, '管理员账号不支持下单', '该账号已被停用，无法下单')
      };
    }

    const product: Product | null = productRepository.getById(productId);
    if (!product || product.isDeleted) {
      return { ok: false, message: '商品不可购买' };
    }
    if (product.sellerId === buyerId) {
      return { ok: false, message: '不能购买自己发布的商品' };
    }

    const reusedOrder = this.reuseExistingActiveOrder(product.id, buyerId);
    if (reusedOrder) {
      return reusedOrder;
    }
    if (product.status !== 'on_sale') {
      return { ok: false, message: '商品不可购买' };
    }

    const token = this.resolveRemoteCreateToken(buyerId);
    if (token.length > 0) {
      const remoteResult = await this.remoteClient.createOrder(
        token,
        new RemoteCreateOrderPayload(product.id, address, product.locationTag)
      );
      if (remoteResult.ok && remoteResult.data) {
        const remoteOrder: Order = {
          id: remoteResult.data.id,
          productId: remoteResult.data.productId,
          buyerId: remoteResult.data.buyerId,
          sellerId: remoteResult.data.sellerId,
          amount: remoteResult.data.amount,
          address: remoteResult.data.address,
          locationTag: remoteResult.data.locationTag,
          schoolId: remoteResult.data.schoolId ?? product.schoolId,
          schoolName: remoteResult.data.schoolName ?? product.schoolName,
          campusId: remoteResult.data.campusId ?? product.campusId,
          campusName: remoteResult.data.campusName ?? product.campusName,
          locationGroupId: remoteResult.data.locationGroupId ?? product.locationGroupId,
          locationGroupName: remoteResult.data.locationGroupName ?? product.locationGroupName,
          tradeLocationId: remoteResult.data.tradeLocationId ?? product.tradeLocationId,
          tradeLocationName: remoteResult.data.tradeLocationName ?? product.tradeLocationName,
          locationSafetyTips: remoteResult.data.locationSafetyTips ?? product.locationSafetyTips,
          payType: remoteResult.data.payType,
          status: remoteResult.data.status,
          buyerArrived: remoteResult.data.buyerArrived,
          sellerArrived: remoteResult.data.sellerArrived,
          reviewed: remoteResult.data.reviewed,
          createdAt: remoteResult.data.createdAt,
          updatedAt: remoteResult.data.updatedAt
        };
        return this.finalizeCreatedOrder(remoteOrder, product.title, remoteResult.message);
      }
    }

    return this.createLocalOrderResult(buyerId, product, address);
  }

  async listMyOrders(userId: string): Promise<OperationResult<Order[]>> {
    const localOrders = orderRepository.listByUser(userId);
    const token = this.resolveRemoteReadToken(userId);
    if (token.length === 0) {
      return { ok: true, message: '获取订单列表成功', data: localOrders };
    }

    const remoteResult = await this.remoteClient.listMyOrders(token);
    if (remoteResult.ok && remoteResult.data) {
      const hydratedOrders = remoteResult.data
        .map((order) => this.hydrateRemoteReadOrder(order))
        .filter((order) => order.buyerId === userId || order.sellerId === userId)
        .sort((a, b) => b.createdAt - a.createdAt);
      return {
        ok: true,
        message: remoteResult.message,
        data: hydratedOrders
      };
    }

    return {
      ok: true,
      message: localOrders.length > 0 ? '已使用本地订单缓存' : remoteResult.message,
      data: localOrders
    };
  }

  async getOrderDetail(orderId: string, viewerId: string): Promise<OperationResult<Order | null>> {
    const localOrder = orderRepository.getById(orderId);
    const token = this.resolveRemoteReadToken(viewerId);
    if (token.length === 0 || !this.canRequestRemoteOrderDetail(orderId)) {
      return {
        ok: localOrder !== null,
        message: localOrder ? '获取订单详情成功' : '订单不存在',
        data: localOrder
      };
    }

    const remoteResult = await this.remoteClient.getOrderDetail(token, orderId);
    if (remoteResult.ok && remoteResult.data) {
      const hydratedOrder = this.hydrateRemoteReadOrder(remoteResult.data);
      return {
        ok: true,
        message: remoteResult.message,
        data: hydratedOrder
      };
    }

    return {
      ok: localOrder !== null,
      message: localOrder ? '已使用本地订单缓存' : remoteResult.message,
      data: localOrder
    };
  }

  async simulatePay(orderId: string, operatorId: string): Promise<OperationResult<Order>> {
    const operatorState = this.ensureTradeOperator(operatorId, '管理员账号不支持支付订单', '该账号已被停用，无法支付订单');
    if (!operatorState.ok) {
      return { ok: false, message: operatorState.message };
    }

    const token = this.resolveRemoteActionToken(operatorId);
    if (token.length > 0 && this.canRequestRemoteOrderMutation(orderId)) {
      const remoteResult = await this.remoteClient.simulatePay(token, orderId);
      if (remoteResult.ok && remoteResult.data) {
        return this.syncRemoteMutatedOrder(remoteResult.data, remoteResult.message || '模拟支付成功');
      }
    }

    return this.localSimulatePay(orderId, operatorId);
  }

  async cancelOrder(orderId: string, operatorId: string): Promise<OperationResult<Order>> {
    const operatorState = this.ensureTradeOperator(operatorId, '管理员账号不支持取消订单', '该账号已被停用，无法取消订单');
    if (!operatorState.ok) {
      return { ok: false, message: operatorState.message };
    }

    const token = this.resolveRemoteActionToken(operatorId);
    if (token.length > 0 && this.canRequestRemoteOrderMutation(orderId)) {
      const remoteResult = await this.remoteClient.cancelOrder(token, orderId);
      if (remoteResult.ok && remoteResult.data) {
        return this.syncRemoteMutatedOrder(remoteResult.data, remoteResult.message || '订单已取消', 'cancel');
      }
    }

    return this.localCancelOrder(orderId, operatorId);
  }

  async markArrived(orderId: string, operatorId: string): Promise<OperationResult<Order>> {
    const operatorState = this.ensureTradeOperator(operatorId, '管理员账号不支持确认到场', '该账号已被停用，无法确认到场');
    if (!operatorState.ok) {
      return { ok: false, message: operatorState.message };
    }

    const token = this.resolveRemoteActionToken(operatorId);
    if (token.length > 0 && this.canRequestRemoteOrderMutation(orderId)) {
      const remoteResult = await this.remoteClient.markArrived(token, orderId);
      if (remoteResult.ok && remoteResult.data) {
        return this.syncRemoteMutatedOrder(remoteResult.data, remoteResult.message || '到达状态已更新');
      }
    }

    return this.localMarkArrived(orderId, operatorId);
  }

  async completeOrder(orderId: string, operatorId: string): Promise<OperationResult<Order>> {
    const operatorState = this.ensureTradeOperator(operatorId, '管理员账号不支持完结订单', '该账号已被停用，无法完结订单');
    if (!operatorState.ok) {
      return { ok: false, message: operatorState.message };
    }

    const token = this.resolveRemoteActionToken(operatorId);
    if (token.length > 0 && this.canRequestRemoteOrderMutation(orderId)) {
      const remoteResult = await this.remoteClient.completeOrder(token, orderId);
      if (remoteResult.ok && remoteResult.data) {
        return this.syncRemoteMutatedOrder(remoteResult.data, remoteResult.message || '订单已完成', 'complete');
      }
    }

    return this.localCompleteOrder(orderId, operatorId);
  }

  addReview(orderId: string, fromUserId: string, rating: number, tag: string, comment: string): OperationResult<Review> {
    const operatorState = this.ensureTradeOperator(fromUserId, '管理员账号不支持评价订单', '该账号已被停用，无法评价订单');
    if (!operatorState.ok) {
      return { ok: false, message: operatorState.message };
    }

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
