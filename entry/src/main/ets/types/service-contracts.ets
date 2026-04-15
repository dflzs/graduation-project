import {
  AppealEligibility,
  AppealRecord,
  AppealStatus,
  AuthSession,
  Campus,
  ChatMessage,
  ChatThread,
  LocationGroup,
  MessageNotification,
  ModerationRecord,
  ModerationStatus,
  GovernanceAction,
  GovernanceActionType,
  GovernanceSourceType,
  GovernanceUserSummary,
  NotificationType,
  OperationResult,
  Order,
  Product,
  RegisterCodeVerification,
  Review,
  School,
  StudentVerification,
  SyncPayload,
  TradeLocation,
  User,
  UserStatus,
  VerificationCodeDispatch,
  VerificationStatus
} from './domain';
import { RemoteCreateProductPayload } from './product-remote';

export interface AuthService {
  sendLoginCode(phone: string): Promise<OperationResult<VerificationCodeDispatch>>;
  loginByPhone(phone: string, code: string): Promise<OperationResult<AuthSession>>;
  loginByPassword(phone: string, password: string): Promise<OperationResult<AuthSession>>;
  sendRegisterCode(phone: string): Promise<OperationResult<VerificationCodeDispatch>>;
  verifyRegisterCode(phone: string, code: string): Promise<OperationResult<RegisterCodeVerification>>;
  completeRegister(phone: string, registerTicket: string, nickname: string, password: string): Promise<OperationResult<AuthSession>>;
  updateProfile(nickname: string, avatar: string): Promise<OperationResult<User>>;
  updateAvatar(avatar: string): Promise<OperationResult<User>>;
  loginByAdminCode(phone: string, adminCode: string): OperationResult<AuthSession>;
  logout(): void;
  restoreSession(): AuthSession | null;
}

export interface OrderService {
  createOrder(buyerId: string, productId: string, address: string): Promise<OperationResult<Order>>;
  listMyOrders(userId: string): Promise<OperationResult<Order[]>>;
  getOrderDetail(orderId: string, viewerId: string): Promise<OperationResult<Order | null>>;
  simulatePay(orderId: string, operatorId: string): Promise<OperationResult<Order>>;
  cancelOrder(orderId: string, operatorId: string): Promise<OperationResult<Order>>;
  markArrived(orderId: string, operatorId: string): Promise<OperationResult<Order>>;
  completeOrder(orderId: string, operatorId: string): Promise<OperationResult<Order>>;
  addReview(orderId: string, fromUserId: string, rating: number, tag: string, comment: string): OperationResult<Review>;
}

export interface CreditService {
  recalculateCredit(userId: string): number;
}

export interface SyncService {
  publish(payload: SyncPayload): void;
  subscribe(key: string, callback: (payload: SyncPayload) => void): () => void;
}

export interface ProductQuery {
  keyword?: string;
  category?: string;
  status?: string;
}

export interface ProductService {
  listProducts(query?: ProductQuery): Product[];
  getProductById(productId: string): Product | null;
  createProduct(input: Partial<Product>, sellerId: string): OperationResult<Product>;
  updateProduct(productId: string, input: Partial<Product>, operatorId: string): OperationResult<Product>;
}

export interface GuardService {
  canAccessAdmin(user: User | null): boolean;
}

export interface AdminUserService {
  listUsers(): Promise<OperationResult<User[]>>;
  updateUserStatus(userId: string, status: UserStatus): Promise<OperationResult<User>>;
}

export interface AdminProductService {
  listProducts(): Promise<OperationResult<Product[]>>;
  approveProduct(productId: string): Promise<OperationResult<Product>>;
  rejectProduct(productId: string): Promise<OperationResult<Product>>;
  forceOffShelfProduct(productId: string): Promise<OperationResult<Product>>;
}

export interface MarketplaceProductService {
  listMarketplaceProducts(): Promise<OperationResult<Product[]>>;
  listMyPublishedProducts(userId: string): Promise<OperationResult<Product[]>>;
  getProductDetail(productId: string): Promise<OperationResult<Product>>;
  createMarketplaceProduct(input: RemoteCreateProductPayload, sellerId: string): Promise<OperationResult<Product>>;
}

export interface NotificationService {
  listByUser(userId: string): MessageNotification[];
  countUnread(userId: string): number;
  create(
    userId: string,
    type: NotificationType,
    title: string,
    summary: string,
    relatedId: string
  ): OperationResult<MessageNotification>;
  markRead(notificationId: string): void;
  markAllRead(userId: string): void;
  notifyOrderCreated(buyerId: string, productTitle: string, orderId: string): void;
  notifyOrderCanceled(buyerId: string, productTitle: string, orderId: string): void;
  notifyOrderCompleted(userId: string, productTitle: string, orderId: string): void;
  notifyProductSubmitted(sellerId: string, productTitle: string, productId: string): void;
  notifyProductApproved(sellerId: string, productTitle: string, productId: string): void;
  notifyProductRejected(sellerId: string, productTitle: string, productId: string): void;
}

