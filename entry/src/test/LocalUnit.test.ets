import { describe, it, expect } from '@ohos/hypium';
import { canTransition, moveOrderStatus } from '../main/ets/services/order-state-machine';
import { promptAction, router } from '@kit.ArkUI';
import { appContext } from '../main/ets/app/app-context';
import { calculateCreditScore } from '../main/ets/services/credit.service.impl';
import { productRepository } from '../main/ets/repositories/product.repo';
import { orderRepository } from '../main/ets/repositories/order.repo';
import { canAccessAdmin } from '../main/ets/services/guard.service';
import { AuthServiceImpl, authService } from '../main/ets/services/auth.service.impl';
import { cartService } from '../main/ets/services/cart.service.impl';
import { productService } from '../main/ets/services/product.service.impl';
import { orderService } from '../main/ets/services/order.service.impl';
import { announcementService } from '../main/ets/services/announcement.service.impl';
import { AuthStateService, authStateService } from '../main/ets/services/auth-state.service';
import { userRepository } from '../main/ets/repositories/user.repo';
import { CampusServiceImpl, mergeRemoteCampusProfile } from '../main/ets/services/campus.service.impl';
import { notificationService } from '../main/ets/services/notification.service.impl';
import { chatService } from '../main/ets/services/chat.service.impl';
import {
  Campus,
  CartItem,
  LocationGroup,
  OperationResult,
  Order,
  OrderStatus,
  Product,
  School,
  StudentVerification,
  TradeLocation,
  User,
  VerificationStatus
} from '../main/ets/types/domain';
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
import { mergeKnownRemoteProductIds, resolveVisibleRemoteHomeProducts } from '../main/ets/utils/product-feed';
import { normalizeUploadedImageUrl, resolveUploadMimeType } from '../main/ets/services/upload-remote.client';
import { LocalDb } from '../main/ets/data/db/local-db';
import { createMemoryPersistenceAdapter, MemoryPersistenceAdapter } from '../main/ets/data/db/persistence-adapter';
import { RemoteCreateProductPayload } from '../main/ets/types/product-remote';
import { normalizeManualCoverUrl } from '../main/ets/utils/cover-image';
import { RemoteUpdateMePayload } from '../main/ets/types/auth-remote';
import {
  RemoteCampusItem,
  RemoteCampusProfileResponse,
  RemoteCampusResponse,
  RemoteCampusProfilePayload,
  RemoteCampusProfileItem,
  RemoteCampusPayload,
  RemoteLocationGroupItem,
  RemoteLocationGroupResponse,
  RemoteLocationGroupPayload,
  RemoteReviewVerificationPayload,
  RemoteSchoolItem,
  RemoteSchoolResponse,
  RemoteSchoolPayload,
  RemoteSubmitVerificationPayload,
  RemoteStudentVerificationListResponse,
  RemoteStudentVerificationResponse,
  RemoteTradeLocationResponse,
  RemoteTradeLocationItem,
  RemoteTradeLocationPayload
} from '../main/ets/types/campus-remote';
import { RemoteCampusClient } from '../main/ets/services/campus-remote.client';
import { mapRemoteProductItem } from '../main/ets/services/product-remote.client';
import { canRequestRemoteProductDetail } from '../main/ets/utils/product-detail-source';
import {
  canCurrentUserJoinTrade,
  canUserAccessOrder,
  canUserTradeProduct,
  getMarketplaceAudienceMode
} from '../main/ets/utils/trade-guard';
import {
  buildCartAudiencePresentation,
  buildMessageHubAudiencePresentation,
  shouldShowMarketplaceUnreadBadge
} from '../main/ets/utils/marketplace-audience-ui';
import { buildOrderDetailReturnTarget, resolveIndexRouteTab } from '../main/ets/utils/detail-return-route';
import {
  buildAnnouncementRenderKey,
  buildOrderRenderKey,
  buildProductRenderKey,
  buildProductRowRenderKey,
  buildReminderRenderKey,
  buildThreadRenderKey,
  buildUserRenderKey
} from '../main/ets/utils/render-keys';
import {
  getAuthHeroSurfaceTone,
  getAuthInputSurfaceTone,
  getAuthSymmetricSplitButtonLayout,
  getPolishDangerButtonTone,
  getPolishGhostButtonTone,
  getPolishNeutralButtonTone,
  getPolishPrimaryButtonTone,
  getPolishSecondaryButtonTone
} from '../main/ets/utils/ui-polish-tokens';
import { getAdminDashboardEntries } from '../main/ets/utils/admin-navigation';
import {
  buildCampusIdentityPresentation,
  buildCampusVerificationDraft,
  CampusVerificationDraftInput,
  getCampusVerificationMethodLabel,
  getCampusVerificationMethodOptions,
  pickDefaultCampus,
  pickDefaultSchool,
  resolveCampusForSchoolSelection,
  validateCampusVerificationDraft
} from '../main/ets/utils/campus-identity-ui';
import {
  buildTradeLocationLabel,
  filterTradeLocationsForCategory,
  pickPreferredTradeLocation
} from '../main/ets/utils/campus-location-ui';
import {
  FALLBACK_ACADEMIC_OPTION,
  findExactSchoolSelection,
  filterAcademicOptions,
  findSchoolSuggestions,
  listCollegeOptions,
  listMajorOptions,
  normalizeCollegeInput,
  normalizeMajorInput,
  shouldShowAcademicSuggestionPanel,
  shouldShowSchoolSuggestionPanel
} from '../main/ets/utils/campus-academics';
import {
  getVerificationMaterialPreviewUrls,
  groupVerificationByReviewTab,
  pickLatestVerificationByUser
} from '../main/ets/utils/verification-review';
import { openPublishEntry, resolvePublishEntryTarget } from '../main/ets/utils/publish-entry';
import { buildPublicCampusTrustPresentation } from '../main/ets/utils/campus-trust-ui';
import {
  buildProfileVerificationLifecyclePresentation,
  buildVerificationEditorPresentation,
  buildVerificationAcademicSummary,
  buildVerificationCampusSummary,
  resolveDisplayedVerificationStatus
} from '../main/ets/utils/campus-verification-lifecycle-ui';

class FakeRemoteAuthClient implements RemoteAuthClient {
  sendLoginCodeCalled: boolean = false;
  validateLoginCodeCalled: boolean = false;
  loginByPasswordCalled: boolean = false;
  sendRegisterCodeCalled: boolean = false;
  verifyRegisterCodeCalled: boolean = false;
  registerWithTicketCalled: boolean = false;
  updateMeCalled: boolean = false;
  remoteUserFactory?: (phone: string) => RemoteAuthUser;

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
    if (this.remoteUserFactory) {
      return this.remoteUserFactory(phone);
    }
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

class FakeRemoteCampusClient implements RemoteCampusClient {
  async listSchools(): Promise<OperationResult<RemoteSchoolItem[]>> {
    const schools: RemoteSchoolItem[] = [{
      id: 'school-hnrku',
      name: '湖南人文科技学院',
      short_name: '湖人文',
      city: '娄底',
      is_enabled: true,
      sort_order: 1,
      created_at: 1,
      updated_at: 2
    }];
    return {
      ok: true,
      message: '学校列表',
      data: schools
    };
  }

  async listCampuses(_schoolId: string): Promise<OperationResult<RemoteCampusItem[]>> {
    const campuses: RemoteCampusItem[] = [{
      id: 'campus-main',
      school_id: 'school-hnrku',
      name: '主校区',
      short_name: '主校区',
      is_main_campus: true,
      is_enabled: true,
      sort_order: 1,
      created_at: 1,
      updated_at: 2
    }];
    return {
      ok: true,
      message: '校区列表',
      data: campuses
    };
  }

  async listLocationGroups(_schoolId: string, _campusId: string): Promise<OperationResult<RemoteLocationGroupItem[]>> {
    const groups: RemoteLocationGroupItem[] = [{
      id: 'group-library',
      school_id: 'school-hnrku',
      campus_id: 'campus-main',
      name: '图书馆区',
      description: '适合教材与数码商品面交',
      is_enabled: true,
      sort_order: 1,
      created_at: 1,
      updated_at: 2
    }];
    return {
      ok: true,
      message: '地点分组',
      data: groups
    };
  }

  async listTradeLocations(): Promise<OperationResult<RemoteTradeLocationItem[]>> {
    const locations: RemoteTradeLocationItem[] = [{
      id: 'location-library-hall',
      school_id: 'school-hnrku',
      campus_id: 'campus-main',
      group_id: 'group-library',
      name: '图书馆大厅',
      alias: '图书馆大厅',
      description: '适合教材面交',
      safety_tips: '建议白天交易',
      recommended_categories: ['教材书籍'],
      is_enabled: true,
      is_hot: true,
      sort_order: 1,
      created_at: 1,
      updated_at: 2
    }];
    return {
      ok: true,
      message: '交易地点',
      data: locations
    };
  }

