import { describe, it, expect } from '@ohos/hypium';
import { canTransition, moveOrderStatus } from '../main/ets/services/order-state-machine';
import { promptAction, router } from '@kit.ArkUI';
import { calculateCreditScore } from '../main/ets/services/credit.service.impl';
import { productRepository } from '../main/ets/repositories/product.repo';
import { orderRepository } from '../main/ets/repositories/order.repo';
import { canAccessAdmin } from '../main/ets/services/guard.service';
import { AuthServiceImpl, authService } from '../main/ets/services/auth.service.impl';
import { productService } from '../main/ets/services/product.service.impl';
import { orderService } from '../main/ets/services/order.service.impl';
import { announcementService } from '../main/ets/services/announcement.service.impl';
import { AuthStateService, authStateService } from '../main/ets/services/auth-state.service';
import { userRepository } from '../main/ets/repositories/user.repo';
import { notificationService } from '../main/ets/services/notification.service.impl';
import { chatService } from '../main/ets/services/chat.service.impl';
import { CartItem, Order, OrderStatus, User } from '../main/ets/types/domain';
import { syncService } from '../main/ets/services/sync.service.impl';
import {
  RemoteAuthClient,
  RemoteAuthUser,
  RemoteMeResponse,
  RemotePassResponse,
  RemoteRegisterCodeResponse,
  RemoteRegisterCodeVerifyResponse
} from '../main/ets/types/auth-remote';
import {
  buildResendCountdownLabel,
  buildVerificationCodeSlots,
  normalizeVerificationCode
} from '../main/ets/utils/verification-code';
import { CAMPUS_TRADE_QUICK_REPLIES } from '../main/ets/constants/message-quick-replies';
import {
  calculateSelectedCartAmount,
  getAllSelectedCartItemIds,
  isCartAllSelected,
  resolveCartCheckoutState,
  syncSelectedCartItemIds
} from '../main/ets/utils/cart-selection';
import {
  getCartCardBackground,
  getCartCardBorder,
  getCartSelectionInnerBorder,
  getCartSelectionInnerFill,
  getCartSelectionOuterBorder,
  getCartSelectionOuterFill
} from '../main/ets/utils/cart-visuals';
import {
  getPublishChipBackground,
  getPublishChipBorder,
  getPublishChipText
} from '../main/ets/utils/publish-chip';
import {
  backByContext,
  getParamsByContext,
  pushUrlByContext,
  replaceUrlByContext,
  showToastByContext,
  UiContextHost,
  UiContextLike,
  UiContextPromptLike,
  UiContextRouterLike
} from '../main/ets/utils/ui-context-actions';
import { mergeKnownRemoteProductIds } from '../main/ets/utils/product-feed';
import { normalizeUploadedImageUrl, resolveUploadMimeType } from '../main/ets/services/upload-remote.client';
import { LocalDb } from '../main/ets/data/db/local-db';
import { MemoryPersistenceAdapter } from '../main/ets/data/db/persistence-adapter';
import { RemoteCreateProductPayload } from '../main/ets/types/product-remote';
import { normalizeManualCoverUrl } from '../main/ets/utils/cover-image';
import { RemoteUpdateMePayload } from '../main/ets/types/auth-remote';

class FakeRemoteAuthClient implements RemoteAuthClient {
  sendLoginCodeCalled: boolean = false;
  validateLoginCodeCalled: boolean = false;
  loginByPasswordCalled: boolean = false;
  sendRegisterCodeCalled: boolean = false;
  verifyRegisterCodeCalled: boolean = false;
  registerWithTicketCalled: boolean = false;
  updateMeCalled: boolean = false;

  async sendLoginCode(_phone: string): Promise<RemotePassResponse> {
    this.sendLoginCodeCalled = true;
    return {
      code: 0,
      message: '登录验证码已发送',
      data: {
        token: 'token-login-code',
        user: this.buildRemoteUser('18800000000')
      }
    };
  }

  async validateLoginCode(phone: string, _code: string): Promise<RemotePassResponse> {
    this.validateLoginCodeCalled = true;
    return this.buildSuccessResponse(phone, '远程登录成功');
  }

  async loginByPassword(phone: string, _password: string): Promise<RemotePassResponse> {
    this.loginByPasswordCalled = true;
    return this.buildSuccessResponse(phone, '密码登录成功');
  }

  async sendRegisterCode(phone: string): Promise<RemoteRegisterCodeResponse> {
    this.sendRegisterCodeCalled = true;
    return {
      code: 0,
      message: '注册验证码已发送',
      data: {
        phone,
        debugCode: '123456'
      }
    };
  }

  async verifyRegisterCode(phone: string, _code: string): Promise<RemoteRegisterCodeVerifyResponse> {
    this.verifyRegisterCodeCalled = true;
    return {
      code: 0,
      message: '注册验证码校验成功',
      data: {
        phone,
        registerTicket: 'ticket-123456'
      }
    };
  }

  async registerWithTicket(phone: string, _ticket: string, _nickname: string, _password: string): Promise<RemotePassResponse> {
    this.registerWithTicketCalled = true;
    return this.buildSuccessResponse(phone, '远程注册成功');
  }