export interface ModerationService {
  submitProductReport(
    productId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>>;
  submitUserReport(
    userId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>>;
  submitOrderComplaint(
    orderId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>>;
  submitChatReport(
    threadId: string,
    reporterId: string,
    reason: string,
    description: string
  ): Promise<OperationResult<ModerationRecord>>;
  listMyModerationRecords(reporterId: string): Promise<OperationResult<ModerationRecord[]>>;
  listModerationRecords(status?: ModerationStatus): Promise<OperationResult<ModerationRecord[]>>;
  triageModerationRecord(recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>>;
  requestModerationEvidence(recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>>;
  closeModerationRecord(recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>>;
  reviewModerationRecord(
    recordId: string,
    status: ModerationStatus,
    adminComment: string
  ): Promise<OperationResult<ModerationRecord>>;
  reviewModerationRecordWithGovernance(
    recordId: string,
    status: ModerationStatus,
    adminComment: string,
    governanceActionType?: GovernanceActionType
  ): Promise<OperationResult<ModerationRecord>>;
}

export interface AppealService {
  checkAppealEligibility(
    moderationRecordId: string,
    appellantId: string
  ): Promise<OperationResult<AppealEligibility>>;
  submitAppeal(
    moderationRecordId: string,
    appellantId: string,
    reason: string,
    description: string,
    evidenceItems?: string[]
  ): Promise<OperationResult<AppealRecord>>;
  listMyAppeals(appellantId: string): Promise<OperationResult<AppealRecord[]>>;
  listAppeals(status?: AppealStatus): Promise<OperationResult<AppealRecord[]>>;
  reviewAppeal(
    appealId: string,
    status: AppealStatus,
    reviewComment: string
  ): Promise<OperationResult<AppealRecord>>;
}

export interface GovernanceService {
  createAction(
    userId: string,
    sourceType: GovernanceSourceType,
    sourceId: string,
    actionType: GovernanceActionType,
    reason: string,
    comment: string,
    startAt: number,
    endAt?: number
  ): Promise<OperationResult<GovernanceAction>>;
  listActions(): Promise<OperationResult<GovernanceAction[]>>;
  listActionsByUser(userId: string): Promise<OperationResult<GovernanceAction[]>>;
  cancelAction(actionId: string, comment: string): Promise<OperationResult<GovernanceAction>>;
  getUserSummary(userId: string): Promise<OperationResult<GovernanceUserSummary>>;
}

export interface ChatService {
  listThreads(userId: string): Promise<ChatThread[]>;
  countUnread(userId: string): Promise<number>;
  getThread(threadId: string, viewerId: string): ChatThread | null;
  getMessages(threadId: string, viewerId: string): Promise<ChatMessage[]>;
  openProductThread(productId: string, buyerId: string, sellerId: string): Promise<OperationResult<string>>;
  sendMessage(threadId: string, fromUserId: string, content: string): Promise<OperationResult<ChatMessage>>;
  markThreadRead(threadId: string, viewerId: string): void;
}

export interface CampusLocationQuery {
  schoolId?: string;
  campusId?: string;
  groupId?: string;
  category?: string;
  enabledOnly?: boolean;
}

export interface CampusService {
  listSchools(): Promise<OperationResult<School[]>>;
  listCampuses(schoolId: string): Promise<OperationResult<Campus[]>>;
  listLocationGroups(schoolId: string, campusId: string): Promise<OperationResult<LocationGroup[]>>;
  listTradeLocations(query?: CampusLocationQuery): Promise<OperationResult<TradeLocation[]>>;
  getCurrentCampusProfile(): Promise<OperationResult<User | null>>;
  updateCampusProfile(
    schoolId: string,
    campusId: string,
    campusName: string,
    studentNo: string,
    gradeYear?: number,
    collegeName?: string,
    majorName?: string
  ): Promise<OperationResult<User>>;
  getCurrentVerification(): Promise<OperationResult<StudentVerification | null>>;
  submitVerification(input: StudentVerification): Promise<OperationResult<StudentVerification>>;
  listVerificationApplications(status?: VerificationStatus): Promise<OperationResult<StudentVerification[]>>;
  reviewVerification(
    verificationId: string,
    status: VerificationStatus,
    reviewComment: string,
    rejectReason: string
  ): Promise<OperationResult<StudentVerification>>;
  upsertSchool(school: School): Promise<OperationResult<School>>;
  upsertCampus(campus: Campus): Promise<OperationResult<Campus>>;
  upsertLocationGroup(group: LocationGroup): Promise<OperationResult<LocationGroup>>;
  upsertTradeLocation(location: TradeLocation): Promise<OperationResult<TradeLocation>>;
  updateTradeLocationStatus(locationId: string, isEnabled: boolean): Promise<OperationResult<TradeLocation>>;
}
