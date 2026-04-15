export type UserRole = 'user' | 'admin';
export type UserStatus = 'active' | 'restricted' | 'muted' | 'suspended' | 'banned';
export type ProductStatus = 'pending_review' | 'on_sale' | 'locked' | 'sold' | 'off_shelf' | 'rejected';
export type PayType = 'simulated';
export type VerificationMethod =
  | 'MANUAL_STUDENT_CARD'
  | 'MANUAL_CAMPUS_CARD'
  | 'MANUAL_ENROLLMENT_PROOF'
  | 'FUTURE_SSO';
export type ModerationTargetType = 'product_report' | 'user_report' | 'order_complaint' | 'chat_report';
export type ModerationStatus =
  | 'pending'
  | 'triaging'
  | 'awaiting_evidence'
  | 'in_review'
  | 'resolved_valid'
  | 'resolved_rejected'
  | 'resolved_partial'
  | 'appealed'
  | 'appeal_reviewing'
  | 'closed';
export type ModerationPriority = 'low' | 'medium' | 'high' | 'urgent';
export type AppealStatus = 'pending' | 'in_review' | 'accepted' | 'rejected' | 'closed';
export type GovernanceSourceType = 'moderation' | 'manual_admin';
export type GovernanceActionType =
  | 'warning'
  | 'mute_chat'
  | 'restrict_trade'
  | 'temporary_ban'
  | 'permanent_ban';
export type NotificationType =
  | 'product_submitted'
  | 'product_approved'
  | 'product_rejected'
  | 'order_created'
  | 'order_canceled'
  | 'order_completed'
  | 'system_notice';

export enum OrderStatus {
  PENDING_PAYMENT = 'PENDING_PAYMENT',
  PAID_SIMULATED = 'PAID_SIMULATED',
  READY_HANDOVER = 'READY_HANDOVER',
  COMPLETED = 'COMPLETED',
  CANCELED = 'CANCELED'
}

export enum VerificationStatus {
  UNVERIFIED = 'UNVERIFIED',
  PENDING_REVIEW = 'PENDING_REVIEW',
  VERIFIED = 'VERIFIED',
  REJECTED = 'REJECTED',
  SUSPENDED = 'SUSPENDED'
}

export interface School {
  id: string;
  name: string;
  shortName: string;
  city?: string;
  isEnabled: boolean;
  sortOrder: number;
  createdAt: number;
  updatedAt: number;
}

export interface Campus {
  id: string;
  schoolId: string;
  name: string;
  shortName: string;
  isMainCampus: boolean;
  isEnabled: boolean;
  sortOrder: number;
  createdAt: number;
  updatedAt: number;
}

export interface LocationGroup {
  id: string;
  schoolId: string;
  campusId: string;
  name: string;
  description?: string;
  isEnabled: boolean;
  sortOrder: number;
  createdAt: number;
  updatedAt: number;
}

export interface TradeLocation {
  id: string;
  schoolId: string;
  campusId: string;
  groupId: string;
  name: string;
  alias?: string;
  description?: string;
  safetyTips?: string;
  recommendedCategories: string[];
  isEnabled: boolean;
  isHot: boolean;
  sortOrder: number;
  createdAt: number;
  updatedAt: number;
}

export interface StudentVerification {
  id: string;
  userId: string;
  schoolId: string;
  schoolName?: string;
  campusId: string;
  campusName?: string;
  studentNo: string;
  gradeYear?: number;
  collegeName?: string;
  majorName?: string;
  verificationMethod: VerificationMethod;
  materialUrls: string[];
  status: VerificationStatus;
  submittedAt: number;
  reviewedAt?: number;
  reviewedBy?: string;
  reviewComment?: string;
  rejectReason?: string;
  updatedAt: number;
}

export interface User {
  id: string;
  phone: string;
  nickname: string;
  avatar?: string;
  role: UserRole;
  status: UserStatus;
  creditScore: number;
  remoteUserId?: string;
  remoteSalt?: string;
  passwordConfigured?: boolean;
  schoolId?: string;
  schoolName?: string;
  campusId?: string;
  campusName?: string;
  studentNo?: string;
  gradeYear?: number;
  collegeName?: string;
  majorName?: string;
  verificationStatus?: VerificationStatus;
  verificationMethod?: VerificationMethod;
  verifiedAt?: number;
  verificationRejectedReason?: string;
  verificationUpdatedAt?: number;
  completedOrderCount?: number;
  reportCount?: number;
  lastActiveAt?: number;
  createdAt: number;
  updatedAt: number;
}