  async getCurrentCampusProfile(_token: string): Promise<OperationResult<RemoteCampusProfileResponse>> {
    const profile: RemoteCampusProfileItem = {
      id: 'user-campus-1',
      school_id: 'school-hnrku',
      school_name: '湖南人文科技学院',
      campus_id: 'campus-main',
      campus_name: '主校区',
      student_no: '2024123456',
      grade_year: 2024,
      college_name: '信息学院',
      major_name: '软件工程',
        verification_status: VerificationStatus.VERIFIED,
        verification_method: 'MANUAL_STUDENT_CARD',
        verified_at: 10,
        verification_updated_at: 10,
        completed_order_count: 3,
        report_count: 0,
        last_active_at: 12
    };
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '获取校园资料成功',
        data: profile
      }
    };
  }

  async updateCampusProfile(_token: string, _payload: RemoteCampusProfilePayload): Promise<OperationResult<RemoteCampusProfileResponse>> {
    return this.getCurrentCampusProfile('');
  }

  async getCurrentVerification(_token: string): Promise<OperationResult<RemoteStudentVerificationResponse>> {
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '获取认证状态成功',
        data: {
          id: 'verification-1',
          user_id: 'user-campus-1',
          school_id: 'school-hnrku',
          campus_id: 'campus-main',
          student_no: '2024123456',
          grade_year: 2024,
          college_name: '信息学院',
          major_name: '软件工程',
          verification_method: 'MANUAL_STUDENT_CARD',
          material_urls: ['https://example.com/student-card.png'],
          status: VerificationStatus.VERIFIED,
          submitted_at: 1,
          reviewed_at: 2,
          reviewed_by: 'admin-1',
          review_comment: '通过',
          updated_at: 3
        }
      }
    };
  }

  async submitVerification(_token: string, _payload: RemoteSubmitVerificationPayload): Promise<OperationResult<RemoteStudentVerificationResponse>> {
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '提交认证成功',
        data: {
          id: 'verification-pending-1',
          user_id: 'user-campus-1',
          school_id: 'school-hnrku',
          campus_id: 'campus-main',
          student_no: '2024123456',
          grade_year: 2024,
          college_name: '信息学院',
          major_name: '软件工程',
          verification_method: 'MANUAL_STUDENT_CARD',
          material_urls: ['https://example.com/student-card.png'],
          status: VerificationStatus.PENDING_REVIEW,
          submitted_at: 1,
          updated_at: 3
        }
      }
    };
  }

  async listVerificationApplications(_token: string, _status?: string): Promise<OperationResult<RemoteStudentVerificationListResponse>> {
    const verification = await this.getCurrentVerification('');
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '认证申请列表',
        data: verification.data?.data ? [verification.data.data] : []
      }
    };
  }

  async reviewVerification(
    _token: string,
    _verificationId: string,
    _payload: RemoteReviewVerificationPayload
  ): Promise<OperationResult<RemoteStudentVerificationResponse>> {
    return this.getCurrentVerification('');
  }

  async upsertSchool(_token: string, _schoolId: string, _payload: RemoteSchoolPayload): Promise<OperationResult<RemoteSchoolResponse>> {
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '保存学校成功',
        data: (await this.listSchools()).data?.[0]
      }
    };
  }

  async upsertCampus(_token: string, _campusId: string, _payload: RemoteCampusPayload): Promise<OperationResult<RemoteCampusResponse>> {
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '保存校区成功',
        data: (await this.listCampuses('school-hnrku')).data?.[0]
      }
    };
  }

  async upsertLocationGroup(
    _token: string,
    _groupId: string,
    _payload: RemoteLocationGroupPayload
  ): Promise<OperationResult<RemoteLocationGroupResponse>> {
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '保存地点分组成功',
        data: (await this.listLocationGroups('school-hnrku', 'campus-main')).data?.[0]
      }
    };
  }

  async upsertTradeLocation(
    _token: string,
    _locationId: string,
    _payload: RemoteTradeLocationPayload
  ): Promise<OperationResult<RemoteTradeLocationResponse>> {
    return {
      ok: true,
      message: '',
      data: {
        code: 0,
        message: '保存交易地点成功',
        data: (await this.listTradeLocations()).data?.[0]
      }
    };
  }

  async updateTradeLocationStatus(
    _token: string,
    _locationId: string,
    _isEnabled: boolean
  ): Promise<OperationResult<RemoteTradeLocationResponse>> {
    return this.upsertTradeLocation('', '', new RemoteTradeLocationPayload('', '', '', '', [], 0));
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

    it('auth_state_should_downgrade_stale_verified_user_when_restoring_local_session', 0, () => {
      const adapter = new MemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const staleUser: User = {
        id: 'restore-stale-user',
        phone: '18800006666',
        nickname: '恢复态用户',
        role: 'user',
        status: 'active',
        creditScore: 90,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: 100,
        verificationUpdatedAt: 101,
        createdAt: 1,
        updatedAt: 1
      };

      userRepository.save(staleUser);
      stateService.saveSession({
        currentUser: staleUser,
        token: 'restore-token',
        expiresAt: Date.now() + 3600 * 1000
      });

      const restoredService = new AuthServiceImpl(new FakeRemoteAuthClient(), stateService);
      const restoredSession = restoredService.restoreSession();

      expect(restoredSession !== null).assertTrue();
      expect(restoredSession?.currentUser.verificationStatus).assertEqual(VerificationStatus.UNVERIFIED);
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

    it('auth_service_should_downgrade_stale_verified_status_during_login_session_build', 0, async () => {
      authStateService.clear();
      const fakeRemoteClient = new FakeRemoteAuthClient();
      fakeRemoteClient.remoteUserFactory = (phone: string): RemoteAuthUser => ({
        id: Number(phone.slice(-4)),
        phone,
        nickname: `remote-${phone.slice(-4)}`,
        avatar: '',
        role: 'user',
        status: 'active',
        credit_score: 88,
        school_id: 'school-hnu',
        school_name: '湖南大学',
        campus_id: 'campus-main',
        campus_name: '主校区',
        student_no: '20245555',
        grade_year: 2024,
        college_name: '信息科学与工程学院',
        major_name: '计算机科学与技术',
        verification_status: VerificationStatus.VERIFIED,
        verified_at: 100,
        verification_updated_at: 101
      });
      const service = new AuthServiceImpl(fakeRemoteClient);

      const result = await service.loginByPassword('18800004444', '123456');

      expect(result.ok).assertTrue();
      expect(result.data?.currentUser.verificationStatus).assertEqual(VerificationStatus.UNVERIFIED);
      expect(result.data?.currentUser.verifiedAt).assertEqual(100);
      expect(result.data?.currentUser.verificationUpdatedAt).assertEqual(101);
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

    it('notification_service_should_publish_message_change_when_marking_read', 0, () => {
      const userId = `notify-sync-${Date.now()}`;
      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('messages:changed', (payload) => {
        syncValues.push(payload.value);
      });

      const created = notificationService.create(
        userId,
        'order_created',
        '提醒同步测试',
        '验证标记已读会广播消息变更',
        'order-sync-1'
      );
      expect(created.ok).assertTrue();

      notificationService.markRead(created.data!.id);
      expect(syncValues.length > 0).assertTrue();

      unsubscribe();
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

    it('chat_service_should_reject_non_participant_thread_access_and_messages', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('181', timestamp, 0);
      const buyerPhone: string = buildTestPhone('171', timestamp, 1);
      const outsiderPhone: string = buildTestPhone('161', timestamp, 2);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '越权会话防呆测试商品',
        desc: '不应允许非交易双方查看或发送消息',
        price: 42,
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

      const threadResult = chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      expect(chatService.sendMessage(threadResult.data!, buyer.id, '这件商品还在吗？').ok).assertTrue();

      testAuthService.logout();
      const outsiderLogin = await testAuthService.loginByPhone(outsiderPhone, '123456');
      expect(outsiderLogin.ok).assertTrue();
      const outsider = outsiderLogin.data!.currentUser;

      expect(chatService.getThread(threadResult.data!, outsider.id)).assertNull();
      const blockedSend = chatService.sendMessage(threadResult.data!, outsider.id, '我也想买');
      expect(blockedSend.ok).assertFalse();
      expect(blockedSend.message).assertEqual('仅交易双方可发送消息');
    });

    it('chat_service_should_reject_admin_users_from_opening_trade_threads', 0, () => {
      const now = Date.now();
      const seller: User = {
        id: 'chat-seller-user',
        phone: '18800005555',
        nickname: '卖家',
        role: 'user',
        status: 'active',
        creditScore: 84,
        createdAt: now,
        updatedAt: now
      };
      const admin: User = {
        id: 'chat-admin-user',
        phone: '19900000003',
        nickname: '系统管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: 'chat-product-guard',
        sellerId: seller.id,
        title: '聊天守卫测试商品',
        desc: '管理员不能发起商品沟通',
        price: 30,
        category: '教材书籍',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(admin);
      productRepository.save(product);

      const result = chatService.openProductThread(product.id, admin.id, seller.id);
      expect(result.ok).assertFalse();
      expect(result.message).assertEqual('管理员账号不支持参与商品沟通');
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

    it('product_feed_should_only_show_products_backed_by_current_remote_ids', 0, () => {
      const now = Date.now();
      const products: Product[] = [
        {
          id: 'p_1',
          sellerId: 'seed-seller',
          title: '本地教材',
          desc: '本地种子商品',
          price: 28,
          category: '教材书籍',
          images: [],
          locationTag: '图书馆大厅',
          status: 'on_sale',
          isDeleted: false,
          createdAt: now,
          updatedAt: now
        },
        {
          id: '12',
          sellerId: 'remote-seller',
          title: '云端商品',
          desc: '云端在售商品',
          price: 66,
          category: '电子数码',
          images: [],
          locationTag: '教学楼大厅',
          status: 'on_sale',
          isDeleted: false,
          createdAt: now + 1,
          updatedAt: now + 1
        }
      ];

      expect(resolveVisibleRemoteHomeProducts(products, []).length).assertEqual(0);

      const visibleProducts = resolveVisibleRemoteHomeProducts(products, ['12']);
      expect(visibleProducts.length).assertEqual(1);
      expect(visibleProducts[0].id).assertEqual('12');
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

    it('order_service_should_publish_orders_changed_when_status_changes', 0, async () => {
      const orderSignals: string[] = [];
      const unsubscribe = syncService.subscribe('orders:changed', (payload) => {
        orderSignals.push(payload.value);
      });

      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('187', timestamp, 0);
      const buyerPhone: string = buildTestPhone('177', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '订单同步测试商品',
        desc: '验证订单状态变化会广播列表刷新信号',
        price: 48,
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
      expect(orderSignals.includes('PENDING_PAYMENT')).assertTrue();

      const cancelResult = orderService.cancelOrder(orderResult.data!.id, buyer.id);
      expect(cancelResult.ok).assertTrue();
      expect(orderSignals.includes('CANCELED')).assertTrue();

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

    it('cart_service_should_reject_adding_self_owned_product', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('185', timestamp, 0);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '自购防呆测试商品',
        desc: '不应允许加入自己的购物车',
        price: 28,
        category: '教材书籍',
        locationTag: '图书馆大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();

      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      const addResult = cartService.addToCart(seller.id, product.id);
      expect(addResult.ok).assertFalse();
      expect(addResult.message).assertEqual('不能购买自己发布的商品');
    });

    it('product_detail_should_only_request_remote_for_numeric_product_id', 0, () => {
      expect(canRequestRemoteProductDetail('p_1')).assertFalse();
      expect(canRequestRemoteProductDetail(' local-product ')).assertFalse();
      expect(canRequestRemoteProductDetail('12')).assertTrue();
      expect(canRequestRemoteProductDetail(' 345 ')).assertTrue();
    });

    it('order_access_guard_should_only_allow_buyer_or_seller', 0, () => {
      const now = Date.now();
      const order: Order = {
        id: 'order-access-1',
        productId: 'product-access-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        amount: 88,
        address: '图书馆门口',
        locationTag: '图书馆门口',
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      };

      expect(canUserAccessOrder(order, 'buyer-1')).assertTrue();
      expect(canUserAccessOrder(order, 'seller-1')).assertTrue();
      expect(canUserAccessOrder(order, 'outsider')).assertFalse();
      expect(canUserAccessOrder(null, 'buyer-1')).assertFalse();
    });

    it('order_service_should_reject_buying_self_owned_product', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('184', timestamp, 0);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '自购下单防呆测试商品',
        desc: '不应允许给自己下单',
        price: 35,
        category: '电子数码',
        locationTag: '教学楼大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();

      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      const orderResult = orderService.createOrder(seller.id, product.id, '教学楼大厅');
      expect(orderResult.ok).assertFalse();
      expect(orderResult.message).assertEqual('不能购买自己发布的商品');
    });

    it('cart_service_should_reject_admin_users_from_joining_trade_flow', 0, () => {
      const now = Date.now();
      const seller: User = {
        id: 'seller-market-user',
        phone: '18800003333',
        nickname: '卖家',
        role: 'user',
        status: 'active',
        creditScore: 85,
        createdAt: now,
        updatedAt: now
      };
      const admin: User = {
        id: 'admin-market-user',
        phone: '19900000000',
        nickname: '系统管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(admin);

      const createProduct = productService.createProduct({
        title: '管理员禁交易测试商品',
        desc: '仅普通用户可交易',
        price: 66,
        category: '教材书籍',
        locationTag: '图书馆大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();

      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      const addResult = cartService.addToCart(admin.id, product.id);
      expect(addResult.ok).assertFalse();
      expect(addResult.message).assertEqual('管理员账号不支持加入购物车');
    });

    it('order_service_should_reject_admin_users_from_joining_trade_flow', 0, () => {
      const now = Date.now();
      const seller: User = {
        id: 'seller-order-user',
        phone: '18800004444',
        nickname: '卖家',
        role: 'user',
        status: 'active',
        creditScore: 85,
        createdAt: now,
        updatedAt: now
      };
      const admin: User = {
        id: 'admin-order-user',
        phone: '19900000001',
        nickname: '系统管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(admin);

      const createProduct = productService.createProduct({
        title: '管理员禁下单测试商品',
        desc: '仅普通用户可下单',
        price: 88,
        category: '电子数码',
        locationTag: '教学楼大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();

      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      const orderResult = orderService.createOrder(admin.id, product.id, '教学楼大厅');
      expect(orderResult.ok).assertFalse();
      expect(orderResult.message).assertEqual('管理员账号不支持下单');
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

    it('detail_return_route_should_send_message_source_back_to_message_tab', 0, () => {
      const messageTarget = buildOrderDetailReturnTarget('message');
      const listTarget = buildOrderDetailReturnTarget('list');
      const createTarget = buildOrderDetailReturnTarget('create');
      const unknownTarget = buildOrderDetailReturnTarget('unknown');

      expect(messageTarget?.url).assertEqual('pages/Index');
      expect(messageTarget?.params?.tab).assertEqual('message');
      expect(listTarget?.url).assertEqual('pages/Order/OrderListPage');
      expect(createTarget?.url).assertEqual('pages/Order/OrderListPage');
      expect(unknownTarget === null).assertTrue();
    });

    it('index_route_tab_should_only_override_when_tab_param_is_known', 0, () => {
      expect(resolveIndexRouteTab('home', 4)).assertEqual(0);
      expect(resolveIndexRouteTab('message', 0)).assertEqual(1);
      expect(resolveIndexRouteTab('mine', 0)).assertEqual(4);
      expect(resolveIndexRouteTab(undefined, 3)).assertEqual(3);
      expect(resolveIndexRouteTab('unknown', 1)).assertEqual(1);
    });

    it('publish_entry_target_should_require_login_for_guest_and_allow_logged_in_user', 0, () => {
      const guestTarget = resolvePublishEntryTarget(null);
      const loggedInTarget = resolvePublishEntryTarget({
        id: 'publish-user-1',
        phone: '18800001111',
        nickname: '发布用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: 1,
        updatedAt: 1
      });
      const adminTarget = resolvePublishEntryTarget({
        id: 'publish-admin-1',
        phone: '19900000000',
        nickname: '系统管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      });

      expect(guestTarget.url).assertEqual('pages/Auth/LoginPage');
      expect(guestTarget.requiresLogin).assertTrue();
      expect(guestTarget.promptMessage).assertEqual('请先登录后再发布商品');

      expect(loggedInTarget.url).assertEqual('pages/Product/PublishProductPage');
      expect(loggedInTarget.requiresLogin).assertFalse();
      expect(loggedInTarget.promptMessage).assertEqual('');

      expect(adminTarget.url).assertEqual('pages/Admin/AdminDashboardPage');
      expect(adminTarget.requiresLogin).assertFalse();
      expect(adminTarget.promptMessage).assertEqual('管理员账号不支持发布商品，已为你切换到后台管理');
    });

    it('trade_guard_should_only_allow_normal_user_to_join_trade_flow', 0, () => {
      const product: Product = {
        id: 'trade-guard-product',
        sellerId: 'seller-1',
        title: '交易守卫测试商品',
        desc: '测试管理员禁交易',
        price: 42,
        category: '教材书籍',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: 1,
        updatedAt: 1
      };

      expect(canUserTradeProduct(product, 'buyer-1', 'user')).assertTrue();
      expect(canUserTradeProduct(product, 'seller-1', 'user')).assertFalse();
      expect(canUserTradeProduct(product, 'admin-1', 'admin')).assertFalse();
      expect(canUserTradeProduct(product, 'buyer-1', undefined)).assertTrue();
    });

    it('marketplace_audience_mode_should_distinguish_guest_admin_and_trader', 0, () => {
      const trader: User = {
        id: 'audience-user',
        phone: '18800006666',
        nickname: '校园用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: 1,
        updatedAt: 1
      };
      const admin: User = {
        id: 'audience-admin',
        phone: '19900000004',
        nickname: '系统管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };

      expect(getMarketplaceAudienceMode(null)).assertEqual('guest');
      expect(getMarketplaceAudienceMode(trader)).assertEqual('trader');
      expect(getMarketplaceAudienceMode(admin)).assertEqual('admin');
      expect(canCurrentUserJoinTrade(trader)).assertTrue();
      expect(canCurrentUserJoinTrade(admin)).assertFalse();
    });

    it('marketplace_audience_ui_should_hide_trader_unread_badges_for_admins', 0, () => {
      expect(shouldShowMarketplaceUnreadBadge('guest')).assertFalse();
      expect(shouldShowMarketplaceUnreadBadge('admin')).assertFalse();
      expect(shouldShowMarketplaceUnreadBadge('trader')).assertTrue();
    });

    it('message_hub_audience_presentation_should_switch_admin_to_management_copy', 0, () => {
      const guestPresentation = buildMessageHubAudiencePresentation('guest');
      const adminPresentation = buildMessageHubAudiencePresentation('admin');
      const traderPresentation = buildMessageHubAudiencePresentation('trader');

      expect(guestPresentation.showThreads).assertFalse();
      expect(guestPresentation.emptyPrimaryActionLabel).assertEqual('去登录');

      expect(adminPresentation.showThreads).assertFalse();
      expect(adminPresentation.headerDescription.includes('管理员账号不参与普通交易沟通')).assertTrue();
      expect(adminPresentation.emptyPrimaryActionLabel).assertEqual('进入后台管理');
      expect(adminPresentation.reminderSectionTitle).assertEqual('后台提醒');

      expect(traderPresentation.showThreads).assertTrue();
      expect(traderPresentation.reminderSectionTitle).assertEqual('交易提醒');
      expect(traderPresentation.threadSectionTitle).assertEqual('会话');
    });

    it('cart_audience_presentation_should_lock_admins_out_of_marketplace_cart_flow', 0, () => {
      const guestPresentation = buildCartAudiencePresentation('guest');
      const adminPresentation = buildCartAudiencePresentation('admin');
      const traderPresentation = buildCartAudiencePresentation('trader');

      expect(guestPresentation.isLocked).assertFalse();
      expect(guestPresentation.emptyPrimaryActionLabel).assertEqual('去登录');

      expect(adminPresentation.isLocked).assertTrue();
      expect(adminPresentation.headerDescription.includes('管理员账号不参与普通交易')).assertTrue();
      expect(adminPresentation.emptyTitle).assertEqual('管理员不使用购物车');
      expect(adminPresentation.emptyPrimaryActionLabel).assertEqual('进入后台管理');

      expect(traderPresentation.isLocked).assertFalse();
      expect(traderPresentation.emptyPrimaryActionLabel).assertEqual('去首页继续挑选');
    });

    it('open_publish_entry_should_toast_for_guest_and_push_expected_route', 0, () => {
      const guestRouter = new FakeUiContextRouter();
      const guestPrompt = new FakeUiContextPrompt();
      const guestHost = new FakeUiContextHost(new FakeUiContext(guestRouter, guestPrompt));

      openPublishEntry(guestHost, null);
      expect(guestPrompt.toastMessage).assertEqual('请先登录后再发布商品');
      expect(guestRouter.pushedUrl).assertEqual('pages/Auth/LoginPage');

      const memberRouter = new FakeUiContextRouter();
      const memberPrompt = new FakeUiContextPrompt();
      const memberHost = new FakeUiContextHost(new FakeUiContext(memberRouter, memberPrompt));

      openPublishEntry(memberHost, {
        id: 'publish-user-2',
        phone: '18800002222',
        nickname: '已登录用户',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: 1,
        updatedAt: 1
      });
      expect(memberPrompt.calls.length).assertEqual(0);
      expect(memberRouter.pushedUrl).assertEqual('pages/Product/PublishProductPage');

      const adminRouter = new FakeUiContextRouter();
      const adminPrompt = new FakeUiContextPrompt();
      const adminHost = new FakeUiContextHost(new FakeUiContext(adminRouter, adminPrompt));

      openPublishEntry(adminHost, {
        id: 'publish-admin-2',
        phone: '19900000002',
        nickname: '系统管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      });
      expect(adminPrompt.toastMessage).assertEqual('管理员账号不支持发布商品，已为你切换到后台管理');
      expect(adminRouter.pushedUrl).assertEqual('pages/Admin/AdminDashboardPage');
    });

    it('render_keys_should_change_when_ui_status_changes', 0, () => {
      const reminderReadKey = buildReminderRenderKey({
        id: 'n-1',
        userId: 'u-1',
        type: 'order_canceled',
        title: '订单已取消',
        summary: '测试提醒',
        relatedId: 'order-1',
        isRead: true,
        createdAt: 1
      });
      const reminderUnreadKey = buildReminderRenderKey({
        id: 'n-1',
        userId: 'u-1',
        type: 'order_canceled',
        title: '订单已取消',
        summary: '测试提醒',
        relatedId: 'order-1',
        isRead: false,
        createdAt: 1
      });

      const orderPendingKey = buildOrderRenderKey({
        id: 'order-1',
        productId: 'product-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        amount: 88,
        address: '图书馆门口',
        locationTag: '图书馆门口',
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: 1,
        updatedAt: 2
      });
      const orderCanceledKey = buildOrderRenderKey({
        id: 'order-1',
        productId: 'product-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        amount: 88,
        address: '图书馆门口',
        locationTag: '图书馆门口',
        payType: 'simulated',
        status: OrderStatus.CANCELED,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: 1,
        updatedAt: 3
      });

      const threadUnreadKey = buildThreadRenderKey({
        id: 'thread-1',
        productId: 'product-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        peerUserId: 'seller-1',
        peerNickname: '卖家',
        productTitle: '测试商品',
        lastMessage: '你好',
        lastMessageAt: 2,
        unreadCount: 1
      });
      const threadReadKey = buildThreadRenderKey({
        id: 'thread-1',
        productId: 'product-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        peerUserId: 'seller-1',
        peerNickname: '卖家',
        productTitle: '测试商品',
        lastMessage: '你好',
        lastMessageAt: 3,
        unreadCount: 0
      });

      const productSaleKey = buildProductRenderKey({
        id: 'product-1',
        sellerId: 'seller-1',
        title: '测试商品',
        desc: '测试描述',
        price: 88,
        category: '教材书籍',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: 1,
        updatedAt: 2
      });
      const productSoldKey = buildProductRenderKey({
        id: 'product-1',
        sellerId: 'seller-1',
        title: '测试商品',
        desc: '测试描述',
        price: 88,
        category: '教材书籍',
        images: [],
        locationTag: '图书馆大厅',
        status: 'sold',
        isDeleted: false,
        createdAt: 1,
        updatedAt: 3
      });

      const userActiveKey = buildUserRenderKey({
        id: 'user-1',
        phone: '18800000001',
        nickname: '测试用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: 1,
        updatedAt: 2
      });
      const userBannedKey = buildUserRenderKey({
        id: 'user-1',
        phone: '18800000001',
        nickname: '测试用户',
        role: 'user',
        status: 'banned',
        creditScore: 80,
        createdAt: 1,
        updatedAt: 3
      });

      const announcementOldKey = buildAnnouncementRenderKey({
        id: 'announcement-1',
        title: '旧公告',
        content: '旧内容',
        publisherId: 'admin-1',
        isDeleted: false,
        createdAt: 1,
        updatedAt: 2
      });
      const announcementNewKey = buildAnnouncementRenderKey({
        id: 'announcement-1',
        title: '新公告',
        content: '新内容',
        publisherId: 'admin-1',
        isDeleted: false,
        createdAt: 1,
        updatedAt: 3
      });

      const productRowBefore = buildProductRowRenderKey([
        {
          id: 'product-1',
          sellerId: 'seller-1',
          title: '测试商品1',
          desc: '测试描述',
          price: 18,
          category: '教材书籍',
          images: [],
          locationTag: '图书馆大厅',
          status: 'on_sale',
          isDeleted: false,
          createdAt: 1,
          updatedAt: 2
        },
        {
          id: 'product-2',
          sellerId: 'seller-2',
          title: '测试商品2',
          desc: '测试描述',
          price: 28,
          category: '电子数码',
          images: [],
          locationTag: '教学楼大厅',
          status: 'on_sale',
          isDeleted: false,
          createdAt: 1,
          updatedAt: 2
        }
      ]);
      const productRowAfter = buildProductRowRenderKey([
        {
          id: 'product-1',
          sellerId: 'seller-1',
          title: '测试商品1',
          desc: '测试描述',
          price: 18,
          category: '教材书籍',
          images: [],
          locationTag: '图书馆大厅',
          status: 'on_sale',
          isDeleted: false,
          createdAt: 1,
          updatedAt: 2
        },
        {
          id: 'product-2',
          sellerId: 'seller-2',
          title: '测试商品2',
          desc: '测试描述',
          price: 28,
          category: '电子数码',
          images: [],
          locationTag: '教学楼大厅',
          status: 'locked',
          isDeleted: false,
          createdAt: 1,
          updatedAt: 3
        }
      ]);

      expect(reminderReadKey === reminderUnreadKey).assertFalse();
      expect(orderPendingKey === orderCanceledKey).assertFalse();
      expect(threadUnreadKey === threadReadKey).assertFalse();
      expect(productSaleKey === productSoldKey).assertFalse();
      expect(userActiveKey === userBannedKey).assertFalse();
      expect(announcementOldKey === announcementNewKey).assertFalse();
      expect(productRowBefore === productRowAfter).assertFalse();
    });

    it('ui_polish_button_tones_should_keep_primary_secondary_and_danger_consistent', 0, () => {
      const primary = getPolishPrimaryButtonTone();
      const secondary = getPolishSecondaryButtonTone();
      const danger = getPolishDangerButtonTone();
      const neutral = getPolishNeutralButtonTone();
      const ghost = getPolishGhostButtonTone();

      expect(primary.backgroundColor).assertEqual('#2F6BFF');
      expect(primary.textColor).assertEqual('#FFFFFF');
      expect(secondary.backgroundColor).assertEqual('#EDF3FF');
      expect(secondary.textColor).assertEqual('#2F6BFF');
      expect(danger.backgroundColor).assertEqual('#FFF4EF');
      expect(danger.textColor).assertEqual('#B8643C');
      expect(neutral.borderColor).assertEqual('#E4DACF');
      expect(ghost.backgroundColor).assertEqual(neutral.backgroundColor);
      expect(ghost.textColor).assertEqual(neutral.textColor);
      expect(primary.height).assertEqual(danger.height);
      expect(primary.radius).assertEqual(secondary.radius);
      expect(secondary.radius).assertEqual(neutral.radius);
    });

    it('auth_ui_polish_tones_should_define_hero_and_input_surfaces', 0, () => {
      const heroTone = getAuthHeroSurfaceTone();
      const inputTone = getAuthInputSurfaceTone();

      expect(heroTone.backgroundColor).assertEqual('#FFFCF8');
      expect(heroTone.borderColor).assertEqual('#E4D9CC');
      expect(inputTone.backgroundColor).assertEqual('#FFFFFF');
      expect(inputTone.borderColor).assertEqual('#E5DDD1');
      expect(heroTone.radius > inputTone.radius).assertTrue();
    });

    it('auth_ui_split_buttons_should_stay_centered_and_symmetric', 0, () => {
      const layout = getAuthSymmetricSplitButtonLayout();

      expect(layout.leftWeight).assertEqual(layout.rightWeight);
      expect(layout.leftWeight).assertEqual(1);
      expect(layout.gap).assertEqual(12);
    });

    it('app_context_should_expose_campus_service_contract', 0, () => {
      expect(appContext.campus !== undefined).assertTrue();
      expect(typeof appContext.campus.listSchools).assertEqual('function');
      expect(typeof appContext.campus.getCurrentCampusProfile).assertEqual('function');
      expect(typeof appContext.campus.submitVerification).assertEqual('function');
      expect(typeof appContext.campus.upsertTradeLocation).assertEqual('function');
    });

    it('campus_service_should_map_remote_identity_and_location_data', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const currentUser: User = {
        id: 'campus-user-1',
        phone: '18800009999',
        nickname: '校园用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(currentUser);
      stateService.saveSession({
        currentUser,
        token: 'campus-token',
        expiresAt: now + 3600 * 1000
      });

      const service = new CampusServiceImpl(new FakeRemoteCampusClient(), stateService);
      const schoolsResult = await service.listSchools();
      const profileResult = await service.getCurrentCampusProfile();
      const verificationResult = await service.getCurrentVerification();
      const locationsResult = await service.listTradeLocations({ enabledOnly: true });

      expect(schoolsResult.ok).assertTrue();
      expect(schoolsResult.data?.[0].name).assertEqual('湖南人文科技学院');
      expect(profileResult.ok).assertTrue();
      expect(profileResult.data?.verificationStatus).assertEqual(VerificationStatus.VERIFIED);
      expect(profileResult.data?.schoolName).assertEqual('湖南人文科技学院');
      expect(verificationResult.ok).assertTrue();
      expect(verificationResult.data?.studentNo).assertEqual('2024123456');
      expect(locationsResult.ok).assertTrue();
      expect(locationsResult.data?.[0].name).assertEqual('图书馆大厅');

      const persistedUser = userRepository.getById(currentUser.id);
      expect(persistedUser?.campusName).assertEqual('主校区');
      expect(persistedUser?.verificationStatus).assertEqual(VerificationStatus.VERIFIED);
    });

    it('campus_profile_merge_should_preserve_existing_user_identity_fields', 0, () => {
      const existingUser: User = {
        id: 'campus-user-merge',
        phone: '18800008888',
        nickname: '原始用户',
        avatar: 'https://example.com/original-avatar.png',
        role: 'user',
        status: 'active',
        creditScore: 92,
        createdAt: 10,
        updatedAt: 11
      };
      const profile: RemoteCampusProfileItem = {
        id: existingUser.id,
        school_id: 'school-hnrku',
        school_name: '湖南人文科技学院',
        campus_id: 'campus-main',
        campus_name: '主校区',
        student_no: '2024123456',
        grade_year: 2024,
        college_name: '信息学院',
        major_name: '软件工程',
        verification_status: VerificationStatus.VERIFIED,
        verification_method: 'MANUAL_STUDENT_CARD',
        verified_at: 100,
        verification_updated_at: 100,
        completed_order_count: 3,
        report_count: 0,
        last_active_at: 102
      };

      const merged = mergeRemoteCampusProfile(existingUser, profile);

      expect(merged.id).assertEqual(existingUser.id);
      expect(merged.phone).assertEqual(existingUser.phone);
      expect(merged.nickname).assertEqual(existingUser.nickname);
      expect(merged.avatar).assertEqual(existingUser.avatar);
      expect(merged.schoolId).assertEqual('school-hnrku');
      expect(merged.campusName).assertEqual('主校区');
      expect(merged.verificationStatus).assertEqual(VerificationStatus.VERIFIED);
      expect(merged.completedOrderCount).assertEqual(3);
      expect(merged.reportCount).assertEqual(0);
    });

    it('campus_profile_merge_should_downgrade_verified_status_when_profile_changes_after_approval', 0, () => {
      const existingUser: User = {
        id: 'campus-user-stale',
        phone: '18800006666',
        nickname: '已认证用户',
        role: 'user',
        status: 'active',
        creditScore: 91,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: 100,
        verificationUpdatedAt: 100,
        createdAt: 10,
        updatedAt: 11
      };
      const profile: RemoteCampusProfileItem = {
        id: existingUser.id,
        school_id: 'school-hnu',
        school_name: '湖南大学',
        campus_id: 'campus-main',
        campus_name: '主校区',
        student_no: '20245555',
        grade_year: 2024,
        college_name: '信息科学与工程学院',
        major_name: '计算机科学与技术',
        verification_status: VerificationStatus.VERIFIED,
        verification_method: 'MANUAL_STUDENT_CARD',
        verified_at: 100,
        verification_updated_at: 101
      };

      const merged = mergeRemoteCampusProfile(existingUser, profile);

      expect(merged.verificationStatus).assertEqual(VerificationStatus.UNVERIFIED);
      expect(merged.verifiedAt).assertEqual(100);
      expect(merged.verificationUpdatedAt).assertEqual(101);
    });

    it('campus_profile_merge_should_conservatively_downgrade_verified_status_when_identity_fields_change_without_remote_timestamp_bump', 0, () => {
      const existingUser: User = {
        id: 'campus-user-profile-change',
        phone: '18800005555',
        nickname: '资料变更用户',
        role: 'user',
        status: 'active',
        creditScore: 90,
        schoolId: 'school-hnrku',
        schoolName: '湖南人文科技学院',
        campusId: 'campus-main',
        campusName: '主校区',
        studentNo: '224081113',
        gradeYear: 2022,
        collegeName: '信息学院',
        majorName: '计算机科学与技术',
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: 100,
        verificationUpdatedAt: 100,
        createdAt: 10,
        updatedAt: 11
      };
      const profile: RemoteCampusProfileItem = {
        id: existingUser.id,
        school_id: 'school-hnu',
        school_name: '湖南大学',
        campus_id: 'campus-yuelu',
        campus_name: '岳麓校区',
        student_no: '224081113',
        grade_year: 2022,
        college_name: '信息科学与工程学院',
        major_name: '软件工程',
        verification_status: VerificationStatus.VERIFIED,
        verification_method: 'MANUAL_STUDENT_CARD',
        verified_at: 100,
        verification_updated_at: 100
      };

      const merged = mergeRemoteCampusProfile(existingUser, profile);

      expect(merged.verificationStatus).assertEqual(VerificationStatus.UNVERIFIED);
    });

    it('campus_submit_verification_should_update_local_user_state_to_pending_review', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const currentUser: User = {
        id: 'campus-user-submit',
        phone: '18800007777',
        nickname: '待认证用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(currentUser);
      stateService.saveSession({
        currentUser,
        token: 'submit-campus-token',
        expiresAt: now + 3600 * 1000
      });

      const service = new CampusServiceImpl(new FakeRemoteCampusClient(), stateService);
      const result = await service.submitVerification({
        id: 'verification-pending',
        userId: currentUser.id,
        schoolId: 'school-hnrku',
        campusId: 'campus-main',
        studentNo: '2024555555',
        gradeYear: 2024,
        collegeName: '信息学院',
        majorName: '软件工程',
        verificationMethod: 'MANUAL_STUDENT_CARD',
        materialUrls: ['https://example.com/student-card.png'],
        status: VerificationStatus.PENDING_REVIEW,
        submittedAt: now,
        updatedAt: now
      });

      expect(result.ok).assertTrue();
      const persistedUser = userRepository.getById(currentUser.id);
      expect(persistedUser?.schoolId).assertEqual('school-hnrku');
      expect(persistedUser?.campusId).assertEqual('campus-main');
      expect(persistedUser?.studentNo).assertEqual('2024555555');
      expect(persistedUser?.verificationStatus).assertEqual(VerificationStatus.PENDING_REVIEW);
      expect(persistedUser?.verificationMethod).assertEqual('MANUAL_STUDENT_CARD');
    });

    it('campus_submit_verification_should_keep_existing_campus_id_when_only_campus_name_is_provided', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const currentUser: User = {
        id: 'campus-user-submit-name-only',
        phone: '18800006666',
        nickname: '手填校区用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        schoolId: 'school-hnu',
        schoolName: '湖南大学',
        campusId: 'campus-hnu-main',
        campusName: '主校区',
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(currentUser);
      stateService.saveSession({
        currentUser,
        token: 'submit-campus-name-only-token',
        expiresAt: now + 3600 * 1000
      });

      const service = new CampusServiceImpl(new FakeRemoteCampusClient(), stateService);
      const result = await service.submitVerification({
        id: 'verification-pending-name-only',
        userId: currentUser.id,
        schoolId: 'school-hnu',
        campusId: '',
        campusName: '主校区',
        studentNo: '224081113',
        gradeYear: 2022,
        collegeName: '信息学院',
        majorName: '计算机科学与技术',
        verificationMethod: 'MANUAL_STUDENT_CARD',
        materialUrls: ['https://example.com/student-card.png'],
        status: VerificationStatus.PENDING_REVIEW,
        submittedAt: now,
        updatedAt: now
      });

      expect(result.ok).assertTrue();
      const persistedUser = userRepository.getById(currentUser.id);
      expect(persistedUser?.schoolId).assertEqual('school-hnu');
      expect(persistedUser?.campusId).assertEqual('campus-hnu-main');
      expect(persistedUser?.campusName).assertEqual('主校区');
      expect(persistedUser?.verificationStatus).assertEqual(VerificationStatus.PENDING_REVIEW);
    });

    it('campus_service_should_reject_profile_and_verification_operations_for_admin_accounts', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const adminUser: User = {
        id: 'campus-admin-user',
        phone: '19900000000',
        nickname: '系统管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(adminUser);
      stateService.saveSession({
        currentUser: adminUser,
        token: 'admin-campus-token',
        expiresAt: now + 3600 * 1000
      });

      const service = new CampusServiceImpl(new FakeRemoteCampusClient(), stateService);
      const currentProfileResult = await service.getCurrentCampusProfile();
      const currentVerificationResult = await service.getCurrentVerification();
      const updateResult = await service.updateCampusProfile(
        'school-hnrku',
        'campus-main',
        '主校区',
        '224081113',
        2022,
        '信息学院',
        '计算机科学与技术'
      );
      const submitResult = await service.submitVerification({
        id: 'admin-verification',
        userId: adminUser.id,
        schoolId: 'school-hnrku',
        campusId: 'campus-main',
        campusName: '主校区',
        studentNo: '224081113',
        gradeYear: 2022,
        collegeName: '信息学院',
        majorName: '计算机科学与技术',
        verificationMethod: 'MANUAL_STUDENT_CARD',
        materialUrls: ['https://example.com/student-card.png'],
        status: VerificationStatus.PENDING_REVIEW,
        submittedAt: now,
        updatedAt: now
      });

      expect(currentProfileResult.ok).assertFalse();
      expect(currentVerificationResult.ok).assertFalse();
      expect(updateResult.ok).assertFalse();
      expect(submitResult.ok).assertFalse();
    });

    it('campus_foundation_domain_types_should_support_identity_and_location_structures', 0, () => {
      const school: School = {
        id: 'school-hnrku',
        name: '湖南人文科技学院',
        shortName: '湖人文',
        city: '娄底',
        isEnabled: true,
        sortOrder: 1,
        createdAt: 1,
        updatedAt: 2
      };
      const campus: Campus = {
        id: 'campus-main',
        schoolId: school.id,
        name: '主校区',
        shortName: '主校区',
        isMainCampus: true,
        isEnabled: true,
        sortOrder: 1,
        createdAt: 1,
        updatedAt: 2
      };
      const group: LocationGroup = {
        id: 'group-library',
        schoolId: school.id,
        campusId: campus.id,
        name: '图书馆区',
        description: '适合教材与数码商品面交',
        isEnabled: true,
        sortOrder: 1,
        createdAt: 1,
        updatedAt: 2
      };
      const location: TradeLocation = {
        id: 'location-library-hall',
        schoolId: school.id,
        campusId: campus.id,
        groupId: group.id,
        name: '图书馆大厅',
        alias: '图书馆一楼大厅',
        description: '人流稳定的校内交易点',
        safetyTips: '建议白天交易并当场验货',
        recommendedCategories: ['教材书籍', '电子数码'],
        isEnabled: true,
        isHot: true,
        sortOrder: 1,
        createdAt: 1,
        updatedAt: 2
      };
      const verification: StudentVerification = {
        id: 'verification-1',
        userId: 'user-1',
        schoolId: school.id,
        campusId: campus.id,
        studentNo: '2024123456',
        gradeYear: 2024,
        collegeName: '信息学院',
        majorName: '软件工程',
        verificationMethod: 'MANUAL_STUDENT_CARD',
        materialUrls: ['https://example.com/student-card.png'],
        status: VerificationStatus.PENDING_REVIEW,
        submittedAt: 3,
        updatedAt: 3
      };

      expect(location.recommendedCategories.length).assertEqual(2);
      expect(verification.status).assertEqual(VerificationStatus.PENDING_REVIEW);
      expect(verification.verificationMethod).assertEqual('MANUAL_STUDENT_CARD');
      expect(group.campusId).assertEqual(campus.id);
      expect(campus.schoolId).assertEqual(school.id);
    });

    it('campus_remote_contracts_should_cover_profile_verification_and_trade_location_payloads', 0, () => {
      const profilePayload = new RemoteCampusProfilePayload(
        'school-hnrku',
        'campus-main',
        '主校区',
        '2024123456',
        2024,
        '信息学院',
        '软件工程'
      );
      const verificationPayload = new RemoteSubmitVerificationPayload(
        'school-hnrku',
        'campus-main',
        '主校区',
        '2024123456',
        'MANUAL_STUDENT_CARD',
        ['https://example.com/student-card.png'],
        2024,
        '信息学院',
        '软件工程'
      );
      const reviewPayload = new RemoteReviewVerificationPayload(
        VerificationStatus.REJECTED,
        '材料不清晰',
        '请重新上传清晰学生证'
      );
      const locationItem: RemoteTradeLocationItem = {
        id: 'location-library-hall',
        school_id: 'school-hnrku',
        campus_id: 'campus-main',
        group_id: 'group-library',
        name: '图书馆大厅',
        alias: '图书馆一楼大厅',
        description: '人流稳定的校内交易点',
        safety_tips: '建议白天交易并当场验货',
        recommended_categories: ['教材书籍'],
        is_enabled: true,
        is_hot: true,
        sort_order: 1,
        created_at: '2026-04-09T00:00:00Z',
        updated_at: '2026-04-09T00:00:00Z'
      };
      const updatePayload = new RemoteUpdateMePayload(
        '测试用户',
        'https://example.com/avatar.png',
        'school-hnrku',
        'campus-main',
        '2024123456',
        2024,
        '信息学院',
        '软件工程'
      );
      const createPayload = new RemoteCreateProductPayload(
        '高数教材',
        '九成新',
        28,
        '教材书籍',
        '图书馆大厅',
        'https://example.com/book.png',
        'school-hnrku',
        'campus-main',
        'group-library',
        'location-library-hall'
      );

      expect(profilePayload.school_id).assertEqual('school-hnrku');
      expect(profilePayload.student_no).assertEqual('2024123456');
      expect(verificationPayload.verification_method).assertEqual('MANUAL_STUDENT_CARD');
      expect(verificationPayload.material_urls.length).assertEqual(1);
      expect(reviewPayload.status).assertEqual(VerificationStatus.REJECTED);
      expect(reviewPayload.reject_reason).assertEqual('请重新上传清晰学生证');
      expect(locationItem.group_id).assertEqual('group-library');
      expect(updatePayload.school_id).assertEqual('school-hnrku');
      expect(createPayload.trade_location_id).assertEqual('location-library-hall');
    });

    it('admin_dashboard_entries_should_include_verification_review_entry', 0, () => {
      const entries = getAdminDashboardEntries();
      const verificationEntry = entries.find((item) => item.url === 'pages/Admin/AdminVerificationPage');

      expect(entries.length >= 4).assertTrue();
      expect(verificationEntry !== undefined).assertTrue();
      expect(verificationEntry?.title).assertEqual('认证审核');
    });

    it('campus_identity_presentation_should_cover_verification_state_matrix', 0, () => {
      const now = Date.now();
      const baseUser: User = {
        id: 'identity-user',
        phone: '18812345678',
        nickname: '校园用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        schoolName: '湖南人文科技学院',
        campusName: '主校区',
        createdAt: now,
        updatedAt: now
      };

      const unverified = buildCampusIdentityPresentation(baseUser);
      const pendingUser: User = {
        id: baseUser.id,
        phone: baseUser.phone,
        nickname: baseUser.nickname,
        role: baseUser.role,
        status: baseUser.status,
        creditScore: baseUser.creditScore,
        schoolName: baseUser.schoolName,
        campusName: baseUser.campusName,
        createdAt: baseUser.createdAt,
        updatedAt: baseUser.updatedAt,
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        studentNo: '2024123456'
      };
      const verifiedUserForIdentity: User = {
        id: baseUser.id,
        phone: baseUser.phone,
        nickname: baseUser.nickname,
        role: baseUser.role,
        status: baseUser.status,
        creditScore: baseUser.creditScore,
        schoolName: baseUser.schoolName,
        campusName: baseUser.campusName,
        createdAt: baseUser.createdAt,
        updatedAt: baseUser.updatedAt,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: baseUser.updatedAt,
        verificationUpdatedAt: baseUser.updatedAt,
        studentNo: '2024123456',
        collegeName: '信息学院',
        majorName: '软件工程',
        completedOrderCount: 6
      };
      const rejectedUser: User = {
        id: baseUser.id,
        phone: baseUser.phone,
        nickname: baseUser.nickname,
        role: baseUser.role,
        status: baseUser.status,
        creditScore: baseUser.creditScore,
        schoolName: baseUser.schoolName,
        campusName: baseUser.campusName,
        createdAt: baseUser.createdAt,
        updatedAt: baseUser.updatedAt,
        verificationStatus: VerificationStatus.REJECTED,
        verificationRejectedReason: '学生证照片不清晰'
      };
      const suspendedUser: User = {
        id: baseUser.id,
        phone: baseUser.phone,
        nickname: baseUser.nickname,
        role: baseUser.role,
        status: baseUser.status,
        creditScore: baseUser.creditScore,
        schoolName: baseUser.schoolName,
        campusName: baseUser.campusName,
        createdAt: baseUser.createdAt,
        updatedAt: baseUser.updatedAt,
        verificationStatus: VerificationStatus.SUSPENDED
      };
      const pending = buildCampusIdentityPresentation(pendingUser);
      const verified = buildCampusIdentityPresentation(verifiedUserForIdentity);
      const rejected = buildCampusIdentityPresentation(rejectedUser);
      const suspended = buildCampusIdentityPresentation(suspendedUser);

      expect(unverified.badgeText).assertEqual('未认证');
      expect(unverified.actionLabel).assertEqual('完善校园资料');
      expect(pending.badgeText).assertEqual('待审核');
      expect(pending.helperText).assertEqual('平台正在核验你的学生身份，请耐心等待审核结果。');
      expect(verified.badgeText).assertEqual('已认证');
      expect(verified.summaryText).assertEqual('湖南人文科技学院 / 主校区 / 信息学院 / 软件工程');
      expect(rejected.badgeText).assertEqual('已驳回');
      expect(rejected.rejectReasonText).assertEqual('驳回原因：学生证照片不清晰');
      expect(suspended.badgeText).assertEqual('已暂停');
      expect(suspended.actionLabel).assertEqual('联系管理员处理');
    });

    it('public_campus_trust_presentation_should_render_conservative_public_states', 0, () => {
      const now = Date.now();
      const verifiedUser: User = {
        id: 'trusted-user',
        phone: '18812340000',
        nickname: '可信用户',
        role: 'user',
        status: 'active',
        creditScore: 90,
        schoolName: '湖南大学',
        campusName: '主校区',
        collegeName: '信息科学与工程学院',
        majorName: '计算机科学与技术',
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      };

      const pendingUser: User = {
        id: 'pending-user',
        phone: verifiedUser.phone,
        nickname: verifiedUser.nickname,
        role: verifiedUser.role,
        status: verifiedUser.status,
        creditScore: verifiedUser.creditScore,
        schoolName: verifiedUser.schoolName,
        campusName: verifiedUser.campusName,
        collegeName: verifiedUser.collegeName,
        majorName: verifiedUser.majorName,
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        createdAt: verifiedUser.createdAt,
        updatedAt: verifiedUser.updatedAt
      };

      const unverifiedUser: User = {
        id: 'unverified-user',
        phone: verifiedUser.phone,
        nickname: verifiedUser.nickname,
        role: verifiedUser.role,
        status: verifiedUser.status,
        creditScore: verifiedUser.creditScore,
        schoolName: verifiedUser.schoolName,
        campusName: verifiedUser.campusName,
        collegeName: verifiedUser.collegeName,
        majorName: verifiedUser.majorName,
        verificationStatus: VerificationStatus.UNVERIFIED,
        createdAt: verifiedUser.createdAt,
        updatedAt: verifiedUser.updatedAt
      };

      const verifiedPresentation = buildPublicCampusTrustPresentation(verifiedUser);
      const pendingPresentation = buildPublicCampusTrustPresentation(pendingUser);
      const unverifiedPresentation = buildPublicCampusTrustPresentation(unverifiedUser);
      const unknownPresentation = buildPublicCampusTrustPresentation(null);

      expect(verifiedPresentation.badgeText).assertEqual('已认证');
      expect(verifiedPresentation.isTrusted).assertTrue();
      expect(verifiedPresentation.summary).assertEqual('湖南大学 / 主校区 / 信息科学与工程学院 / 计算机科学与技术');
      expect(pendingPresentation.badgeText).assertEqual('审核中');
      expect(pendingPresentation.isTrusted).assertFalse();
      expect(pendingPresentation.headline).assertEqual('校园身份审核中');
      expect(unverifiedPresentation.badgeText).assertEqual('待确认');
      expect(unverifiedPresentation.isTrusted).assertFalse();
      expect(unknownPresentation.summary).assertEqual('暂未获取到对方的校园资料');
    });

    it('campus_identity_defaults_should_prefer_enabled_primary_entries', 0, () => {
      const schools: School[] = [
        {
          id: 'school-disabled',
          name: '旧学校',
          shortName: '旧学校',
          isEnabled: false,
          sortOrder: 0,
          createdAt: 1,
          updatedAt: 1
        },
        {
          id: 'school-main',
          name: '湖南人文科技学院',
          shortName: '湖人文',
          isEnabled: true,
          sortOrder: 2,
          createdAt: 1,
          updatedAt: 1
        }
      ];
      const campuses: Campus[] = [
        {
          id: 'campus-secondary',
          schoolId: 'school-main',
          name: '东校区',
          shortName: '东校区',
          isMainCampus: false,
          isEnabled: true,
          sortOrder: 2,
          createdAt: 1,
          updatedAt: 1
        },
        {
          id: 'campus-main',
          schoolId: 'school-main',
          name: '主校区',
          shortName: '主校区',
          isMainCampus: true,
          isEnabled: true,
          sortOrder: 3,
          createdAt: 1,
          updatedAt: 1
        }
      ];

      const defaultSchool = pickDefaultSchool(schools);
      const defaultCampus = pickDefaultCampus(campuses);

      expect(defaultSchool?.id).assertEqual('school-main');
      expect(defaultCampus?.id).assertEqual('campus-main');
    });

    it('campus_identity_selection_should_reset_campus_to_selected_school_scope', 0, () => {
      const campuses: Campus[] = [
        {
          id: 'campus-main',
          schoolId: 'school-main',
          name: '主校区',
          shortName: '主校区',
          isMainCampus: true,
          isEnabled: true,
          sortOrder: 1,
          createdAt: 1,
          updatedAt: 1
        },
        {
          id: 'campus-west',
          schoolId: 'school-main',
          name: '西校区',
          shortName: '西校区',
          isMainCampus: false,
          isEnabled: true,
          sortOrder: 2,
          createdAt: 1,
          updatedAt: 1
        },
        {
          id: 'campus-other',
          schoolId: 'school-other',
          name: '东校区',
          shortName: '东校区',
          isMainCampus: true,
          isEnabled: true,
          sortOrder: 1,
          createdAt: 1,
          updatedAt: 1
        }
      ];

      const keptCampus = resolveCampusForSchoolSelection(campuses, 'school-main', 'campus-west');
      const resetCampus = resolveCampusForSchoolSelection(campuses, 'school-main', 'campus-other');

      expect(keptCampus?.id).assertEqual('campus-west');
      expect(resetCampus?.id).assertEqual('campus-main');
    });

    it('campus_verification_helpers_should_expose_method_labels_and_validate_materials', 0, () => {
      const options = getCampusVerificationMethodOptions();
      const invalidDraft = new CampusVerificationDraftInput(
        'school-hnrku',
        'campus-main',
        '主校区',
        '2024123456',
        'MANUAL_STUDENT_CARD',
        []
      );
      const validDraft = new CampusVerificationDraftInput(
        'school-hnrku',
        'campus-main',
        '主校区',
        '2024123456',
        'MANUAL_STUDENT_CARD',
        ['https://example.com/student-card.png'],
        2024,
        '信息学院',
        '软件工程'
      );

      expect(options.length).assertEqual(3);
      expect(getCampusVerificationMethodLabel('MANUAL_STUDENT_CARD')).assertEqual('学生证');
      expect(getCampusVerificationMethodLabel('MANUAL_CAMPUS_CARD')).assertEqual('校园卡');
      expect(getCampusVerificationMethodLabel('MANUAL_ENROLLMENT_PROOF')).assertEqual('在读证明');
      expect(validateCampusVerificationDraft(invalidDraft)).assertEqual('请先上传或粘贴一份认证材料');
      expect(validateCampusVerificationDraft(validDraft)).assertEqual('');
    });

    it('campus_verification_helpers_should_build_pending_review_draft', 0, () => {
      const now = Date.now();
      const user: User = {
        id: 'verification-user',
        phone: '18812345678',
        nickname: '校园认证用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const draft = buildCampusVerificationDraft(user, new CampusVerificationDraftInput(
        'school-hnrku',
        'campus-main',
        '主校区',
        '2024123456',
        'MANUAL_ENROLLMENT_PROOF',
        ['https://example.com/proof.png'],
        2024,
        '信息学院',
        '软件工程'
      ));

      expect(draft.userId).assertEqual(user.id);
      expect(draft.schoolId).assertEqual('school-hnrku');
      expect(draft.campusId).assertEqual('campus-main');
      expect(draft.verificationMethod).assertEqual('MANUAL_ENROLLMENT_PROOF');
      expect(draft.materialUrls[0]).assertEqual('https://example.com/proof.png');
      expect(draft.status).assertEqual(VerificationStatus.PENDING_REVIEW);
    });

    it('campus_location_helpers_should_prefer_hot_category_matched_location', 0, () => {
      const locations: TradeLocation[] = [
        {
          id: 'location-dorm',
          schoolId: 'school-hnrku',
          campusId: 'campus-main',
          groupId: 'group-life',
          name: '南苑宿舍门口',
          safetyTips: '建议和宿管可见范围内交易',
          recommendedCategories: ['日用百货'],
          isEnabled: true,
          isHot: false,
          sortOrder: 3,
          createdAt: 1,
          updatedAt: 1
        },
        {
          id: 'location-library',
          schoolId: 'school-hnrku',
          campusId: 'campus-main',
          groupId: 'group-study',
          name: '图书馆大厅',
          alias: '图书馆一楼大厅',
          safetyTips: '建议白天交易并当场验货',
          recommendedCategories: ['教材书籍', '电子数码'],
          isEnabled: true,
          isHot: true,
          sortOrder: 2,
          createdAt: 1,
          updatedAt: 1
        },
        {
          id: 'location-playground',
          schoolId: 'school-hnrku',
          campusId: 'campus-main',
          groupId: 'group-sports',
          name: '操场看台',
          recommendedCategories: ['运动健身'],
          isEnabled: true,
          isHot: true,
          sortOrder: 1,
          createdAt: 1,
          updatedAt: 1
        }
      ];

      const ordered = filterTradeLocationsForCategory(locations, '教材书籍');
      const preferred = pickPreferredTradeLocation(locations, '教材书籍');

      expect(ordered[0].id).assertEqual('location-library');
      expect(preferred?.id).assertEqual('location-library');
      expect(buildTradeLocationLabel(locations[1], '教学区')).assertEqual('教学区 · 图书馆一楼大厅');
    });

    it('campus_academic_presets_should_offer_keyword_suggestions_with_other_fallback', 0, () => {
      const schools: School[] = [{
        id: 'school-hnrku',
        name: '湖南人文科技学院',
        shortName: '湖人文',
        isEnabled: true,
        sortOrder: 1,
        createdAt: 1,
        updatedAt: 1
      }];
      const colleges = listCollegeOptions('school-hnrku', '湖南人文科技学院');
      const majors = listMajorOptions('school-hnrku', '湖南人文科技学院', '信息学院');
      const schoolSuggestions = findSchoolSuggestions(schools, '人文');
      const collegeSuggestions = filterAcademicOptions(colleges, '信息');
      const majorSuggestions = filterAcademicOptions(majors, '软件');

      expect(colleges.includes('信息学院')).assertTrue();
      expect(majors.includes('软件工程')).assertTrue();
      expect(schoolSuggestions.length).assertEqual(1);
      expect(findSchoolSuggestions([], '湖南').length).assertEqual(0);
      expect(findExactSchoolSelection(schools, '湖南人文科技学院')?.name ?? '').assertEqual('湖南人文科技学院');
      expect(collegeSuggestions[0]).assertEqual('信息学院');
      expect(majorSuggestions[0]).assertEqual('软件工程');
      expect(shouldShowSchoolSuggestionPanel(schools, '')).assertFalse();
      expect(shouldShowSchoolSuggestionPanel(schools, '湖南')).assertTrue();
      expect(shouldShowSchoolSuggestionPanel(schools, '湖南人文科技学院')).assertFalse();
      expect(shouldShowAcademicSuggestionPanel(colleges, '')).assertFalse();
      expect(shouldShowAcademicSuggestionPanel(colleges, '信息')).assertTrue();
      expect(shouldShowAcademicSuggestionPanel(colleges, '信息学院')).assertFalse();
      expect(normalizeCollegeInput('school-hnrku', '湖南人文科技学院', '星际学院')).assertEqual(FALLBACK_ACADEMIC_OPTION);
      expect(normalizeMajorInput('school-hnrku', '湖南人文科技学院', '信息学院', '星际架构学')).assertEqual(FALLBACK_ACADEMIC_OPTION);
      expect(normalizeCollegeInput('school-hnrku', '湖南人文科技学院', '信息学院')).assertEqual('信息学院');
      expect(listCollegeOptions('school-other', '其他学校').length > 0).assertTrue();
    });

    it('verification_review_grouping_should_use_latest_application_per_user', 0, () => {
      const baseTime = Date.now();
      const items: StudentVerification[] = [
        {
          id: 'verify-u1-old',
          userId: 'user-1',
          schoolId: 'school-a',
          campusId: 'campus-a',
          studentNo: '20240001',
          verificationMethod: 'MANUAL_STUDENT_CARD',
          materialUrls: ['https://example.com/u1-old.png'],
          status: VerificationStatus.REJECTED,
          submittedAt: baseTime - 2000,
          updatedAt: baseTime - 1800
        },
        {
          id: 'verify-u1-new',
          userId: 'user-1',
          schoolId: 'school-a',
          campusId: 'campus-a',
          studentNo: '20240001',
          verificationMethod: 'MANUAL_STUDENT_CARD',
          materialUrls: ['https://example.com/u1-new.png'],
          status: VerificationStatus.PENDING_REVIEW,
          submittedAt: baseTime - 1000,
          updatedAt: baseTime - 800
        },
        {
          id: 'verify-u2',
          userId: 'user-2',
          schoolId: 'school-b',
          campusId: 'campus-b',
          studentNo: '20240002',
          verificationMethod: 'MANUAL_CAMPUS_CARD',
          materialUrls: ['https://example.com/u2.png'],
          status: VerificationStatus.VERIFIED,
          submittedAt: baseTime - 900,
          updatedAt: baseTime - 700
        },
        {
          id: 'verify-u3',
          userId: 'user-3',
          schoolId: 'school-c',
          campusId: 'campus-c',
          studentNo: '20240003',
          verificationMethod: 'MANUAL_ENROLLMENT_PROOF',
          materialUrls: ['https://example.com/u3.png'],
          status: VerificationStatus.SUSPENDED,
          submittedAt: baseTime - 850,
          updatedAt: baseTime - 650
        }
      ];

      const latest = pickLatestVerificationByUser(items);
      const grouped = groupVerificationByReviewTab(items);

      expect(latest.length).assertEqual(3);
      expect(latest[0].id).assertEqual('verify-u3');
      expect(grouped.pending.length).assertEqual(1);
      expect(grouped.pending[0].id).assertEqual('verify-u1-new');
      expect(grouped.approved.length).assertEqual(1);
      expect(grouped.approved[0].id).assertEqual('verify-u2');
      expect(grouped.rejected.length).assertEqual(1);
      expect(grouped.rejected[0].id).assertEqual('verify-u3');
    });

    it('verification_review_grouping_should_accept_remote_status_aliases', 0, () => {
      const baseTime = Date.now();
      const items: StudentVerification[] = [
        {
          id: 'verify-alias-pending',
          userId: 'alias-user-1',
          schoolId: 'school-a',
          campusId: 'campus-a',
          studentNo: '20240101',
          verificationMethod: 'MANUAL_STUDENT_CARD',
          materialUrls: ['https://example.com/pending.png'],
          status: 'PENDING' as VerificationStatus,
          submittedAt: baseTime - 3,
          updatedAt: baseTime - 3
        },
        {
          id: 'verify-alias-approved',
          userId: 'alias-user-2',
          schoolId: 'school-a',
          campusId: 'campus-a',
          studentNo: '20240102',
          verificationMethod: 'MANUAL_STUDENT_CARD',
          materialUrls: ['https://example.com/approved.png'],
          status: 'APPROVED' as VerificationStatus,
          submittedAt: baseTime - 2,
          updatedAt: baseTime - 2
        },
        {
          id: 'verify-alias-rejected',
          userId: 'alias-user-3',
          schoolId: 'school-a',
          campusId: 'campus-a',
          studentNo: '20240103',
          verificationMethod: 'MANUAL_STUDENT_CARD',
          materialUrls: ['https://example.com/rejected.png'],
          status: 'DENIED' as VerificationStatus,
          submittedAt: baseTime - 1,
          updatedAt: baseTime - 1
        }
      ];

      const grouped = groupVerificationByReviewTab(items);
      expect(grouped.pending.length).assertEqual(1);
      expect(grouped.approved.length).assertEqual(1);
      expect(grouped.rejected.length).assertEqual(1);
    });

    it('verification_material_preview_should_filter_invalid_urls_and_limit_count', 0, () => {
      const item: StudentVerification = {
        id: 'verify-material',
        userId: 'user-m',
        schoolId: 'school-m',
        campusId: 'campus-m',
        studentNo: '20249999',
        verificationMethod: 'MANUAL_STUDENT_CARD',
        materialUrls: [
          '',
          'https://example.com/1.png',
          '   ',
          'https://example.com/2.png',
          'https://example.com/3.png',
          'https://example.com/4.png'
        ],
        status: VerificationStatus.PENDING_REVIEW,
        submittedAt: 1,
        updatedAt: 1
      };

      const urls = getVerificationMaterialPreviewUrls(item, 3);
      expect(urls.length).assertEqual(3);
      expect(urls[0]).assertEqual('https://example.com/1.png');
      expect(urls[2]).assertEqual('https://example.com/3.png');
    });

    it('campus_verification_lifecycle_should_describe_pending_snapshot_separately_from_live_profile', 0, () => {
      const user: User = {
        id: 'user-campus-1',
        phone: '13800000001',
        nickname: '校园用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        schoolId: 'school-current',
        schoolName: '湖南大学',
        campusId: 'campus-current',
        campusName: '南校区',
        studentNo: '20240001',
        gradeYear: 2024,
        collegeName: '软件学院',
        majorName: '软件工程',
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        createdAt: 1,
        updatedAt: 1
      };
      const verification: StudentVerification = {
        id: 'verify-campus-1',
        userId: 'user-campus-1',
        schoolId: 'school-snapshot',
        schoolName: '湖南人文科技学院',
        campusId: 'campus-main',
        campusName: '主校区',
        studentNo: '224081113',
        gradeYear: 2022,
        collegeName: '信息学院',
        majorName: '计算机科学与技术',
        verificationMethod: 'MANUAL_STUDENT_CARD',
        materialUrls: ['https://example.com/student-card.png'],
        status: VerificationStatus.PENDING_REVIEW,
        submittedAt: 1710000000000,
        updatedAt: 1710000000000
      };

      const presentation = buildProfileVerificationLifecyclePresentation(user, verification);
      expect(presentation.shouldShowSnapshot).assertTrue();
      expect(buildVerificationCampusSummary(verification)).assertEqual('湖南人文科技学院 / 主校区');
      expect(buildVerificationAcademicSummary(verification)).assertEqual('信息学院 / 计算机科学与技术 / 2022');
      expect(presentation.snapshotTitle).assertEqual('当前审核快照');
      expect(presentation.draftHelperText.includes('不会影响本次审核')).assertTrue();
    });

    it('campus_verification_lifecycle_should_guide_rejected_and_verified_states_differently', 0, () => {
      const user: User = {
        id: 'user-campus-2',
        phone: '13800000002',
        nickname: '校园用户2',
        role: 'user',
        status: 'active',
        creditScore: 82,
        verificationStatus: VerificationStatus.REJECTED,
        verificationRejectedReason: '学生证不清晰',
        createdAt: 1,
        updatedAt: 1
      };
      const rejectedVerification: StudentVerification = {
        id: 'verify-campus-2',
        userId: 'user-campus-2',
        schoolId: 'school-r',
        schoolName: '中南大学',
        campusId: 'campus-r',
        campusName: '铁道校区',
        studentNo: '20240002',
        verificationMethod: 'MANUAL_STUDENT_CARD',
        materialUrls: ['https://example.com/rejected.png'],
        status: VerificationStatus.REJECTED,
        submittedAt: 1710000000000,
        reviewedAt: 1710003600000,
        rejectReason: '学生证不清晰',
        updatedAt: 1710003600000
      };
      const verifiedVerification: StudentVerification = {
        id: 'verify-campus-3',
        userId: 'user-campus-2',
        schoolId: 'school-v',
        schoolName: '湖南大学',
        campusId: 'campus-v',
        campusName: '主校区',
        studentNo: '20240003',
        verificationMethod: 'MANUAL_CAMPUS_CARD',
        materialUrls: ['https://example.com/verified.png'],
        status: VerificationStatus.VERIFIED,
        submittedAt: 1710100000000,
        reviewedAt: 1710103600000,
        updatedAt: 1710103600000
      };

      const rejectedPresentation = buildProfileVerificationLifecyclePresentation(user, rejectedVerification);
      const verifiedPresentation = buildProfileVerificationLifecyclePresentation(user, verifiedVerification);

      expect(rejectedPresentation.snapshotTitle).assertEqual('上次驳回快照');
      expect(rejectedPresentation.draftHelperText.includes('重新提交')).assertTrue();
      expect(verifiedPresentation.snapshotTitle).assertEqual('最近通过快照');
      expect(verifiedPresentation.draftHelperText.includes('公开展示')).assertTrue();
    });

    it('campus_verification_editor_should_only_allow_submission_edits_for_unverified_or_rejected_states', 0, () => {
      const unverifiedEditor = buildVerificationEditorPresentation(null);
      const rejectedEditor = buildVerificationEditorPresentation(VerificationStatus.REJECTED);
      const pendingEditor = buildVerificationEditorPresentation(VerificationStatus.PENDING_REVIEW);
      const verifiedEditor = buildVerificationEditorPresentation(VerificationStatus.VERIFIED);
      const suspendedEditor = buildVerificationEditorPresentation(VerificationStatus.SUSPENDED);

      expect(unverifiedEditor.canEdit).assertTrue();
      expect(unverifiedEditor.canSubmit).assertTrue();
      expect(unverifiedEditor.lockedHintText.length).assertEqual(0);

      expect(rejectedEditor.canEdit).assertTrue();
      expect(rejectedEditor.canSubmit).assertTrue();
      expect(rejectedEditor.submitButtonLabel).assertEqual('重新提交学生身份认证');

      expect(pendingEditor.canEdit).assertFalse();
      expect(pendingEditor.canSubmit).assertFalse();
      expect(pendingEditor.lockedHintText).assertEqual('当前申请已进入审核队列，审核完成前不能修改本次提交内容。');

      expect(verifiedEditor.canEdit).assertFalse();
      expect(verifiedEditor.canSubmit).assertFalse();
      expect(verifiedEditor.lockedHintText).assertEqual('当前公开身份已通过审核。若资料有变化，请先更新校园资料，再在后续重新发起认证。');

      expect(suspendedEditor.canEdit).assertFalse();
      expect(suspendedEditor.canSubmit).assertFalse();
      expect(suspendedEditor.lockedHintText).assertEqual('当前认证资格已暂停，请先联系管理员处理后再继续提交。');
    });

    it('displayed_verification_status_should_downgrade_verified_users_after_profile_changes', 0, () => {
      const staleVerifiedUser: User = {
        id: 'stale-user',
        phone: '13800009999',
        nickname: '资料已变更用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: 1710100000000,
        verificationUpdatedAt: 1710200000000,
        schoolName: '湖南大学',
        campusName: '主校区',
        collegeName: '信息科学与工程学院',
        majorName: '计算机科学与技术',
        createdAt: 1,
        updatedAt: 1
      };

      expect(resolveDisplayedVerificationStatus(staleVerifiedUser)).assertEqual(VerificationStatus.UNVERIFIED);
      expect(buildCampusIdentityPresentation(staleVerifiedUser).badgeText).assertEqual('未认证');
      expect(buildPublicCampusTrustPresentation(staleVerifiedUser).badgeText).assertEqual('待确认');
      expect(buildVerificationEditorPresentation(resolveDisplayedVerificationStatus(staleVerifiedUser)).canEdit).assertTrue();
    });

    it('profile_verification_lifecycle_should_not_show_verified_status_for_stale_verified_user_without_snapshot', 0, () => {
      const staleVerifiedUser: User = {
        id: 'stale-user-no-snapshot',
        phone: '13800008888',
        nickname: '资料已变更用户2',
        role: 'user',
        status: 'active',
        creditScore: 86,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: 1710100000000,
        verificationUpdatedAt: 1710200000000,
        schoolName: '湖南大学',
        campusName: '主校区',
        collegeName: '信息科学与工程学院',
        majorName: '计算机科学与技术',
        createdAt: 1,
        updatedAt: 1
      };

      const presentation = buildProfileVerificationLifecyclePresentation(staleVerifiedUser, null);
      expect(presentation.shouldShowSnapshot).assertFalse();
      expect(presentation.snapshotStatusText).assertEqual('未认证');
    });

    it('remote_product_mapping_should_preserve_structured_campus_location_fields', 0, () => {
      const mapped = mapRemoteProductItem({
        id: 1001,
        seller_id: 2002,
        title: '高数教材',
        description: '九成新',
        price: '28',
        category: '教材书籍',
        location_tag: '图书馆大厅',
        school_id: 'school-hnrku',
        school_name: '湖南人文科技学院',
        campus_id: 'campus-main',
        campus_name: '主校区',
        location_group_id: 'group-study',
        location_group_name: '教学区',
        trade_location_id: 'location-library',
        trade_location_name: '图书馆一楼大厅',
        location_safety_tips: '建议白天交易并当场验货',
        cover_image: 'https://example.com/book.png',
        status: 'on_sale',
        created_at: '2026-04-10T08:00:00Z',
        updated_at: '2026-04-10T09:00:00Z'
      });

      expect(mapped.schoolId).assertEqual('school-hnrku');
      expect(mapped.schoolName).assertEqual('湖南人文科技学院');
      expect(mapped.campusId).assertEqual('campus-main');
      expect(mapped.campusName).assertEqual('主校区');
      expect(mapped.locationGroupId).assertEqual('group-study');
      expect(mapped.locationGroupName).assertEqual('教学区');
      expect(mapped.tradeLocationId).assertEqual('location-library');
      expect(mapped.tradeLocationName).assertEqual('图书馆一楼大厅');
      expect(mapped.locationSafetyTips).assertEqual('建议白天交易并当场验货');
    });

    it('order_service_should_copy_structured_campus_location_fields_from_product', 0, () => {
      const now = Date.now();
      const product: Product = {
        id: 'location-product',
        sellerId: 'location-seller',
        title: '校园耳机',
        desc: '支持当面试听',
        price: 188,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        schoolId: 'school-hnrku',
        schoolName: '湖南人文科技学院',
        campusId: 'campus-main',
        campusName: '主校区',
        locationGroupId: 'group-study',
        locationGroupName: '教学区',
        tradeLocationId: 'location-library',
        tradeLocationName: '图书馆一楼大厅',
        locationSafetyTips: '建议白天交易并当场验货',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };

      productRepository.save(product);

      const result = orderService.createOrder('location-buyer', product.id, '图书馆一楼大厅，17:30 见');

      expect(result.ok).assertTrue();
      expect(result.data?.schoolId).assertEqual('school-hnrku');
      expect(result.data?.campusId).assertEqual('campus-main');
      expect(result.data?.locationGroupId).assertEqual('group-study');
      expect(result.data?.tradeLocationId).assertEqual('location-library');
      expect(result.data?.tradeLocationName).assertEqual('图书馆一楼大厅');
      expect(result.data?.locationSafetyTips).assertEqual('建议白天交易并当场验货');
    });
  });
}
