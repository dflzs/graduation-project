export interface RemoteChatConversationItem {
  id: number | string;
  product_id: number | string;
  order_id?: number | string;
  buyer_id: number | string;
  seller_id: number | string;
  last_message?: string;
  last_message_at?: string | number | null;
  created_at: string | number;
  product_title?: string;
  buyer_nickname?: string;
  seller_nickname?: string;
  unread_count?: number | string;
}

export interface RemoteChatMessageItem {
  id: number | string;
  conversation_id: number | string;
  from_user_id: number | string;
  to_user_id: number | string;
  content: string;
  is_read: number | boolean;
  created_at: string | number;
  from_nickname?: string;
  to_nickname?: string;
}

export class RemoteCreateConversationPayload {
  product_id: string = '';
  order_id?: string = undefined;

  constructor(productId: string, orderId?: string) {
    this.product_id = productId;
    this.order_id = orderId && orderId.trim().length > 0 ? orderId : undefined;
  }
}

export class RemoteSendMessagePayload {
  content: string = '';

  constructor(content: string) {
    this.content = content;
  }
}

export interface RemoteChatConversationListResponse {
  code: number;
  message: string;
  data?: RemoteChatConversationItem[];
}

export interface RemoteChatConversationResponse {
  code: number;
  message: string;
  data?: RemoteChatConversationItem;
}

export interface RemoteChatMessageListResponse {
  code: number;
  message: string;
  data?: RemoteChatMessageItem[];
}

export interface RemoteChatMessageResponse {
  code: number;
  message: string;
  data?: RemoteChatMessageItem;
}
