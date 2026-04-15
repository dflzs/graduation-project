import { describe, it, expect } from '@ohos/hypium';
import { canTransition, moveOrderStatus } from '../main/ets/services/order-state-machine';
import { promptAction, router } from '@kit.ArkUI';
import { appContext } from '../main/ets/app/app-context';
import { calculateCreditScore } from '../main/ets/services/credit.service.impl';
import { productRepository } from '../main/ets/repositories/product.repo';
import { orderRepository } from '../main/ets/repositories/order.repo';
import { chatRepository } from '../main/ets/repositories/chat.repo';
import { announcementRepository } from '../main/ets/repositories/announcement.repo';
import {
  canAccessAdmin,
  getAdminAccessDeniedMessage,
  getAdminActionDeniedMessage
} from '../main/ets/services/guard.service';
import { AuthServiceImpl, authService } from '../main/ets/services/auth.service.impl';
import { cartService } from '../main/ets/services/cart.service.impl';
import { productService } from '../main/ets/services/product.service.impl';
import { OrderServiceImpl, orderService } from '../main/ets/services/order.service.impl';
import { AnnouncementServiceImpl, announcementService } from '../main/ets/services/announcement.service.impl';
import { AdminDashboardServiceImpl } from '../main/ets/services/admin-dashboard.service.impl';
import { AdminProductServiceImpl } from '../main/ets/services/admin-product.service.impl';
import { AdminUserServiceImpl } from '../main/ets/services/admin-user.service.impl';
import { MarketplaceProductServiceImpl } from '../main/ets/services/marketplace-product.service.impl';
import { AuthStateService, authStateService } from '../main/ets/services/auth-state.service';
import { userRepository } from '../main/ets/repositories/user.repo';
import { CampusServiceImpl, mergeRemoteCampusProfile } from '../main/ets/services/campus.service.impl';
import { notificationService } from '../main/ets/services/notification.service.impl';
import { ChatServiceImpl, chatService } from '../main/ets/services/chat.service.impl';
import {
  Announcement,
  Campus,
  CartItem,
  LocationGroup,
  MessageNotification,
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
import { normalizePersistedLocalState } from '../main/ets/data/db/persisted-state';
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
import { mapRemoteOrderItem, RemoteOrderClient } from '../main/ets/services/order-remote.client';
import { RemoteCreateOrderPayload } from '../main/ets/types/order-remote';
import { RemoteChatClient } from '../main/ets/services/chat-remote.client';
import { RemoteAdminDashboardClient } from '../main/ets/services/admin-dashboard-remote.client';
import { RemoteAdminDashboardItem } from '../main/ets/types/admin-dashboard-remote';
import { RemoteProductClient } from '../main/ets/services/product-remote.client';
import {
  RemoteChatConversationItem,
  RemoteChatMessageItem,
  RemoteCreateConversationPayload
} from '../main/ets/types/chat-remote';
import { RemoteAnnouncementClient } from '../main/ets/services/announcement-remote.client';
import { RemoteAnnouncementItem } from '../main/ets/types/announcement-remote';
import { RemoteAdminUserClient } from '../main/ets/services/admin-user-remote.client';
import { RemoteAdminUserItem, RemoteAdminUserStatusPayload } from '../main/ets/types/admin-user-remote';
import { RemoteModerationClient, mapRemoteModerationItem } from '../main/ets/services/moderation-remote.client';
import { ModerationServiceImpl } from '../main/ets/services/moderation.service.impl';
import { moderationRepository } from '../main/ets/repositories/moderation.repo';
import { RemoteAppealClient } from '../main/ets/services/appeal-remote.client';
import { AppealServiceImpl } from '../main/ets/services/appeal.service.impl';
import { appealRepository } from '../main/ets/repositories/appeal.repo';
import { GovernanceServiceImpl } from '../main/ets/services/governance.service.impl';
import { governanceRepository } from '../main/ets/repositories/governance.repo';
import {
  AppealEligibility,
  AppealRecord,
  AppealStatus,
  GovernanceAction,
  GovernanceActionType,
  GovernanceUserSummary,
  ModerationRecord,
  ModerationStatus,
  ModerationTargetType
} from '../main/ets/types/domain';
import {
  RemoteAppealItem,
  RemoteAppealReviewPayload,
  RemoteAppealSubmitPayload
} from '../main/ets/types/appeal-remote';
import {
  RemoteGovernanceActionItem,
  RemoteGovernanceActionPayload,
  RemoteGovernanceCancelPayload,
  RemoteGovernanceUserSummaryItem
} from '../main/ets/types/governance-remote';
import {
  RemoteModerationItem,
  RemoteModerationReviewPayload,
  RemoteModerationSubmitPayload
} from '../main/ets/types/moderation-remote';
import { RemoteGovernanceClient } from '../main/ets/services/governance-remote.client';
import { canRequestRemoteProductDetail } from '../main/ets/utils/product-detail-source';
import {
  canAccessTradeRecord,
  canViewTradeHistory,
  canCurrentUserJoinTrade,
  canCurrentUserOperateTrade,
  canCurrentUserSendTradeMessage,
  canShowProductDetailContactAction,
  getTradeRecordUnavailableDescription,
  getTradeRecordUnavailableTitle,
  getProductDetailTradeHint,
  getTradeReadOnlyHint,
  shouldTreatTradeRecordAsAccessDenied,
  canUserAccessOrder,
  canUserTradeProduct,
  getTradeEntryDeniedMessage,
  getMarketplaceAudienceMode
} from '../main/ets/utils/trade-guard';
import {
  AnnouncementAudiencePresentation,
  buildMarketplaceUserSyncKeys,
  buildAnnouncementAudiencePresentation,
  buildCartAudiencePresentation,
  buildGovernanceCenterAudiencePresentation,
  MineTabAudiencePresentation,
  buildMineTabAudiencePresentation,
  MyPublishedAudiencePresentation,
  buildMyPublishedAudiencePresentation,
  buildMessageHubAudiencePresentation,
  OrderListAudiencePresentation,
  buildOrderListAudiencePresentation,
  shouldShowMarketplaceUnreadBadge
} from '../main/ets/utils/marketplace-audience-ui';
import {
  buildChatDetailReturnTarget,
  DetailReturnTarget,
  buildOrderDetailReturnTarget,
  resolveIndexRouteTab
} from '../main/ets/utils/detail-return-route';
import {
  canSubmitAppealForModerationRecord,
  getAppealReviewActions,
  getAppealReviewActionLabel
} from '../main/ets/utils/appeal-ui';
import {
  GovernanceTimelineStep,
  buildAppealTimelineSummary,
  buildGovernanceCenterTimelineLabel,
  buildModerationTimelineSteps
} from '../main/ets/utils/governance-timeline';
import {
  buildGovernanceCenterAppealBadgeLabel,
  buildGovernanceCenterAppealEmptyState,
  buildGovernanceCenterEntryActionLabel,
  buildGovernanceCenterAppealSubmitTitle,
  buildGovernanceCenterPageTitle,
  buildGovernanceCenterReviewCommentText,
  buildGovernanceCenterReviewCommentPrefix,
  buildGovernanceCenterSectionTitle,
  buildGovernanceCenterSubmittedMeta,
  buildGovernanceCenterSummaryCardCopy,
  buildGovernanceCenterTimelineTitle,
  getGovernanceCenterAppealStatusLabel,
  getGovernanceCenterModerationStatusLabel,
  getGovernanceCenterTargetLabel
} from '../main/ets/utils/governance-center-copy';
import {
  buildSubmitAppealPageHeading,
  buildSubmitAppealReasonLabel,
  buildSubmitAppealDescriptionLabel,
  buildSubmitAppealValidationMessage,
  buildSubmitModerationDescriptionPlaceholder,
  buildSubmitModerationDescriptionLabel,
  buildSubmitModerationPageTitle,
  buildSubmitModerationReasonLabel,
  buildSubmitModerationReasonSuggestions,
  buildSubmitModerationValidationMessage
} from '../main/ets/utils/moderation-submit-copy';
import {
  GovernanceActiveActionPresentation,
  GovernanceSummaryPresentation,
  buildGovernanceActiveActionPresentation,
  buildGovernanceSummaryPresentation
} from '../main/ets/utils/governance-summary-ui';
import {
  buildAppealNextStepGuidance,
  buildDefaultAppealReviewComment,
  buildDefaultModerationAdminComment,
  buildAppealResultSummary,
  buildGovernanceRecoveryCondition,
  buildModerationRecoveryGuidance,
  buildModerationResultSummary
} from '../main/ets/utils/governance-resolution-copy';
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
  buildMessageReminderTarget,
  countVisibleMessageHubUnread,
  filterMessageHubReminders,
  MessageReminderTarget
} from '../main/ets/utils/message-reminder-route';
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
  AdminModerationQueue,
  buildAdminModerationRecordMetaSummary,
  buildAdminModerationQueueSummary,
  getAdminModerationActionLabel,
  getAdminModerationAvailableActions,
  getAdminModerationRecommendedGovernanceAction,
  getAdminModerationPriorityLabel,
  getAdminModerationQueueDescription,
  getAdminModerationQueueLabel,
  getAdminModerationStatusLabel,
  getAdminModerationTargetLabel
} from '../main/ets/utils/admin-moderation-workbench';
import {
  buildAdminModerationBadgeLabel,
  buildAdminModerationCommentPlaceholder,
  buildAdminModerationDetailIntro,
  buildAdminModerationDetailTitle,
  buildAdminModerationEmptyState,
  buildAdminModerationErrorTitle,
  buildAdminModerationFactLabel,
  buildAdminModerationGuidanceTitle,
  buildAdminModerationHeaderDescription,
  buildAdminModerationLinkedRecordMeta,
  buildAdminModerationLoadingCopy,
  buildAdminModerationReviewCommentText,
  buildAdminModerationSelectionToast,
  buildAdminModerationUpdatedMeta,
  buildAdminModerationPageTitle,
  buildAdminModerationSummaryCardCopy,
  getAdminModerationAppealStatusLabel
} from '../main/ets/utils/admin-moderation-copy';
import {
  AdminUserStatusPresentation,
  buildAdminUserGovernanceActionPresentation,
  buildAdminUserStatusPresentation,
  buildAdminUserGovernanceSummaryPresentation,
  getAdminUserNextStatusActions
} from '../main/ets/utils/admin-user-governance-ui';
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
import {
  buildCampusTrustListSnippet,
  buildCampusTrustTonePalette,
  buildPublicCampusTrustPresentation
} from '../main/ets/utils/campus-trust-ui';
import {
  buildProfileVerificationLifecyclePresentation,
  buildVerificationEditorPresentation,
  buildVerificationAcademicSummary,
  buildVerificationCampusSummary,
  resolveDisplayedVerificationStatus
} from '../main/ets/utils/campus-verification-lifecycle-ui';
import { buildAdminDashboardSyncKeys, buildAdminGuardSyncKeys } from '../main/ets/utils/admin-dashboard-sync';

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
  listVerificationApplicationsCalled: boolean = false;
  reviewVerificationCalled: boolean = false;
  upsertSchoolCalled: boolean = false;
  upsertCampusCalled: boolean = false;
  upsertLocationGroupCalled: boolean = false;
  upsertTradeLocationCalled: boolean = false;
  updateTradeLocationStatusCalled: boolean = false;
  reviewVerificationResponse?: RemoteStudentVerificationResponse;

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
    this.listVerificationApplicationsCalled = true;
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
    this.reviewVerificationCalled = true;
    if (this.reviewVerificationResponse) {
      return {
        ok: true,
        message: '',
        data: this.reviewVerificationResponse
      };
    }
    return this.getCurrentVerification('');
  }

  async upsertSchool(_token: string, _schoolId: string, _payload: RemoteSchoolPayload): Promise<OperationResult<RemoteSchoolResponse>> {
    this.upsertSchoolCalled = true;
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
    this.upsertCampusCalled = true;
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
    this.upsertLocationGroupCalled = true;
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
    this.upsertTradeLocationCalled = true;
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
    this.updateTradeLocationStatusCalled = true;
    return this.upsertTradeLocation('', '', new RemoteTradeLocationPayload('', '', '', '', [], 0));
  }
}

class FakeRemoteOrderClient extends RemoteOrderClient {
  createOrderCalled: boolean = false;
  listMyOrdersCalled: boolean = false;
  getOrderDetailCalled: boolean = false;
  simulatePayCalled: boolean = false;
  cancelOrderCalled: boolean = false;
  markArrivedCalled: boolean = false;
  completeOrderCalled: boolean = false;
  failCreate: boolean = false;
  failList: boolean = false;
  failDetail: boolean = false;
  failPay: boolean = false;
  failCancel: boolean = false;
  failArrive: boolean = false;
  failComplete: boolean = false;
  lastCreateToken: string = '';
  lastCreatePayload?: RemoteCreateOrderPayload = undefined;
  createResponse?: OperationResult<Order> = undefined;
  lastListToken: string = '';
  listResponse?: OperationResult<Order[]> = undefined;
  lastDetailToken: string = '';
  lastDetailOrderId: string = '';
  detailResponse?: OperationResult<Order> = undefined;
  lastActionToken: string = '';
  lastActionOrderId: string = '';
  payResponse?: OperationResult<Order> = undefined;
  cancelResponse?: OperationResult<Order> = undefined;
  arriveResponse?: OperationResult<Order> = undefined;
  completeResponse?: OperationResult<Order> = undefined;

  constructor() {
    super('');
  }

  async createOrder(token: string, payload: RemoteCreateOrderPayload): Promise<OperationResult<Order>> {
    this.createOrderCalled = true;
    this.lastCreateToken = token;
    this.lastCreatePayload = payload;
    if (this.failCreate) {
      return { ok: false, message: '远端下单失败' };
    }
    if (this.createResponse) {
      return this.createResponse;
    }
    return {
      ok: true,
      message: '远端下单成功',
      data: {
        id: '3001',
        productId: payload.product_id,
        buyerId: '2001',
        sellerId: '2002',
        amount: 58.5,
        address: payload.address,
        locationTag: payload.location_tag,
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: 1,
        updatedAt: 2
      }
    };
  }

  async listMyOrders(_token: string): Promise<OperationResult<Order[]>> {
    this.lastListToken = _token;
    this.listMyOrdersCalled = true;
    if (this.failList) {
      return { ok: false, message: '远端订单列表失败' };
    }
    if (this.listResponse) {
      return this.listResponse;
    }
    return { ok: true, message: '获取订单列表成功', data: [] };
  }

  async getOrderDetail(_token: string, _orderId: string): Promise<OperationResult<Order>> {
    this.lastDetailToken = _token;
    this.lastDetailOrderId = _orderId;
    this.getOrderDetailCalled = true;
    if (this.failDetail) {
      return { ok: false, message: '远端订单详情失败' };
    }
    if (this.detailResponse) {
      return this.detailResponse;
    }
    return { ok: false, message: '未提供订单详情' };
  }

  async simulatePay(token: string, orderId: string): Promise<OperationResult<Order>> {
    this.simulatePayCalled = true;
    this.lastActionToken = token;
    this.lastActionOrderId = orderId;
    if (this.failPay) {
      return { ok: false, message: '远端支付失败' };
    }
    if (this.payResponse) {
      return this.payResponse;
    }
    return { ok: false, message: '未提供远端支付结果' };
  }

  async cancelOrder(token: string, orderId: string): Promise<OperationResult<Order>> {
    this.cancelOrderCalled = true;
    this.lastActionToken = token;
    this.lastActionOrderId = orderId;
    if (this.failCancel) {
      return { ok: false, message: '远端取消失败' };
    }
    if (this.cancelResponse) {
      return this.cancelResponse;
    }
    return { ok: false, message: '未提供远端取消结果' };
  }

  async markArrived(token: string, orderId: string): Promise<OperationResult<Order>> {
    this.markArrivedCalled = true;
    this.lastActionToken = token;
    this.lastActionOrderId = orderId;
    if (this.failArrive) {
      return { ok: false, message: '远端到场失败' };
    }
    if (this.arriveResponse) {
      return this.arriveResponse;
    }
    return { ok: false, message: '未提供远端到场结果' };
  }

  async completeOrder(token: string, orderId: string): Promise<OperationResult<Order>> {
    this.completeOrderCalled = true;
    this.lastActionToken = token;
    this.lastActionOrderId = orderId;
    if (this.failComplete) {
      return { ok: false, message: '远端完结失败' };
    }
    if (this.completeResponse) {
      return this.completeResponse;
    }
    return { ok: false, message: '未提供远端完结结果' };
  }
}

class FakeRemoteChatClient extends RemoteChatClient {
  listConversationsCalled: boolean = false;
  getMessagesCalled: boolean = false;
  createConversationCalled: boolean = false;
  sendMessageCalled: boolean = false;
  failListConversations: boolean = false;
  failGetMessages: boolean = false;
  failCreateConversation: boolean = false;
  failSendMessage: boolean = false;
  lastListToken: string = '';
  lastMessagesToken: string = '';
  lastMessagesThreadId: string = '';
  lastCreateToken: string = '';
  lastCreatePayload?: RemoteCreateConversationPayload = undefined;
  lastSendToken: string = '';
  lastSendThreadId: string = '';
  lastSendContent: string = '';
  conversationResponse?: OperationResult<RemoteChatConversationItem> = undefined;
  conversationsResponse?: OperationResult<RemoteChatConversationItem[]> = undefined;
  messagesResponse?: OperationResult<RemoteChatMessageItem[]> = undefined;
  sendResponse?: OperationResult<RemoteChatMessageItem> = undefined;

  constructor() {
    super('');
  }

  async listConversations(token: string): Promise<OperationResult<RemoteChatConversationItem[]>> {
    this.listConversationsCalled = true;
    this.lastListToken = token;
    if (this.failListConversations) {
      return { ok: false, message: '远端会话列表失败' };
    }
    if (this.conversationsResponse) {
      return this.conversationsResponse;
    }
    return { ok: true, message: '获取会话列表成功', data: [] };
  }

  async getMessages(token: string, conversationId: string): Promise<OperationResult<RemoteChatMessageItem[]>> {
    this.getMessagesCalled = true;
    this.lastMessagesToken = token;
    this.lastMessagesThreadId = conversationId;
    if (this.failGetMessages) {
      return { ok: false, message: '远端消息列表失败' };
    }
    if (this.messagesResponse) {
      return this.messagesResponse;
    }
    return { ok: true, message: '获取聊天记录成功', data: [] };
  }

  async createConversation(
    token: string,
    payload: RemoteCreateConversationPayload
  ): Promise<OperationResult<RemoteChatConversationItem>> {
    this.createConversationCalled = true;
    this.lastCreateToken = token;
    this.lastCreatePayload = payload;
    if (this.failCreateConversation) {
      return { ok: false, message: '远端创建会话失败' };
    }
    if (this.conversationResponse) {
      return this.conversationResponse;
    }
    return {
      ok: true,
      message: '远端创建会话成功',
      data: {
        id: '9101',
        product_id: payload.product_id,
        order_id: payload.order_id ?? '',
        buyer_id: 'buyer-remote',
        seller_id: 'seller-remote',
        last_message: '',
        last_message_at: 0,
        created_at: 1,
        product_title: '远端会话商品',
        buyer_nickname: '远端买家',
        seller_nickname: '远端卖家',
        unread_count: 0
      }
    };
  }

  async sendMessage(
    token: string,
    conversationId: string,
    content: string
  ): Promise<OperationResult<RemoteChatMessageItem>> {
    this.sendMessageCalled = true;
    this.lastSendToken = token;
    this.lastSendThreadId = conversationId;
    this.lastSendContent = content;
    if (this.failSendMessage) {
      return { ok: false, message: '远端发送消息失败' };
    }
    if (this.sendResponse) {
      return this.sendResponse;
    }
    return {
      ok: true,
      message: '远端发送消息成功',
      data: {
        id: 'message-remote-default',
        conversation_id: conversationId,
        from_user_id: 'buyer-remote',
        to_user_id: 'seller-remote',
        content,
        is_read: false,
        created_at: 2
      }
    };
  }
}

class FakeRemoteAnnouncementClient extends RemoteAnnouncementClient {
  listCalled: boolean = false;
  publishCalled: boolean = false;
  deleteCalled: boolean = false;
  failList: boolean = false;
  failPublish: boolean = false;
  failDelete: boolean = false;
  lastPublishToken: string = '';
  lastPublishTitle: string = '';
  lastPublishContent: string = '';
  lastDeleteToken: string = '';
  lastDeleteId: string = '';
  listResponse?: OperationResult<RemoteAnnouncementItem[]> = undefined;
  publishResponse?: OperationResult<RemoteAnnouncementItem> = undefined;
  deleteResponse?: OperationResult<string> = undefined;

  constructor() {
    super('');
  }

  async listAnnouncements(): Promise<OperationResult<RemoteAnnouncementItem[]>> {
    this.listCalled = true;
    if (this.failList) {
      return { ok: false, message: '远端公告列表失败' };
    }
    if (this.listResponse) {
      return this.listResponse;
    }
    return { ok: true, message: '获取公告列表成功', data: [] };
  }

  async publishAnnouncement(
    token: string,
    title: string,
    content: string
  ): Promise<OperationResult<RemoteAnnouncementItem>> {
    this.publishCalled = true;
    this.lastPublishToken = token;
    this.lastPublishTitle = title;
    this.lastPublishContent = content;
    if (this.failPublish) {
      return { ok: false, message: '远端公告发布失败' };
    }
    if (this.publishResponse) {
      return this.publishResponse;
    }
    return {
      ok: true,
      message: '公告发布成功',
      data: {
        id: 'announcement-remote-default',
        title,
        content,
        publisher_id: 'admin-remote',
        is_deleted: 0,
        created_at: 1,
        updated_at: 2
      }
    };
  }

  async deleteAnnouncement(token: string, announcementId: string): Promise<OperationResult<string>> {
    this.deleteCalled = true;
    this.lastDeleteToken = token;
    this.lastDeleteId = announcementId;
    if (this.failDelete) {
      return { ok: false, message: '远端公告删除失败' };
    }
    if (this.deleteResponse) {
      return this.deleteResponse;
    }
    return { ok: true, message: '公告删除成功', data: announcementId };
  }
}

class FakeRemoteAdminUserClient extends RemoteAdminUserClient {
  listCalled: boolean = false;
  updateStatusCalled: boolean = false;
  failList: boolean = false;
  failUpdateStatus: boolean = false;
  listResponse?: OperationResult<RemoteAdminUserItem[]> = undefined;
  updateStatusResponse?: OperationResult<RemoteAdminUserItem> = undefined;
  lastUpdateToken: string = '';
  lastUpdateUserId: string = '';
  lastUpdatePayload?: RemoteAdminUserStatusPayload = undefined;

  constructor() {
    super('');
  }

  async listUsers(token: string): Promise<OperationResult<RemoteAdminUserItem[]>> {
    this.listCalled = true;
    if (this.failList) {
      return { ok: false, message: '远端用户列表失败' };
    }
    if (this.listResponse) {
      return this.listResponse;
    }
    return {
      ok: true,
      message: '获取用户列表成功',
      data: []
    };
  }

  async updateUserStatus(
    token: string,
    userId: string,
    payload: RemoteAdminUserStatusPayload
  ): Promise<OperationResult<RemoteAdminUserItem>> {
    this.updateStatusCalled = true;
    this.lastUpdateToken = token;
    this.lastUpdateUserId = userId;
    this.lastUpdatePayload = payload;
    if (this.failUpdateStatus) {
      return { ok: false, message: '远端更新用户状态失败' };
    }
    if (this.updateStatusResponse) {
      return this.updateStatusResponse;
    }
    return {
      ok: true,
      message: payload.status === 'banned' ? '用户封禁成功' : '用户恢复成功',
      data: {
        id: userId,
        phone: '18800000000',
        nickname: '远端用户',
        avatar: '',
        role: 'user',
        status: payload.status,
        credit_score: 80,
        created_at: 1,
        updated_at: 2
      }
    };
  }
}

class FakeRemoteAdminDashboardClient extends RemoteAdminDashboardClient {
  getDashboardCalled: boolean = false;
  failGetDashboard: boolean = false;
  response?: OperationResult<RemoteAdminDashboardItem>;
  lastToken: string = '';

  async getDashboard(token: string): Promise<OperationResult<RemoteAdminDashboardItem>> {
    this.getDashboardCalled = true;
    this.lastToken = token;
    if (this.failGetDashboard) {
      return { ok: false, message: '远端后台概览失败' };
    }
    return this.response ?? {
      ok: true,
      message: '远端后台概览成功',
      data: {
        user_count: 12,
        product_count: 8,
        order_count: 6,
        completed_order_count: 3,
        announcement_count: 2
      }
    };
  }
}

class FakeRemoteModerationClient extends RemoteModerationClient {
  submitCalled: boolean = false;
  listCalled: boolean = false;
  listMyCalled: boolean = false;
  reviewCalled: boolean = false;
  failSubmit: boolean = false;
  failList: boolean = false;
  failReview: boolean = false;
  lastToken: string = '';
  lastListStatus?: ModerationStatus = undefined;
  lastSubmitPayload?: RemoteModerationSubmitPayload = undefined;
  lastReviewId: string = '';
  lastReviewPayload?: RemoteModerationReviewPayload = undefined;
  submitResponse?: OperationResult<ModerationRecord> = undefined;
  listResponse?: OperationResult<ModerationRecord[]> = undefined;
  reviewResponse?: OperationResult<ModerationRecord> = undefined;

  constructor() {
    super('');
  }

  async submitRecord(
    token: string,
    payload: RemoteModerationSubmitPayload
  ): Promise<OperationResult<ModerationRecord>> {
    this.submitCalled = true;
    this.lastToken = token;
    this.lastSubmitPayload = payload;
    if (this.failSubmit) {
      return { ok: false, message: '远端举报提交失败' };
    }
    if (this.submitResponse) {
      return this.submitResponse;
    }
    return {
      ok: true,
      message: '举报提交成功',
      data: {
        id: 'moderation-remote-default',
        reporterId: 'reporter-default',
        targetType: payload.target_type,
        targetId: payload.target_id,
        reason: payload.reason,
        description: payload.description,
        status: 'pending',
        createdAt: 1,
        updatedAt: 2
      }
    };
  }

  async listRecords(token: string, status?: ModerationStatus): Promise<OperationResult<ModerationRecord[]>> {
    this.listCalled = true;
    this.lastToken = token;
    this.lastListStatus = status;
    if (this.failList) {
      return { ok: false, message: '远端举报列表失败' };
    }
    if (this.listResponse) {
      return this.listResponse;
    }
    return { ok: true, message: '获取举报列表成功', data: [] };
  }

  async listMyRecords(token: string): Promise<OperationResult<ModerationRecord[]>> {
    this.listMyCalled = true;
    this.lastToken = token;
    if (this.failList) {
      return { ok: false, message: '远端我的治理记录失败' };
    }
    if (this.listResponse) {
      return this.listResponse;
    }
    return { ok: true, message: '获取我的治理记录成功', data: [] };
  }

  async reviewRecord(
    token: string,
    recordId: string,
    payload: RemoteModerationReviewPayload
  ): Promise<OperationResult<ModerationRecord>> {
    this.reviewCalled = true;
    this.lastToken = token;
    this.lastReviewId = recordId;
    this.lastReviewPayload = payload;
    if (this.failReview) {
      return { ok: false, message: '远端举报审核失败' };
    }
    if (this.reviewResponse) {
      return this.reviewResponse;
    }
    return {
      ok: true,
      message: '举报审核成功',
      data: {
        id: recordId,
        reporterId: 'reporter-default',
        targetType: 'chat_report',
        targetId: 'thread-default',
        reason: '默认原因',
        description: '默认说明',
        status: payload.status,
        adminComment: payload.admin_comment,
        reviewedBy: 'admin-default',
        reviewedAt: 3,
        createdAt: 1,
        updatedAt: 3
      }
    };
  }
}

