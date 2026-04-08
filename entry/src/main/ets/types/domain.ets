export type UserRole = 'user' | 'admin';
export type UserStatus = 'active' | 'banned';
export type ProductStatus = 'pending_review' | 'on_sale' | 'locked' | 'sold' | 'off_shelf' | 'rejected';
export type PayType = 'simulated';
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