  async updateMe(_token: string, payload: RemoteUpdateMePayload): Promise<RemoteMeResponse> {
    this.updateMeCalled = true;
    return {
      code: 0,
      message: '资料更新成功',
      data: {
        id: 3333,
        phone: '18800003333',
        nickname: payload.nickname,
        avatar: payload.avatar,
        role: 'user',
        status: 'active',
        credit_score: 88
      }
    };
  }

  private buildSuccessResponse(phone: string, message: string): RemotePassResponse {
    return {
      code: 0,
      message,
      data: {
        token: `token-${phone.slice(-4)}`,
        user: this.buildRemoteUser(phone)
      }
    };
  }

  private buildRemoteUser(phone: string): RemoteAuthUser {
    return {
      id: Number(phone.slice(-4)),
      phone,
      nickname: `remote-${phone.slice(-4)}`,
      avatar: '',
      role: 'user',
      status: 'active',
      credit_score: 88
    };
  }
}

class FakeUiContextRouterOptions implements router.RouterOptions {
  url: string;
  params?: Object;

  constructor(url: string, params?: Object) {
    this.url = url;
    this.params = params;
  }
}

class FakeToastOptions implements promptAction.ShowToastOptions {
  message: string;
  duration?: number;

  constructor(message: string, duration: number) {
    this.message = message;
    this.duration = duration;
  }
}

class FakeRouteParams {
  orderId: string = '';
  source: string = '';
}

class FakeUiContextRouter implements UiContextRouterLike {
  calls: string[] = [];
  pushedUrl: string = '';
  replacedUrl: string = '';
  backedWithUrl: string = '';

  pushUrl(options: router.RouterOptions): Promise<void> {
    this.calls.push('push');
    this.pushedUrl = options.url;
    return Promise.resolve();
  }

  replaceUrl(options: router.RouterOptions): Promise<void> {
    this.calls.push('replace');
    this.replacedUrl = options.url;
    return Promise.resolve();
  }

  back(options?: router.RouterOptions): void {
    this.calls.push('back');
    this.backedWithUrl = options?.url ?? '';
  }

  getParams(): Object {
    const params = new FakeRouteParams();
    params.orderId = 'o-1';
    params.source = 'list';
    return params;
  }
}

class FakeUiContextPrompt implements UiContextPromptLike {
  calls: string[] = [];
  toastMessage: string = '';

  showToast(options: promptAction.ShowToastOptions): void {
    this.calls.push('toast');
    this.toastMessage = options.message as string;
  }
}

class FakeUiContext implements UiContextLike {
  private readonly routerApi: FakeUiContextRouter;
  private readonly promptApi: FakeUiContextPrompt;

  constructor(routerApi: FakeUiContextRouter, promptApi: FakeUiContextPrompt) {
    this.routerApi = routerApi;
    this.promptApi = promptApi;
  }

  getRouter(): UiContextRouterLike {
    return this.routerApi;
  }

  getPromptAction(): UiContextPromptLike {
    return this.promptApi;
  }
}

class FakeUiContextHost implements UiContextHost {
  private readonly context: UiContextLike;

  constructor(context: UiContextLike) {
    this.context = context;
  }

  getUIContext(): UiContextLike {
    return this.context;
  }
}

function buildTestPhone(prefix: string, seed: string, offset: number = 0): string {
  const serial = ((Number.parseInt(seed, 10) + offset) % 100000000).toString().padStart(8, '0');
  return `${prefix}${serial}`;
}