class FakeRemoteAppealClient extends RemoteAppealClient {
  submitCalled: boolean = false;
  listMyCalled: boolean = false;
  listAdminCalled: boolean = false;
  reviewCalled: boolean = false;
  failSubmit: boolean = false;
  failListMy: boolean = false;
  failListAdmin: boolean = false;
  failReview: boolean = false;
  lastToken: string = '';
  lastAppealId: string = '';
  lastReviewPayload?: RemoteAppealReviewPayload = undefined;
  submitResponse?: OperationResult<AppealRecord> = undefined;
  listMyResponse?: OperationResult<AppealRecord[]> = undefined;
  listAdminResponse?: OperationResult<AppealRecord[]> = undefined;
  reviewResponse?: OperationResult<AppealRecord> = undefined;

  constructor() {
    super('');
  }

  async submitAppeal(
    token: string,
    payload: RemoteAppealSubmitPayload
  ): Promise<OperationResult<AppealRecord>> {
    this.submitCalled = true;
    this.lastToken = token;
    if (this.failSubmit) {
      return { ok: false, message: '远端申诉提交失败' };
    }
    if (this.submitResponse) {
      return this.submitResponse;
    }
    return {
      ok: true,
      message: '申诉提交成功',
      data: {
        id: 'appeal-remote-default',
        moderationRecordId: payload.moderation_record_id,
        appellantId: 'appellant-default',
        reason: payload.reason,
        description: payload.description,
        evidenceItems: payload.evidence_items,
        status: 'pending',
        createdAt: 1,
        updatedAt: 2
      }
    };
  }

  async listMyAppeals(token: string): Promise<OperationResult<AppealRecord[]>> {
    this.listMyCalled = true;
    this.lastToken = token;
    if (this.failListMy) {
      return { ok: false, message: '远端我的申诉列表失败' };
    }
    if (this.listMyResponse) {
      return this.listMyResponse;
    }
    return { ok: true, message: '获取我的申诉成功', data: [] };
  }

  async listAppeals(token: string, status?: AppealStatus): Promise<OperationResult<AppealRecord[]>> {
    this.listAdminCalled = true;
    this.lastToken = token;
    if (this.failListAdmin) {
      return { ok: false, message: '远端后台申诉列表失败' };
    }
    if (this.listAdminResponse) {
      return this.listAdminResponse;
    }
    return { ok: true, message: '获取后台申诉成功', data: [] };
  }

  async reviewAppeal(
    token: string,
    appealId: string,
    payload: RemoteAppealReviewPayload
  ): Promise<OperationResult<AppealRecord>> {
    this.reviewCalled = true;
    this.lastToken = token;
    this.lastAppealId = appealId;
    this.lastReviewPayload = payload;
    if (this.failReview) {
      return { ok: false, message: '远端申诉审核失败' };
    }
    if (this.reviewResponse) {
      return this.reviewResponse;
    }
    return {
      ok: true,
      message: '申诉审核完成',
      data: {
        id: appealId,
        moderationRecordId: 'moderation-default',
        appellantId: 'appellant-default',
        reason: '默认申诉原因',
        description: '默认申诉说明',
        evidenceItems: [],
        status: payload.status,
        reviewComment: payload.review_comment,
        createdAt: 1,
        updatedAt: 2
      }
    };
  }
}

class FakeRemoteGovernanceClient extends RemoteGovernanceClient {
  createCalled: boolean = false;
  listCalled: boolean = false;
  listByUserCalled: boolean = false;
  cancelCalled: boolean = false;
  summaryCalled: boolean = false;
  failCreate: boolean = false;
  failList: boolean = false;
  failCancel: boolean = false;
  failSummary: boolean = false;
  lastToken: string = '';
  lastUserId: string = '';
  lastActionId: string = '';
  lastCreatePayload?: RemoteGovernanceActionPayload = undefined;
  lastCancelPayload?: RemoteGovernanceCancelPayload = undefined;
  createResponse?: OperationResult<GovernanceAction> = undefined;
  listResponse?: OperationResult<GovernanceAction[]> = undefined;
  summaryResponse?: OperationResult<GovernanceUserSummary> = undefined;

  constructor() {
    super('');
  }

  async createAction(
    token: string,
    payload: RemoteGovernanceActionPayload
  ): Promise<OperationResult<GovernanceAction>> {
    this.createCalled = true;
    this.lastToken = token;
    this.lastCreatePayload = payload;
    if (this.failCreate) {
      return { ok: false, message: '远端治理动作创建失败' };
    }
    if (this.createResponse) {
      return this.createResponse;
    }
    return {
      ok: true,
      message: '治理动作创建成功',
      data: {
        id: 'governance-action-default',
        userId: payload.user_id,
        sourceType: payload.source_type,
        sourceId: payload.source_id,
        actionType: payload.action_type,
        reason: payload.reason,
        comment: payload.comment,
        startAt: payload.start_at,
        endAt: payload.end_at,
        active: true,
        createdBy: payload.created_by,
        createdAt: payload.start_at,
        updatedAt: payload.start_at
      }
    };
  }

  async listActions(token: string): Promise<OperationResult<GovernanceAction[]>> {
    this.listCalled = true;
    this.lastToken = token;
    if (this.failList) {
      return { ok: false, message: '远端治理动作列表失败' };
    }
    return this.listResponse ?? { ok: true, message: '获取治理动作列表成功', data: [] };
  }

  async listActionsByUser(token: string, userId: string): Promise<OperationResult<GovernanceAction[]>> {
    this.listByUserCalled = true;
    this.lastToken = token;
    this.lastUserId = userId;
    if (this.failList) {
      return { ok: false, message: '远端用户治理动作失败' };
    }
    return this.listResponse ?? { ok: true, message: '获取用户治理动作成功', data: [] };
  }

  async cancelAction(
    token: string,
    actionId: string,
    payload: RemoteGovernanceCancelPayload
  ): Promise<OperationResult<GovernanceAction>> {
    this.cancelCalled = true;
    this.lastToken = token;
    this.lastActionId = actionId;
    this.lastCancelPayload = payload;
    if (this.failCancel) {
      return { ok: false, message: '远端取消治理动作失败' };
    }
    if (this.createResponse) {
      return this.createResponse;
    }
    return {
      ok: true,
      message: '治理动作已取消',
      data: {
        id: actionId,
        userId: 'governance-user-default',
        sourceType: 'manual_admin',
        sourceId: 'manual-default',
        actionType: 'warning',
        reason: '默认治理动作',
        comment: payload.comment,
        startAt: 1,
        active: false,
        createdBy: payload.canceled_by,
        createdAt: 1,
        updatedAt: 2,
        canceledAt: 2,
        canceledBy: payload.canceled_by
      }
    };
  }

  async getUserSummary(token: string, userId: string): Promise<OperationResult<GovernanceUserSummary>> {
    this.summaryCalled = true;
    this.lastToken = token;
    this.lastUserId = userId;
    if (this.failSummary) {
      return { ok: false, message: '远端治理摘要失败' };
    }
    return this.summaryResponse ?? {
      ok: true,
      message: '获取治理摘要成功',
      data: {
        userId,
        activeActionTypes: [],
        totalActionCount: 0,
        openCaseCount: 0,
        latestActionAt: 0
      }
    };
  }
}

class FakeRemoteAdminProductClient extends RemoteProductClient {
  listAdminProductsCalled: boolean = false;
  approveProductCalled: boolean = false;
  rejectProductCalled: boolean = false;
  forceOffShelfProductCalled: boolean = false;
  failListAdminProducts: boolean = false;
  failApproveProduct: boolean = false;
  lastToken: string = '';
  lastProductId: string = '';
  listAdminProductsResponse?: OperationResult<Product[]> = undefined;
  approveProductResponse?: OperationResult<Product> = undefined;

  constructor() {
    super('');
  }

  async listAdminProducts(token: string): Promise<OperationResult<Product[]>> {
    this.listAdminProductsCalled = true;
    this.lastToken = token;
    if (this.failListAdminProducts) {
      return { ok: false, message: '远端后台商品列表失败' };
    }
    return this.listAdminProductsResponse ?? { ok: true, message: '远端后台商品列表成功', data: [] };
  }

  async approveProduct(token: string, productId: string): Promise<OperationResult<Product>> {
    this.approveProductCalled = true;
    this.lastToken = token;
    this.lastProductId = productId;
    if (this.failApproveProduct) {
      return { ok: false, message: '远端审核商品失败' };
    }
    return this.approveProductResponse ?? { ok: false, message: '未提供远端商品审核结果' };
  }
}

class FakeRemoteMarketplaceProductClient extends RemoteProductClient {
  listProductsCalled: boolean = false;
  listMyProductsCalled: boolean = false;
  getProductDetailCalled: boolean = false;
  createProductCalled: boolean = false;
  failListProducts: boolean = false;
  failListMyProducts: boolean = false;
  failGetProductDetail: boolean = false;
  failCreateProduct: boolean = false;
  lastToken: string = '';
  lastProductId: string = '';
  lastCreatePayload?: RemoteCreateProductPayload = undefined;
  listProductsResponse?: OperationResult<Product[]> = undefined;
  listMyProductsResponse?: OperationResult<Product[]> = undefined;
  getProductDetailResponse?: OperationResult<Product> = undefined;
  createProductResponse?: OperationResult<Product> = undefined;

  constructor() {
    super('');
  }

  async listProducts(): Promise<OperationResult<Product[]>> {
    this.listProductsCalled = true;
    if (this.failListProducts) {
      return { ok: false, message: '远端公开商品列表失败' };
    }
    return this.listProductsResponse ?? { ok: true, message: '远端公开商品列表成功', data: [] };
  }

  async listMyProducts(token: string): Promise<OperationResult<Product[]>> {
    this.listMyProductsCalled = true;
    this.lastToken = token;
    if (this.failListMyProducts) {
      return { ok: false, message: '远端我的发布失败' };
    }
    return this.listMyProductsResponse ?? { ok: true, message: '远端我的发布成功', data: [] };
  }

  async getProductDetail(productId: string): Promise<OperationResult<Product>> {
    this.getProductDetailCalled = true;
    this.lastProductId = productId;
    if (this.failGetProductDetail) {
      return { ok: false, message: '远端商品详情失败' };
    }
    return this.getProductDetailResponse ?? { ok: false, message: '未提供远端商品详情结果' };
  }