export interface Product {
  id: string;
  sellerId: string;
  title: string;
  desc: string;
  price: number;
  category: string;
  images: string[];
  locationTag: string;
  schoolId?: string;
  schoolName?: string;
  campusId?: string;
  campusName?: string;
  locationGroupId?: string;
  locationGroupName?: string;
  tradeLocationId?: string;
  tradeLocationName?: string;
  locationSafetyTips?: string;
  status: ProductStatus;
  isDeleted: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface CartItem {
  id: string;
  userId: string;
  productId: string;
  qty: number;
  snapshotPrice: number;
  updatedAt: number;
}

export interface Order {
  id: string;
  productId: string;
  buyerId: string;
  sellerId: string;
  amount: number;
  address: string;
  locationTag: string;
  schoolId?: string;
  schoolName?: string;
  campusId?: string;
  campusName?: string;
  locationGroupId?: string;
  locationGroupName?: string;
  tradeLocationId?: string;
  tradeLocationName?: string;
  locationSafetyTips?: string;
  payType: PayType;
  status: OrderStatus;
  buyerArrived: boolean;
  sellerArrived: boolean;
  reviewed: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface Review {
  id: string;
  orderId: string;
  fromUserId: string;
  toUserId: string;
  rating: number;
  tag: string;
  comment: string;
  createdAt: number;
}

export interface Announcement {
  id: string;
  title: string;
  content: string;
  publisherId: string;
  isDeleted: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface ChatMessage {
  id: string;
  threadId: string;
  productId: string;
  orderId: string;
  fromUserId: string;
  toUserId: string;
  content: string;
  isRead: boolean;
  createdAt: number;
}

export interface ChatThreadRecord {
  id: string;
  productId: string;
  buyerId: string;
  sellerId: string;
  createdAt: number;
  updatedAt: number;
}

export interface ChatThread {
  id: string;
  productId: string;
  buyerId: string;
  sellerId: string;
  peerUserId: string;
  peerNickname: string;
  productTitle: string;
  lastMessage: string;
  lastMessageAt: number;
  unreadCount: number;
}

export interface MessageNotification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  summary: string;
  relatedId: string;
  isRead: boolean;
  createdAt: number;
}

export interface ModerationRecord {
  id: string;
  reporterId: string;
  targetType: ModerationTargetType;
  targetId: string;
  reportedUserId?: string;
  relatedOrderId?: string;
  relatedProductId?: string;
  relatedThreadId?: string;
  category?: string;
  reason: string;
  description: string;
  evidenceItems?: string[];
  status: ModerationStatus;
  priority?: ModerationPriority;
  assignedAdminId?: string;
  adminComment?: string;
  resolutionCode?: string;
  governanceActionId?: string;
  reviewedBy?: string;
  reviewedAt?: number;
  closedAt?: number;
  createdAt: number;
  updatedAt: number;
}

export interface AppealRecord {
  id: string;
  moderationRecordId: string;
  appellantId: string;
  reason: string;
  description: string;
  evidenceItems: string[];
  status: AppealStatus;
  reviewedBy?: string;
  reviewComment?: string;
  reviewedAt?: number;
  createdAt: number;
  updatedAt: number;
}

export interface AppealEligibility {
  moderationRecordId: string;
  appellantId: string;
  eligible: boolean;
  reason: string;
  existingAppealId?: string;
}

export interface GovernanceAction {
  id: string;
  userId: string;
  sourceType: GovernanceSourceType;
  sourceId: string;
  actionType: GovernanceActionType;
  reason: string;
  comment?: string;
  startAt: number;
  endAt?: number;
  active: boolean;
  createdBy: string;
  createdAt: number;
  updatedAt: number;
  canceledAt?: number;
  canceledBy?: string;
}

export interface GovernanceUserSummary {
  userId: string;
  activeActionTypes: GovernanceActionType[];
  latestAction?: GovernanceAction;
  totalActionCount: number;
  openCaseCount: number;
  latestActionAt?: number;
}

export interface AuthSession {
  currentUser: User;
  token: string;
  expiresAt: number;
}

export interface VerificationCodeDispatch {
  phone: string;
  code?: string;
}

export interface RegisterCodeVerification {
  phone: string;
  registerTicket: string;
  code?: string;
}

export interface OperationResult<T> {
  ok: boolean;
  message: string;
  data?: T;
}

export interface SyncPayload {
  key: string;
  value: string;
  updatedAt: number;
}