export default function localUnitTest() {
  describe('CampusMarketUnitTest', () => {
    it('auth_service_should_support_password_login_and_restore_from_local_state', 0, async () => {
      authStateService.clear();
      const fakeRemoteClient = new FakeRemoteAuthClient();
      const firstService = new AuthServiceImpl(fakeRemoteClient);

      const loginResult = await firstService.loginByPassword('18800003333', '123456');
      expect(fakeRemoteClient.loginByPasswordCalled).assertTrue();
      expect(loginResult.ok).assertTrue();
      expect(loginResult.data?.currentUser.phone).assertEqual('18800003333');

      const restoredService = new AuthServiceImpl(fakeRemoteClient);
      const restoredSession = restoredService.restoreSession();
      expect(restoredSession !== null).assertTrue();
      expect(restoredSession?.currentUser.phone).assertEqual('18800003333');

      restoredService.logout();
      const clearedService = new AuthServiceImpl(fakeRemoteClient);
      expect(clearedService.restoreSession()).assertNull();
    });

    it('local_db_should_restore_saved_state_after_reinitialization', 0, () => {
      const adapter = new MemoryPersistenceAdapter();
      const firstDb = new LocalDb(adapter);
      const now = Date.now();
      const appendedUser: User = {
        id: 'persisted-user',
        phone: '18812345678',
        nickname: '持久化用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: now,
        updatedAt: now
      };
      const persistedOrder: Order = {
        id: 'persisted-order',
        productId: 'persisted-product',
        buyerId: appendedUser.id,
        sellerId: 'seed-seller',
        amount: 66,
        address: '图书馆北门',
        locationTag: '图书馆北门',
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      };

      firstDb.setUsers([...firstDb.getUsers(), appendedUser]);
      firstDb.setProducts([
        ...firstDb.getProducts(),
        {
          id: 'persisted-product',
          sellerId: 'seed-seller',
          title: '持久化测试商品',
          desc: '验证 LocalDb 重建后是否恢复',
          price: 66,
          category: '电子数码',
          images: [],
          locationTag: '图书馆北门',
          status: 'on_sale',
          isDeleted: false,
          createdAt: now,
          updatedAt: now
        }
      ]);
      firstDb.setOrders([...firstDb.getOrders(), persistedOrder]);

      const rehydratedDb = new LocalDb(adapter);
      expect(rehydratedDb.getUsers().some((item) => item.id === appendedUser.id)).assertTrue();
      expect(rehydratedDb.getProducts().some((item) => item.id === 'persisted-product')).assertTrue();
      expect(rehydratedDb.getOrders().some((item) => item.id === persistedOrder.id)).assertTrue();
    });

    it('auth_state_should_restore_login_after_process_restart', 0, async () => {
      const adapter = new MemoryPersistenceAdapter();
      const firstStateService = new AuthStateService(adapter);
      const firstService = new AuthServiceImpl(new FakeRemoteAuthClient(), firstStateService);

      const loginResult = firstService.loginByAdminCode('18800005555', 'ADMIN2026');
      expect(loginResult.ok).assertTrue();

      const restoredStateService = new AuthStateService(adapter);
      const restoredService = new AuthServiceImpl(new FakeRemoteAuthClient(), restoredStateService);
      const restoredSession = restoredService.restoreSession();
      expect(restoredSession !== null).assertTrue();
      expect(restoredSession?.currentUser.phone).assertEqual('18800005555');

      restoredService.logout();
      const clearedStateService = new AuthStateService(adapter);
      const clearedService = new AuthServiceImpl(new FakeRemoteAuthClient(), clearedStateService);
      expect(clearedService.restoreSession()).assertNull();
    });

    it('auth_service_should_use_remote_login_result_to_build_session', 0, async () => {
      authStateService.clear();
      const fakeRemoteClient = new FakeRemoteAuthClient();
      const service = new AuthServiceImpl(fakeRemoteClient);

      const sendCodeResult = await service.sendLoginCode('18800001111');
      const result = await service.loginByPhone('18800001111', '654321');
      const currentUser = result.data?.currentUser as User;

      expect(fakeRemoteClient.sendLoginCodeCalled).assertTrue();
      expect(sendCodeResult.ok).assertTrue();
      expect(sendCodeResult.data?.code === undefined).assertTrue();
      expect(fakeRemoteClient.validateLoginCodeCalled).assertTrue();
      expect(result.ok).assertTrue();
      expect(result.message).assertEqual('远程登录成功');
      expect(currentUser.phone).assertEqual('18800001111');
      expect(currentUser.remoteUserId).assertEqual('1111');
    });

    it('auth_service_should_support_verification_first_register_flow', 0, async () => {
      authStateService.clear();
      const fakeRemoteClient = new FakeRemoteAuthClient();
      const service = new AuthServiceImpl(fakeRemoteClient);
      const phone = '18800002222';

      const sendCodeResult = await service.sendRegisterCode(phone);
      expect(sendCodeResult.ok).assertTrue();
      expect(fakeRemoteClient.sendRegisterCodeCalled).assertTrue();
      expect(sendCodeResult.data?.code).assertEqual('123456');

      const verifyCodeResult = await service.verifyRegisterCode(phone, '123456');
      expect(verifyCodeResult.ok).assertTrue();
      expect(fakeRemoteClient.verifyRegisterCodeCalled).assertTrue();
      expect(verifyCodeResult.data?.registerTicket).assertEqual('ticket-123456');

      const registerResult = await service.completeRegister(phone, 'ticket-123456', '测试用户', '123456');
      const currentUser = registerResult.data?.currentUser as User;

      expect(registerResult.ok).assertTrue();
      expect(fakeRemoteClient.registerWithTicketCalled).assertTrue();
      expect(currentUser.remoteUserId).assertEqual(phone.slice(-4));
      expect(currentUser.passwordConfigured).assertTrue();
    });

    it('notification_service_should_store_user_notifications_in_reverse_time_order', 0, () => {
      const userId = `notify-user-${Date.now()}`;
      const older = notificationService.create(
        userId,
        'system_notice',
        '第一条通知',
        '这是较早的一条消息',
        'notice-1'
      );
      const newer = notificationService.create(
        userId,
        'order_created',
        '第二条通知',
        '这是较新的一条消息',
        'order-1'
      );

      expect(older.ok).assertTrue();
      expect(newer.ok).assertTrue();

      const notifications = notificationService.listByUser(userId);
      expect(notifications.length).assertEqual(2);
      expect(notifications[0].title).assertEqual('第二条通知');
      expect(notifications[1].title).assertEqual('第一条通知');
      expect(notificationService.countUnread(userId)).assertEqual(2);

      notificationService.markAllRead(userId);
      expect(notificationService.countUnread(userId)).assertEqual(0);
    });

    it('order_service_should_generate_notifications_for_create_cancel_and_complete', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('185', timestamp, 0);
      const buyerPhone: string = buildTestPhone('175', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '通知联动测试商品',
        desc: '验证订单动作会生成消息提醒',
        price: 77,
        category: '电子数码',
        locationTag: '二食堂门口',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      testAuthService.logout();
      const buyerLogin = await testAuthService.loginByPhone(buyerPhone, '123456');
      expect(buyerLogin.ok).assertTrue();
      const buyer = buyerLogin.data!.currentUser;

      const createOrderResult = orderService.createOrder(buyer.id, product.id, '宿舍楼门口');
      expect(createOrderResult.ok).assertTrue();
      expect(notificationService.listByUser(buyer.id)[0].type).assertEqual('order_created');

      const cancelOrderResult = orderService.cancelOrder(createOrderResult.data!.id, buyer.id);
      expect(cancelOrderResult.ok).assertTrue();
      expect(notificationService.listByUser(buyer.id)[0].type).assertEqual('order_canceled');

      const secondOrderResult = orderService.createOrder(buyer.id, product.id, '宿舍楼门口');
      expect(secondOrderResult.ok).assertTrue();
      const payResult = orderService.simulatePay(secondOrderResult.data!.id, buyer.id);
      expect(payResult.ok).assertTrue();
      const buyerArrived = orderService.markArrived(secondOrderResult.data!.id, buyer.id);
      expect(buyerArrived.ok).assertTrue();
      const sellerArrived = orderService.markArrived(secondOrderResult.data!.id, seller.id);
      expect(sellerArrived.ok).assertTrue();
      const completeResult = orderService.completeOrder(secondOrderResult.data!.id, buyer.id);
      expect(completeResult.ok).assertTrue();

      const buyerNotifications = notificationService.listByUser(buyer.id);
      const sellerNotifications = notificationService.listByUser(seller.id);
      expect(buyerNotifications[0].type).assertEqual('order_completed');
      expect(sellerNotifications[0].type).assertEqual('order_completed');
    });

    it('notification_service_should_generate_publish_review_notifications', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = `184${timestamp}`;
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());
      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '审核提醒测试商品',
        desc: '验证审核通过和驳回会生成消息提醒',
        price: 98,
        category: '电子数码',
        locationTag: '图书馆门口',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;

      notificationService.notifyProductSubmitted(seller.id, product.title, product.id);
      expect(notificationService.listByUser(seller.id)[0].type).assertEqual('product_submitted');

      notificationService.notifyProductApproved(seller.id, product.title, product.id);
      expect(notificationService.listByUser(seller.id)[0].type).assertEqual('product_approved');

      notificationService.notifyProductRejected(seller.id, product.title, product.id);
      expect(notificationService.listByUser(seller.id)[0].type).assertEqual('product_rejected');
    });

    it('message_hub_should_count_unread_reminders_and_threads_together', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('182', timestamp, 0);
      const buyerPhone: string = buildTestPhone('172', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '消息未读聚合测试商品',
        desc: '验证提醒和会话未读可以共同汇总',
        price: 45,
        category: '电子数码',
        locationTag: '图书馆门口',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      testAuthService.logout();
      const buyerLogin = await testAuthService.loginByPhone(buyerPhone, '123456');
      expect(buyerLogin.ok).assertTrue();
      const buyer = buyerLogin.data!.currentUser;

      notificationService.create(
        buyer.id,
        'system_notice',
        '未读提醒测试',
        '验证消息中心底部角标的聚合逻辑',
        product.id
      );
      const threadResult = chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      const sendMessageResult = chatService.sendMessage(threadResult.data!, seller.id, '你好，这件商品还在');
      expect(sendMessageResult.ok).assertTrue();

      const reminderUnread = notificationService.countUnread(buyer.id);
      const threadUnread = chatService.countUnread(buyer.id);
      expect(reminderUnread).assertEqual(1);
      expect(threadUnread).assertEqual(1);
      expect(reminderUnread + threadUnread).assertEqual(2);
    });

    it('notification_service_should_mark_single_notification_as_read', 0, () => {
      const userId = `notify-single-${Date.now()}`;
      const created = notificationService.create(
        userId,
        'order_created',
        '单条已读测试',
        '验证单条交易提醒可以被设置为已读',
        'order-test-1'
      );

      expect(created.ok).assertTrue();
      expect(notificationService.countUnread(userId)).assertEqual(1);
      notificationService.markRead(created.data!.id);
      expect(notificationService.countUnread(userId)).assertEqual(0);
    });

    it('chat_service_should_create_or_reuse_product_bound_threads_and_store_messages', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('183', timestamp, 0);
      const buyerPhone: string = buildTestPhone('173', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '会话线程测试商品',
        desc: '验证消息页线程聚合逻辑',
        price: 59,
        category: '电子数码',
        locationTag: '图书馆门口',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;

      testAuthService.logout();
      const buyerLogin = await testAuthService.loginByPhone(buyerPhone, '123456');
      expect(buyerLogin.ok).assertTrue();
      const buyer = buyerLogin.data!.currentUser;

      const firstThread = chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(firstThread.ok).assertTrue();

      const sendMessage = chatService.sendMessage(firstThread.data!, buyer.id, '你好，请问今晚方便面交吗？');
      expect(sendMessage.ok).assertTrue();

      const reusedThread = chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(reusedThread.ok).assertTrue();
      expect(reusedThread.data).assertEqual(firstThread.data);

      const buyerThreads = chatService.listThreads(buyer.id);
      expect(buyerThreads.length > 0).assertTrue();
      expect(buyerThreads[0].productId).assertEqual(product.id);
      expect(buyerThreads[0].lastMessage).assertEqual('你好，请问今晚方便面交吗？');

      const threadMessages = chatService.getMessages(firstThread.data!);
      expect(threadMessages.length).assertEqual(1);
      expect(threadMessages[0].content).assertEqual('你好，请问今晚方便面交吗？');
    });

    it('cart_selection_helpers_should_sync_selection_and_amounts', 0, () => {
      const cartItems: CartItem[] = [
        {
          id: 'cart-1',
          userId: 'user-1',
          productId: 'product-1',
          qty: 1,
          snapshotPrice: 20,
          updatedAt: 1
        },
        {
          id: 'cart-2',
          userId: 'user-1',
          productId: 'product-2',
          qty: 2,
          snapshotPrice: 15,
          updatedAt: 2
        }
      ];

      const allSelected = getAllSelectedCartItemIds(cartItems);
      expect(allSelected.length).assertEqual(2);
      expect(isCartAllSelected(cartItems, allSelected)).assertTrue();
      expect(calculateSelectedCartAmount(cartItems, ['cart-2'])).assertEqual(30);
      expect(resolveCartCheckoutState(0)).assertEqual('none');
      expect(resolveCartCheckoutState(1)).assertEqual('single');
      expect(resolveCartCheckoutState(2)).assertEqual('multiple');

      const synced = syncSelectedCartItemIds(cartItems, ['cart-2', 'missing']);
      expect(synced.length).assertEqual(1);
      expect(synced[0]).assertEqual('cart-2');

      const restoredDefault = syncSelectedCartItemIds(cartItems, []);
      expect(restoredDefault.length).assertEqual(0);
    });

    it('cart_visuals_should_distinguish_checked_and_unchecked_states', 0, () => {
      expect(getCartSelectionOuterFill(true)).assertEqual('#E8F0FF');
      expect(getCartSelectionOuterFill(false)).assertEqual('#FFFFFF');
      expect(getCartSelectionOuterBorder(true)).assertEqual('#D9E6FF');
      expect(getCartSelectionOuterBorder(false)).assertEqual('#FFFFFF');
      expect(getCartSelectionInnerFill(true)).assertEqual('#2F6BFF');
      expect(getCartSelectionInnerFill(false)).assertEqual('#FFFFFF');
      expect(getCartSelectionInnerBorder(true)).assertEqual('#2F6BFF');
      expect(getCartSelectionInnerBorder(false)).assertEqual('#B7B0A6');
      expect(getCartCardBackground(true)).assertEqual('#F3F7FF');
      expect(getCartCardBackground(false)).assertEqual('#FFFDFC');
      expect(getCartCardBorder(true)).assertEqual('#BFD3FF');
      expect(getCartCardBorder(false)).assertEqual('#E7DED2');
    });

    it('chat_service_should_return_messages_for_a_thread_in_time_order', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('184', timestamp, 0);
      const buyerPhone: string = buildTestPhone('174', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '会话排序测试商品',
        desc: '验证会话详情顺序与已读逻辑',
        price: 79,
        category: '电子数码',
        locationTag: '实验楼大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;

      testAuthService.logout();
      const buyerLogin = await testAuthService.loginByPhone(buyerPhone, '123456');
      expect(buyerLogin.ok).assertTrue();
      const buyer = buyerLogin.data!.currentUser;

      const threadResult = chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      chatService.sendMessage(threadResult.data!, buyer.id, '第一条消息');
      chatService.sendMessage(threadResult.data!, seller.id, '第二条消息');

      const messages = chatService.getMessages(threadResult.data!);
      expect(messages.length).assertEqual(2);
      expect(messages[0].content).assertEqual('第一条消息');
      expect(messages[1].content).assertEqual('第二条消息');

      const threadBeforeRead = chatService.getThread(threadResult.data!, seller.id);
      expect(threadBeforeRead?.unreadCount).assertEqual(1);
      chatService.markThreadRead(threadResult.data!, seller.id);
      const threadAfterRead = chatService.getThread(threadResult.data!, seller.id);
      expect(threadAfterRead?.unreadCount).assertEqual(0);
    });

    it('message_quick_replies_should_expose_campus_trade_phrases', 0, () => {
      expect(CAMPUS_TRADE_QUICK_REPLIES.length >= 4).assertTrue();
      expect(CAMPUS_TRADE_QUICK_REPLIES.includes('还在吗？')).assertTrue();
      expect(CAMPUS_TRADE_QUICK_REPLIES.includes('今晚方便面交吗？')).assertTrue();
      expect(CAMPUS_TRADE_QUICK_REPLIES.includes('可以在一食堂门口交易吗？')).assertTrue();
      expect(CAMPUS_TRADE_QUICK_REPLIES.includes('我大概十分钟后到。')).assertTrue();
    });

    it('verification_code_helpers_should_normalize_and_split_code_for_slot_input', 0, () => {
      const normalized = normalizeVerificationCode('12a34 567', 6);
      const slots = buildVerificationCodeSlots(normalized, 6);
      const countdownLabel = buildResendCountdownLabel(60);
      const resendLabel = buildResendCountdownLabel(0);

      expect(normalized).assertEqual('123456');
      expect(slots.length).assertEqual(6);
      expect(slots[0]).assertEqual('1');
      expect(slots[5]).assertEqual('6');
      expect(countdownLabel).assertEqual('60s');
      expect(resendLabel).assertEqual('获取验证码');
    });

    it('product_feed_should_keep_known_remote_ids_when_remote_list_is_temporarily_empty', 0, () => {
      const existingIds: string[] = ['remote-product-1'];
      const mergedWithEmpty = mergeKnownRemoteProductIds(existingIds, []);
      expect(mergedWithEmpty.length).assertEqual(1);
      expect(mergedWithEmpty[0]).assertEqual('remote-product-1');

      const mergedWithNewProduct = mergeKnownRemoteProductIds(existingIds, [{
        id: 'remote-product-2',
        sellerId: 'seller-2',
        title: '新增远端商品',
        desc: '用于验证首页商品流 ID 合并逻辑',
        price: 19.9,
        category: '电子数码',
        images: [],
        locationTag: '教学楼大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: Date.now(),
        updatedAt: Date.now()
      }]);

      expect(mergedWithNewProduct.length).assertEqual(2);
      expect(mergedWithNewProduct[0]).assertEqual('remote-product-1');
      expect(mergedWithNewProduct[1]).assertEqual('remote-product-2');
    });

    it('product_repository_should_allow_local_status_restore_from_locked_to_on_sale', 0, () => {
      const now = Date.now();
      const productId = `product-restore-${now}`;
      productRepository.save({
        id: productId,
        sellerId: 'seller-restore',
        title: '状态恢复测试商品',
        desc: '验证本地订单取消后商品状态能恢复为在售',
        price: 28.8,
        category: '电子数码',
        images: [],
        locationTag: '教学楼门口',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });

      productRepository.updateStatus(productId, 'locked');
      const restored = productRepository.updateStatus(productId, 'on_sale');

      expect(restored !== null).assertTrue();
      expect(restored?.status).assertEqual('on_sale');
      expect(productRepository.getById(productId)?.status).assertEqual('on_sale');
    });

    it('product_repository_should_heal_stale_locked_status_from_remote_on_sale_when_no_active_order_exists', 0, () => {
      const now = Date.now();
      const productId = `product-heal-${now}`;
      productRepository.save({
        id: productId,
        sellerId: 'seller-heal',
        title: '锁定恢复测试商品',
        desc: '验证旧锁定状态可以被远端在售修复',
        price: 33.5,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'locked',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });

      const merged = productRepository.mergeRemote({
        id: productId,
        sellerId: 'seller-heal',
        title: '锁定恢复测试商品',
        desc: '验证旧锁定状态可以被远端在售修复',
        price: 33.5,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now + 1
      });

      expect(merged.status).assertEqual('on_sale');
      expect(productRepository.getById(productId)?.status).assertEqual('on_sale');
    });

    it('product_repository_should_keep_locked_status_when_active_local_order_exists', 0, () => {
      const now = Date.now();
      const productId = `product-active-${now}`;
      const orderId = `order-active-${now}`;
      productRepository.save({
        id: productId,
        sellerId: 'seller-active',
        title: '进行中交易商品',
        desc: '验证进行中订单不会被远端在售覆盖',
        price: 41.2,
        category: '电子数码',
        images: [],
        locationTag: '教学楼门口',
        status: 'locked',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });
      orderRepository.save({
        id: orderId,
        productId,
        buyerId: 'buyer-active',
        sellerId: 'seller-active',
        amount: 41.2,
        address: '宿舍楼下',
        locationTag: '教学楼门口',
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      });

      const merged = productRepository.mergeRemote({
        id: productId,
        sellerId: 'seller-active',
        title: '进行中交易商品',
        desc: '验证进行中订单不会被远端在售覆盖',
        price: 41.2,
        category: '电子数码',
        images: [],
        locationTag: '教学楼门口',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now + 1
      });

      expect(merged.status).assertEqual('locked');
      expect(productRepository.getById(productId)?.status).assertEqual('locked');
    });

    it('order_state_machine_should_block_invalid_transition', 0, () => {
      expect(canTransition(OrderStatus.PENDING_PAYMENT, OrderStatus.PAID_SIMULATED)).assertTrue();
      expect(canTransition(OrderStatus.PENDING_PAYMENT, OrderStatus.COMPLETED)).assertFalse();

      const order: Order = {
        id: 'o1',
        productId: 'p1',
        buyerId: 'u1',
        sellerId: 'u2',
        amount: 10,
        address: 'A',
        locationTag: '图书馆大厅',
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };

      const moved = moveOrderStatus(order, OrderStatus.PAID_SIMULATED);
      expect(moved.ok).assertTrue();

      const invalid = moveOrderStatus(order, OrderStatus.CANCELED);
      expect(invalid.ok).assertFalse();
    });

    it('order_service_should_publish_product_feed_change_when_transaction_status_changes', 0, async () => {
      const feedSignals: string[] = [];
      const unsubscribe = syncService.subscribe('products:changed', (payload) => {
        feedSignals.push(payload.value);
      });

      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('186', timestamp, 0);
      const buyerPhone: string = buildTestPhone('176', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '首页刷新测试商品',
        desc: '验证交易状态变更后首页立即刷新',
        price: 52,
        category: '电子数码',
        locationTag: '教学楼大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      testAuthService.logout();
      const buyerLogin = await testAuthService.loginByPhone(buyerPhone, '123456');
      expect(buyerLogin.ok).assertTrue();
      const buyer = buyerLogin.data!.currentUser;

      const orderResult = orderService.createOrder(buyer.id, product.id, '宿舍楼下');
      expect(orderResult.ok).assertTrue();
      expect(feedSignals.includes('locked')).assertTrue();

      const cancelResult = orderService.cancelOrder(orderResult.data!.id, buyer.id);
      expect(cancelResult.ok).assertTrue();
      expect(feedSignals.includes('on_sale')).assertTrue();

      unsubscribe();
    });

    it('credit_score_should_follow_formula', 0, () => {
      expect(calculateCreditScore(0, 3)).assertEqual(72);
      expect(calculateCreditScore(25, 5)).assertEqual(100);
      expect(calculateCreditScore(1, 1)).assertEqual(65);
    });

    it('product_search_should_filter_by_keyword', 0, () => {
      const list = productRepository.search({ keyword: '键盘', status: 'on_sale' });
      expect(list.length > 0).assertTrue();
      expect(list[0].title.includes('键盘')).assertTrue();
    });

    it('guard_should_only_allow_admin', 0, () => {
      const admin: User = {
        id: 'a1',
        phone: '18800000000',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      const user: User = {
        id: 'u1',
        phone: '18800000001',
        nickname: '用户',
        role: 'user',
        status: 'active',
        creditScore: 60,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      expect(canAccessAdmin(admin)).assertTrue();
      expect(canAccessAdmin(user)).assertFalse();
      expect(canAccessAdmin(null)).assertFalse();
    });

    it('order_service_should_complete_demo_trade_flow', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('189', timestamp, 0);
      const buyerPhone: string = buildTestPhone('177', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '测试二手台灯',
        desc: '用于测试交易闭环',
        price: 35,
        category: '日用百货',
        locationTag: '一食堂门口',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      testAuthService.logout();

      const buyerLogin = await testAuthService.loginByPhone(buyerPhone, '123456');
      expect(buyerLogin.ok).assertTrue();
      const buyer = buyerLogin.data!.currentUser;

      const createOrder = orderService.createOrder(buyer.id, product.id, '南苑宿舍楼下');
      expect(createOrder.ok).assertTrue();
      const order = createOrder.data!;

      const payResult = orderService.simulatePay(order.id, buyer.id);
      expect(payResult.ok).assertTrue();

      const buyerArrived = orderService.markArrived(order.id, buyer.id);
      expect(buyerArrived.ok).assertTrue();

      const sellerArrived = orderService.markArrived(order.id, seller.id);
      expect(sellerArrived.ok).assertTrue();
      expect(sellerArrived.data!.status).assertEqual(OrderStatus.READY_HANDOVER);

      const completeOrder = orderService.completeOrder(order.id, buyer.id);
      expect(completeOrder.ok).assertTrue();
      expect(completeOrder.data!.status).assertEqual(OrderStatus.COMPLETED);

      const reviewResult = orderService.addReview(order.id, buyer.id, 5, '守时', '交易顺利');
      expect(reviewResult.ok).assertTrue();

      const latestSeller = userRepository.getById(seller.id);
      expect(latestSeller !== null).assertTrue();
      expect((latestSeller?.creditScore ?? 0) > 60).assertTrue();
    });

    it('announcement_service_should_support_delete', 0, () => {
      authStateService.clear();
      const adminResult = authService.loginByAdminCode('16600001234', 'ADMIN2026');
      expect(adminResult.ok).assertTrue();
      const admin = adminResult.data!.currentUser;

      const publishResult = announcementService.publish('测试公告', '用于测试删除能力', admin.id);
      expect(publishResult.ok).assertTrue();

      const deleteResult = announcementService.delete(publishResult.data!.id, admin.id);
      expect(deleteResult.ok).assertTrue();

      const list = announcementService.list();
      const exists = list.some((item) => item.id === publishResult.data!.id);
      expect(exists).assertFalse();
    });

    it('upload_client_should_normalize_relative_uploaded_image_url', 0, () => {
      expect(normalizeUploadedImageUrl('http://49.232.30.147', '/uploads/demo/test.png'))
        .assertEqual('http://49.232.30.147/uploads/demo/test.png');
      expect(normalizeUploadedImageUrl('http://49.232.30.147/', 'http://cdn.example.com/demo.png'))
        .assertEqual('http://cdn.example.com/demo.png');
      expect(resolveUploadMimeType('/data/storage/el2/base/cache/cover.jpg')).assertEqual('image/jpeg');
      expect(resolveUploadMimeType('/data/storage/el2/base/cache/cover.png')).assertEqual('image/png');
    });

    it('remote_create_product_payload_should_include_cover_image', 0, () => {
      const payload = new RemoteCreateProductPayload(
        '测试商品',
        '带封面的测试商品',
        66.6,
        '电子数码',
        '图书馆大厅',
        'http://49.232.30.147/uploads/products/demo.png'
      );

      expect(payload.cover_image).assertEqual('http://49.232.30.147/uploads/products/demo.png');
      expect(payload.location_tag).assertEqual('图书馆大厅');
    });

    it('manual_cover_url_should_only_accept_http_or_https', 0, () => {
      expect(normalizeManualCoverUrl(' https://example.com/demo.png ')).assertEqual('https://example.com/demo.png');
      expect(normalizeManualCoverUrl('http://example.com/demo.jpg')).assertEqual('http://example.com/demo.jpg');
      expect(normalizeManualCoverUrl('ata\":null}[root@VM-0-10-opencloudos backend]# https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80'))
        .assertEqual('https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80');
      expect(normalizeManualCoverUrl('/uploads/demo.png')).assertEqual('');
      expect(normalizeManualCoverUrl('')).assertEqual('');
    });

    it('publish_chip_helpers_should_match_minimal_flat_option_c_tokens', 0, () => {
      expect(getPublishChipBackground(true)).assertEqual('#F1EDE7');
      expect(getPublishChipBackground(false)).assertEqual('#FFFFFF');
      expect(getPublishChipBorder(true)).assertEqual('#D4CCBF');
      expect(getPublishChipBorder(false)).assertEqual('#E5DDD2');
      expect(getPublishChipText(true)).assertEqual('#3D3935');
      expect(getPublishChipText(false)).assertEqual('#676058');
    });

    it('ui_context_helper_should_delegate_navigation_and_prompt_calls', 0, () => {
      const routerApi = new FakeUiContextRouter();
      const promptApi = new FakeUiContextPrompt();
      const fakeHost = new FakeUiContextHost(new FakeUiContext(routerApi, promptApi));

      pushUrlByContext(fakeHost, new FakeUiContextRouterOptions('pages/Index'));
      replaceUrlByContext(fakeHost, new FakeUiContextRouterOptions('pages/Auth/LoginPage'));
      backByContext(fakeHost, new FakeUiContextRouterOptions('pages/Order/OrderListPage'));
      showToastByContext(fakeHost, new FakeToastOptions('测试提示', 1200));
      const params = getParamsByContext<FakeRouteParams>(fakeHost);

      expect(routerApi.calls.join(',')).assertEqual('push,replace,back');
      expect(promptApi.calls.join(',')).assertEqual('toast');
      expect(routerApi.pushedUrl).assertEqual('pages/Index');
      expect(routerApi.replacedUrl).assertEqual('pages/Auth/LoginPage');
      expect(routerApi.backedWithUrl).assertEqual('pages/Order/OrderListPage');
      expect(promptApi.toastMessage).assertEqual('测试提示');
      expect(params.orderId).assertEqual('o-1');
      expect(params.source).assertEqual('list');
    });

    it('remote_update_me_payload_should_include_nickname_and_avatar', 0, () => {
      const payload = new RemoteUpdateMePayload(
        '新昵称',
        'http://49.232.30.147/uploads/avatar/demo.png'
      );
      expect(payload.nickname).assertEqual('新昵称');
      expect(payload.avatar).assertEqual('http://49.232.30.147/uploads/avatar/demo.png');
    });

    it('auth_service_should_update_avatar_and_refresh_persisted_session', 0, async () => {
      authStateService.clear();
      const fakeRemoteClient = new FakeRemoteAuthClient();
      const service = new AuthServiceImpl(fakeRemoteClient);

      const loginResult = await service.loginByPassword('18800003333', '123456');
      expect(loginResult.ok).assertTrue();

      const updateResult = await service.updateProfile(
        '校园新昵称',
        'http://49.232.30.147/uploads/avatar/demo.png'
      );
      expect(fakeRemoteClient.updateMeCalled).assertTrue();
      expect(updateResult.ok).assertTrue();
      expect(updateResult.data?.nickname).assertEqual('校园新昵称');
      expect(updateResult.data?.avatar).assertEqual('http://49.232.30.147/uploads/avatar/demo.png');

      const restoredService = new AuthServiceImpl(fakeRemoteClient);
      const restoredSession = restoredService.restoreSession();
      expect(restoredSession !== null).assertTrue();
      expect(restoredSession?.currentUser.nickname).assertEqual('校园新昵称');
      expect(restoredSession?.currentUser.avatar).assertEqual('http://49.232.30.147/uploads/avatar/demo.png');
    });
  });
}