  async createProduct(token: string, payload: RemoteCreateProductPayload): Promise<OperationResult<Product>> {
    this.createProductCalled = true;
    this.lastToken = token;
    this.lastCreatePayload = payload;
    if (this.failCreateProduct) {
      return { ok: false, message: '远端发布商品失败' };
    }
    return this.createProductResponse ?? { ok: false, message: '未提供远端发布商品结果' };
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

    it('auth_state_should_keep_banned_user_as_restricted_session_when_restoring_local_state', 0, () => {
      const adapter = new MemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const bannedUser: User = {
        id: 'restore-banned-user',
        phone: '18800009999',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 30,
        createdAt: 1,
        updatedAt: 2
      };

      stateService.saveSession({
        currentUser: bannedUser,
        token: 'restricted-token',
        expiresAt: Date.now() + 3600 * 1000
      });

      const restoredService = new AuthServiceImpl(new FakeRemoteAuthClient(), stateService);
      const restoredSession = restoredService.restoreSession();

      expect(restoredSession !== null).assertTrue();
      expect(restoredSession?.currentUser.id).assertEqual(bannedUser.id);
      expect(restoredSession?.currentUser.status).assertEqual('banned');
      expect(getMarketplaceAudienceMode(restoredSession?.currentUser ?? null)).assertEqual('restricted');
    });

    it('auth_state_should_keep_suspended_user_as_restricted_session_when_restoring_local_state', 0, () => {
      const adapter = new MemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const suspendedUser: User = {
        id: 'restore-suspended-user',
        phone: '18800008888',
        nickname: '暂停用户',
        role: 'user',
        status: 'suspended',
        creditScore: 40,
        createdAt: 1,
        updatedAt: 2
      };

      stateService.saveSession({
        currentUser: suspendedUser,
        token: 'suspended-token',
        expiresAt: Date.now() + 3600 * 1000
      });

      const restoredService = new AuthServiceImpl(new FakeRemoteAuthClient(), stateService);
      const restoredSession = restoredService.restoreSession();

      expect(restoredSession !== null).assertTrue();
      expect(restoredSession?.currentUser.status).assertEqual('suspended');
      expect(getMarketplaceAudienceMode(restoredSession?.currentUser ?? null)).assertEqual('restricted');
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

      const createOrderResult = await orderService.createOrder(buyer.id, product.id, '宿舍楼门口');
      expect(createOrderResult.ok).assertTrue();
      expect(notificationService.listByUser(buyer.id)[0].type).assertEqual('order_created');

      const cancelOrderResult = await orderService.cancelOrder(createOrderResult.data!.id, buyer.id);
      expect(cancelOrderResult.ok).assertTrue();
      expect(notificationService.listByUser(buyer.id)[0].type).assertEqual('order_canceled');

      const secondOrderResult = await orderService.createOrder(buyer.id, product.id, '宿舍楼门口');
      expect(secondOrderResult.ok).assertTrue();
      const payResult = await orderService.simulatePay(secondOrderResult.data!.id, buyer.id);
      expect(payResult.ok).assertTrue();
      const buyerArrived = await orderService.markArrived(secondOrderResult.data!.id, buyer.id);
      expect(buyerArrived.ok).assertTrue();
      const sellerArrived = await orderService.markArrived(secondOrderResult.data!.id, seller.id);
      expect(sellerArrived.ok).assertTrue();
      const completeResult = await orderService.completeOrder(secondOrderResult.data!.id, buyer.id);
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
      const threadResult = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      const sendMessageResult = await chatService.sendMessage(threadResult.data!, seller.id, '你好，这件商品还在');
      expect(sendMessageResult.ok).assertTrue();

      const reminderUnread = notificationService.countUnread(buyer.id);
      const threadUnread = await chatService.countUnread(buyer.id);
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

    it('user_repository_should_publish_admin_status_change_when_toggling_user_status', 0, () => {
      const userId = `admin-status-${Date.now()}`;
      userRepository.save({
        id: userId,
        phone: '18877770001',
        nickname: '状态切换用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: Date.now(),
        updatedAt: Date.now()
      });

      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('admin:user-status-changed', (payload) => {
        syncValues.push(payload.value);
      });

      const updated = userRepository.updateStatus(userId, 'banned');

      unsubscribe();

      expect(updated?.status ?? '').assertEqual('banned');
      expect(syncValues.length > 0).assertTrue();
      expect(syncValues[syncValues.length - 1]).assertEqual(userId);
    });

    it('user_repository_should_publish_users_changed_when_toggling_user_status', 0, () => {
      const userId = `user-status-sync-${Date.now()}`;
      userRepository.save({
        id: userId,
        phone: '18877770011',
        nickname: '通用状态同步用户',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: Date.now(),
        updatedAt: Date.now()
      });

      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('users:changed', (payload) => {
        syncValues.push(payload.value);
      });

      const updated = userRepository.updateStatus(userId, 'banned');

      unsubscribe();

      expect(updated?.status ?? '').assertEqual('banned');
      expect(syncValues.length > 0).assertTrue();
      expect(syncValues[syncValues.length - 1]).assertEqual(userId);
    });

    it('user_repository_should_publish_users_changed_when_saving_user_records', 0, () => {
      const userId = `user-sync-${Date.now()}`;
      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('users:changed', (payload) => {
        syncValues.push(payload.value);
      });

      userRepository.save({
        id: userId,
        phone: '18877770002',
        nickname: '用户同步测试',
        role: 'user',
        status: 'active',
        creditScore: 82,
        createdAt: Date.now(),
        updatedAt: Date.now()
      });

      unsubscribe();

      expect(syncValues.length > 0).assertTrue();
      expect(syncValues[syncValues.length - 1]).assertEqual(userId);
    });

    it('user_repository_should_not_publish_users_changed_for_identical_save_payloads', 0, () => {
      const userId = `user-sync-stable-${Date.now()}`;
      const stableUser: User = {
        id: userId,
        phone: '18877770003',
        nickname: '稳定用户',
        role: 'user',
        status: 'active',
        creditScore: 84,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      userRepository.save(stableUser);

      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('users:changed', (payload) => {
        syncValues.push(payload.value);
      });
      const baselineSignalCount = syncValues.length;

      userRepository.save(stableUser);

      unsubscribe();

      expect(syncValues.length).assertEqual(baselineSignalCount);
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

      const firstThread = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(firstThread.ok).assertTrue();

      const sendMessage = await chatService.sendMessage(firstThread.data!, buyer.id, '你好，请问今晚方便面交吗？');
      expect(sendMessage.ok).assertTrue();

      const reusedThread = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(reusedThread.ok).assertTrue();
      expect(reusedThread.data).assertEqual(firstThread.data);

      const buyerThreads = await chatService.listThreads(buyer.id);
      expect(buyerThreads.length > 0).assertTrue();
      expect(buyerThreads[0].productId).assertEqual(product.id);
      expect(buyerThreads[0].lastMessage).assertEqual('你好，请问今晚方便面交吗？');

      const threadMessages = await chatService.getMessages(firstThread.data!, buyer.id);
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

      const threadResult = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      await chatService.sendMessage(threadResult.data!, buyer.id, '第一条消息');
      await chatService.sendMessage(threadResult.data!, seller.id, '第二条消息');

      const messages = await chatService.getMessages(threadResult.data!, seller.id);
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

      const threadResult = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      expect((await chatService.sendMessage(threadResult.data!, buyer.id, '这件商品还在吗？')).ok).assertTrue();

      testAuthService.logout();
      const outsiderLogin = await testAuthService.loginByPhone(outsiderPhone, '123456');
      expect(outsiderLogin.ok).assertTrue();
      const outsider = outsiderLogin.data!.currentUser;

      expect(chatService.getThread(threadResult.data!, outsider.id)).assertNull();
      expect((await chatService.getMessages(threadResult.data!, outsider.id)).length).assertEqual(0);
      const blockedSend = await chatService.sendMessage(threadResult.data!, outsider.id, '我也想买');
      expect(blockedSend.ok).assertFalse();
      expect(blockedSend.message).assertEqual('仅交易双方可发送消息');
    });

    it('chat_service_should_only_expose_messages_to_trade_participants_or_restricted_participants', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('186', timestamp, 0);
      const buyerPhone: string = buildTestPhone('176', timestamp, 1);
      const outsiderPhone: string = buildTestPhone('166', timestamp, 2);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '会话消息可见性测试商品',
        desc: '验证消息只对交易参与方开放',
        price: 88,
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

      const threadResult = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      expect((await chatService.sendMessage(threadResult.data!, buyer.id, '这件商品现在还能面交吗？')).ok).assertTrue();

      userRepository.updateStatus(buyer.id, 'banned');

      const restrictedMessages = await chatService.getMessages(threadResult.data!, buyer.id);
      expect(restrictedMessages.length).assertEqual(1);
      expect(restrictedMessages[0].content).assertEqual('这件商品现在还能面交吗？');

      testAuthService.logout();
      const outsiderLogin = await testAuthService.loginByPhone(outsiderPhone, '123456');
      expect(outsiderLogin.ok).assertTrue();
      const outsider = outsiderLogin.data!.currentUser;

      const outsiderMessages = await chatService.getMessages(threadResult.data!, outsider.id);
      expect(outsiderMessages.length).assertEqual(0);
    });

    it('chat_service_should_allow_restricted_participants_to_view_history_in_read_only_mode', 0, async () => {
      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('182', timestamp, 0);
      const buyerPhone: string = buildTestPhone('172', timestamp, 1);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());

      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createProduct = productService.createProduct({
        title: '受限只读聊天测试商品',
        desc: '封禁后仍应允许查看历史聊天',
        price: 66,
        category: '电子数码',
        locationTag: '实验楼门口',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      testAuthService.logout();
      const buyerLogin = await testAuthService.loginByPhone(buyerPhone, '123456');
      expect(buyerLogin.ok).assertTrue();
      const buyer = buyerLogin.data!.currentUser;

      const threadResult = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      expect((await chatService.sendMessage(threadResult.data!, buyer.id, '我想周五面交')).ok).assertTrue();

      userRepository.updateStatus(buyer.id, 'banned');

      const restrictedThread = chatService.getThread(threadResult.data!, buyer.id);
      expect(restrictedThread !== null).assertTrue();
      expect(restrictedThread?.id).assertEqual(threadResult.data!);

      chatService.markThreadRead(threadResult.data!, buyer.id);
      const afterRead = chatService.getThread(threadResult.data!, buyer.id);
      expect(afterRead?.unreadCount).assertEqual(0);

      const blockedSend = await chatService.sendMessage(threadResult.data!, buyer.id, '我还能继续发消息吗');
      expect(blockedSend.ok).assertFalse();
      expect(blockedSend.message.includes('停用') || blockedSend.message.includes('无法')).assertTrue();
    });

    it('chat_service_should_reject_admin_users_from_opening_trade_threads', 0, async () => {
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

      const result = await chatService.openProductThread(product.id, admin.id, seller.id);
      expect(result.ok).assertFalse();
      expect(result.message).assertEqual('管理员账号不支持参与商品沟通');
    });

    it('chat_service_should_allow_muted_user_to_read_history_but_block_sending_new_messages', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'chat-muted-seller',
        phone: '18800005666',
        nickname: '卖家',
        role: 'user',
        status: 'active',
        creditScore: 85,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'chat-muted-buyer',
        phone: '18800005667',
        nickname: '买家',
        role: 'user',
        status: 'active',
        creditScore: 83,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: 'chat-muted-product',
        sellerId: seller.id,
        title: '禁言查看历史测试商品',
        desc: '禁言后可看历史但不可发消息',
        price: 42,
        category: '电子数码',
        images: [],
        locationTag: '实验楼门口',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      productRepository.save(product);

      const threadResult = await chatService.openProductThread(product.id, buyer.id, seller.id);
      expect(threadResult.ok).assertTrue();
      expect((await chatService.sendMessage(threadResult.data!, buyer.id, '先发一条历史消息')).ok).assertTrue();

      userRepository.updateStatus(buyer.id, 'muted');

      const thread = chatService.getThread(threadResult.data!, buyer.id);
      const messages = await chatService.getMessages(threadResult.data!, buyer.id);
      const blockedSend = await chatService.sendMessage(threadResult.data!, buyer.id, '禁言后继续发消息');

      expect(thread !== null).assertTrue();
      expect(messages.length).assertEqual(1);
      expect(blockedSend.ok).assertFalse();
      expect(blockedSend.message.includes('禁言') || blockedSend.message.includes('消息')).assertTrue();
    });

    it('chat_service_should_prefer_remote_thread_list_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'remote-chat-seller',
        phone: '18881000002',
        nickname: '远端卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'remote-chat-buyer',
        phone: '18881000001',
        nickname: '远端买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: '8101',
        sellerId: seller.id,
        title: '远端会话列表测试商品',
        desc: '验证聊天列表优先使用远端并回灌本地缓存',
        price: 39,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      productRepository.save(product);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-chat-list-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteChatClient();
      fakeRemoteClient.conversationsResponse = {
        ok: true,
        message: '远端会话列表成功',
        data: [{
          id: '8102',
          product_id: product.id,
          order_id: '',
          buyer_id: buyer.id,
          seller_id: seller.id,
          last_message: '远端最新消息',
          last_message_at: now + 10,
          created_at: now + 5,
          product_title: product.title,
          buyer_nickname: buyer.nickname,
          seller_nickname: seller.nickname,
          unread_count: 2
        }]
      };

      const service = new ChatServiceImpl(fakeRemoteClient, stateService);
      const threads = await service.listThreads(buyer.id);
      const unreadCount = await service.countUnread(buyer.id);

      expect(fakeRemoteClient.listConversationsCalled).assertTrue();
      expect(fakeRemoteClient.lastListToken).assertEqual('remote-chat-list-token');
      expect(threads.length).assertEqual(1);
      expect(threads[0].id).assertEqual('8102');
      expect(threads[0].lastMessage).assertEqual('远端最新消息');
      expect(unreadCount).assertEqual(2);
      expect(chatRepository.getThreadById('8102')?.productId).assertEqual(product.id);
    });

    it('chat_service_should_prefer_remote_messages_and_hydrate_local_history', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'remote-message-seller',
        phone: '18882000002',
        nickname: '远端消息卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'remote-message-buyer',
        phone: '18882000001',
        nickname: '远端消息买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      chatRepository.saveThread({
        id: '8202',
        productId: '8201',
        buyerId: buyer.id,
        sellerId: seller.id,
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-chat-messages-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteChatClient();
      fakeRemoteClient.messagesResponse = {
        ok: true,
        message: '远端聊天记录成功',
        data: [{
          id: '8203',
          conversation_id: '8202',
          from_user_id: seller.id,
          to_user_id: buyer.id,
          content: '这是远端返回的历史消息',
          is_read: true,
          created_at: now + 5
        }]
      };

      const service = new ChatServiceImpl(fakeRemoteClient, stateService);
      const messages = await service.getMessages('8202', buyer.id);

      expect(fakeRemoteClient.getMessagesCalled).assertTrue();
      expect(fakeRemoteClient.lastMessagesToken).assertEqual('remote-chat-messages-token');
      expect(fakeRemoteClient.lastMessagesThreadId).assertEqual('8202');
      expect(messages.length).assertEqual(1);
      expect(messages[0].content).assertEqual('这是远端返回的历史消息');
      expect(chatRepository.listMessages('8202').length).assertEqual(1);
      expect(chatRepository.listMessages('8202')[0].id).assertEqual('8203');
    });

    it('chat_service_should_prefer_remote_thread_creation_and_send_message', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'remote-open-seller',
        phone: '18883000002',
        nickname: '远端开聊卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'remote-open-buyer',
        phone: '18883000001',
        nickname: '远端开聊买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: '8301',
        sellerId: seller.id,
        title: '远端开聊测试商品',
        desc: '验证聊天创建与发消息优先使用远端',
        price: 56,
        category: '电子数码',
        images: [],
        locationTag: '教学楼门口',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      productRepository.save(product);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-chat-create-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteChatClient();
      fakeRemoteClient.conversationResponse = {
        ok: true,
        message: '远端会话创建成功',
        data: {
          id: '8302',
          product_id: product.id,
          order_id: '',
          buyer_id: buyer.id,
          seller_id: seller.id,
          last_message: '',
          last_message_at: 0,
          created_at: now + 1,
          product_title: product.title,
          buyer_nickname: buyer.nickname,
          seller_nickname: seller.nickname,
          unread_count: 0
        }
      };
      fakeRemoteClient.sendResponse = {
        ok: true,
        message: '远端消息发送成功',
        data: {
          id: '8303',
          conversation_id: '8302',
          from_user_id: buyer.id,
          to_user_id: seller.id,
          content: '你好，今晚可以面交吗？',
          is_read: false,
          created_at: now + 2
        }
      };

      const service = new ChatServiceImpl(fakeRemoteClient, stateService);
      const threadResult = await service.openProductThread(product.id, buyer.id, seller.id);
      const sendResult = await service.sendMessage(threadResult.data!, buyer.id, '你好，今晚可以面交吗？');

      expect(threadResult.ok).assertTrue();
      expect(fakeRemoteClient.createConversationCalled).assertTrue();
      expect(fakeRemoteClient.lastCreateToken).assertEqual('remote-chat-create-token');
      expect(fakeRemoteClient.lastCreatePayload?.product_id).assertEqual(product.id);
      expect(sendResult.ok).assertTrue();
      expect(fakeRemoteClient.sendMessageCalled).assertTrue();
      expect(fakeRemoteClient.lastSendToken).assertEqual('remote-chat-create-token');
      expect(fakeRemoteClient.lastSendThreadId).assertEqual('8302');
      expect(fakeRemoteClient.lastSendContent).assertEqual('你好，今晚可以面交吗？');
      expect(chatRepository.getThreadById('8302')?.buyerId).assertEqual(buyer.id);
      expect(chatRepository.listMessages('8302').length).assertEqual(1);
      expect(chatRepository.listMessages('8302')[0].id).assertEqual('8303');
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

    it('product_repository_merge_remote_should_publish_product_feed_change', 0, () => {
      const now = Date.now();
      const productId = `product-remote-sync-${now}`;
      productRepository.save({
        id: productId,
        sellerId: 'seller-remote-sync',
        title: '远端同步商品',
        desc: '验证远端并入后广播首页刷新',
        price: 66,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'pending_review',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });

      const feedSignals: string[] = [];
      const unsubscribe = syncService.subscribe('products:changed', (payload) => {
        feedSignals.push(payload.value);
      });
      const baselineSignalCount = feedSignals.length;

      const merged = productRepository.mergeRemote({
        id: productId,
        sellerId: 'seller-remote-sync',
        title: '远端同步商品',
        desc: '验证远端并入后广播首页刷新',
        price: 66,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now + 1
      });

      unsubscribe();

      expect(merged.status).assertEqual('on_sale');
      expect(feedSignals.length).assertEqual(baselineSignalCount + 1);
      expect(feedSignals[feedSignals.length - 1]).assertEqual(productId);
    });

    it('product_service_should_publish_product_feed_change_when_creating_or_updating_product', 0, async () => {
      const feedSignals: string[] = [];
      const unsubscribe = syncService.subscribe('products:changed', (payload) => {
        feedSignals.push(payload.value);
      });
      const baselineSignalCount = feedSignals.length;

      const timestamp: string = Date.now().toString().slice(-8);
      const sellerPhone: string = buildTestPhone('185', timestamp, 0);
      const testAuthService = new AuthServiceImpl(new FakeRemoteAuthClient());
      const sellerLogin = await testAuthService.loginByPhone(sellerPhone, '123456');
      expect(sellerLogin.ok).assertTrue();
      const seller = sellerLogin.data!.currentUser;

      const createResult = productService.createProduct({
        title: '商品同步创建测试',
        desc: '验证本地创建也会驱动商品流刷新',
        price: 73,
        category: '电子数码',
        locationTag: '图书馆大厅',
        images: []
      }, seller.id);
      expect(createResult.ok).assertTrue();
      const productId = createResult.data!.id;
      const afterCreateSignalCount = feedSignals.length;

      const updateResult = productService.updateProduct(productId, {
        title: '商品同步更新测试',
        price: 79
      }, seller.id);

      unsubscribe();

      expect(afterCreateSignalCount).assertEqual(baselineSignalCount + 1);
      expect(feedSignals[afterCreateSignalCount - 1]).assertEqual(productId);
      expect(updateResult.ok).assertTrue();
      expect(feedSignals.length).assertEqual(afterCreateSignalCount + 1);
      expect(feedSignals[feedSignals.length - 1]).assertEqual(productId);
    });

    it('product_service_should_reject_admin_or_banned_users_from_creating_or_updating_products', 0, () => {
      const now = Date.now();
      userRepository.save({
        id: 'product-admin-blocked',
        phone: '19966660001',
        nickname: '管理员卖家',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      });
      userRepository.save({
        id: 'product-banned-blocked',
        phone: '18866660001',
        nickname: '封禁用户',
        role: 'user',
        status: 'banned',
        creditScore: 60,
        createdAt: now,
        updatedAt: now
      });
      productRepository.save({
        id: 'product-owned-by-admin',
        sellerId: 'product-admin-blocked',
        title: '管理员商品',
        desc: '不应允许管理员编辑',
        price: 22,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'pending_review',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });
      productRepository.save({
        id: 'product-owned-by-banned',
        sellerId: 'product-banned-blocked',
        title: '封禁用户商品',
        desc: '不应允许封禁用户编辑',
        price: 23,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'pending_review',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });

      const adminCreate = productService.createProduct({
        title: '管理员新商品',
        desc: '管理员不应允许发布',
        price: 33,
        category: '电子数码',
        locationTag: '图书馆大厅',
        images: []
      }, 'product-admin-blocked');
      const bannedCreate = productService.createProduct({
        title: '封禁用户新商品',
        desc: '封禁账号不应允许发布',
        price: 34,
        category: '电子数码',
        locationTag: '图书馆大厅',
        images: []
      }, 'product-banned-blocked');
      const adminUpdate = productService.updateProduct('product-owned-by-admin', {
        title: '管理员修改标题'
      }, 'product-admin-blocked');
      const bannedUpdate = productService.updateProduct('product-owned-by-banned', {
        title: '封禁用户修改标题'
      }, 'product-banned-blocked');

      expect(adminCreate.ok).assertFalse();
      expect(adminCreate.message.includes('管理员')).assertTrue();
      expect(bannedCreate.ok).assertFalse();
      expect(bannedCreate.message.includes('停用') || bannedCreate.message.includes('封禁')).assertTrue();
      expect(adminUpdate.ok).assertFalse();
      expect(adminUpdate.message.includes('管理员')).assertTrue();
      expect(bannedUpdate.ok).assertFalse();
      expect(bannedUpdate.message.includes('停用') || bannedUpdate.message.includes('封禁')).assertTrue();
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

      const orderResult = await orderService.createOrder(buyer.id, product.id, '宿舍楼下');
      expect(orderResult.ok).assertTrue();
      expect(feedSignals.includes('locked')).assertTrue();

      const cancelResult = await orderService.cancelOrder(orderResult.data!.id, buyer.id);
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

      const orderResult = await orderService.createOrder(buyer.id, product.id, '宿舍楼下');
      expect(orderResult.ok).assertTrue();
      expect(orderSignals.includes('PENDING_PAYMENT')).assertTrue();

      const cancelResult = await orderService.cancelOrder(orderResult.data!.id, buyer.id);
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

    it('guard_should_return_specific_denied_message_for_restricted_admin_actions', 0, () => {
      const bannedAdmin: User = {
        id: 'a2',
        phone: '19900000002',
        nickname: '受限管理员',
        role: 'admin',
        status: 'banned',
        creditScore: 100,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      const user: User = {
        id: 'u2',
        phone: '18800000002',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };

      expect(getAdminActionDeniedMessage(null)).assertEqual('仅管理员可执行该操作');
      expect(getAdminActionDeniedMessage(user)).assertEqual('仅管理员可执行该操作');
      expect(getAdminActionDeniedMessage(bannedAdmin)).assertEqual('当前管理员账号已被停用，无法继续执行该操作');
      expect(getAdminActionDeniedMessage({
        id: 'a3',
        phone: '19900000003',
        nickname: '正常管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: Date.now(),
        updatedAt: Date.now()
      })).assertEqual('');
    });

    it('guard_should_return_specific_denied_message_for_restricted_admin_page_access', 0, () => {
      const bannedAdmin: User = {
        id: 'a4',
        phone: '19900000004',
        nickname: '受限管理员2',
        role: 'admin',
        status: 'banned',
        creditScore: 100,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };

      expect(getAdminAccessDeniedMessage(null)).assertEqual('仅管理员可访问');
      expect(getAdminAccessDeniedMessage(bannedAdmin)).assertEqual('当前管理员账号已被停用，已停止后台访问');
      expect(getAdminAccessDeniedMessage({
        id: 'a5',
        phone: '19900000005',
        nickname: '正常管理员2',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: Date.now(),
        updatedAt: Date.now()
      })).assertEqual('');
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

      const createOrder = await orderService.createOrder(buyer.id, product.id, '南苑宿舍楼下');
      expect(createOrder.ok).assertTrue();
      const order = createOrder.data!;

      const payResult = await orderService.simulatePay(order.id, buyer.id);
      expect(payResult.ok).assertTrue();

      const buyerArrived = await orderService.markArrived(order.id, buyer.id);
      expect(buyerArrived.ok).assertTrue();

      const sellerArrived = await orderService.markArrived(order.id, seller.id);
      expect(sellerArrived.ok).assertTrue();
      expect(sellerArrived.data!.status).assertEqual(OrderStatus.READY_HANDOVER);

      const completeOrder = await orderService.completeOrder(order.id, buyer.id);
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

      const orderResult = await orderService.createOrder(seller.id, product.id, '教学楼大厅');
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

    it('order_service_should_reject_admin_users_from_joining_trade_flow', 0, async () => {
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

      const orderResult = await orderService.createOrder(admin.id, product.id, '教学楼大厅');
      expect(orderResult.ok).assertFalse();
      expect(orderResult.message).assertEqual('管理员账号不支持下单');
    });

    it('trade_flow_services_should_reject_banned_users', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'seller-banned-trade-user',
        phone: '18800005555',
        nickname: '正常卖家',
        role: 'user',
        status: 'active',
        creditScore: 85,
        createdAt: now,
        updatedAt: now
      };
      const bannedBuyer: User = {
        id: 'banned-buyer-trade-user',
        phone: '18800006666',
        nickname: '封禁买家',
        role: 'user',
        status: 'banned',
        creditScore: 20,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(bannedBuyer);

      const createProduct = productService.createProduct({
        title: '封禁用户禁交易测试商品',
        desc: '封禁后不应允许继续参与购物车、下单和聊天',
        price: 58,
        category: '电子数码',
        locationTag: '图书馆大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      const addResult = cartService.addToCart(bannedBuyer.id, product.id);
      const orderResult = await orderService.createOrder(bannedBuyer.id, product.id, '教学楼大厅');
      const threadResult = await chatService.openProductThread(product.id, bannedBuyer.id, seller.id);

      expect(addResult.ok).assertFalse();
      expect(addResult.message.includes('停用') || addResult.message.includes('封禁')).assertTrue();
      expect(orderResult.ok).assertFalse();
      expect(orderResult.message.includes('停用') || orderResult.message.includes('封禁')).assertTrue();
      expect(threadResult.ok).assertFalse();
      expect(threadResult.message.includes('停用') || threadResult.message.includes('封禁')).assertTrue();
    });

    it('cart_service_should_hide_and_freeze_cart_for_restricted_accounts', 0, () => {
      const now = Date.now();
      const seller: User = {
        id: 'seller-cart-restricted-user',
        phone: '18800009991',
        nickname: '正常卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'buyer-cart-restricted-user',
        phone: '18800009992',
        nickname: '正常买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);

      const createProduct = productService.createProduct({
        title: '受限购物车测试商品',
        desc: '验证账号受限后购物车服务不再继续暴露或修改数据',
        price: 39,
        category: '教材书籍',
        locationTag: '图书馆大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      const addResult = cartService.addToCart(buyer.id, product.id);
      expect(addResult.ok).assertTrue();
      const cartItemId = addResult.data!.id;
      expect(cartService.listByUser(buyer.id).length).assertEqual(1);

      userRepository.updateStatus(buyer.id, 'banned');

      expect(cartService.listByUser(buyer.id).length).assertEqual(0);
      cartService.removeItem(buyer.id, cartItemId);
      cartService.clearByUser(buyer.id);

      userRepository.updateStatus(buyer.id, 'active');
      const restoredCart = cartService.listByUser(buyer.id);
      expect(restoredCart.length).assertEqual(1);
      expect(restoredCart[0].id).assertEqual(cartItemId);
    });

    it('order_service_should_block_follow_up_actions_after_user_is_banned', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'seller-banned-followup-user',
        phone: '18800007777',
        nickname: '正常卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'buyer-banned-followup-user',
        phone: '18800008888',
        nickname: '正常买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);

      const createProduct = productService.createProduct({
        title: '封禁后续动作测试商品',
        desc: '验证交易中被封禁后不能继续推进订单',
        price: 61,
        category: '电子数码',
        locationTag: '图书馆大厅',
        images: []
      }, seller.id);
      expect(createProduct.ok).assertTrue();
      const product = createProduct.data!;
      productRepository.updateStatus(product.id, 'on_sale');

      const orderResult = await orderService.createOrder(buyer.id, product.id, '教学楼大厅');
      expect(orderResult.ok).assertTrue();
      const orderId = orderResult.data!.id;

      userRepository.updateStatus(buyer.id, 'banned');
      userRepository.updateStatus(seller.id, 'banned');

      const payResult = await orderService.simulatePay(orderId, buyer.id);
      const cancelResult = await orderService.cancelOrder(orderId, buyer.id);
      const arriveResult = await orderService.markArrived(orderId, seller.id);
      const completeResult = await orderService.completeOrder(orderId, seller.id);
      const reviewResult = orderService.addReview(orderId, buyer.id, 5, '好评', '封禁后不应允许评价');

      expect(payResult.ok).assertFalse();
      expect(payResult.message.includes('停用') || payResult.message.includes('封禁')).assertTrue();
      expect(cancelResult.ok).assertFalse();
      expect(cancelResult.message.includes('停用') || cancelResult.message.includes('封禁')).assertTrue();
      expect(arriveResult.ok).assertFalse();
      expect(arriveResult.message.includes('停用') || arriveResult.message.includes('封禁')).assertTrue();
      expect(completeResult.ok).assertFalse();
      expect(completeResult.message.includes('停用') || completeResult.message.includes('封禁')).assertTrue();
      expect(reviewResult.ok).assertFalse();
      expect(reviewResult.message.includes('停用') || reviewResult.message.includes('封禁')).assertTrue();
    });

    it('announcement_service_should_support_delete', 0, async () => {
      authStateService.clear();
      const adminResult = authService.loginByAdminCode('16600001234', 'ADMIN2026');
      expect(adminResult.ok).assertTrue();
      const admin = adminResult.data!.currentUser;

      const publishResult = await announcementService.publish('测试公告', '用于测试删除能力', admin.id);
      expect(publishResult.ok).assertTrue();

      const deleteResult = await announcementService.delete(publishResult.data!.id, admin.id);
      expect(deleteResult.ok).assertTrue();

      const list = await announcementService.list();
      const exists = list.some((item) => item.id === publishResult.data!.id);
      expect(exists).assertFalse();
    });

    it('announcement_service_should_reject_non_admin_publish_requests', 0, async () => {
      const userId = `announcement-user-${Date.now()}`;
      userRepository.save({
        id: userId,
        phone: '18855550001',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: Date.now(),
        updatedAt: Date.now()
      });

      const publishResult = await announcementService.publish('普通用户公告', '这条公告不应该发布成功', userId);

      expect(publishResult.ok).assertFalse();
      expect(publishResult.message.includes('管理员')).assertTrue();
    });

    it('announcement_service_should_reject_restricted_admin_publish_and_delete_requests', 0, async () => {
      const activeAdminResult = authService.loginByAdminCode('16600001236', 'ADMIN2026');
      expect(activeAdminResult.ok).assertTrue();
      const activeAdmin = activeAdminResult.data!.currentUser;

      const restrictedAdminId = `announcement-banned-admin-${Date.now()}`;
      userRepository.save({
        id: restrictedAdminId,
        phone: '19900001234',
        nickname: '受限管理员',
        role: 'admin',
        status: 'banned',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      });
      const restrictedAdmin = userRepository.getById(restrictedAdminId);

      const publishResult = await announcementService.publish('受限管理员公告', '这条公告不应该发布成功', restrictedAdminId);
      expect(publishResult.ok).assertFalse();
      expect(publishResult.message).assertEqual(getAdminActionDeniedMessage(restrictedAdmin));

      const announcement = await announcementService.publish('待删除公告', '用于验证受限管理员删除权限', activeAdmin.id);
      expect(announcement.ok).assertTrue();

      const deleteResult = await announcementService.delete(announcement.data!.id, restrictedAdminId);
      expect(deleteResult.ok).assertFalse();
      expect(deleteResult.message).assertEqual(getAdminActionDeniedMessage(restrictedAdmin));
    });

    it('announcement_service_should_publish_sync_events_with_chinese_messages', 0, async () => {
      authStateService.clear();
      const adminResult = authService.loginByAdminCode('16600001235', 'ADMIN2026');
      expect(adminResult.ok).assertTrue();
      const admin = adminResult.data!.currentUser;

      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('announcements:changed', (payload) => {
        syncValues.push(payload.value);
      });

      const publishResult = await announcementService.publish('公告同步测试', '验证公告同步事件', admin.id);
      const deleteResult = await announcementService.delete(publishResult.data!.id, admin.id);

      unsubscribe();

      expect(publishResult.ok).assertTrue();
      expect(publishResult.message).assertEqual('公告发布成功');
      expect(deleteResult.ok).assertTrue();
      expect(deleteResult.message).assertEqual('公告删除成功');
      expect(syncValues.length >= 2).assertTrue();
      expect(syncValues.includes(publishResult.data!.id)).assertTrue();
      expect(syncValues[syncValues.length - 1]).assertEqual(publishResult.data!.id);
    });

    it('announcement_service_should_prefer_remote_list_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const remoteClient = new FakeRemoteAnnouncementClient();
      remoteClient.listResponse = {
        ok: true,
        message: '远端公告列表成功',
        data: [{
          id: '91001',
          title: '远端公告一',
          content: '这是远端返回的公告内容',
          publisher_id: '1',
          is_deleted: 0,
          created_at: now,
          updated_at: now + 1
        }]
      };

      const service = new AnnouncementServiceImpl(remoteClient, new AuthStateService(createMemoryPersistenceAdapter()));
      const list = await service.list();

      expect(remoteClient.listCalled).assertTrue();
      expect(list.length).assertEqual(1);
      expect(list[0].id).assertEqual('91001');
      expect(announcementRepository.getById('91001')?.title).assertEqual('远端公告一');
    });

    it('announcement_service_should_prefer_remote_publish_and_delete_then_sync_local_state', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '90001',
        phone: '19988880001',
        nickname: '远端公告管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'announcement-remote-token',
        expiresAt: now + 60_000
      });

      const remoteClient = new FakeRemoteAnnouncementClient();
      remoteClient.publishResponse = {
        ok: true,
        message: '远端公告发布成功',
        data: {
          id: '91002',
          title: '远端发布公告',
          content: '远端公告正文',
          publisher_id: admin.id,
          is_deleted: 0,
          created_at: now + 1,
          updated_at: now + 2
        }
      };
      remoteClient.deleteResponse = {
        ok: true,
        message: '远端公告删除成功',
        data: '91002'
      };

      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('announcements:changed', (payload) => {
        syncValues.push(payload.value);
      });

      const service = new AnnouncementServiceImpl(remoteClient, stateService);
      const publishResult = await service.publish('远端发布公告', '远端公告正文', admin.id);
      const deleteResult = await service.delete('91002', admin.id);

      unsubscribe();

      expect(publishResult.ok).assertTrue();
      expect(remoteClient.publishCalled).assertTrue();
      expect(remoteClient.lastPublishToken).assertEqual('announcement-remote-token');
      expect(remoteClient.lastPublishTitle).assertEqual('远端发布公告');
      expect(deleteResult.ok).assertTrue();
      expect(remoteClient.deleteCalled).assertTrue();
      expect(remoteClient.lastDeleteToken).assertEqual('announcement-remote-token');
      expect(remoteClient.lastDeleteId).assertEqual('91002');
      expect(announcementRepository.list().some((item: Announcement) => item.id === '91002')).assertFalse();
      expect(syncValues.includes('91002')).assertTrue();
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

    it('detail_return_route_should_provide_safe_chat_fallback_targets', 0, () => {
      const guestTarget: DetailReturnTarget = buildChatDetailReturnTarget(null);
      const traderTarget: DetailReturnTarget = buildChatDetailReturnTarget({
        id: 'chat-return-trader',
        phone: '18800007791',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: 1,
        updatedAt: 1
      });
      const adminTarget: DetailReturnTarget = buildChatDetailReturnTarget({
        id: 'chat-return-admin',
        phone: '19900000052',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      });

      expect(guestTarget.url).assertEqual('pages/Auth/LoginPage');
      expect(traderTarget.url).assertEqual('pages/Index');
      expect(traderTarget.params?.tab).assertEqual('message');
      expect(adminTarget.url).assertEqual('pages/Index');
      expect(adminTarget.params?.tab).assertEqual('message');
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
      const bannedTarget = resolvePublishEntryTarget({
        id: 'publish-banned-1',
        phone: '18800003333',
        nickname: '封禁用户',
        role: 'user',
        status: 'banned',
        creditScore: 20,
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

      expect(bannedTarget.url).assertEqual('pages/Profile/ProfilePage');
      expect(bannedTarget.requiresLogin).assertFalse();
      expect(bannedTarget.promptMessage).assertEqual('该账号已被停用，无法发布商品');
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
      expect(canUserTradeProduct(product, '', undefined)).assertFalse();
      expect(canUserTradeProduct(product, 'buyer-1', 'user', 'banned')).assertFalse();
    });

    it('trade_guard_should_hide_product_detail_contact_entry_for_non_tradable_audiences', 0, () => {
      const product: Product = {
        id: 'trade-contact-product',
        sellerId: 'seller-1',
        title: '商品详情联系入口测试',
        desc: '校验联系卖家入口展示',
        price: 56,
        category: '电子设备',
        images: [],
        locationTag: '教学楼门口',
        status: 'on_sale',
        isDeleted: false,
        createdAt: 1,
        updatedAt: 1
      };
      const trader: User = {
        id: 'buyer-2',
        phone: '18800007773',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: 1,
        updatedAt: 1
      };
      const admin: User = {
        id: 'admin-contact',
        phone: '19900000041',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedTrader: User = {
        id: 'banned-contact',
        phone: '18800007774',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 20,
        createdAt: 1,
        updatedAt: 1
      };

      expect(canShowProductDetailContactAction(product, trader)).assertTrue();
      expect(canShowProductDetailContactAction(product, null)).assertFalse();
      expect(canShowProductDetailContactAction(product, admin)).assertFalse();
      expect(canShowProductDetailContactAction(product, bannedTrader)).assertFalse();
      expect(canShowProductDetailContactAction(product, {
        id: 'seller-1',
        phone: '18800007775',
        nickname: '卖家本人',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: 1,
        updatedAt: 1
      })).assertFalse();
    });

    it('trade_guard_should_describe_product_detail_trade_hint_by_audience', 0, () => {
      const product: Product = {
        id: 'trade-hint-product',
        sellerId: 'seller-2',
        title: '商品详情提示测试',
        desc: '校验不同身份下的详情提示',
        price: 88,
        category: '电子设备',
        images: [],
        locationTag: '食堂门口',
        status: 'on_sale',
        isDeleted: false,
        createdAt: 1,
        updatedAt: 1
      };
      const trader: User = {
        id: 'buyer-3',
        phone: '18800007776',
        nickname: '普通交易用户',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: 1,
        updatedAt: 1
      };
      const admin: User = {
        id: 'admin-hint',
        phone: '19900000042',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedTrader: User = {
        id: 'banned-hint',
        phone: '18800007777',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 10,
        createdAt: 1,
        updatedAt: 1
      };

      expect(getProductDetailTradeHint(product, trader)).assertEqual('商品可正常加入购物车并下单');
      expect(getProductDetailTradeHint(product, null)).assertEqual('登录后可联系卖家、加入购物车并下单');
      expect(getProductDetailTradeHint(product, admin)).assertEqual('管理员账号仅可浏览商品信息，不参与普通交易');
      expect(getProductDetailTradeHint(product, bannedTrader)).assertEqual('账号当前受限，仅可浏览商品信息，无法继续沟通或下单');
    });

    it('trade_guard_should_provide_consistent_entry_denied_messages_for_guest_admin_and_restricted_user', 0, () => {
      const admin: User = {
        id: 'entry-denied-admin',
        phone: '19900000040',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedTrader: User = {
        id: 'entry-denied-banned',
        phone: '18800007770',
        nickname: '封禁用户',
        role: 'user',
        status: 'banned',
        creditScore: 30,
        createdAt: 1,
        updatedAt: 1
      };

      expect(getTradeEntryDeniedMessage(null, 'cart')).assertEqual('请先登录后再继续');
      expect(getTradeEntryDeniedMessage(admin, 'cart')).assertEqual('管理员账号不支持加入购物车');
      expect(getTradeEntryDeniedMessage(admin, 'order')).assertEqual('管理员账号不支持下单');
      expect(getTradeEntryDeniedMessage(admin, 'chat')).assertEqual('管理员账号不支持发起商品沟通');
      expect(getTradeEntryDeniedMessage(bannedTrader, 'cart')).assertEqual('该账号已被停用，无法加入购物车');
      expect(getTradeEntryDeniedMessage(bannedTrader, 'order')).assertEqual('该账号已被停用，无法下单');
      expect(getTradeEntryDeniedMessage(bannedTrader, 'chat')).assertEqual('该账号已被停用，无法发起商品沟通');
    });

    it('trade_guard_should_only_allow_campus_users_to_view_personal_trade_history', 0, () => {
      const trader: User = {
        id: 'history-trader',
        phone: '18800007778',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 76,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedTrader: User = {
        id: 'history-banned-trader',
        phone: '18800007779',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 18,
        createdAt: 1,
        updatedAt: 1
      };
      const admin: User = {
        id: 'history-admin',
        phone: '19900000043',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedAdmin: User = {
        id: 'history-banned-admin',
        phone: '19900000044',
        nickname: '受限管理员',
        role: 'admin',
        status: 'banned',
        creditScore: 50,
        createdAt: 1,
        updatedAt: 1
      };

      expect(canViewTradeHistory(null)).assertFalse();
      expect(canViewTradeHistory(trader)).assertTrue();
      expect(canViewTradeHistory(bannedTrader)).assertTrue();
      expect(canViewTradeHistory(admin)).assertFalse();
      expect(canViewTradeHistory(bannedAdmin)).assertFalse();
    });

    it('trade_guard_should_only_allow_campus_users_to_open_trade_record_details', 0, () => {
      const trader: User = {
        id: 'trade-record-trader',
        phone: '18800007781',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 70,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedTrader: User = {
        id: 'trade-record-banned-trader',
        phone: '18800007782',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 12,
        createdAt: 1,
        updatedAt: 1
      };
      const admin: User = {
        id: 'trade-record-admin',
        phone: '19900000047',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };

      expect(canAccessTradeRecord(trader, ['trade-record-trader', 'seller-1'])).assertTrue();
      expect(canAccessTradeRecord(bannedTrader, ['trade-record-banned-trader', 'seller-1'])).assertTrue();
      expect(canAccessTradeRecord(trader, ['buyer-2', 'seller-1'])).assertFalse();
      expect(canAccessTradeRecord(admin, ['trade-record-admin', 'seller-1'])).assertFalse();
      expect(canAccessTradeRecord(null, ['buyer-2', 'seller-1'])).assertFalse();
    });

    it('trade_guard_should_describe_trade_record_unavailable_state_by_identity', 0, () => {
      const admin: User = {
        id: 'trade-record-copy-admin',
        phone: '19900000049',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedAdmin: User = {
        id: 'trade-record-copy-banned-admin',
        phone: '19900000050',
        nickname: '受限管理员',
        role: 'admin',
        status: 'banned',
        creditScore: 42,
        createdAt: 1,
        updatedAt: 1
      };
      const outsider: User = {
        id: 'trade-record-copy-outsider',
        phone: '18800007785',
        nickname: '旁观用户',
        role: 'user',
        status: 'active',
        creditScore: 60,
        createdAt: 1,
        updatedAt: 1
      };

      expect(getTradeRecordUnavailableTitle('order', null, true)).assertEqual('请先登录后查看订单');
      expect(getTradeRecordUnavailableTitle('chat', admin, true)).assertEqual('管理员账号不参与普通交易');
      expect(getTradeRecordUnavailableTitle('chat', bannedAdmin, true)).assertEqual('当前管理员账号已被停用');
      expect(getTradeRecordUnavailableTitle('order', outsider, true)).assertEqual('无权查看该订单');
      expect(getTradeRecordUnavailableTitle('chat', outsider, false)).assertEqual('会话暂时不可用');

      expect(getTradeRecordUnavailableDescription('chat', admin, true))
        .assertEqual('当前账号仅用于后台治理，不提供普通商品沟通记录查看。');
      expect(getTradeRecordUnavailableDescription('order', bannedAdmin, true))
        .assertEqual('当前管理员账号已被停用，无法继续查看普通交易记录。');
      expect(getTradeRecordUnavailableDescription('order', outsider, true))
        .assertEqual('这笔订单不属于当前账号，请返回订单列表查看你自己的交易记录。');
      expect(getTradeRecordUnavailableDescription('chat', null, true))
        .assertEqual('登录后可查看你参与过的商品沟通记录和历史消息。');
      expect(getTradeRecordUnavailableDescription('chat', outsider, false))
        .assertEqual('当前会话不存在、已失效，或已经不再对当前账号可见。');
    });

    it('trade_guard_should_treat_protected_trade_details_as_access_denied_when_login_is_required', 0, () => {
      expect(shouldTreatTradeRecordAsAccessDenied(null, true, false)).assertTrue();
      expect(shouldTreatTradeRecordAsAccessDenied(null, false, false)).assertTrue();
      expect(shouldTreatTradeRecordAsAccessDenied({
        id: 'trade-protected-user',
        phone: '18800007786',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: 1,
        updatedAt: 1
      }, true, false)).assertTrue();
      expect(shouldTreatTradeRecordAsAccessDenied({
        id: 'trade-protected-owner',
        phone: '18800007787',
        nickname: '订单所有者',
        role: 'user',
        status: 'active',
        creditScore: 85,
        createdAt: 1,
        updatedAt: 1
      }, true, true)).assertFalse();
      expect(shouldTreatTradeRecordAsAccessDenied({
        id: 'trade-protected-missing',
        phone: '18800007788',
        nickname: '正常用户',
        role: 'user',
        status: 'active',
        creditScore: 85,
        createdAt: 1,
        updatedAt: 1
      }, false, false)).assertFalse();
    });

    it('trade_guard_should_provide_read_only_hints_for_restricted_trade_pages', 0, () => {
      const trader: User = {
        id: 'readonly-trader',
        phone: '18800007771',
        nickname: '正常用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedTrader: User = {
        id: 'readonly-banned',
        phone: '18800007772',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 25,
        createdAt: 1,
        updatedAt: 1
      };

      expect(canCurrentUserOperateTrade(trader)).assertTrue();
      expect(canCurrentUserOperateTrade(bannedTrader)).assertFalse();
      expect(getTradeReadOnlyHint(trader, 'chat')).assertEqual('');
      expect(getTradeReadOnlyHint(bannedTrader, 'chat').includes('当前仅可查看历史沟通记录')).assertTrue();
      expect(getTradeReadOnlyHint(bannedTrader, 'order').includes('当前仅可查看订单记录')).assertTrue();
    });

    it('marketplace_user_sync_keys_should_cover_user_status_and_verification_updates', 0, () => {
      const keys: string[] = buildMarketplaceUserSyncKeys();
      expect(keys.includes('users:changed')).assertTrue();
      expect(keys.includes('governance:changed')).assertTrue();
      expect(keys.includes('moderation:changed')).assertTrue();
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
      const bannedTrader: User = {
        id: 'audience-banned-user',
        phone: '18800007777',
        nickname: '封禁用户',
        role: 'user',
        status: 'banned',
        creditScore: 20,
        createdAt: 1,
        updatedAt: 1
      };
      const mutedTrader: User = {
        id: 'audience-muted-user',
        phone: '18800008881',
        nickname: '禁言用户',
        role: 'user',
        status: 'muted',
        creditScore: 66,
        createdAt: 1,
        updatedAt: 1
      };
      const suspendedTrader: User = {
        id: 'audience-suspended-user',
        phone: '18800008882',
        nickname: '暂停用户',
        role: 'user',
        status: 'suspended',
        creditScore: 30,
        createdAt: 1,
        updatedAt: 1
      };

      expect(getMarketplaceAudienceMode(null)).assertEqual('guest');
      expect(getMarketplaceAudienceMode(trader)).assertEqual('trader');
      expect(getMarketplaceAudienceMode(admin)).assertEqual('admin');
      expect(getMarketplaceAudienceMode(mutedTrader)).assertEqual('trader');
      expect(getMarketplaceAudienceMode(suspendedTrader)).assertEqual('restricted');
      expect(canCurrentUserJoinTrade(trader)).assertTrue();
      expect(canCurrentUserJoinTrade(mutedTrader)).assertTrue();
      expect(canCurrentUserJoinTrade(admin)).assertFalse();
      expect(canCurrentUserJoinTrade(bannedTrader)).assertFalse();
      expect(canCurrentUserJoinTrade(suspendedTrader)).assertFalse();
      expect(canCurrentUserSendTradeMessage(trader)).assertTrue();
      expect(canCurrentUserSendTradeMessage(mutedTrader)).assertFalse();
    });

    it('marketplace_audience_ui_should_show_message_badges_for_all_signed_in_audiences', 0, () => {
      expect(shouldShowMarketplaceUnreadBadge('guest')).assertFalse();
      expect(shouldShowMarketplaceUnreadBadge('admin')).assertTrue();
      expect(shouldShowMarketplaceUnreadBadge('restricted')).assertTrue();
      expect(shouldShowMarketplaceUnreadBadge('trader')).assertTrue();
    });

    it('admin_user_governance_ui_should_describe_extended_statuses_and_actions', 0, () => {
      const activePresentation: AdminUserStatusPresentation = buildAdminUserStatusPresentation('active');
      const mutedPresentation: AdminUserStatusPresentation = buildAdminUserStatusPresentation('muted');
      const suspendedPresentation: AdminUserStatusPresentation = buildAdminUserStatusPresentation('suspended');

      const activeActions = getAdminUserNextStatusActions('active');
      const mutedActions = getAdminUserNextStatusActions('muted');

      expect(activePresentation.label).assertEqual('正常');
      expect(mutedPresentation.label).assertEqual('已禁言');
      expect(suspendedPresentation.label).assertEqual('已暂停');
      expect(activeActions.includes('restricted')).assertTrue();
      expect(activeActions.includes('muted')).assertTrue();
      expect(activeActions.includes('suspended')).assertTrue();
      expect(activeActions.includes('banned')).assertTrue();
      expect(mutedActions.length).assertEqual(1);
      expect(mutedActions[0]).assertEqual('active');
    });

    it('admin_user_governance_ui_should_build_summary_for_clean_and_limited_accounts', 0, () => {
      const cleanSummary: GovernanceUserSummary = {
        userId: 'admin-user-summary-clean',
        activeActionTypes: [],
        totalActionCount: 0,
        openCaseCount: 0,
        latestActionAt: 0
      };
      const limitedSummary: GovernanceUserSummary = {
        userId: 'admin-user-summary-limited',
        activeActionTypes: ['restrict_trade', 'mute_chat'],
        latestAction: {
          id: 'admin-user-summary-action-1',
          userId: 'admin-user-summary-limited',
          sourceType: 'manual_admin',
          sourceId: 'admin-user-summary-source-1',
          actionType: 'restrict_trade',
          reason: '多次违约并辱骂沟通对象',
          comment: '限制交易并禁言',
          startAt: 10,
          endAt: 20,
          active: true,
          createdBy: 'admin-user-summary-admin-1',
          createdAt: 10,
          updatedAt: 11
        },
        totalActionCount: 4,
        openCaseCount: 2,
        latestActionAt: 11
      };

      const cleanPresentation = buildAdminUserGovernanceSummaryPresentation(cleanSummary);
      const limitedPresentation = buildAdminUserGovernanceSummaryPresentation(limitedSummary);

      expect(cleanPresentation.title).assertEqual('当前没有生效中的治理动作');
      expect(cleanPresentation.badges.length).assertEqual(0);
      expect(limitedPresentation.title.includes('限制交易')).assertTrue();
      expect(limitedPresentation.title.includes('聊天禁言')).assertTrue();
      expect(limitedPresentation.badges.length).assertEqual(2);
      expect(limitedPresentation.description.includes('累计治理 4 次')).assertTrue();
      expect(limitedPresentation.description.includes('未结案件 2 条')).assertTrue();
    });

    it('admin_user_governance_ui_should_build_active_action_presentation', 0, () => {
      const actionPresentation = buildAdminUserGovernanceActionPresentation({
        id: 'admin-user-action-1',
        userId: 'admin-user-1',
        sourceType: 'moderation',
        sourceId: 'moderation-1',
        actionType: 'temporary_ban',
        reason: '多次严重违约',
        comment: '暂停 7 天并等待复核',
        startAt: 1000,
        endAt: 2000,
        active: true,
        createdBy: 'admin-1',
        createdAt: 1000,
        updatedAt: 1000
      });

      expect(actionPresentation.title).assertEqual('暂停账号');
      expect(actionPresentation.detail.includes('原因：多次严重违约')).assertTrue();
      expect(actionPresentation.detail.includes('备注：暂停 7 天并等待复核')).assertTrue();
      expect(actionPresentation.tone).assertEqual('danger');
      expect(actionPresentation.cancelLabel).assertEqual('解除暂停账号');
    });

    it('dashboard_stats_should_include_campus_verification_workload', 0, () => {
      const baseStats = appContext.getDashboardStats();
      const now = Date.now();
      userRepository.save({
        id: 'dashboard-pending-user',
        phone: '18811110001',
        nickname: '待审核用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        createdAt: now,
        updatedAt: now
      });
      userRepository.save({
        id: 'dashboard-verified-user',
        phone: '18811110002',
        nickname: '已认证用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      });

      const stats = appContext.getDashboardStats();
      expect(stats.pendingVerificationCount).assertEqual(baseStats.pendingVerificationCount + 1);
      expect(stats.verifiedUserCount).assertEqual(baseStats.verifiedUserCount + 1);
    });

    it('dashboard_stats_should_include_governance_pressure_counts', 0, () => {
      const baseStats = appContext.getDashboardStats();
      const now = Date.now();

      governanceRepository.save({
        id: 'dashboard-governance-action-1',
        userId: 'dashboard-governance-user-1',
        sourceType: 'manual_admin',
        sourceId: 'dashboard-governance-source-1',
        actionType: 'restrict_trade',
        reason: '多次爽约',
        comment: '限制交易 7 天',
        startAt: now,
        endAt: now + 7 * 24 * 60 * 60 * 1000,
        active: true,
        createdBy: 'dashboard-governance-admin-1',
        createdAt: now,
        updatedAt: now
      });

      moderationRepository.save({
        id: 'dashboard-moderation-open-1',
        reporterId: 'dashboard-reporter-1',
        targetType: 'order_complaint',
        targetId: 'dashboard-order-1',
        relatedOrderId: 'dashboard-order-1',
        reason: '面交违约',
        description: '后台概览应统计未结案治理记录',
        evidenceItems: [],
        status: 'in_review',
        priority: 'medium',
        createdAt: now,
        updatedAt: now
      });

      const stats = appContext.getDashboardStats();
      expect(stats.activeGovernanceCount).assertEqual(baseStats.activeGovernanceCount + 1);
      expect(stats.openModerationCaseCount).assertEqual(baseStats.openModerationCaseCount + 1);
    });

    it('dashboard_stats_should_ignore_admin_verification_statuses', 0, () => {
      const baseStats = appContext.getDashboardStats();
      const now = Date.now();
      userRepository.save({
        id: 'dashboard-admin-pending',
        phone: '19911110001',
        nickname: '待审核管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        createdAt: now,
        updatedAt: now
      });
      userRepository.save({
        id: 'dashboard-admin-verified',
        phone: '19911110002',
        nickname: '已认证管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      });

      const stats = appContext.getDashboardStats();
      expect(stats.pendingVerificationCount).assertEqual(baseStats.pendingVerificationCount);
      expect(stats.verifiedUserCount).assertEqual(baseStats.verifiedUserCount);
    });

    it('dashboard_stats_should_count_restricted_and_suspended_accounts_as_limited_users', 0, () => {
      const baseStats = appContext.getDashboardStats();
      const now = Date.now();
      userRepository.save({
        id: 'dashboard-restricted-user',
        phone: '18811110021',
        nickname: '受限用户',
        role: 'user',
        status: 'restricted',
        creditScore: 50,
        createdAt: now,
        updatedAt: now
      });
      userRepository.save({
        id: 'dashboard-suspended-user',
        phone: '18811110022',
        nickname: '暂停用户',
        role: 'user',
        status: 'suspended',
        creditScore: 40,
        createdAt: now,
        updatedAt: now
      });

      const stats = appContext.getDashboardStats();
      expect(stats.bannedUserCount).assertEqual(baseStats.bannedUserCount + 2);
    });

    it('admin_dashboard_service_should_prefer_remote_core_stats_and_preserve_local_workload_metrics', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '90013',
        phone: '19900009013',
        nickname: '远端概览管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save({
        id: 'dashboard-remote-pending',
        phone: '18811119001',
        nickname: '待审核校园用户',
        role: 'user',
        status: 'active',
        creditScore: 77,
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        createdAt: now,
        updatedAt: now
      });
      userRepository.save({
        id: 'dashboard-remote-verified',
        phone: '18811119002',
        nickname: '已认证校园用户',
        role: 'user',
        status: 'active',
        creditScore: 91,
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      });
      productRepository.save({
        id: 'dashboard-remote-product',
        sellerId: 'dashboard-remote-verified',
        title: '后台概览商品',
        desc: '用于验证远端后台概览商品统计覆盖本地总量',
        price: 58,
        category: '教材书籍',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });
      orderRepository.save({
        id: 'dashboard-remote-order',
        productId: 'dashboard-remote-product',
        buyerId: 'dashboard-remote-pending',
        sellerId: 'dashboard-remote-verified',
        amount: 58,
        address: '宿舍楼下',
        locationTag: '图书馆大厅',
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'remote-dashboard-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAdminDashboardClient();
      fakeRemoteClient.response = {
        ok: true,
        message: '远端后台概览成功',
        data: {
          user_count: 25,
          product_count: 13,
          order_count: 9,
          completed_order_count: 4,
          announcement_count: 6
        }
      };

      const localStats = appContext.getDashboardStats();
      const service = new AdminDashboardServiceImpl(fakeRemoteClient, stateService);
      const result = await service.getStats();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.getDashboardCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('remote-dashboard-token');
      expect(result.data?.userCount).assertEqual(25);
      expect(result.data?.productCount).assertEqual(13);
      expect(result.data?.orderCount).assertEqual(9);
      expect(result.data?.completedOrderCount).assertEqual(4);
      expect(result.data?.announcementCount).assertEqual(6);
      expect(result.data?.pendingVerificationCount).assertEqual(localStats.pendingVerificationCount);
      expect(result.data?.verifiedUserCount).assertEqual(localStats.verifiedUserCount);
      expect(result.data?.pendingOrderCount).assertEqual(localStats.pendingOrderCount);
    });

    it('admin_dashboard_service_should_fallback_to_local_stats_when_remote_dashboard_fails', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '90014',
        phone: '19900009014',
        nickname: '概览回退管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save({
        id: 'dashboard-local-user',
        phone: '18811119003',
        nickname: '本地统计用户',
        role: 'user',
        status: 'banned',
        creditScore: 60,
        createdAt: now,
        updatedAt: now
      });
      productRepository.save({
        id: 'dashboard-local-product',
        sellerId: 'dashboard-local-user',
        title: '本地统计商品',
        desc: '用于验证后台概览远端失败后的本地回退',
        price: 35,
        category: '电子数码',
        images: [],
        locationTag: '教学楼门口',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });
      orderRepository.save({
        id: 'dashboard-local-order',
        productId: 'dashboard-local-product',
        buyerId: 'dashboard-local-user',
        sellerId: 'dashboard-local-user',
        amount: 35,
        address: '操场门口',
        locationTag: '教学楼门口',
        payType: 'simulated',
        status: OrderStatus.PAID_SIMULATED,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'remote-dashboard-fallback-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAdminDashboardClient();
      fakeRemoteClient.failGetDashboard = true;

      const localStats = appContext.getDashboardStats();
      const service = new AdminDashboardServiceImpl(fakeRemoteClient, stateService);
      const result = await service.getStats();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.getDashboardCalled).assertTrue();
      expect(result.message).assertEqual('已使用本地后台统计缓存');
      expect(result.data?.userCount).assertEqual(localStats.userCount);
      expect(result.data?.bannedUserCount).assertEqual(localStats.bannedUserCount);
      expect(result.data?.productCount).assertEqual(localStats.productCount);
      expect(result.data?.paidOrderCount).assertEqual(localStats.paidOrderCount);
    });

    it('admin_dashboard_sync_keys_should_cover_admin_summary_dependencies', 0, () => {
      const keys = buildAdminDashboardSyncKeys();
      expect(keys.length).assertEqual(6);
      expect(keys[0]).assertEqual('admin:verification-changed');
      expect(keys[1]).assertEqual('admin:user-status-changed');
      expect(keys[2]).assertEqual('users:changed');
      expect(keys[3]).assertEqual('products:changed');
      expect(keys[4]).assertEqual('orders:changed');
      expect(keys[5]).assertEqual('announcements:changed');
    });

    it('admin_guard_sync_keys_should_cover_live_admin_access_changes', 0, () => {
      const keys: string[] = buildAdminGuardSyncKeys();
      expect(keys.length).assertEqual(2);
      expect(keys[0]).assertEqual('admin:user-status-changed');
      expect(keys[1]).assertEqual('users:changed');
    });

    it('admin_user_service_should_prefer_remote_user_list_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '90011',
        phone: '19900009011',
        nickname: '远端后台管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const localUser: User = {
        id: '91011',
        phone: '18800009011',
        nickname: '本地校园用户',
        role: 'user',
        status: 'active',
        creditScore: 66,
        schoolName: '湖南人文科技学院',
        verificationStatus: VerificationStatus.VERIFIED,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save(localUser);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'remote-admin-user-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAdminUserClient();
      fakeRemoteClient.listResponse = {
        ok: true,
        message: '远端用户列表成功',
        data: [{
          id: localUser.id,
          phone: localUser.phone,
          nickname: '远端更新后的昵称',
          avatar: '',
          role: 'user',
          status: 'banned',
          credit_score: 88,
          created_at: now - 1000,
          updated_at: now + 10
        }]
      };

      const service = new AdminUserServiceImpl(fakeRemoteClient, stateService);
      const result = await service.listUsers();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.listCalled).assertTrue();
      expect(result.data?.length).assertEqual(1);
      expect(result.data?.[0].nickname).assertEqual('远端更新后的昵称');
      expect(result.data?.[0].status).assertEqual('banned');
      expect(userRepository.getById(localUser.id)?.schoolName).assertEqual('湖南人文科技学院');
      expect(userRepository.getById(localUser.id)?.verificationStatus).assertEqual(VerificationStatus.VERIFIED);
      expect(userRepository.getById(localUser.id)?.creditScore).assertEqual(88);
    });

    it('admin_user_service_should_prefer_remote_status_update_and_preserve_sync_semantics', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '90012',
        phone: '19900009012',
        nickname: '远端状态管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const managedUser: User = {
        id: '91012',
        phone: '18800009012',
        nickname: '待封禁用户',
        role: 'user',
        status: 'active',
        creditScore: 70,
        schoolName: '湖南人文科技学院',
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save(managedUser);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'remote-admin-status-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAdminUserClient();
      fakeRemoteClient.updateStatusResponse = {
        ok: true,
        message: '用户封禁成功',
        data: {
          id: managedUser.id,
          phone: managedUser.phone,
          nickname: managedUser.nickname,
          avatar: '',
          role: 'user',
          status: 'banned',
          credit_score: 70,
          created_at: managedUser.createdAt,
          updated_at: now + 20
        }
      };

      const syncKeys: string[] = [];
      const unsubscribeStatus = syncService.subscribe('admin:user-status-changed', () => {
        syncKeys.push('admin:user-status-changed');
      });
      const unsubscribeUsers = syncService.subscribe('users:changed', () => {
        syncKeys.push('users:changed');
      });

      const service = new AdminUserServiceImpl(fakeRemoteClient, stateService);
      const result = await service.updateUserStatus(managedUser.id, 'banned');

      unsubscribeStatus();
      unsubscribeUsers();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.updateStatusCalled).assertTrue();
      expect(fakeRemoteClient.lastUpdateToken).assertEqual('remote-admin-status-token');
      expect(fakeRemoteClient.lastUpdateUserId).assertEqual(managedUser.id);
      expect(fakeRemoteClient.lastUpdatePayload?.status).assertEqual('banned');
      expect(userRepository.getById(managedUser.id)?.status).assertEqual('banned');
      expect(syncKeys.includes('admin:user-status-changed')).assertTrue();
      expect(syncKeys.includes('users:changed')).assertTrue();
    });

    it('admin_user_status_payload_should_support_extended_restriction_statuses', 0, () => {
      const mutedPayload = new RemoteAdminUserStatusPayload('muted');
      const restrictedPayload = new RemoteAdminUserStatusPayload('restricted');
      const suspendedPayload = new RemoteAdminUserStatusPayload('suspended');

      expect(mutedPayload.status).assertEqual('muted');
      expect(restrictedPayload.status).assertEqual('restricted');
      expect(suspendedPayload.status).assertEqual('suspended');
    });

    it('admin_user_service_should_link_status_changes_with_governance_actions', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '92001',
        phone: '199000092001',
        nickname: '治理联动管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const managedUser: User = {
        id: '92002',
        phone: '188000092002',
        nickname: '治理联动用户',
        role: 'user',
        status: 'active',
        creditScore: 76,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save(managedUser);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'admin-governance-link-token',
        expiresAt: now + 60_000
      });

      const fakeAdminRemoteClient = new FakeRemoteAdminUserClient();
      const fakeGovernanceRemoteClient = new FakeRemoteGovernanceClient();
      const governanceService = new GovernanceServiceImpl(fakeGovernanceRemoteClient, stateService);
      const service = new AdminUserServiceImpl(fakeAdminRemoteClient, stateService, governanceService);

      const restrictResult = await service.updateUserStatus(managedUser.id, 'restricted');

      expect(restrictResult.ok).assertTrue();
      expect(fakeGovernanceRemoteClient.createCalled).assertTrue();
      expect(fakeGovernanceRemoteClient.lastCreatePayload?.user_id).assertEqual(managedUser.id);
      expect(fakeGovernanceRemoteClient.lastCreatePayload?.action_type).assertEqual('restrict_trade');
      expect(governanceRepository.listActiveByUser(managedUser.id).length).assertEqual(1);
      expect(governanceRepository.listActiveByUser(managedUser.id)[0].actionType).assertEqual('restrict_trade');

      const restoreResult = await service.updateUserStatus(managedUser.id, 'active');

      expect(restoreResult.ok).assertTrue();
      expect(fakeGovernanceRemoteClient.cancelCalled).assertTrue();
      expect(governanceRepository.listActiveByUser(managedUser.id).length).assertEqual(0);
    });

    it('admin_product_service_should_prefer_remote_list_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '90015',
        phone: '19900009015',
        nickname: '远端商品管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const localProduct: Product = {
        id: '92015',
        sellerId: 'seller-92015',
        title: '本地待审核商品',
        desc: '用于验证后台商品远端列表回灌',
        price: 48,
        category: '教材书籍',
        images: [],
        locationTag: '图书馆大厅',
        status: 'pending_review',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      productRepository.save(localProduct);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'remote-admin-product-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAdminProductClient();
      fakeRemoteClient.listAdminProductsResponse = {
        ok: true,
        message: '远端后台商品列表成功',
        data: [{
          id: localProduct.id,
          sellerId: localProduct.sellerId,
          title: '远端审核后商品',
          desc: localProduct.desc,
          price: 52,
          category: localProduct.category,
          images: [],
          locationTag: localProduct.locationTag,
          status: 'on_sale',
          isDeleted: false,
          createdAt: now - 5,
          updatedAt: now + 10
        }]
      };

      const service = new AdminProductServiceImpl(fakeRemoteClient, stateService);
      const result = await service.listProducts();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.listAdminProductsCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('remote-admin-product-token');
      expect(result.data?.length).assertEqual(1);
      expect(result.data?.[0].title).assertEqual('远端审核后商品');
      expect(result.data?.[0].status).assertEqual('on_sale');
      expect(productRepository.getById(localProduct.id)?.status).assertEqual('on_sale');
    });

    it('admin_product_service_should_fallback_to_local_approve_and_publish_sync', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '90016',
        phone: '19900009016',
        nickname: '商品回退管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: '92016',
        sellerId: 'seller-92016',
        title: '待回退审核商品',
        desc: '用于验证后台商品审核远端失败后的本地回退',
        price: 66,
        category: '电子数码',
        images: [],
        locationTag: '教学楼门口',
        status: 'pending_review',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      productRepository.save(product);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'remote-admin-product-fallback-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAdminProductClient();
      fakeRemoteClient.failApproveProduct = true;
      const syncKeys: string[] = [];
      const unsubscribe = syncService.subscribe('products:changed', () => {
        syncKeys.push('products:changed');
      });

      const service = new AdminProductServiceImpl(fakeRemoteClient, stateService);
      const result = await service.approveProduct(product.id);

      unsubscribe();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.approveProductCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('remote-admin-product-fallback-token');
      expect(fakeRemoteClient.lastProductId).assertEqual(product.id);
      expect(result.message).assertEqual('商品审核通过');
      expect(productRepository.getById(product.id)?.status).assertEqual('on_sale');
      expect(syncKeys.includes('products:changed')).assertTrue();
    });

    it('marketplace_product_service_should_prefer_remote_public_list_and_hydrate_cache', 0, async () => {
      const now = Date.now();
      const localProduct: Product = {
        id: '93001',
        sellerId: 'seller-93001',
        title: '本地旧商品',
        desc: '用于验证公开商品列表远端回灌',
        price: 32,
        category: '教材书籍',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      productRepository.save(localProduct);

      const fakeRemoteClient = new FakeRemoteMarketplaceProductClient();
      fakeRemoteClient.listProductsResponse = {
        ok: true,
        message: '远端公开商品列表成功',
        data: [{
          id: localProduct.id,
          sellerId: localProduct.sellerId,
          title: '远端新商品标题',
          desc: localProduct.desc,
          price: 45,
          category: localProduct.category,
          images: ['https://example.com/p1.png'],
          locationTag: localProduct.locationTag,
          status: 'on_sale',
          isDeleted: false,
          createdAt: now - 20,
          updatedAt: now + 10
        }]
      };

      const service = new MarketplaceProductServiceImpl(fakeRemoteClient, authStateService);
      const result = await service.listMarketplaceProducts();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.listProductsCalled).assertTrue();
      expect(result.data?.length).assertEqual(1);
      expect(result.data?.[0].title).assertEqual('远端新商品标题');
      expect(productRepository.getById(localProduct.id)?.title).assertEqual('远端新商品标题');
      expect(productRepository.getById(localProduct.id)?.price).assertEqual(45);
    });

    it('marketplace_product_service_should_prefer_remote_my_published_list_and_fallback_to_local_cache', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: '93002',
        phone: '18800009302',
        nickname: '发布用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: now,
        updatedAt: now
      };
      const localProduct: Product = {
        id: '94002',
        sellerId: seller.id,
        title: '本地我的发布',
        desc: '用于验证我的发布远端回退',
        price: 66,
        category: '电子数码',
        images: [],
        locationTag: '教学楼门口',
        status: 'pending_review',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      productRepository.save(localProduct);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: seller,
        token: 'marketplace-my-products-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteMarketplaceProductClient();
      fakeRemoteClient.failListMyProducts = true;

      const service = new MarketplaceProductServiceImpl(fakeRemoteClient, stateService);
      const result = await service.listMyPublishedProducts(seller.id);

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.listMyProductsCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('marketplace-my-products-token');
      expect(result.message).assertEqual('已使用本地我的发布缓存');
      expect(result.data?.length).assertEqual(1);
      expect(result.data?.[0].id).assertEqual(localProduct.id);
    });

    it('marketplace_product_service_should_prefer_remote_create_and_fallback_to_local_submission', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: '93003',
        phone: '18800009303',
        nickname: '远端发布用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        schoolId: 'school-hnrku',
        schoolName: '湖南人文科技学院',
        campusId: 'campus-main',
        campusName: '主校区',
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: seller,
        token: 'marketplace-create-token',
        expiresAt: now + 60_000
      });

      const payload = new RemoteCreateProductPayload(
        '远端发布商品',
        '用于验证商品服务远端优先发布',
        79,
        '电子数码',
        '图书馆大厅',
        '',
        'school-hnrku',
        'campus-main',
        'group-library',
        'location-library-hall'
      );

      const fakeRemoteClient = new FakeRemoteMarketplaceProductClient();
      fakeRemoteClient.createProductResponse = {
        ok: true,
        message: '远端发布商品成功',
        data: {
          id: '95003',
          sellerId: seller.id,
          title: payload.title,
          desc: payload.description,
          price: payload.price,
          category: payload.category,
          images: [],
          locationTag: payload.location_tag,
          schoolId: payload.school_id,
          campusId: payload.campus_id,
          locationGroupId: payload.location_group_id,
          tradeLocationId: payload.trade_location_id,
          status: 'pending_review',
          isDeleted: false,
          createdAt: now,
          updatedAt: now + 10
        }
      };

      const service = new MarketplaceProductServiceImpl(fakeRemoteClient, stateService);
      const result = await service.createMarketplaceProduct(payload, seller.id);

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.createProductCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('marketplace-create-token');
      expect(fakeRemoteClient.lastCreatePayload?.title).assertEqual('远端发布商品');
      expect(result.data?.id).assertEqual('95003');
      expect(productRepository.getById('95003')?.title).assertEqual('远端发布商品');
      expect(notificationService.listByUser(seller.id).some((item) => item.type === 'product_submitted')).assertTrue();
    });

    it('moderation_service_should_prefer_remote_submit_order_complaint_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: '96001',
        phone: '18800009601',
        nickname: '投诉用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);
      const complainedOrder: Order = {
        id: 'order-97001',
        productId: 'product-97001',
        buyerId: reporter.id,
        sellerId: 'seller-97001',
        amount: 66,
        address: '图书馆大厅',
        locationTag: '图书馆大厅',
        payType: 'simulated',
        status: OrderStatus.PAID_SIMULATED,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      };
      orderRepository.save(complainedOrder);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: reporter,
        token: 'moderation-submit-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      const submittedRecord: ModerationRecord = {
        id: '97001',
        reporterId: reporter.id,
        targetType: 'order_complaint',
        targetId: 'order-97001',
        reason: '爽约未到场',
        description: '对方约定后未按时出现，且没有进一步说明。',
        status: 'pending',
        createdAt: now,
        updatedAt: now + 1
      };
      fakeRemoteClient.submitResponse = {
        ok: true,
        message: '投诉提交成功',
        data: submittedRecord
      };

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.submitOrderComplaint(
        'order-97001',
        reporter.id,
        '爽约未到场',
        '对方约定后未按时出现，且没有进一步说明。'
      );

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.submitCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('moderation-submit-token');
      expect(fakeRemoteClient.lastSubmitPayload?.target_type).assertEqual('order_complaint');
      expect(fakeRemoteClient.lastSubmitPayload?.target_id).assertEqual('order-97001');
      expect(result.data?.targetType).assertEqual('order_complaint');
      expect(result.data?.status).assertEqual('pending');
      expect(moderationRepository.getById('97001')?.targetType).assertEqual('order_complaint');
    });

    it('moderation_service_should_list_my_records_and_fallback_to_local_cache', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: '96001-self-list',
        phone: '18800009611',
        nickname: '治理中心用户',
        role: 'user',
        status: 'active',
        creditScore: 89,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);
      moderationRepository.save({
        id: '97001-self-list',
        reporterId: reporter.id,
        targetType: 'product_report',
        targetId: 'product-self-list',
        reason: '疑似违规商品',
        description: '用于验证治理中心本人记录读取',
        evidenceItems: [],
        status: 'pending',
        priority: 'medium',
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: reporter,
        token: 'moderation-my-list-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      fakeRemoteClient.failList = true;

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.listMyModerationRecords(reporter.id);

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.listMyCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('moderation-my-list-token');
      expect(result.data?.length).assertEqual(1);
      expect(result.data?.[0].id).assertEqual('97001-self-list');
    });

    it('moderation_domain_should_support_full_target_types_and_lifecycle_statuses', 0, () => {
      const productTarget: ModerationTargetType = 'product_report';
      const userTarget: ModerationTargetType = 'user_report';
      const triagingStatus: ModerationStatus = 'triaging';
      const awaitingEvidenceStatus: ModerationStatus = 'awaiting_evidence';
      const appealReviewingStatus: ModerationStatus = 'appeal_reviewing';
      const closedStatus: ModerationStatus = 'closed';

      const record: ModerationRecord = {
        id: 'moderation-full-domain',
        reporterId: 'reporter-full-domain',
        targetType: productTarget,
        targetId: 'product-full-domain',
        reportedUserId: 'seller-full-domain',
        relatedProductId: 'product-full-domain',
        category: 'counterfeit_risk',
        reason: '疑似虚假描述',
        description: '商品成色与描述严重不符。',
        evidenceItems: ['https://example.com/evidence/1.png'],
        status: triagingStatus,
        priority: 'high',
        assignedAdminId: 'admin-full-domain',
        resolutionCode: 'needs_manual_review',
        createdAt: 1,
        updatedAt: 2
      };

      expect(productTarget).assertEqual('product_report');
      expect(userTarget).assertEqual('user_report');
      expect(triagingStatus).assertEqual('triaging');
      expect(awaitingEvidenceStatus).assertEqual('awaiting_evidence');
      expect(appealReviewingStatus).assertEqual('appeal_reviewing');
      expect(closedStatus).assertEqual('closed');
      expect(record.category).assertEqual('counterfeit_risk');
      expect(record.priority).assertEqual('high');
      expect(record.evidenceItems?.length).assertEqual(1);
    });

    it('appeal_domain_should_support_first_class_records_statuses_and_eligibility', 0, () => {
      const pendingStatus: AppealStatus = 'pending';
      const reviewStatus: AppealStatus = 'in_review';
      const acceptedStatus: AppealStatus = 'accepted';
      const rejectedStatus: AppealStatus = 'rejected';
      const closedStatus: AppealStatus = 'closed';
      const record: AppealRecord = {
        id: 'appeal-domain-1',
        moderationRecordId: 'moderation-domain-1',
        appellantId: 'user-appeal-1',
        reason: '对处理结果有异议',
        description: '补充说明新的时间线和材料',
        evidenceItems: ['https://example.com/appeal-evidence.png'],
        status: 'pending',
        createdAt: 100,
        updatedAt: 200
      };
      const eligibility: AppealEligibility = {
        moderationRecordId: 'moderation-domain-1',
        appellantId: 'user-appeal-1',
        eligible: true,
        reason: '当前结论允许发起一次申诉'
      };

      expect(pendingStatus).assertEqual('pending');
      expect(reviewStatus).assertEqual('in_review');
      expect(acceptedStatus).assertEqual('accepted');
      expect(rejectedStatus).assertEqual('rejected');
      expect(closedStatus).assertEqual('closed');
      expect(record.evidenceItems.length).assertEqual(1);
      expect(eligibility.eligible).assertTrue();
    });

    it('governance_domain_should_support_action_types_records_and_user_summary', 0, () => {
      const actionType: GovernanceActionType = 'restrict_trade';
      const record: GovernanceAction = {
        id: 'governance-domain-1',
        userId: 'user-governance-1',
        sourceType: 'moderation',
        sourceId: 'moderation-governance-1',
        actionType,
        reason: '多次恶意爽约',
        comment: '限制交易七天',
        startAt: 10,
        endAt: 20,
        active: true,
        createdBy: 'admin-governance-1',
        createdAt: 10,
        updatedAt: 11
      };
      const summary: GovernanceUserSummary = {
        userId: record.userId,
        activeActionTypes: [record.actionType],
        latestAction: record,
        totalActionCount: 2,
        openCaseCount: 1,
        latestActionAt: record.updatedAt
      };

      expect(actionType).assertEqual('restrict_trade');
      expect(record.active).assertTrue();
      expect(summary.activeActionTypes[0]).assertEqual('restrict_trade');
      expect(summary.latestAction?.reason).assertEqual('多次恶意爽约');
    });

    it('remote_moderation_payloads_should_accept_full_governance_targets_and_statuses', 0, () => {
      const productPayload = new RemoteModerationSubmitPayload(
        'product_report',
        'product-complaint-1',
        '疑似违禁商品',
        '商品内容存在明显违规信息。'
      );
      const userPayload = new RemoteModerationSubmitPayload(
        'user_report',
        'user-risk-1',
        '疑似恶意引流',
        '对方多次发送站外联系方式。'
      );
      const reviewPayload = new RemoteModerationReviewPayload('awaiting_evidence', '请补充聊天截图和商品图片');

      expect(productPayload.target_type).assertEqual('product_report');
      expect(userPayload.target_type).assertEqual('user_report');
      expect(reviewPayload.status).assertEqual('awaiting_evidence');
    });

    it('remote_appeal_payloads_should_support_submit_and_review_contracts', 0, () => {
      const remoteItem: RemoteAppealItem = {
        id: 'appeal-97001',
        moderation_record_id: 'moderation-97001',
        appellant_id: 'user-appeal-1',
        reason: '对初审结论有异议',
        description: '补充上传新的聊天截图和交易凭证',
        evidence_items: ['https://example.com/appeal-proof.png'],
        status: 'in_review',
        reviewed_by: 'admin-1',
        review_comment: '已进入复核流程',
        created_at: '2026-04-14T08:00:00.000Z',
        updated_at: '2026-04-14T08:30:00.000Z'
      };
      const submitPayload = new RemoteAppealSubmitPayload(
        'moderation-97001',
        '对初审结论有异议',
        '补充上传新的聊天截图和交易凭证',
        ['https://example.com/appeal-proof.png']
      );
      const reviewPayload = new RemoteAppealReviewPayload('accepted', '复核后接受申诉');

      expect(remoteItem.status).assertEqual('in_review');
      expect(submitPayload.moderation_record_id).assertEqual('moderation-97001');
      expect(submitPayload.evidence_items.length).assertEqual(1);
      expect(reviewPayload.status).assertEqual('accepted');
    });

    it('remote_governance_payloads_should_support_create_cancel_and_summary_contracts', 0, () => {
      const actionItem: RemoteGovernanceActionItem = {
        id: 'governance-remote-1',
        user_id: 'user-governance-1',
        source_type: 'moderation',
        source_id: 'moderation-remote-1',
        action_type: 'temporary_ban',
        reason: '存在风险交易行为',
        comment: '暂停账号 3 天',
        start_at: 100,
        end_at: 200,
        active: true,
        created_by: 'admin-governance-1',
        created_at: 100,
        updated_at: 110
      };
      const createPayload = new RemoteGovernanceActionPayload(
        'user-governance-1',
        'moderation',
        'moderation-remote-1',
        'temporary_ban',
        '存在风险交易行为',
        '暂停账号 3 天',
        100,
        200,
        'admin-governance-1'
      );
      const cancelPayload = new RemoteGovernanceCancelPayload('admin-governance-1', '已整改');
      const summaryItem: RemoteGovernanceUserSummaryItem = {
        user_id: 'user-governance-1',
        active_action_types: ['temporary_ban'],
        total_action_count: 3,
        open_case_count: 1,
        latest_action_at: 110,
        latest_action: actionItem
      };

      expect(actionItem.action_type).assertEqual('temporary_ban');
      expect(createPayload.action_type).assertEqual('temporary_ban');
      expect(cancelPayload.comment).assertEqual('已整改');
      expect(summaryItem.active_action_types.length).assertEqual(1);
    });

    it('appeal_ui_should_only_allow_entry_for_eligible_records_without_open_appeal', 0, () => {
      const moderationRecord: ModerationRecord = {
        id: 'appeal-entry-record-1',
        reporterId: 'user-appeal-entry',
        targetType: 'order_complaint',
        targetId: 'order-appeal-entry',
        reason: '交易纠纷',
        description: '需要验证申诉入口资格',
        evidenceItems: [],
        status: 'resolved_rejected',
        priority: 'medium',
        createdAt: 1,
        updatedAt: 2
      };
      const openAppeal: AppealRecord = {
        id: 'appeal-open-1',
        moderationRecordId: moderationRecord.id,
        appellantId: moderationRecord.reporterId,
        reason: '已有申诉',
        description: '已有进行中的申诉',
        evidenceItems: [],
        status: 'pending',
        createdAt: 3,
        updatedAt: 4
      };
      const pendingRecord: ModerationRecord = {
        id: moderationRecord.id,
        reporterId: moderationRecord.reporterId,
        targetType: moderationRecord.targetType,
        targetId: moderationRecord.targetId,
        reason: moderationRecord.reason,
        description: moderationRecord.description,
        evidenceItems: moderationRecord.evidenceItems,
        status: 'pending',
        priority: moderationRecord.priority,
        createdAt: moderationRecord.createdAt,
        updatedAt: moderationRecord.updatedAt
      };

      expect(canSubmitAppealForModerationRecord(moderationRecord, [])).assertTrue();
      expect(canSubmitAppealForModerationRecord(moderationRecord, [openAppeal])).assertFalse();
      expect(canSubmitAppealForModerationRecord(pendingRecord, [])).assertFalse();
    });

    it('appeal_ui_should_offer_admin_review_actions_by_status', 0, () => {
      const pendingActions = getAppealReviewActions('pending');
      const reviewActions = getAppealReviewActions('in_review');
      const acceptedActions = getAppealReviewActions('accepted');
      const closedActions = getAppealReviewActions('closed');

      expect(pendingActions.includes('accept')).assertTrue();
      expect(pendingActions.includes('reject')).assertTrue();
      expect(reviewActions.includes('close')).assertTrue();
      expect(acceptedActions.includes('close')).assertTrue();
      expect(closedActions.length).assertEqual(0);
      expect(getAppealReviewActionLabel('accept')).assertEqual('接受申诉');
      expect(getAppealReviewActionLabel('reject')).assertEqual('驳回申诉');
    });

    it('governance_timeline_should_build_moderation_steps_for_awaiting_evidence_case', 0, () => {
      const record: ModerationRecord = {
        id: 'moderation-timeline-1',
        reporterId: 'timeline-user-1',
        targetType: 'order_complaint',
        targetId: 'order-timeline-1',
        relatedOrderId: 'order-timeline-1',
        reason: '线下交易纠纷',
        description: '平台正在等待补充截图和时间点',
        evidenceItems: ['https://example.com/evidence-1.png'],
        status: 'awaiting_evidence',
        priority: 'high',
        createdAt: 100,
        updatedAt: 200
      };

      const noAppeals: AppealRecord[] = [];
      const steps: GovernanceTimelineStep[] = buildModerationTimelineSteps(record, noAppeals);
      const summary = buildGovernanceCenterTimelineLabel(record, noAppeals);

      expect(steps.length).assertEqual(5);
      expect(steps[0].label).assertEqual('已提交');
      expect(steps[0].state).assertEqual('done');
      expect(steps[1].state).assertEqual('done');
      expect(steps[2].label).assertEqual('补充材料');
      expect(steps[2].state).assertEqual('current');
      expect(summary).assertEqual('平台需要补充更完整的截图、订单或沟通材料后再继续判断。');
    });

    it('governance_timeline_should_reflect_appeal_stage_for_appealed_moderation_case', 0, () => {
      const record: ModerationRecord = {
        id: 'moderation-timeline-2',
        reporterId: 'timeline-user-2',
        targetType: 'chat_report',
        targetId: 'thread-timeline-2',
        relatedThreadId: 'thread-timeline-2',
        reason: '恶意言语',
        description: '举报后已进入申诉',
        evidenceItems: [],
        status: 'appealed',
        priority: 'medium',
        createdAt: 300,
        updatedAt: 500
      };
      const appealRecord: AppealRecord = {
        id: 'appeal-timeline-2',
        moderationRecordId: record.id,
        appellantId: record.reporterId,
        reason: '补充新的聊天截图',
        description: '补充新的时间线和材料',
        evidenceItems: ['https://example.com/appeal-evidence-2.png'],
        status: 'in_review',
        createdAt: 400,
        updatedAt: 600
      };

      const steps: GovernanceTimelineStep[] = buildModerationTimelineSteps(record, [appealRecord]);
      const summary = buildGovernanceCenterTimelineLabel(record, [appealRecord]);

      expect(steps[3].label).assertEqual('平台结论');
      expect(steps[3].state).assertEqual('done');
      expect(steps[4].label).assertEqual('申诉复核');
      expect(steps[4].state).assertEqual('current');
      expect(summary).assertEqual('平台正在复核这次申诉，后续会同步处理结果。');
    });

    it('governance_timeline_should_build_appeal_summary_by_review_status', 0, () => {
      const appealRecord: AppealRecord = {
        id: 'appeal-timeline-3',
        moderationRecordId: 'moderation-timeline-3',
        appellantId: 'timeline-user-3',
        reason: '重新核对',
        description: '已补充更多截图',
        evidenceItems: [],
        status: 'accepted',
        reviewComment: '申诉成立，进入纠偏',
        createdAt: 700,
        updatedAt: 900
      };

      expect(buildAppealTimelineSummary(appealRecord)).assertEqual('平台已接受本次申诉，案件会进入进一步复核与纠偏处理。');
    });

    it('governance_center_copy_should_build_clean_labels_and_titles', 0, () => {
      expect(getGovernanceCenterTargetLabel('product_report')).assertEqual('商品举报');
      expect(getGovernanceCenterTargetLabel('order_complaint')).assertEqual('订单投诉');
      expect(getGovernanceCenterModerationStatusLabel('appeal_reviewing')).assertEqual('申诉复核中');
      expect(getGovernanceCenterAppealStatusLabel('accepted')).assertEqual('申诉成立');
      expect(buildGovernanceCenterPageTitle()).assertEqual('治理中心');
      expect(buildGovernanceCenterEntryActionLabel('trader')).assertEqual('查看治理中心');
      expect(buildGovernanceCenterEntryActionLabel('admin')).assertEqual('进入后台治理台');
      expect(buildGovernanceCenterEntryActionLabel('guest')).assertEqual('去登录');
      expect(buildGovernanceCenterSectionTitle('actions')).assertEqual('当前生效限制');
      expect(buildGovernanceCenterSectionTitle('appeals')).assertEqual('申诉记录');
      expect(buildGovernanceCenterTimelineTitle('moderation')).assertEqual('处理进度');
      expect(buildGovernanceCenterTimelineTitle('appeal')).assertEqual('申诉进度');
      expect(buildGovernanceCenterSummaryCardCopy('open_appeal').helper).assertEqual('等待结果');
      expect(buildGovernanceCenterAppealEmptyState().title).assertEqual('当前还没有申诉记录');
      expect(buildGovernanceCenterAppealBadgeLabel()).assertEqual('申诉记录');
      expect(buildGovernanceCenterReviewCommentPrefix()).assertEqual('处理备注：');
      expect(buildGovernanceCenterReviewCommentText('平台已收到补充材料')).assertEqual(
        '处理备注：平台已收到补充材料'
      );
      expect(buildGovernanceCenterSubmittedMeta('昨天 10:00', '今天 09:00')).assertEqual(
        '提交于 昨天 10:00 / 最近更新 今天 09:00'
      );
      expect(buildGovernanceCenterAppealSubmitTitle('恶意爽约')).assertEqual(
        '针对“恶意爽约”补充新的说明和证据后，可在这里提交申诉。'
      );
    });

    it('moderation_submit_copy_should_build_clean_titles_and_validation_messages', 0, () => {
      expect(buildSubmitModerationPageTitle('chat_report')).assertEqual('提交会话举报');
      expect(buildSubmitModerationReasonSuggestions('user_report')[0]).assertEqual('疑似恶意引流');
      expect(buildSubmitModerationReasonLabel()).assertEqual('请选择问题类型');
      expect(buildSubmitModerationDescriptionLabel()).assertEqual('请补充情况说明');
      expect(buildSubmitModerationDescriptionPlaceholder()).assertEqual(
        '尽量说明具体场景、对方行为、关键时间点，以及你希望平台关注的问题。'
      );
      expect(buildSubmitModerationValidationMessage('login')).assertEqual('请先登录后再继续');
      expect(buildSubmitAppealPageHeading()).assertEqual('提交申诉');
      expect(buildSubmitAppealReasonLabel()).assertEqual('申诉原因');
      expect(buildSubmitAppealDescriptionLabel()).assertEqual('申诉说明');
      expect(buildSubmitAppealValidationMessage('description')).assertEqual('请补充更具体的申诉说明');
    });

    it('admin_navigation_should_expose_clean_dashboard_entries', 0, () => {
      const entries = getAdminDashboardEntries();
      const moderationEntry = entries.find((item) => item.url === 'pages/Admin/AdminModerationPage');
      expect(moderationEntry?.title).assertEqual('举报处理');
      expect(moderationEntry?.description).assertEqual('集中查看商品、用户、订单、会话治理记录并输出处理结论。');
    });

    it('governance_summary_ui_should_distinguish_clean_and_restricted_accounts', 0, () => {
      const cleanSummary: GovernanceUserSummary = {
        userId: 'governance-summary-clean',
        activeActionTypes: [],
        totalActionCount: 0,
        openCaseCount: 0,
        latestActionAt: 0
      };
      const restrictedSummary: GovernanceUserSummary = {
        userId: 'governance-summary-restricted',
        activeActionTypes: ['restrict_trade', 'mute_chat'],
        latestAction: {
          id: 'governance-summary-action-1',
          userId: 'governance-summary-restricted',
          sourceType: 'manual_admin',
          sourceId: 'manual-summary-1',
          actionType: 'restrict_trade',
          reason: '多次异常交易',
          comment: '限制交易并禁言',
          startAt: 10,
          endAt: 20,
          active: true,
          createdBy: 'admin-summary-1',
          createdAt: 10,
          updatedAt: 11
        },
        totalActionCount: 3,
        openCaseCount: 1,
        latestActionAt: 11
      };

      const cleanPresentation: GovernanceSummaryPresentation = buildGovernanceSummaryPresentation(cleanSummary);
      const restrictedPresentation: GovernanceSummaryPresentation = buildGovernanceSummaryPresentation(restrictedSummary);

      expect(cleanPresentation.tone).assertEqual('calm');
      expect(cleanPresentation.title).assertEqual('当前没有生效中的治理限制');
      expect(restrictedPresentation.tone).assertEqual('warning');
      expect(restrictedPresentation.title.includes('当前账号存在')).assertTrue();
      expect(restrictedPresentation.badges.length).assertEqual(2);
      expect(restrictedPresentation.description.includes('多次异常交易')).assertTrue();
    });

    it('governance_summary_ui_should_build_public_active_action_copy', 0, () => {
      const actionPresentation: GovernanceActiveActionPresentation = buildGovernanceActiveActionPresentation({
        id: 'governance-public-action-1',
        userId: 'governance-public-user-1',
        sourceType: 'moderation',
        sourceId: 'moderation-public-1',
        actionType: 'restrict_trade',
        reason: '多次异常交易',
        comment: '限制交易并等待复核',
        startAt: 100,
        endAt: 200,
        active: true,
        createdBy: 'admin-public-1',
        createdAt: 100,
        updatedAt: 100
      });

      expect(actionPresentation.title).assertEqual('当前交易权限受限');
      expect(actionPresentation.detail.includes('原因：多次异常交易')).assertTrue();
      expect(actionPresentation.hint.includes('交易入口会受到限制')).assertTrue();
      expect(actionPresentation.tone).assertEqual('warning');
    });

    it('governance_resolution_copy_should_build_consistent_result_and_recovery_messages', 0, () => {
      expect(buildGovernanceRecoveryCondition('restrict_trade')).assertEqual('治理动作解除或复核通过后，交易入口会恢复开放。');
      expect(buildModerationResultSummary('resolved_partial', 'product_report')).assertEqual('平台已核实案件部分成立，会保留处理结论并采取保守治理措施。');
      expect(buildModerationRecoveryGuidance('resolved_valid', 'chat_report')).assertEqual('限制到期或平台完成复核后，聊天能力会恢复正常。');
      expect(buildAppealResultSummary('accepted')).assertEqual('平台已接受本次申诉，案件会进入进一步复核与纠偏处理。');
      expect(buildAppealNextStepGuidance('rejected')).assertEqual('若仍有新的关键证据，可在后续补充说明中继续沟通。');
    });

    it('governance_resolution_copy_should_build_default_admin_comments_from_shared_summary', 0, () => {
      expect(buildDefaultModerationAdminComment('resolve_valid', 'order_complaint')).assertEqual(
        '平台已核实案件成立，并会按结论继续采取治理措施。'
      );
      expect(buildDefaultModerationAdminComment('request_evidence', 'chat_report')).assertEqual(
        '平台需要补充更完整的截图、订单或沟通材料后再继续判断。'
      );
      expect(buildDefaultAppealReviewComment('accept')).assertEqual(
        '平台已接受本次申诉，案件会进入进一步复核与纠偏处理。'
      );
      expect(buildDefaultAppealReviewComment('close')).assertEqual(
        '本次申诉复核已完成，案件已正式结案。'
      );
    });

    it('appeal_service_should_submit_with_local_fallback_and_publish_sync', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: 'appeal-user-1',
        phone: '18800009701',
        nickname: '申诉用户',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const moderationRecord: ModerationRecord = {
        id: 'moderation-appeal-1',
        reporterId: reporter.id,
        targetType: 'order_complaint',
        targetId: 'order-appeal-1',
        relatedOrderId: 'order-appeal-1',
        reason: '交易纠纷',
        description: '首次处理结果仍有争议',
        evidenceItems: [],
        status: 'resolved_rejected',
        priority: 'medium',
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);
      moderationRepository.save(moderationRecord);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: reporter,
        token: 'appeal-submit-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAppealClient();
      fakeRemoteClient.failSubmit = true;
      const syncKeys: string[] = [];
      const unsubscribeAppeal = syncService.subscribe('appeals:changed', () => {
        syncKeys.push('appeals:changed');
      });
      const unsubscribeModeration = syncService.subscribe('moderation:changed', () => {
        syncKeys.push('moderation:changed');
      });

      const service = new AppealServiceImpl(fakeRemoteClient, stateService);
      const result = await service.submitAppeal(
        moderationRecord.id,
        reporter.id,
        '我有新的证据',
        '补充上传新的聊天截图和到场时间证明',
        ['https://example.com/appeal-proof-1.png']
      );

      unsubscribeAppeal();
      unsubscribeModeration();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.submitCalled).assertTrue();
      expect(result.data?.status).assertEqual('pending');
      expect(appealRepository.listByAppellant(reporter.id).length).assertEqual(1);
      expect(moderationRepository.getById(moderationRecord.id)?.status).assertEqual('appealed');
      expect(syncKeys.includes('appeals:changed')).assertTrue();
      expect(syncKeys.includes('moderation:changed')).assertTrue();
    });

    it('appeal_service_should_prefer_remote_my_list_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: 'appeal-user-2',
        phone: '18800009702',
        nickname: '申诉查看用户',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: reporter,
        token: 'appeal-list-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAppealClient();
      fakeRemoteClient.listMyResponse = {
        ok: true,
        message: '远端我的申诉列表成功',
        data: [{
          id: 'appeal-remote-2',
          moderationRecordId: 'moderation-remote-2',
          appellantId: reporter.id,
          reason: '对结论有异议',
          description: '补充上传新的截图说明',
          evidenceItems: ['https://example.com/appeal-proof-2.png'],
          status: 'in_review',
          createdAt: now,
          updatedAt: now + 10
        }]
      };

      const service = new AppealServiceImpl(fakeRemoteClient, stateService);
      const result = await service.listMyAppeals(reporter.id);

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.listMyCalled).assertTrue();
      expect(fakeRemoteClient.lastToken).assertEqual('appeal-list-token');
      expect(result.data?.length).assertEqual(1);
      expect(appealRepository.getById('appeal-remote-2')?.status).assertEqual('in_review');
    });

    it('appeal_service_should_review_remote_and_notify_appellant', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: 'appeal-user-3',
        phone: '18800009703',
        nickname: '申诉复核用户',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: now,
        updatedAt: now
      };
      const admin: User = {
        id: 'appeal-admin-1',
        phone: '19900009703',
        nickname: '申诉管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);
      userRepository.save(admin);
      moderationRepository.save({
        id: 'moderation-appeal-3',
        reporterId: reporter.id,
        targetType: 'chat_report',
        targetId: 'thread-appeal-3',
        relatedThreadId: 'thread-appeal-3',
        reason: '聊天违规',
        description: '需要继续复核',
        evidenceItems: [],
        status: 'appealed',
        priority: 'high',
        createdAt: now,
        updatedAt: now
      });
      appealRepository.save({
        id: 'appeal-review-3',
        moderationRecordId: 'moderation-appeal-3',
        appellantId: reporter.id,
        reason: '补充提交新证据',
        description: '申诉说明',
        evidenceItems: [],
        status: 'pending',
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'appeal-review-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteAppealClient();
      fakeRemoteClient.reviewResponse = {
        ok: true,
        message: '申诉审核完成',
        data: {
          id: 'appeal-review-3',
          moderationRecordId: 'moderation-appeal-3',
          appellantId: reporter.id,
          reason: '补充提交新证据',
          description: '申诉说明',
          evidenceItems: [],
          status: 'accepted',
          reviewedBy: admin.id,
          reviewComment: '申诉成立，进入复核修正',
          reviewedAt: now + 10,
          createdAt: now,
          updatedAt: now + 10
        }
      };

      const beforeCount = notificationService.listByUser(reporter.id).length;
      const service = new AppealServiceImpl(fakeRemoteClient, stateService);
      const result = await service.reviewAppeal('appeal-review-3', 'accepted', '申诉成立，进入复核修正');

      expect(result.ok).assertTrue();
      expect(result.message).assertEqual(
        '平台已接受本次申诉，案件会进入进一步复核与纠偏处理。 你可以继续在治理中心查看案件纠偏进展和后续治理结果。'
      );
      expect(fakeRemoteClient.reviewCalled).assertTrue();
      expect(fakeRemoteClient.lastAppealId).assertEqual('appeal-review-3');
      expect(result.data?.status).assertEqual('accepted');
      expect(appealRepository.getById('appeal-review-3')?.status).assertEqual('accepted');
      expect(moderationRepository.getById('moderation-appeal-3')?.status).assertEqual('appeal_reviewing');
      const notifications = notificationService.listByUser(reporter.id);
      expect(notifications.length).assertEqual(beforeCount + 1);
      expect(notifications[0].summary.includes('平台已接受本次申诉')).assertTrue();
      expect(notifications[0].summary.includes('你可以继续在治理中心查看案件纠偏进展')).assertTrue();
    });

    it('governance_service_should_create_action_with_local_fallback_and_publish_sync', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: 'governance-admin-1',
        phone: '19900009801',
        nickname: '治理管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const targetUser: User = {
        id: 'governance-user-1',
        phone: '18800009801',
        nickname: '被治理用户',
        role: 'user',
        status: 'active',
        creditScore: 74,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save(targetUser);
      moderationRepository.save({
        id: 'moderation-governance-1',
        reporterId: 'reporter-governance-1',
        reportedUserId: targetUser.id,
        targetType: 'order_complaint',
        targetId: 'order-governance-1',
        relatedOrderId: 'order-governance-1',
        reason: '恶意爽约',
        description: '需要施加治理动作',
        evidenceItems: [],
        status: 'resolved_valid',
        priority: 'high',
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'governance-create-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteGovernanceClient();
      fakeRemoteClient.failCreate = true;
      const syncKeys: string[] = [];
      const unsubscribe = syncService.subscribe('governance:changed', () => {
        syncKeys.push('governance:changed');
      });

      const service = new GovernanceServiceImpl(fakeRemoteClient, stateService);
      const result = await service.createAction(
        targetUser.id,
        'moderation',
        'moderation-governance-1',
        'restrict_trade',
        '多次恶意爽约',
        '限制交易七天',
        now,
        now + 7 * 24 * 60 * 60 * 1000
      );

      unsubscribe();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.createCalled).assertTrue();
      expect(result.data?.actionType).assertEqual('restrict_trade');
      expect(governanceRepository.listByUser(targetUser.id).length).assertEqual(1);
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('restricted');
      expect(moderationRepository.getById('moderation-governance-1')?.governanceActionId?.length).assertLarger(0);
      expect(syncKeys.includes('governance:changed')).assertTrue();
    });

    it('governance_service_should_cancel_action_and_close_local_record', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: 'governance-admin-2',
        phone: '19900009802',
        nickname: '治理管理员二号',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const targetUser: User = {
        id: 'governance-user-2',
        phone: '18800009802',
        nickname: '治理目标用户',
        role: 'user',
        status: 'active',
        creditScore: 78,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save(targetUser);
      governanceRepository.save({
        id: 'governance-action-2',
        userId: targetUser.id,
        sourceType: 'manual_admin',
        sourceId: 'manual-governance-2',
        actionType: 'warning',
        reason: '发布信息不完整',
        comment: '先给予警告',
        startAt: now,
        active: true,
        createdBy: admin.id,
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'governance-cancel-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteGovernanceClient();
      fakeRemoteClient.failCancel = true;

      const beforeCount = notificationService.listByUser(targetUser.id).length;
      const service = new GovernanceServiceImpl(fakeRemoteClient, stateService);
      const result = await service.cancelAction('governance-action-2', '已完成整改');

      expect(result.ok).assertTrue();
      expect(result.message).assertEqual('治理动作已解除');
      expect(fakeRemoteClient.cancelCalled).assertTrue();
      expect(governanceRepository.getById('governance-action-2')?.active).assertFalse();
      expect(governanceRepository.getById('governance-action-2')?.canceledBy).assertEqual(admin.id);
      expect(result.data?.comment).assertEqual('已完成整改');
      const notifications = notificationService.listByUser(targetUser.id);
      expect(notifications.length).assertEqual(beforeCount + 1);
      expect(notifications[0].summary.includes('平台已解除当前治理动作')).assertTrue();
      expect(notifications[0].summary.includes('治理中心')).assertTrue();
    });

    it('governance_service_should_prefer_remote_summary_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const targetUser: User = {
        id: 'governance-user-3',
        phone: '18800009803',
        nickname: '治理摘要用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(targetUser);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: targetUser,
        token: 'governance-summary-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteGovernanceClient();
      fakeRemoteClient.summaryResponse = {
        ok: true,
        message: '远端治理摘要成功',
        data: {
          userId: targetUser.id,
          activeActionTypes: ['mute_chat'],
          latestAction: {
            id: 'governance-action-3',
            userId: targetUser.id,
            sourceType: 'manual_admin',
            sourceId: 'manual-governance-3',
            actionType: 'mute_chat',
            reason: '多次辱骂',
            comment: '禁言 3 天',
            startAt: now,
            endAt: now + 3 * 24 * 60 * 60 * 1000,
            active: true,
            createdBy: 'admin-governance-3',
            createdAt: now,
            updatedAt: now + 10
          },
          totalActionCount: 1,
          openCaseCount: 1,
          latestActionAt: now + 10
        }
      };

      const service = new GovernanceServiceImpl(fakeRemoteClient, stateService);
      const result = await service.getUserSummary(targetUser.id);

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.summaryCalled).assertTrue();
      expect(result.data?.activeActionTypes[0]).assertEqual('mute_chat');
      expect(governanceRepository.getById('governance-action-3')?.actionType).assertEqual('mute_chat');
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('muted');
    });

    it('governance_service_should_escalate_and_restore_user_status_based_on_active_actions', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: 'governance-admin-restore-1',
        phone: '19900009804',
        nickname: '治理恢复管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const targetUser: User = {
        id: 'governance-user-restore-1',
        phone: '18800009804',
        nickname: '治理恢复用户',
        role: 'user',
        status: 'active',
        creditScore: 82,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save(targetUser);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'governance-restore-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteGovernanceClient();
      fakeRemoteClient.failCreate = true;
      fakeRemoteClient.failCancel = true;
      const service = new GovernanceServiceImpl(fakeRemoteClient, stateService);

      const muteResult = await service.createAction(
        targetUser.id,
        'manual_admin',
        'manual-mute-1',
        'mute_chat',
        '多次骚扰',
        '先禁言处理',
        now
      );
      expect(muteResult.ok).assertTrue();
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('muted');

      const restrictResult = await service.createAction(
        targetUser.id,
        'manual_admin',
        'manual-restrict-1',
        'restrict_trade',
        '存在严重纠纷',
        '升级为限制交易',
        now + 1
      );
      expect(restrictResult.ok).assertTrue();
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('restricted');

      const warningResult = await service.createAction(
        targetUser.id,
        'manual_admin',
        'manual-warning-1',
        'warning',
        '补充提醒',
        '记录一次平台提醒',
        now + 2
      );
      expect(warningResult.ok).assertTrue();
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('restricted');

      const cancelRestrictResult = await service.cancelAction(restrictResult.data?.id ?? '', '解除交易限制');
      expect(cancelRestrictResult.ok).assertTrue();
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('muted');

      const cancelMuteResult = await service.cancelAction(muteResult.data?.id ?? '', '解除禁言');
      expect(cancelMuteResult.ok).assertTrue();
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('active');
    });

    it('persisted_local_state_should_normalize_richer_moderation_defaults', 0, () => {
      const normalized = normalizePersistedLocalState({
        version: 1,
        moderationRecords: [
          {
            id: 'moderation-normalize-1',
            reporterId: 'reporter-normalize-1',
            targetType: 'user_report',
            targetId: 'user-normalize-1',
            reason: '恶意骚扰',
            description: '对方多次发送骚扰内容。',
            status: 'triaging',
            createdAt: 11,
            updatedAt: 12
          } as ModerationRecord
        ]
      });

      expect(normalized.moderationRecords.length).assertEqual(1);
      expect(normalized.moderationRecords[0].evidenceItems?.length).assertEqual(0);
      expect(normalized.moderationRecords[0].priority).assertEqual('medium');
    });

    it('moderation_repository_should_fill_richer_defaults_when_saving_and_replacing', 0, () => {
      moderationRepository.replaceAll([]);

      const saved = moderationRepository.save({
        id: 'moderation-persist-1',
        reporterId: 'reporter-persist-1',
        targetType: 'product_report',
        targetId: 'product-persist-1',
        reason: '疑似虚假宣传',
        description: '商品介绍存在明显夸大内容。',
        status: 'in_review',
        createdAt: 21,
        updatedAt: 22
      });

      const replaced = moderationRepository.replaceAll([
        {
          id: 'moderation-persist-2',
          reporterId: 'reporter-persist-2',
          targetType: 'user_report',
          targetId: 'user-persist-2',
          reason: '站外引流',
          description: '对方反复发送第三方交易方式。',
          status: 'awaiting_evidence',
          createdAt: 31,
          updatedAt: 32
        }
      ]);

      expect(saved.evidenceItems?.length).assertEqual(0);
      expect(saved.priority).assertEqual('medium');
      expect(replaced[0].evidenceItems?.length).assertEqual(0);
      expect(replaced[0].priority).assertEqual('medium');
    });

    it('moderation_service_should_hydrate_remote_admin_review_list_and_publish_sync', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '96002',
        phone: '19900009602',
        nickname: '审核管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'moderation-admin-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      const listedRecord: ModerationRecord = {
        id: '97002',
        reporterId: '96001',
        targetType: 'chat_report',
        targetId: 'thread-97002',
        reason: '辱骂骚扰',
        description: '会话中出现持续辱骂内容。',
        status: 'pending',
        createdAt: now,
        updatedAt: now + 2
      };
      fakeRemoteClient.listResponse = {
        ok: true,
        message: '举报列表获取成功',
        data: [listedRecord]
      };
      const reviewedRecord: ModerationRecord = {
        id: '97002',
        reporterId: '96001',
        targetType: 'chat_report',
        targetId: 'thread-97002',
        reason: '辱骂骚扰',
        description: '会话中出现持续辱骂内容。',
        status: 'resolved_valid',
        adminComment: '已确认违规，保留处理记录。',
        reviewedBy: admin.id,
        reviewedAt: now + 3,
        createdAt: now,
        updatedAt: now + 3
      };
      fakeRemoteClient.reviewResponse = {
        ok: true,
        message: '审核完成',
        data: reviewedRecord
      };

      const syncKeys: string[] = [];
      const unsubscribe = syncService.subscribe('moderation:changed', () => {
        syncKeys.push('moderation:changed');
      });

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const listResult = await service.listModerationRecords('pending');
      const reviewResult = await service.reviewModerationRecord(
        '97002',
        'resolved_valid',
        '已确认违规，保留处理记录。'
      );

      unsubscribe();

      expect(listResult.ok).assertTrue();
      expect(fakeRemoteClient.listCalled).assertTrue();
      expect(fakeRemoteClient.lastListStatus).assertEqual('pending');
      expect(listResult.data?.[0].targetType).assertEqual('chat_report');
      expect(reviewResult.ok).assertTrue();
      expect(fakeRemoteClient.reviewCalled).assertTrue();
      expect(fakeRemoteClient.lastReviewPayload?.status).assertEqual('resolved_valid');
      expect(moderationRepository.getById('97002')?.status).assertEqual('resolved_valid');
      expect(syncKeys.includes('moderation:changed')).assertTrue();
    });

    it('moderation_review_should_notify_reporter_after_admin_decision', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: '96003',
        phone: '18800009603',
        nickname: '举报人',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: now,
        updatedAt: now
      };
      const admin: User = {
        id: '96004',
        phone: '19900009604',
        nickname: '处理管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);
      userRepository.save(admin);

      const record: ModerationRecord = {
        id: '97003',
        reporterId: reporter.id,
        targetType: 'order_complaint',
        targetId: 'order-97003',
        reason: '爽约未到场',
        description: '对方约定后未按时出现，影响本次交易。',
        status: 'pending',
        createdAt: now,
        updatedAt: now
      };
      moderationRepository.save(record);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'moderation-review-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      fakeRemoteClient.reviewResponse = {
        ok: true,
        message: '审核完成',
        data: {
          id: record.id,
          reporterId: reporter.id,
          targetType: record.targetType,
          targetId: record.targetId,
          reason: record.reason,
          description: record.description,
          status: 'resolved_valid',
          adminComment: '平台已核实情况属实',
          reviewedBy: admin.id,
          reviewedAt: now + 10,
          createdAt: record.createdAt,
          updatedAt: now + 10
        }
      };

      const beforeCount = notificationService.listByUser(reporter.id).length;
      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.reviewModerationRecord(
        record.id,
        'resolved_valid',
        '平台已核实情况属实'
      );

      expect(result.ok).assertTrue();
      expect(result.message).assertEqual('平台已核实案件成立，并会按结论继续采取治理措施。');
      const notifications = notificationService.listByUser(reporter.id);
      expect(notifications.length).assertEqual(beforeCount + 1);
      expect(notifications[0].type).assertEqual('system_notice');
      expect(notifications[0].relatedId).assertEqual(record.id);
      expect(notifications[0].summary.includes('平台已核实案件成立')).assertTrue();
      expect(notifications[0].summary.includes('治理动作解除或复核通过后')).assertTrue();
    });

    it('moderation_service_should_support_triage_lifecycle_action', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '96005',
        phone: '19900009605',
        nickname: '分诊管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      moderationRepository.save({
        id: '97004',
        reporterId: '96003',
        targetType: 'user_report',
        targetId: 'user-97004',
        reason: '反复骚扰',
        description: '对方多次私聊骚扰。',
        evidenceItems: [],
        status: 'pending',
        priority: 'medium',
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'moderation-triage-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      fakeRemoteClient.reviewResponse = {
        ok: true,
        message: '分诊完成',
        data: {
          id: '97004',
          reporterId: '96003',
          targetType: 'user_report',
          targetId: 'user-97004',
          reason: '反复骚扰',
          description: '对方多次私聊骚扰。',
          evidenceItems: [],
          status: 'triaging',
          priority: 'medium',
          adminComment: '已进入平台人工分诊',
          reviewedBy: admin.id,
          reviewedAt: now + 1,
          createdAt: now,
          updatedAt: now + 1
        }
      };

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.triageModerationRecord('97004', '已进入平台人工分诊');

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.reviewCalled).assertTrue();
      expect(result.data?.status).assertEqual('triaging');
    });

    it('moderation_service_should_support_requesting_more_evidence', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '96006',
        phone: '19900009606',
        nickname: '补证管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      moderationRepository.save({
        id: '97005',
        reporterId: '96003',
        targetType: 'chat_report',
        targetId: 'thread-97005',
        reason: '辱骂骚扰',
        description: '会话内持续出现辱骂内容。',
        evidenceItems: [],
        status: 'triaging',
        priority: 'high',
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'moderation-evidence-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      fakeRemoteClient.reviewResponse = {
        ok: true,
        message: '已请求补证',
        data: {
          id: '97005',
          reporterId: '96003',
          targetType: 'chat_report',
          targetId: 'thread-97005',
          reason: '辱骂骚扰',
          description: '会话内持续出现辱骂内容。',
          evidenceItems: [],
          status: 'awaiting_evidence',
          priority: 'high',
          adminComment: '请补充聊天截图和关键时间点',
          reviewedBy: admin.id,
          reviewedAt: now + 2,
          createdAt: now,
          updatedAt: now + 2
        }
      };

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.requestModerationEvidence('97005', '请补充聊天截图和关键时间点');

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.reviewCalled).assertTrue();
      expect(result.data?.status).assertEqual('awaiting_evidence');
    });

    it('moderation_service_should_close_record_with_closed_at_on_local_fallback', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: '96007',
        phone: '19900009607',
        nickname: '结案管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      moderationRepository.save({
        id: '97006',
        reporterId: '96003',
        targetType: 'order_complaint',
        targetId: 'order-97006',
        relatedOrderId: 'order-97006',
        reason: '交易纠纷',
        description: '双方已提交补充说明，等待平台结案。',
        evidenceItems: [],
        status: 'appeal_reviewing',
        priority: 'medium',
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'moderation-close-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      fakeRemoteClient.failReview = true;

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.closeModerationRecord('97006', '申诉复核结束，案件正式结案');

      expect(result.ok).assertTrue();
      expect(result.data?.status).assertEqual('closed');
      expect((result.data?.closedAt ?? 0) > 0).assertTrue();
    });

    it('moderation_service_should_support_product_report_submission', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: '96008',
        phone: '18800009608',
        nickname: '商品举报人',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: now,
        updatedAt: now
      };
      const seller: User = {
        id: '96009',
        phone: '18800009609',
        nickname: '商品卖家',
        role: 'user',
        status: 'active',
        creditScore: 82,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);
      userRepository.save(seller);
      productRepository.save({
        id: 'product-97007',
        sellerId: seller.id,
        title: '二手键盘',
        desc: '描述存在明显疑点',
        price: 99,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: reporter,
        token: 'moderation-product-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      fakeRemoteClient.submitResponse = {
        ok: true,
        message: '商品举报提交成功',
        data: {
          id: '97007',
          reporterId: reporter.id,
          targetType: 'product_report',
          targetId: 'product-97007',
          reportedUserId: seller.id,
          relatedProductId: 'product-97007',
          reason: '疑似虚假宣传',
          description: '商品描述与封面明显不符。',
          evidenceItems: [],
          status: 'pending',
          priority: 'medium',
          createdAt: now,
          updatedAt: now + 1
        }
      };

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.submitProductReport(
        'product-97007',
        reporter.id,
        '疑似虚假宣传',
        '商品描述与封面明显不符。'
      );

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.submitCalled).assertTrue();
      expect(fakeRemoteClient.lastSubmitPayload?.target_type).assertEqual('product_report');
      expect(result.data?.relatedProductId).assertEqual('product-97007');
      expect(result.data?.reportedUserId).assertEqual(seller.id);
    });

    it('moderation_service_should_support_user_report_submission', 0, async () => {
      const now = Date.now();
      const reporter: User = {
        id: '96010',
        phone: '18800009610',
        nickname: '用户举报人',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: now,
        updatedAt: now
      };
      const targetUser: User = {
        id: '96011',
        phone: '18800009611',
        nickname: '被举报用户',
        role: 'user',
        status: 'active',
        creditScore: 60,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(reporter);
      userRepository.save(targetUser);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: reporter,
        token: 'moderation-user-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteModerationClient();
      fakeRemoteClient.submitResponse = {
        ok: true,
        message: '用户举报提交成功',
        data: {
          id: '97008',
          reporterId: reporter.id,
          targetType: 'user_report',
          targetId: targetUser.id,
          reportedUserId: targetUser.id,
          reason: '疑似恶意引流',
          description: '对方频繁要求站外联系。',
          evidenceItems: [],
          status: 'pending',
          priority: 'high',
          createdAt: now,
          updatedAt: now + 1
        }
      };

      const service = new ModerationServiceImpl(fakeRemoteClient, stateService);
      const result = await service.submitUserReport(
        targetUser.id,
        reporter.id,
        '疑似恶意引流',
        '对方频繁要求站外联系。'
      );

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.submitCalled).assertTrue();
      expect(fakeRemoteClient.lastSubmitPayload?.target_type).assertEqual('user_report');
      expect(result.data?.reportedUserId).assertEqual(targetUser.id);
    });

    it('admin_moderation_workbench_should_group_records_into_extended_queues', 0, () => {
      const now = Date.now();
      const summary = buildAdminModerationQueueSummary([
        {
          id: 'moderation-queue-1',
          reporterId: 'u-1',
          targetType: 'product_report',
          targetId: 'p-1',
          reason: '疑似虚假宣传',
          description: '描述严重不符',
          evidenceItems: [],
          status: 'pending',
          priority: 'medium',
          createdAt: now,
          updatedAt: now
        },
        {
          id: 'moderation-queue-2',
          reporterId: 'u-2',
          targetType: 'chat_report',
          targetId: 't-2',
          reason: '辱骂骚扰',
          description: '存在持续辱骂',
          evidenceItems: [],
          status: 'awaiting_evidence',
          priority: 'high',
          createdAt: now,
          updatedAt: now
        },
        {
          id: 'moderation-queue-3',
          reporterId: 'u-3',
          targetType: 'order_complaint',
          targetId: 'o-3',
          reason: '交易纠纷',
          description: '双方各执一词',
          evidenceItems: [],
          status: 'appeal_reviewing',
          priority: 'medium',
          createdAt: now,
          updatedAt: now
        },
        {
          id: 'moderation-queue-4',
          reporterId: 'u-4',
          targetType: 'user_report',
          targetId: 'u-4-target',
          reason: '恶意引流',
          description: '持续诱导站外',
          evidenceItems: [],
          status: 'closed',
          priority: 'low',
          createdAt: now,
          updatedAt: now
        }
      ]);

      expect(summary.get(AdminModerationQueue.PENDING)?.length).assertEqual(1);
      expect(summary.get(AdminModerationQueue.AWAITING_EVIDENCE)?.length).assertEqual(1);
      expect(summary.get(AdminModerationQueue.APPEAL)?.length).assertEqual(1);
      expect(summary.get(AdminModerationQueue.CLOSED)?.length).assertEqual(1);
    });

    it('admin_moderation_workbench_should_offer_actions_by_lifecycle_status', 0, () => {
      const pendingActions = getAdminModerationAvailableActions('pending');
      const triagingActions = getAdminModerationAvailableActions('triaging');
      const appealActions = getAdminModerationAvailableActions('appeal_reviewing');
      const closedActions = getAdminModerationAvailableActions('closed');

      expect(pendingActions.includes('triage')).assertTrue();
      expect(pendingActions.includes('resolve_valid')).assertTrue();
      expect(pendingActions.includes('resolve_partial')).assertTrue();
      expect(triagingActions.includes('request_evidence')).assertTrue();
      expect(triagingActions.includes('resolve_rejected')).assertTrue();
      expect(triagingActions.includes('resolve_partial')).assertTrue();
      expect(appealActions.includes('close')).assertTrue();
      expect(closedActions.length).assertEqual(0);
      expect(getAdminModerationTargetLabel('product_report')).assertEqual('商品举报');
      expect(getAdminModerationTargetLabel('user_report')).assertEqual('用户举报');
      expect(getAdminModerationActionLabel('resolve_partial')).assertEqual('部分成立');
      expect(getAdminModerationRecommendedGovernanceAction('chat_report', 'resolve_valid')).assertEqual('mute_chat');
      expect(getAdminModerationRecommendedGovernanceAction('order_complaint', 'resolve_valid')).assertEqual('restrict_trade');
      expect(getAdminModerationRecommendedGovernanceAction('user_report', 'resolve_partial')).assertEqual('warning');
    });

    it('moderation_service_should_link_valid_review_to_governance_action_when_requested', 0, async () => {
      const now = Date.now();
      const admin: User = {
        id: 'moderation-admin-governance-1',
        phone: '19900009701',
        nickname: '案件治理管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const targetUser: User = {
        id: 'moderation-target-governance-1',
        phone: '18800009701',
        nickname: '被处理用户',
        role: 'user',
        status: 'active',
        creditScore: 65,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(admin);
      userRepository.save(targetUser);
      moderationRepository.save({
        id: 'moderation-review-governance-1',
        reporterId: 'moderation-reporter-governance-1',
        reportedUserId: targetUser.id,
        targetType: 'order_complaint',
        targetId: 'order-review-governance-1',
        relatedOrderId: 'order-review-governance-1',
        reason: '多次爽约',
        description: '平台已核实存在恶意爽约行为。',
        evidenceItems: [],
        status: 'in_review',
        priority: 'high',
        createdAt: now,
        updatedAt: now
      });

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: admin,
        token: 'moderation-governance-review-token',
        expiresAt: now + 60_000
      });

      const fakeModerationRemoteClient = new FakeRemoteModerationClient();
      fakeModerationRemoteClient.reviewResponse = {
        ok: true,
        message: '举报审核成功',
        data: {
          id: 'moderation-review-governance-1',
          reporterId: 'moderation-reporter-governance-1',
          reportedUserId: targetUser.id,
          targetType: 'order_complaint',
          targetId: 'order-review-governance-1',
          relatedOrderId: 'order-review-governance-1',
          reason: '多次爽约',
          description: '平台已核实存在恶意爽约行为。',
          evidenceItems: [],
          status: 'resolved_valid',
          priority: 'high',
          adminComment: '已核实成立，限制交易',
          reviewedBy: admin.id,
          reviewedAt: now + 10,
          createdAt: now,
          updatedAt: now + 10
        }
      };

      const fakeGovernanceRemoteClient = new FakeRemoteGovernanceClient();
      fakeGovernanceRemoteClient.createResponse = {
        ok: true,
        message: '治理动作创建成功',
        data: {
          id: 'governance-from-moderation-1',
          userId: targetUser.id,
          sourceType: 'moderation',
          sourceId: 'moderation-review-governance-1',
          actionType: 'restrict_trade',
          reason: '多次爽约',
          comment: '已核实成立，限制交易',
          startAt: now + 10,
          active: true,
          createdBy: admin.id,
          createdAt: now + 10,
          updatedAt: now + 10
        }
      };

      const governanceService = new GovernanceServiceImpl(fakeGovernanceRemoteClient, stateService);
      const moderationService = new ModerationServiceImpl(fakeModerationRemoteClient, stateService, governanceService);
      const result = await moderationService.reviewModerationRecordWithGovernance(
        'moderation-review-governance-1',
        'resolved_valid',
        '已核实成立，限制交易',
        'restrict_trade'
      );

      expect(result.ok).assertTrue();
      expect(fakeModerationRemoteClient.reviewCalled).assertTrue();
      expect(fakeGovernanceRemoteClient.createCalled).assertTrue();
      expect(fakeGovernanceRemoteClient.lastCreatePayload?.source_type).assertEqual('moderation');
      expect(fakeGovernanceRemoteClient.lastCreatePayload?.source_id).assertEqual('moderation-review-governance-1');
      expect(fakeGovernanceRemoteClient.lastCreatePayload?.action_type).assertEqual('restrict_trade');
      expect(result.data?.governanceActionId).assertEqual('governance-from-moderation-1');
      expect(governanceRepository.getById('governance-from-moderation-1')?.userId).assertEqual(targetUser.id);
      expect(userRepository.getById(targetUser.id)?.status).assertEqual('restricted');
    });

    it('admin_moderation_workbench_should_expose_queue_copy_and_record_summary', 0, () => {
      const summary = buildAdminModerationRecordMetaSummary({
        id: 'moderation-summary-1',
        reporterId: 'u-10',
        reportedUserId: 'u-20',
        relatedProductId: 'p-20',
        targetType: 'product_report',
        targetId: 'p-20',
        reason: '商品描述不符',
        description: '实物与图片完全不一致',
        evidenceItems: ['https://example.com/evidence-1.png'],
        status: 'awaiting_evidence',
        priority: 'high',
        createdAt: 1000,
        updatedAt: 2000
      });

      expect(getAdminModerationQueueLabel(AdminModerationQueue.PENDING)).assertEqual('待处理');
      expect(getAdminModerationQueueDescription(AdminModerationQueue.AWAITING_EVIDENCE).includes('等待补充')).assertTrue();
      expect(getAdminModerationStatusLabel('appeal_reviewing')).assertEqual('申诉复核中');
      expect(getAdminModerationPriorityLabel('urgent')).assertEqual('紧急');
      expect(getAdminModerationActionLabel('request_evidence')).assertEqual('请求补充材料');
      expect(summary.includes('商品举报')).assertTrue();
      expect(summary.includes('高优先级')).assertTrue();
      expect(summary.includes('证据 1 份')).assertTrue();
    });

    it('admin_moderation_copy_should_build_clean_page_copy', 0, () => {
      expect(buildAdminModerationPageTitle()).assertEqual('举报处理');
      expect(buildAdminModerationHeaderDescription()).assertEqual(
        '按待处理、补充材料、申诉复核、已结案四个队列统一推进商品举报、用户举报、订单投诉与申诉处理。'
      );
      expect(buildAdminModerationLoadingCopy().title).assertEqual('正在同步治理记录');
      expect(buildAdminModerationErrorTitle()).assertEqual('治理记录加载失败');
      expect(buildAdminModerationSummaryCardCopy('appeal').helper).assertEqual('复核案件');
      expect(buildAdminModerationSummaryCardCopy('open_appeal').label).assertEqual('申诉处理中');
      expect(buildAdminModerationDetailTitle('moderation')).assertEqual('治理详情');
      expect(buildAdminModerationDetailTitle('appeal')).assertEqual('申诉复核详情');
      expect(buildAdminModerationDetailIntro('appeal')).assertEqual(
        '这里集中处理已经发起申诉的案件，给出接受、驳回或结案结论。'
      );
      expect(buildAdminModerationCommentPlaceholder('appeal')).assertEqual(
        '填写申诉复核备注，说明接受、驳回或结案依据。'
      );
      expect(buildAdminModerationEmptyState('待处理', '集中查看待进入正式处理流程的举报、投诉与申诉案件。').title)
        .assertEqual('待处理暂无记录');
      expect(getAdminModerationAppealStatusLabel('accepted')).assertEqual('申诉成立');
    });

    it('admin_moderation_copy_should_build_detail_copy_and_toasts', 0, () => {
      expect(buildAdminModerationBadgeLabel('appeal')).assertEqual('申诉记录');
      expect(buildAdminModerationFactLabel('reporter')).assertEqual('举报人');
      expect(buildAdminModerationFactLabel('linked_record')).assertEqual('关联治理记录');
      expect(buildAdminModerationGuidanceTitle('moderation')).assertEqual('处理结论与恢复条件');
      expect(buildAdminModerationGuidanceTitle('appeal')).assertEqual('申诉结论与后续说明');
      expect(buildAdminModerationReviewCommentText('处理中说明')).assertEqual('当前处理备注：处理中说明');
      expect(buildAdminModerationLinkedRecordMeta('mod-1')).assertEqual('关联治理记录 mod-1');
      expect(buildAdminModerationUpdatedMeta('2026-04-15 20:30')).assertEqual('更新时间 2026-04-15 20:30');
      expect(buildAdminModerationSelectionToast('moderation')).assertEqual('请先选择一条治理记录');
      expect(buildAdminModerationSelectionToast('appeal')).assertEqual('请先选择一条申诉记录');
    });

    it('message_hub_audience_presentation_should_switch_admin_to_management_copy', 0, () => {
      const guestPresentation = buildMessageHubAudiencePresentation('guest');
      const adminPresentation = buildMessageHubAudiencePresentation('admin');
      const restrictedPresentation = buildMessageHubAudiencePresentation('restricted');
      const traderPresentation = buildMessageHubAudiencePresentation('trader');

      expect(guestPresentation.showThreads).assertFalse();
      expect(guestPresentation.emptyPrimaryActionLabel).assertEqual('去登录');

      expect(adminPresentation.showThreads).assertFalse();
      expect(adminPresentation.headerDescription.includes('管理员账号不参与普通交易沟通')).assertTrue();
      expect(adminPresentation.emptyPrimaryActionLabel).assertEqual('进入后台管理');
      expect(adminPresentation.reminderSectionTitle).assertEqual('后台提醒');

      expect(restrictedPresentation.showThreads).assertFalse();
      expect(restrictedPresentation.headerDescription.includes('账号当前已被限制')).assertTrue();
      expect(restrictedPresentation.emptyPrimaryActionLabel).assertEqual('查看账号状态');
      expect(restrictedPresentation.primaryAction).assertEqual('profile');

      expect(traderPresentation.showThreads).assertTrue();
      expect(traderPresentation.reminderSectionTitle).assertEqual('交易提醒');
      expect(traderPresentation.threadSectionTitle).assertEqual('会话');
    });

    it('governance_center_audience_presentation_should_distinguish_guest_admin_and_restricted_users', 0, () => {
      const guestPresentation = buildGovernanceCenterAudiencePresentation('guest');
      const adminPresentation = buildGovernanceCenterAudiencePresentation('admin');
      const restrictedPresentation = buildGovernanceCenterAudiencePresentation('restricted');
      const traderPresentation = buildGovernanceCenterAudiencePresentation('trader');

      expect(guestPresentation.primaryAction).assertEqual('login');
      expect(guestPresentation.headerDescription.includes('登录后')).assertTrue();

      expect(adminPresentation.primaryAction).assertEqual('admin');
      expect(adminPresentation.emptyTitle).assertEqual('管理员请前往后台治理台');
      expect(adminPresentation.showAppealSection).assertFalse();

      expect(restrictedPresentation.primaryAction).assertEqual('none');
      expect(restrictedPresentation.readOnlyHint.includes('账号当前受限')).assertTrue();
      expect(restrictedPresentation.showAppealSection).assertTrue();

      expect(traderPresentation.primaryAction).assertEqual('none');
      expect(traderPresentation.showAppealSection).assertTrue();
      expect(traderPresentation.headerDescription.includes('举报')).assertTrue();
    });

    it('cart_audience_presentation_should_lock_admins_out_of_marketplace_cart_flow', 0, () => {
      const guestPresentation = buildCartAudiencePresentation('guest');
      const adminPresentation = buildCartAudiencePresentation('admin');
      const restrictedPresentation = buildCartAudiencePresentation('restricted');
      const traderPresentation = buildCartAudiencePresentation('trader');

      expect(guestPresentation.isLocked).assertFalse();
      expect(guestPresentation.emptyPrimaryActionLabel).assertEqual('去登录');

      expect(adminPresentation.isLocked).assertTrue();
      expect(adminPresentation.headerDescription.includes('管理员账号不参与普通交易')).assertTrue();
      expect(adminPresentation.emptyTitle).assertEqual('管理员不使用购物车');
      expect(adminPresentation.emptyPrimaryActionLabel).assertEqual('进入后台管理');

      expect(restrictedPresentation.isLocked).assertTrue();
      expect(restrictedPresentation.headerDescription.includes('账号当前已被限制')).assertTrue();
      expect(restrictedPresentation.emptyTitle).assertEqual('当前账号暂不可使用购物车');
      expect(restrictedPresentation.emptyPrimaryActionLabel).assertEqual('查看账号状态');
      expect(restrictedPresentation.primaryAction).assertEqual('profile');

      expect(traderPresentation.isLocked).assertFalse();
      expect(traderPresentation.emptyPrimaryActionLabel).assertEqual('去首页继续挑选');
    });

    it('my_published_audience_presentation_should_explain_restricted_seller_state', 0, () => {
      const guestPresentation: MyPublishedAudiencePresentation = buildMyPublishedAudiencePresentation('guest');
      const restrictedPresentation: MyPublishedAudiencePresentation = buildMyPublishedAudiencePresentation('restricted');
      const traderPresentation: MyPublishedAudiencePresentation = buildMyPublishedAudiencePresentation('trader');

      expect(guestPresentation.emptyPrimaryActionLabel).assertEqual('去登录');
      expect(guestPresentation.primaryAction).assertEqual('login');

      expect(restrictedPresentation.headerDescription.includes('当前账号已被限制')).assertTrue();
      expect(restrictedPresentation.emptyTitle).assertEqual('当前账号暂不能继续发布商品');
      expect(restrictedPresentation.emptyPrimaryActionLabel).assertEqual('查看账号状态');
      expect(restrictedPresentation.primaryAction).assertEqual('profile');

      expect(traderPresentation.emptyPrimaryActionLabel).assertEqual('去发布商品');
      expect(traderPresentation.primaryAction).assertEqual('publish');
    });

    it('order_list_audience_presentation_should_explain_restricted_read_only_state', 0, () => {
      const guestPresentation: OrderListAudiencePresentation = buildOrderListAudiencePresentation('guest');
      const restrictedPresentation: OrderListAudiencePresentation = buildOrderListAudiencePresentation('restricted');
      const traderPresentation: OrderListAudiencePresentation = buildOrderListAudiencePresentation('trader');

      expect(guestPresentation.emptyPrimaryActionLabel).assertEqual('去登录');
      expect(guestPresentation.primaryAction).assertEqual('login');

      expect(restrictedPresentation.headerDescription.includes('当前账号已被限制')).assertTrue();
      expect(restrictedPresentation.readOnlyHint.includes('仅可查看历史订单')).assertTrue();
      expect(restrictedPresentation.emptyPrimaryActionLabel).assertEqual('查看账号状态');
      expect(restrictedPresentation.primaryAction).assertEqual('profile');

      expect(traderPresentation.readOnlyHint).assertEqual('');
      expect(traderPresentation.emptyPrimaryActionLabel).assertEqual('去逛逛商品');
    });

    it('announcement_audience_presentation_should_only_expose_admin_publish_entry', 0, () => {
      const guestPresentation: AnnouncementAudiencePresentation = buildAnnouncementAudiencePresentation('guest');
      const restrictedPresentation: AnnouncementAudiencePresentation = buildAnnouncementAudiencePresentation('restricted');
      const traderPresentation: AnnouncementAudiencePresentation = buildAnnouncementAudiencePresentation('trader');
      const adminPresentation: AnnouncementAudiencePresentation = buildAnnouncementAudiencePresentation('admin');

      expect(guestPresentation.headerDescription.includes('平台规则')).assertTrue();
      expect(guestPresentation.showPublishAction).assertFalse();

      expect(restrictedPresentation.headerDescription.includes('仅可查看公告')).assertTrue();
      expect(restrictedPresentation.showPublishAction).assertFalse();

      expect(traderPresentation.showPublishAction).assertFalse();

      expect(adminPresentation.headerDescription.includes('管理员')).assertTrue();
      expect(adminPresentation.showPublishAction).assertTrue();
      expect(adminPresentation.publishActionLabel).assertEqual('发布');
    });

    it('mine_tab_audience_presentation_should_distinguish_restricted_admin_from_restricted_trader', 0, () => {
      const restrictedAdminPresentation: MineTabAudiencePresentation = buildMineTabAudiencePresentation({
        id: 'mine-restricted-admin',
        phone: '19900001201',
        nickname: '受限管理员',
        role: 'admin',
        status: 'banned',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      });
      const restrictedTraderPresentation: MineTabAudiencePresentation = buildMineTabAudiencePresentation({
        id: 'mine-restricted-trader',
        phone: '18800001202',
        nickname: '受限普通用户',
        role: 'user',
        status: 'banned',
        creditScore: 60,
        createdAt: 1,
        updatedAt: 1
      });

      expect(restrictedAdminPresentation.showAdminSection).assertFalse();
      expect(restrictedAdminPresentation.showTradeSection).assertFalse();
      expect(restrictedAdminPresentation.platformSectionDescription.includes('账号当前受限')).assertTrue();

      expect(restrictedTraderPresentation.showTradeSection).assertTrue();
      expect(restrictedTraderPresentation.tradeSectionDescription.includes('历史订单')).assertTrue();
      expect(restrictedTraderPresentation.showPlatformSection).assertTrue();
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

      const bannedRouter = new FakeUiContextRouter();
      const bannedPrompt = new FakeUiContextPrompt();
      const bannedHost = new FakeUiContextHost(new FakeUiContext(bannedRouter, bannedPrompt));

      openPublishEntry(bannedHost, {
        id: 'publish-banned-2',
        phone: '18800004444',
        nickname: '封禁用户',
        role: 'user',
        status: 'banned',
        creditScore: 20,
        createdAt: 1,
        updatedAt: 1
      });
      expect(bannedPrompt.toastMessage).assertEqual('该账号已被停用，无法发布商品');
      expect(bannedRouter.pushedUrl).assertEqual('pages/Profile/ProfilePage');
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

    it('message_reminder_route_should_keep_admin_out_of_trade_pages', 0, () => {
      const activeAdmin: User = {
        id: 'reminder-admin-active',
        phone: '19900000045',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedAdmin: User = {
        id: 'reminder-admin-banned',
        phone: '19900000046',
        nickname: '受限管理员',
        role: 'admin',
        status: 'banned',
        creditScore: 55,
        createdAt: 1,
        updatedAt: 1
      };

      const activeAdminTarget: MessageReminderTarget = buildMessageReminderTarget({
        id: 'notification-admin-order',
        userId: activeAdmin.id,
        type: 'order_created',
        title: '订单提醒',
        summary: '管理员旧提醒',
        relatedId: 'order-9001',
        isRead: false,
        createdAt: 1
      }, activeAdmin);
      expect(activeAdminTarget.url).assertEqual('pages/Admin/AdminDashboardPage');

      const bannedAdminTarget: MessageReminderTarget = buildMessageReminderTarget({
        id: 'notification-admin-product',
        userId: bannedAdmin.id,
        type: 'product_approved',
        title: '商品通过提醒',
        summary: '受限管理员旧提醒',
        relatedId: 'product-9001',
        isRead: false,
        createdAt: 1
      }, bannedAdmin);
      expect(bannedAdminTarget.url).assertEqual('pages/Profile/ProfilePage');
    });

    it('message_reminder_route_should_route_trader_notifications_to_matching_pages', 0, () => {
      const trader: User = {
        id: 'reminder-trader',
        phone: '18800007780',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 82,
        createdAt: 1,
        updatedAt: 1
      };

      const productTarget: MessageReminderTarget = buildMessageReminderTarget({
        id: 'notification-product-rejected',
        userId: trader.id,
        type: 'product_rejected',
        title: '审核未通过',
        summary: '去修改后重提',
        relatedId: 'product-1001',
        isRead: false,
        createdAt: 1
      }, trader);
      expect(productTarget.url).assertEqual('pages/Product/MyPublishedProductsPage');

      const orderTarget: MessageReminderTarget = buildMessageReminderTarget({
        id: 'notification-order-created',
        userId: trader.id,
        type: 'order_created',
        title: '订单已创建',
        summary: '继续支付',
        relatedId: 'order-1001',
        isRead: false,
        createdAt: 1
      }, trader);
      expect(orderTarget.url).assertEqual('pages/Order/OrderDetailPage');
      expect(orderTarget.params?.orderId).assertEqual('order-1001');
      expect(orderTarget.params?.source).assertEqual('message');

      const noticeTarget: MessageReminderTarget = buildMessageReminderTarget({
        id: 'notification-system-notice',
        userId: trader.id,
        type: 'system_notice',
        title: '系统公告',
        summary: '请查看公告',
        relatedId: 'announcement-1',
        isRead: false,
        createdAt: 1
      }, trader);
      expect(noticeTarget.url).assertEqual('pages/Announcement/AnnouncementPage');
    });

    it('message_reminder_route_should_filter_trade_reminders_for_admin_and_restricted_audiences', 0, () => {
      const trader: User = {
        id: 'reminder-filter-trader',
        phone: '18800007783',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 84,
        createdAt: 1,
        updatedAt: 1
      };
      const bannedTrader: User = {
        id: 'reminder-filter-banned-trader',
        phone: '18800007784',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 14,
        createdAt: 1,
        updatedAt: 1
      };
      const admin: User = {
        id: 'reminder-filter-admin',
        phone: '19900000048',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const reminders: MessageNotification[] = [
        {
          id: 'notice-1',
          userId: trader.id,
          type: 'system_notice',
          title: '系统提醒',
          summary: '平台规则更新',
          relatedId: 'announcement-2',
          isRead: false,
          createdAt: 3
        },
        {
          id: 'order-1',
          userId: trader.id,
          type: 'order_created',
          title: '订单已创建',
          summary: '继续支付',
          relatedId: 'order-2',
          isRead: false,
          createdAt: 2
        },
        {
          id: 'product-1',
          userId: trader.id,
          type: 'product_rejected',
          title: '审核未通过',
          summary: '去修改',
          relatedId: 'product-2',
          isRead: false,
          createdAt: 1
        }
      ];

      expect(filterMessageHubReminders(trader, reminders).length).assertEqual(3);
      expect(filterMessageHubReminders(admin, reminders).length).assertEqual(1);
      expect(filterMessageHubReminders(admin, reminders)[0].type).assertEqual('system_notice');
      expect(filterMessageHubReminders(bannedTrader, reminders).length).assertEqual(1);
      expect(filterMessageHubReminders(bannedTrader, reminders)[0].type).assertEqual('system_notice');
      expect(filterMessageHubReminders(null, reminders).length).assertEqual(0);
    });

    it('message_reminder_route_should_count_only_visible_unread_reminders', 0, () => {
      const trader: User = {
        id: 'reminder-count-trader',
        phone: '18800007789',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 86,
        createdAt: 1,
        updatedAt: 1
      };
      const admin: User = {
        id: 'reminder-count-admin',
        phone: '19900000051',
        nickname: '管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: 1,
        updatedAt: 1
      };
      const restrictedTrader: User = {
        id: 'reminder-count-restricted',
        phone: '18800007790',
        nickname: '受限用户',
        role: 'user',
        status: 'banned',
        creditScore: 16,
        createdAt: 1,
        updatedAt: 1
      };
      const reminders: MessageNotification[] = [
        {
          id: 'notice-unread',
          userId: trader.id,
          type: 'system_notice',
          title: '公告',
          summary: '未读公告',
          relatedId: 'announcement-3',
          isRead: false,
          createdAt: 3
        },
        {
          id: 'order-read',
          userId: trader.id,
          type: 'order_created',
          title: '订单提醒',
          summary: '已读订单',
          relatedId: 'order-3',
          isRead: true,
          createdAt: 2
        },
        {
          id: 'order-unread',
          userId: trader.id,
          type: 'order_completed',
          title: '订单完成',
          summary: '未读订单',
          relatedId: 'order-4',
          isRead: false,
          createdAt: 1
        }
      ];

      expect(countVisibleMessageHubUnread(trader, reminders)).assertEqual(2);
      expect(countVisibleMessageHubUnread(admin, reminders)).assertEqual(1);
      expect(countVisibleMessageHubUnread(restrictedTrader, reminders)).assertEqual(1);
      expect(countVisibleMessageHubUnread(null, reminders)).assertEqual(0);
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

    it('campus_service_should_allow_restricted_user_to_read_identity_but_block_mutations', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const bannedUser: User = {
        id: 'campus-banned-user',
        phone: '18800009998',
        nickname: '受限校园用户',
        role: 'user',
        status: 'banned',
        creditScore: 35,
        schoolId: 'school-hnrku',
        campusId: 'campus-main',
        campusName: '主校区',
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(bannedUser);
      stateService.saveSession({
        currentUser: bannedUser,
        token: 'banned-campus-token',
        expiresAt: now + 3600 * 1000
      });

      const service = new CampusServiceImpl(new FakeRemoteCampusClient(), stateService);
      const profileResult = await service.getCurrentCampusProfile();
      const verificationResult = await service.getCurrentVerification();
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
        id: 'banned-verification',
        userId: bannedUser.id,
        schoolId: 'school-hnrku',
        campusId: 'campus-main',
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

      expect(profileResult.ok).assertTrue();
      expect(profileResult.data?.campusName).assertEqual('主校区');
      expect(verificationResult.ok).assertTrue();
      expect(verificationResult.data?.studentNo).assertEqual('2024123456');
      expect(updateResult.ok).assertFalse();
      expect(updateResult.message.includes('停用') || updateResult.message.includes('封禁')).assertTrue();
      expect(submitResult.ok).assertFalse();
      expect(submitResult.message.includes('停用') || submitResult.message.includes('封禁')).assertTrue();
    });

    it('campus_review_verification_should_sync_review_result_to_local_user_state', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const adminUser: User = {
        id: 'campus-review-admin',
        phone: '19900000009',
        nickname: '审核管理员',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const applicant: User = {
        id: 'campus-review-user',
        phone: '18800008881',
        nickname: '待审核学生',
        role: 'user',
        status: 'active',
        creditScore: 78,
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(adminUser);
      userRepository.save(applicant);
      stateService.saveSession({
        currentUser: adminUser,
        token: 'campus-review-admin-token',
        expiresAt: now + 3600 * 1000
      });

      const fakeRemoteClient = new FakeRemoteCampusClient();
      fakeRemoteClient.reviewVerificationResponse = {
        code: 0,
        message: '审核通过',
        data: {
          id: 'review-verification-1',
          user_id: applicant.id,
          school_id: 'school-hnu',
          school_name: '湖南大学',
          campus_id: 'campus-main',
          campus_name: '主校区',
          student_no: '224081113',
          grade_year: 2022,
          college_name: '信息科学与工程学院',
          major_name: '计算机科学与技术',
          verification_method: 'MANUAL_STUDENT_CARD',
          material_urls: ['https://example.com/student-card.png'],
          status: VerificationStatus.VERIFIED,
          submitted_at: now - 60000,
          reviewed_at: now,
          reviewed_by: adminUser.id,
          review_comment: '资料齐全，审核通过',
          updated_at: now
        }
      };

      const service = new CampusServiceImpl(fakeRemoteClient, stateService);
      const reviewResult = await service.reviewVerification(
        'review-verification-1',
        VerificationStatus.VERIFIED,
        '资料齐全，审核通过',
        ''
      );

      expect(reviewResult.ok).assertTrue();
      const persistedUser = userRepository.getById(applicant.id);
      expect(persistedUser?.verificationStatus).assertEqual(VerificationStatus.VERIFIED);
      expect(persistedUser?.schoolName).assertEqual('湖南大学');
      expect(persistedUser?.campusName).assertEqual('主校区');
      expect(persistedUser?.collegeName).assertEqual('信息科学与工程学院');
      expect(persistedUser?.majorName).assertEqual('计算机科学与技术');
      expect(persistedUser?.verificationRejectedReason ?? '').assertEqual('');
    });

    it('campus_review_verification_should_publish_admin_sync_event', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const adminUser: User = {
        id: 'campus-review-sync-admin',
        phone: '19900000010',
        nickname: '审核管理员2',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };
      const applicant: User = {
        id: 'campus-review-sync-user',
        phone: '18800008882',
        nickname: '待审核学生2',
        role: 'user',
        status: 'active',
        creditScore: 79,
        verificationStatus: VerificationStatus.PENDING_REVIEW,
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(adminUser);
      userRepository.save(applicant);
      stateService.saveSession({
        currentUser: adminUser,
        token: 'campus-review-sync-token',
        expiresAt: now + 3600 * 1000
      });

      const fakeRemoteClient = new FakeRemoteCampusClient();
      fakeRemoteClient.reviewVerificationResponse = {
        code: 0,
        message: '审核通过',
        data: {
          id: 'review-verification-sync-1',
          user_id: applicant.id,
          school_id: 'school-hnu',
          school_name: '湖南大学',
          campus_id: 'campus-main',
          campus_name: '主校区',
          student_no: '224081114',
          grade_year: 2022,
          college_name: '信息科学与工程学院',
          major_name: '计算机科学与技术',
          verification_method: 'MANUAL_STUDENT_CARD',
          material_urls: ['https://example.com/student-card-2.png'],
          status: VerificationStatus.VERIFIED,
          submitted_at: now - 60000,
          reviewed_at: now,
          reviewed_by: adminUser.id,
          review_comment: '资料齐全，审核通过',
          updated_at: now
        }
      };

      const syncValues: string[] = [];
      const unsubscribe = syncService.subscribe('admin:verification-changed', (payload) => {
        syncValues.push(payload.value);
      });

      const service = new CampusServiceImpl(fakeRemoteClient, stateService);
      const reviewResult = await service.reviewVerification(
        'review-verification-sync-1',
        VerificationStatus.VERIFIED,
        '资料齐全，审核通过',
        ''
      );

      unsubscribe();

      expect(reviewResult.ok).assertTrue();
      expect(syncValues.length > 0).assertTrue();
      expect(syncValues[syncValues.length - 1]).assertEqual('review-verification-sync-1');
    });

    it('campus_admin_operations_should_reject_non_admin_users_before_remote_calls', 0, async () => {
      const adapter = createMemoryPersistenceAdapter();
      const stateService = new AuthStateService(adapter);
      const now = Date.now();
      const normalUser: User = {
        id: 'campus-normal-user',
        phone: '18800001111',
        nickname: '普通用户',
        role: 'user',
        status: 'active',
        creditScore: 76,
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(normalUser);
      stateService.saveSession({
        currentUser: normalUser,
        token: 'campus-normal-token',
        expiresAt: now + 3600 * 1000
      });

      const fakeRemoteClient = new FakeRemoteCampusClient();
      const service = new CampusServiceImpl(fakeRemoteClient, stateService);
      const listResult = await service.listVerificationApplications();
      const reviewResult = await service.reviewVerification(
        'verification-pending-1',
        VerificationStatus.VERIFIED,
        '审核通过',
        ''
      );
      const schoolResult = await service.upsertSchool({
        id: 'school-hnrku',
        name: '湖南人文科技学院',
        shortName: '湖人文',
        city: '娄底',
        isEnabled: true,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now
      });

      expect(listResult.ok).assertFalse();
      expect(reviewResult.ok).assertFalse();
      expect(schoolResult.ok).assertFalse();
      expect(fakeRemoteClient.listVerificationApplicationsCalled).assertFalse();
      expect(fakeRemoteClient.reviewVerificationCalled).assertFalse();
      expect(fakeRemoteClient.upsertSchoolCalled).assertFalse();
    });

    it('campus_admin_operations_should_distinguish_restricted_admin_users_before_remote_calls', 0, async () => {
      const now = Date.now();
      const stateService = new AuthStateService();
      const restrictedAdmin: User = {
        id: 'campus-restricted-admin-user',
        phone: '19900007777',
        nickname: '受限管理员',
        role: 'admin',
        status: 'banned',
        creditScore: 100,
        createdAt: now,
        updatedAt: now
      };

      userRepository.save(restrictedAdmin);
      stateService.saveSession({
        currentUser: restrictedAdmin,
        token: 'campus-restricted-admin-token',
        expiresAt: now + 3600 * 1000
      });

      const fakeRemoteClient = new FakeRemoteCampusClient();
      const service = new CampusServiceImpl(fakeRemoteClient, stateService);
      const listResult = await service.listVerificationApplications();
      const reviewResult = await service.reviewVerification(
        'verification-pending-1',
        VerificationStatus.VERIFIED,
        '审核通过',
        ''
      );
      const schoolResult = await service.upsertSchool({
        id: 'school-hnrku',
        name: '湖南人文科技学院',
        shortName: '湖人文',
        city: '娄底',
        isEnabled: true,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now
      });

      expect(listResult.ok).assertFalse();
      expect(listResult.message).assertEqual(getAdminAccessDeniedMessage(restrictedAdmin));
      expect(reviewResult.ok).assertFalse();
      expect(reviewResult.message).assertEqual(getAdminActionDeniedMessage(restrictedAdmin));
      expect(schoolResult.ok).assertFalse();
      expect(schoolResult.message).assertEqual(getAdminActionDeniedMessage(restrictedAdmin));
      expect(fakeRemoteClient.listVerificationApplicationsCalled).assertFalse();
      expect(fakeRemoteClient.reviewVerificationCalled).assertFalse();
      expect(fakeRemoteClient.upsertSchoolCalled).assertFalse();
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
        completedOrderCount: 6,
        reportCount: 0,
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
      expect(verifiedPresentation.tone).assertEqual('calm');
      expect(verifiedPresentation.riskLabel).assertEqual('低风险');
      expect(verifiedPresentation.summary).assertEqual('湖南大学 / 主校区 / 信息科学与工程学院 / 计算机科学与技术');
      expect(verifiedPresentation.trustTags.includes('完成 6 笔交易')).assertTrue();
      expect(verifiedPresentation.trustTags.includes('当前无生效治理限制')).assertTrue();
      expect(verifiedPresentation.riskText).assertEqual('该账号当前没有生效中的平台治理限制。');
      expect(pendingPresentation.badgeText).assertEqual('审核中');
      expect(pendingPresentation.isTrusted).assertFalse();
      expect(pendingPresentation.tone).assertEqual('caution');
      expect(pendingPresentation.headline).assertEqual('校园身份审核中');
      expect(unverifiedPresentation.badgeText).assertEqual('待确认');
      expect(unverifiedPresentation.isTrusted).assertFalse();
      expect(unverifiedPresentation.tone).assertEqual('caution');
      expect(unknownPresentation.summary).assertEqual('暂未获取到对方的校园资料');
    });

    it('public_campus_trust_presentation_should_surface_governance_and_dispute_signals_conservatively', 0, () => {
      const now = Date.now();
      const governedUser: User = {
        id: 'governed-trusted-user',
        phone: '18812345555',
        nickname: '受治理用户',
        role: 'user',
        status: 'restricted',
        creditScore: 72,
        completedOrderCount: 2,
        reportCount: 3,
        schoolName: '湖南大学',
        campusName: '主校区',
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      };
      governanceRepository.save({
        id: 'trust-governance-action-1',
        userId: governedUser.id,
        sourceType: 'manual_admin',
        sourceId: 'trust-governance-source-1',
        actionType: 'restrict_trade',
        reason: '多次违约',
        comment: '限制交易 7 天',
        startAt: now,
        endAt: now + 7 * 24 * 60 * 60 * 1000,
        active: true,
        createdBy: 'trust-admin-1',
        createdAt: now,
        updatedAt: now
      });
      governanceRepository.save({
        id: 'trust-governance-action-2',
        userId: governedUser.id,
        sourceType: 'manual_admin',
        sourceId: 'trust-governance-source-2',
        actionType: 'mute_chat',
        reason: '辱骂骚扰',
        comment: '聊天禁言 3 天',
        startAt: now,
        endAt: now + 3 * 24 * 60 * 60 * 1000,
        active: true,
        createdBy: 'trust-admin-1',
        createdAt: now,
        updatedAt: now
      });

      const presentation = buildPublicCampusTrustPresentation(governedUser);

      expect(presentation.isTrusted).assertFalse();
      expect(presentation.tone).assertEqual('warning');
      expect(presentation.riskLabel).assertEqual('高风险');
      expect(presentation.trustTags.includes('完成 2 笔交易')).assertTrue();
      expect(presentation.trustTags.includes('历史纠纷 3 次')).assertTrue();
      expect(presentation.trustTags.includes('交易权限受限')).assertTrue();
      expect(presentation.trustTags.includes('聊天禁言')).assertFalse();
      expect(presentation.riskText.includes('部分交易能力已受限')).assertTrue();
    });

    it('public_campus_trust_presentation_should_keep_warning_only_records_as_caution_level_public_signal', 0, () => {
      const now = Date.now();
      const warnedUser: User = {
        id: 'warned-trusted-user',
        phone: '18812349999',
        nickname: '提醒用户',
        role: 'user',
        status: 'active',
        creditScore: 80,
        completedOrderCount: 1,
        reportCount: 0,
        schoolName: '湖南大学',
        campusName: '主校区',
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      };
      governanceRepository.save({
        id: 'trust-governance-warning-1',
        userId: warnedUser.id,
        sourceType: 'manual_admin',
        sourceId: 'trust-governance-warning-source-1',
        actionType: 'warning',
        reason: '轻度违规',
        comment: '提醒规范沟通',
        startAt: now,
        endAt: now + 2 * 24 * 60 * 60 * 1000,
        active: true,
        createdBy: 'trust-admin-1',
        createdAt: now,
        updatedAt: now
      });

      const presentation = buildPublicCampusTrustPresentation(warnedUser);

      expect(presentation.tone).assertEqual('caution');
      expect(presentation.riskLabel).assertEqual('需确认');
      expect(presentation.trustTags.includes('近期收到平台提醒')).assertTrue();
      expect(presentation.riskText.includes('近期收到平台提醒')).assertTrue();
    });

    it('campus_trust_list_snippet_should_keep_compact_risk_and_tag_summary_for_list_surfaces', 0, () => {
      const now = Date.now();
      const trustedUser: User = {
        id: 'list-trusted-user',
        phone: '18812346666',
        nickname: '列表可信用户',
        role: 'user',
        status: 'active',
        creditScore: 91,
        completedOrderCount: 5,
        reportCount: 0,
        schoolName: '湖南大学',
        campusName: '主校区',
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      };

      const snippet = buildCampusTrustListSnippet(trustedUser);

      expect(snippet.badgeText).assertEqual('已认证');
      expect(snippet.riskLabel).assertEqual('低风险');
      expect(snippet.tone).assertEqual('calm');
      expect(snippet.tags.length).assertEqual(2);
      expect(snippet.tags[0]).assertEqual('完成 5 笔交易');
      expect(snippet.tags[1]).assertEqual('当前无生效治理限制');
      expect(snippet.hasMoreTags).assertFalse();
    });

    it('campus_trust_list_snippet_should_truncate_extra_governance_tags_for_dense_lists', 0, () => {
      const now = Date.now();
      const governedUser: User = {
        id: 'list-governed-user',
        phone: '18812347777',
        nickname: '列表治理用户',
        role: 'user',
        status: 'restricted',
        creditScore: 74,
        completedOrderCount: 3,
        reportCount: 2,
        schoolName: '湖南大学',
        campusName: '主校区',
        verificationStatus: VerificationStatus.VERIFIED,
        verifiedAt: now,
        verificationUpdatedAt: now,
        createdAt: now,
        updatedAt: now
      };
      governanceRepository.save({
        id: 'list-governance-action-1',
        userId: governedUser.id,
        sourceType: 'manual_admin',
        sourceId: 'list-governance-source-1',
        actionType: 'restrict_trade',
        reason: '多次违约',
        comment: '限制交易 7 天',
        startAt: now,
        endAt: now + 7 * 24 * 60 * 60 * 1000,
        active: true,
        createdBy: 'trust-admin-1',
        createdAt: now,
        updatedAt: now
      });
      governanceRepository.save({
        id: 'list-governance-action-2',
        userId: governedUser.id,
        sourceType: 'manual_admin',
        sourceId: 'list-governance-source-2',
        actionType: 'mute_chat',
        reason: '辱骂骚扰',
        comment: '聊天禁言 3 天',
        startAt: now,
        endAt: now + 3 * 24 * 60 * 60 * 1000,
        active: true,
        createdBy: 'trust-admin-1',
        createdAt: now,
        updatedAt: now
      });

      const snippet = buildCampusTrustListSnippet(governedUser, 2);

      expect(snippet.riskLabel).assertEqual('高风险');
      expect(snippet.tone).assertEqual('warning');
      expect(snippet.tags.length).assertEqual(2);
      expect(snippet.tags[0]).assertEqual('完成 3 笔交易');
      expect(snippet.tags[1]).assertEqual('历史纠纷 2 次');
      expect(snippet.hasMoreTags).assertTrue();
    });

    it('campus_trust_tone_palette_should_keep_surface_and_chip_colors_consistent', 0, () => {
      const calmPalette = buildCampusTrustTonePalette('calm');
      const warningPalette = buildCampusTrustTonePalette('warning');

      expect(calmPalette.surfaceBackgroundColor).assertEqual('#F7F4EF');
      expect(calmPalette.riskBadgeTextColor).assertEqual('#237B46');
      expect(calmPalette.riskBadgeBackgroundColor).assertEqual('#E8F5EA');
      expect(calmPalette.tagBackgroundColor).assertEqual('#EEF6F1');
      expect(warningPalette.surfaceBackgroundColor).assertEqual('#FFF5EE');
      expect(warningPalette.riskBadgeTextColor).assertEqual('#B8643C');
      expect(warningPalette.riskBadgeBackgroundColor).assertEqual('#FBE7DE');
      expect(warningPalette.tagBackgroundColor).assertEqual('#FBE7DE');
    });

    it('marketplace_user_sync_keys_should_include_governance_refresh_events', 0, () => {
      const keys = buildMarketplaceUserSyncKeys();

      expect(keys.includes('users:changed')).assertTrue();
      expect(keys.includes('governance:changed')).assertTrue();
      expect(keys.includes('moderation:changed')).assertTrue();
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

    it('remote_order_mapping_should_preserve_status_and_trade_fields', 0, () => {
      const mapped = mapRemoteOrderItem({
        id: 3001,
        order_no: 'CM202604130001',
        product_id: 1001,
        buyer_id: 2001,
        seller_id: 2002,
        amount: '58.50',
        address: '图书馆北门面交',
        location_tag: '图书馆大厅',
        pay_type: 'simulated',
        status: 'ready_handover',
        buyer_arrived: 1,
        seller_arrived: 0,
        created_at: '2026-04-13T08:00:00Z',
        updated_at: '2026-04-13T09:00:00Z'
      });

      expect(mapped.id).assertEqual('3001');
      expect(mapped.productId).assertEqual('1001');
      expect(mapped.buyerId).assertEqual('2001');
      expect(mapped.sellerId).assertEqual('2002');
      expect(mapped.amount).assertEqual(58.5);
      expect(mapped.address).assertEqual('图书馆北门面交');
      expect(mapped.locationTag).assertEqual('图书馆大厅');
      expect(mapped.payType).assertEqual('simulated');
      expect(mapped.status).assertEqual(OrderStatus.READY_HANDOVER);
      expect(mapped.buyerArrived).assertTrue();
      expect(mapped.sellerArrived).assertFalse();
      expect(mapped.reviewed).assertFalse();
    });

    it('order_service_should_prefer_remote_create_with_session_token_and_hydrate_local_cache', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: '2002',
        phone: '18820002002',
        nickname: '远端卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: '2001',
        phone: '18820002001',
        nickname: '远端买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: '1001',
        sellerId: seller.id,
        title: '远端订单测试商品',
        desc: '验证订单服务优先使用远端创建',
        price: 58.5,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        schoolId: 'school-hnrku',
        schoolName: '湖南人文科技学院',
        campusId: 'campus-main',
        campusName: '主校区',
        locationGroupId: 'group-library',
        locationGroupName: '图书馆区',
        tradeLocationId: 'location-library-hall',
        tradeLocationName: '图书馆大厅',
        locationSafetyTips: '建议白天交易并现场验货',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      productRepository.save(product);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-order-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteOrderClient();
      fakeRemoteClient.createResponse = {
        ok: true,
        message: '远端下单成功',
        data: {
          id: '3001',
          productId: product.id,
          buyerId: buyer.id,
          sellerId: seller.id,
          amount: product.price,
          address: '图书馆大厅面交',
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
          createdAt: now + 1,
          updatedAt: now + 2
        }
      };

      const orderSignals: string[] = [];
      const productSignals: string[] = [];
      const unsubscribeOrders = syncService.subscribe('orders:changed', (payload) => {
        orderSignals.push(payload.value);
      });
      const unsubscribeProducts = syncService.subscribe('products:changed', (payload) => {
        productSignals.push(payload.value);
      });

      const service = new OrderServiceImpl(fakeRemoteClient, stateService);
      const result = await service.createOrder(buyer.id, product.id, '图书馆大厅面交');

      unsubscribeOrders();
      unsubscribeProducts();

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.createOrderCalled).assertTrue();
      expect(fakeRemoteClient.lastCreateToken).assertEqual('remote-order-token');
      expect(fakeRemoteClient.lastCreatePayload?.product_id).assertEqual(product.id);
      expect(fakeRemoteClient.lastCreatePayload?.location_tag).assertEqual(product.locationTag);
      expect(result.data?.id).assertEqual('3001');
      expect(orderRepository.getById('3001')?.buyerId).assertEqual(buyer.id);
      expect(productRepository.getById(product.id)?.status).assertEqual('locked');
      expect(orderSignals.includes(OrderStatus.PENDING_PAYMENT)).assertTrue();
      expect(productSignals.includes('locked')).assertTrue();
      expect(notificationService.listByUser(buyer.id)[0].type).assertEqual('order_created');
    });

    it('order_service_should_fall_back_to_local_create_when_remote_create_fails', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'fallback-seller',
        phone: '18830003002',
        nickname: '回退卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'fallback-buyer',
        phone: '18830003001',
        nickname: '回退买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: 'product-local-fallback',
        sellerId: seller.id,
        title: '本地回退订单测试商品',
        desc: '验证远端失败后仍沿用本地下单链路',
        price: 42,
        category: '教材书籍',
        images: [],
        locationTag: '教学楼大厅',
        status: 'on_sale',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      productRepository.save(product);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-order-token-fallback',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteOrderClient();
      fakeRemoteClient.failCreate = true;
      const service = new OrderServiceImpl(fakeRemoteClient, stateService);

      const result = await service.createOrder(buyer.id, product.id, '教学楼大厅面交');

      expect(fakeRemoteClient.createOrderCalled).assertTrue();
      expect(result.ok).assertTrue();
      expect(result.message).assertEqual('下单成功，商品已进入交易中');
      expect(result.data?.id.includes('order')).assertTrue();
      expect(orderRepository.getById(result.data!.id)?.buyerId).assertEqual(buyer.id);
      expect(productRepository.getById(product.id)?.status).assertEqual('locked');
    });

    it('order_service_should_hydrate_local_cache_from_remote_order_list', 0, async () => {
      const now = Date.now();
      const buyer: User = {
        id: 'remote-list-buyer',
        phone: '18840004001',
        nickname: '远端列表买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(buyer);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-order-list-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteOrderClient();
      fakeRemoteClient.listResponse = {
        ok: true,
        message: '远端订单列表成功',
        data: [{
          id: '4001',
          productId: '1001',
          buyerId: buyer.id,
          sellerId: 'seller-4001',
          amount: 66,
          address: '图书馆大厅',
          locationTag: '图书馆大厅',
          payType: 'simulated',
          status: OrderStatus.PAID_SIMULATED,
          buyerArrived: false,
          sellerArrived: false,
          reviewed: false,
          createdAt: now + 1,
          updatedAt: now + 2
        }]
      };

      const service = new OrderServiceImpl(fakeRemoteClient, stateService);
      const result = await service.listMyOrders(buyer.id);

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.listMyOrdersCalled).assertTrue();
      expect(fakeRemoteClient.lastListToken).assertEqual('remote-order-list-token');
      expect(result.data?.length).assertEqual(1);
      expect(result.data?.[0].id).assertEqual('4001');
      expect(orderRepository.getById('4001')?.status).assertEqual(OrderStatus.PAID_SIMULATED);
    });

    it('order_service_should_hydrate_local_cache_from_remote_order_detail', 0, async () => {
      const now = Date.now();
      const buyer: User = {
        id: 'remote-detail-buyer',
        phone: '18850005001',
        nickname: '远端详情买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(buyer);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-order-detail-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteOrderClient();
      fakeRemoteClient.detailResponse = {
        ok: true,
        message: '远端订单详情成功',
        data: {
          id: '5001',
          productId: '1002',
          buyerId: buyer.id,
          sellerId: 'seller-5001',
          amount: 79,
          address: '教学楼大厅',
          locationTag: '教学楼大厅',
          payType: 'simulated',
          status: OrderStatus.READY_HANDOVER,
          buyerArrived: true,
          sellerArrived: true,
          reviewed: false,
          createdAt: now + 1,
          updatedAt: now + 2
        }
      };

      const service = new OrderServiceImpl(fakeRemoteClient, stateService);
      const result = await service.getOrderDetail('5001', buyer.id);

      expect(result.ok).assertTrue();
      expect(fakeRemoteClient.getOrderDetailCalled).assertTrue();
      expect(fakeRemoteClient.lastDetailToken).assertEqual('remote-order-detail-token');
      expect(fakeRemoteClient.lastDetailOrderId).assertEqual('5001');
      expect(result.data?.id).assertEqual('5001');
      expect(orderRepository.getById('5001')?.status).assertEqual(OrderStatus.READY_HANDOVER);
    });

    it('order_service_should_fall_back_to_local_order_reads_when_remote_fetch_fails', 0, async () => {
      const now = Date.now();
      const buyer: User = {
        id: 'remote-read-fallback-buyer',
        phone: '18860006001',
        nickname: '读取回退买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const localOrder: Order = {
        id: 'order-read-fallback',
        productId: 'product-read-fallback',
        buyerId: buyer.id,
        sellerId: 'seller-read-fallback',
        amount: 55,
        address: '宿舍楼下',
        locationTag: '宿舍楼下',
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(buyer);
      orderRepository.save(localOrder);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-order-read-fallback-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteOrderClient();
      fakeRemoteClient.failList = true;
      fakeRemoteClient.failDetail = true;

      const service = new OrderServiceImpl(fakeRemoteClient, stateService);
      const listResult = await service.listMyOrders(buyer.id);
      const detailResult = await service.getOrderDetail(localOrder.id, buyer.id);

      expect(fakeRemoteClient.listMyOrdersCalled).assertTrue();
      expect(fakeRemoteClient.getOrderDetailCalled).assertFalse();
      expect(listResult.ok).assertTrue();
      expect(listResult.data?.length).assertEqual(1);
      expect(listResult.data?.[0].id).assertEqual(localOrder.id);
      expect(detailResult.ok).assertTrue();
      expect(detailResult.data?.id).assertEqual(localOrder.id);
    });

    it('order_service_should_prefer_remote_actions_and_hydrate_local_trade_state', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'remote-action-seller',
        phone: '18870007002',
        nickname: '远端动作卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'remote-action-buyer',
        phone: '18870007001',
        nickname: '远端动作买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: '7001',
        sellerId: seller.id,
        title: '远端动作测试商品',
        desc: '验证订单动作优先走远端并同步本地状态',
        price: 75,
        category: '电子数码',
        images: [],
        locationTag: '图书馆大厅',
        status: 'locked',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      const order: Order = {
        id: '7002',
        productId: product.id,
        buyerId: buyer.id,
        sellerId: seller.id,
        amount: product.price,
        address: '图书馆大厅',
        locationTag: product.locationTag,
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      productRepository.save(product);
      orderRepository.save(order);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-order-action-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteOrderClient();
      fakeRemoteClient.payResponse = {
        ok: true,
        message: '远端支付成功',
        data: {
          id: order.id,
          productId: order.productId,
          buyerId: order.buyerId,
          sellerId: order.sellerId,
          amount: order.amount,
          address: order.address,
          locationTag: order.locationTag,
          payType: order.payType,
          status: OrderStatus.PAID_SIMULATED,
          buyerArrived: order.buyerArrived,
          sellerArrived: order.sellerArrived,
          reviewed: order.reviewed,
          createdAt: order.createdAt,
          updatedAt: now + 1
        }
      };
      fakeRemoteClient.arriveResponse = {
        ok: true,
        message: '远端到场成功',
        data: {
          id: order.id,
          productId: order.productId,
          buyerId: order.buyerId,
          sellerId: order.sellerId,
          amount: order.amount,
          address: order.address,
          locationTag: order.locationTag,
          payType: order.payType,
          status: OrderStatus.READY_HANDOVER,
          buyerArrived: true,
          sellerArrived: true,
          reviewed: order.reviewed,
          createdAt: order.createdAt,
          updatedAt: now + 2
        }
      };
      fakeRemoteClient.completeResponse = {
        ok: true,
        message: '远端完结成功',
        data: {
          id: order.id,
          productId: order.productId,
          buyerId: order.buyerId,
          sellerId: order.sellerId,
          amount: order.amount,
          address: order.address,
          locationTag: order.locationTag,
          payType: order.payType,
          status: OrderStatus.COMPLETED,
          buyerArrived: true,
          sellerArrived: true,
          reviewed: order.reviewed,
          createdAt: order.createdAt,
          updatedAt: now + 3
        }
      };

      const service = new OrderServiceImpl(fakeRemoteClient, stateService);
      const payResult = await service.simulatePay(order.id, buyer.id);
      expect(payResult.ok).assertTrue();
      expect(fakeRemoteClient.simulatePayCalled).assertTrue();
      expect(payResult.data?.status).assertEqual(OrderStatus.PAID_SIMULATED);
      expect(orderRepository.getById(order.id)?.status).assertEqual(OrderStatus.PAID_SIMULATED);
      expect(productRepository.getById(product.id)?.status).assertEqual('locked');

      const arriveResult = await service.markArrived(order.id, buyer.id);
      expect(arriveResult.ok).assertTrue();
      expect(fakeRemoteClient.markArrivedCalled).assertTrue();
      expect(arriveResult.data?.status).assertEqual(OrderStatus.READY_HANDOVER);
      expect(orderRepository.getById(order.id)?.buyerArrived).assertTrue();
      expect(orderRepository.getById(order.id)?.sellerArrived).assertTrue();

      const completeResult = await service.completeOrder(order.id, buyer.id);
      expect(completeResult.ok).assertTrue();
      expect(fakeRemoteClient.completeOrderCalled).assertTrue();
      expect(completeResult.data?.status).assertEqual(OrderStatus.COMPLETED);
      expect(productRepository.getById(product.id)?.status).assertEqual('sold');
    });

    it('order_service_should_fall_back_to_local_actions_when_remote_order_actions_fail', 0, async () => {
      const now = Date.now();
      const seller: User = {
        id: 'remote-action-fallback-seller',
        phone: '18880008002',
        nickname: '动作回退卖家',
        role: 'user',
        status: 'active',
        creditScore: 90,
        createdAt: now,
        updatedAt: now
      };
      const buyer: User = {
        id: 'remote-action-fallback-buyer',
        phone: '18880008001',
        nickname: '动作回退买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      };
      const product: Product = {
        id: '8001',
        sellerId: seller.id,
        title: '动作回退测试商品',
        desc: '验证远端动作失败后仍保留本地状态机',
        price: 64,
        category: '日用百货',
        images: [],
        locationTag: '教学楼大厅',
        status: 'locked',
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      };
      const order: Order = {
        id: '8002',
        productId: product.id,
        buyerId: buyer.id,
        sellerId: seller.id,
        amount: product.price,
        address: '教学楼大厅',
        locationTag: product.locationTag,
        payType: 'simulated',
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: false,
        sellerArrived: false,
        reviewed: false,
        createdAt: now,
        updatedAt: now
      };
      userRepository.save(seller);
      userRepository.save(buyer);
      productRepository.save(product);
      orderRepository.save(order);

      const stateService = new AuthStateService(createMemoryPersistenceAdapter());
      stateService.saveSession({
        currentUser: buyer,
        token: 'remote-order-action-fallback-token',
        expiresAt: now + 60_000
      });

      const fakeRemoteClient = new FakeRemoteOrderClient();
      fakeRemoteClient.failPay = true;
      fakeRemoteClient.failCancel = true;
      const service = new OrderServiceImpl(fakeRemoteClient, stateService);

      const payResult = await service.simulatePay(order.id, buyer.id);
      expect(fakeRemoteClient.simulatePayCalled).assertTrue();
      expect(payResult.ok).assertTrue();
      expect(payResult.data?.status).assertEqual(OrderStatus.PAID_SIMULATED);
      expect(orderRepository.getById(order.id)?.status).assertEqual(OrderStatus.PAID_SIMULATED);

      const cancelBlocked = await service.cancelOrder(order.id, buyer.id);
      expect(fakeRemoteClient.cancelOrderCalled).assertTrue();
      expect(cancelBlocked.ok).assertFalse();

      const fallbackOrder: Order = {
        id: order.id,
        productId: order.productId,
        buyerId: order.buyerId,
        sellerId: order.sellerId,
        amount: order.amount,
        address: order.address,
        locationTag: order.locationTag,
        payType: order.payType,
        status: OrderStatus.PENDING_PAYMENT,
        buyerArrived: order.buyerArrived,
        sellerArrived: order.sellerArrived,
        reviewed: order.reviewed,
        createdAt: order.createdAt,
        updatedAt: now + 2
      };
      orderRepository.save(fallbackOrder);
      const fallbackProduct: Product = {
        id: product.id,
        sellerId: product.sellerId,
        title: product.title,
        desc: product.desc,
        price: product.price,
        category: product.category,
        images: product.images,
        locationTag: product.locationTag,
        status: 'locked',
        isDeleted: product.isDeleted,
        createdAt: product.createdAt,
        updatedAt: now + 2
      };
      productRepository.save(fallbackProduct);

      const cancelResult = await service.cancelOrder(order.id, buyer.id);
      expect(cancelResult.ok).assertTrue();
      expect(cancelResult.data?.status).assertEqual(OrderStatus.CANCELED);
      expect(productRepository.getById(product.id)?.status).assertEqual('on_sale');
    });

    it('order_service_should_copy_structured_campus_location_fields_from_product', 0, async () => {
      const now = Date.now();
      userRepository.save({
        id: 'location-buyer',
        phone: '18877773333',
        nickname: '交易买家',
        role: 'user',
        status: 'active',
        creditScore: 88,
        createdAt: now,
        updatedAt: now
      });
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

      const result = await orderService.createOrder('location-buyer', product.id, '图书馆一楼大厅，17:30 见');

      expect(result.ok).assertTrue();
      expect(result.data?.schoolId).assertEqual('school-hnrku');
      expect(result.data?.campusId).assertEqual('campus-main');
      expect(result.data?.locationGroupId).assertEqual('group-study');
      expect(result.data?.tradeLocationId).assertEqual('location-library');
      expect(result.data?.tradeLocationName).assertEqual('图书馆一楼大厅');
      expect(result.data?.locationSafetyTips).assertEqual('建议白天交易并当场验货');
    });

    it('admin_dashboard_entries_should_include_moderation_management', 0, () => {
      const entries = getAdminDashboardEntries();
      const moderationEntry = entries.find((item) => item.url === 'pages/Admin/AdminModerationPage');

      expect(moderationEntry !== undefined).assertTrue();
      expect(moderationEntry?.title).assertEqual('举报处理');
    });
  });
}
