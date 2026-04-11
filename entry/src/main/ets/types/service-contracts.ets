import {
  AuthSession,
  Campus,
  ChatMessage,
  ChatThread,
  LocationGroup,
  MessageNotification,
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
  VerificationCodeDispatch,
  VerificationStatus
} from './domain';

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
  createOrder(buyerId: string, productId: string, address: string): OperationResult<Order>;
  simulatePay(orderId: string, operatorId: string): OperationResult<Order>;
  cancelOrder(orderId: string, operatorId: string): OperationResult<Order>;
  markArrived(orderId: string, operatorId: string): OperationResult<Order>;
  completeOrder(orderId: string, operatorId: string): OperationResult<Order>;
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

export interface ChatService {
  listThreads(userId: string): ChatThread[];
  countUnread(userId: string): number;
  getThread(threadId: string, viewerId: string): ChatThread | null;
  getMessages(threadId: string): ChatMessage[];
  openProductThread(productId: string, buyerId: string, sellerId: string): OperationResult<string>;
  sendMessage(threadId: string, fromUserId: string, content: string): OperationResult<ChatMessage>;
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
