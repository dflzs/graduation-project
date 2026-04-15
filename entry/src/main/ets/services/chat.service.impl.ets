import { chatRepository } from '../repositories/chat.repo';
import { productRepository } from '../repositories/product.repo';
import { userRepository } from '../repositories/user.repo';
import { ChatMessage, ChatThread, ChatThreadRecord, OperationResult, User } from '../types/domain';
import { ChatService } from '../types/service-contracts';
import { newId } from '../utils/id';
import {
  canCurrentUserJoinTrade,
  canCurrentUserSendTradeMessage,
  canViewTradeHistory,
  getTradeAccessDeniedMessage
} from '../utils/trade-guard';
import { syncService } from './sync.service.impl';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteChatClient, remoteChatClient } from './chat-remote.client';
import {
  RemoteChatConversationItem,
  RemoteChatMessageItem,
  RemoteCreateConversationPayload
} from '../types/chat-remote';

function parseTimestamp(value: string | number | null | undefined): number {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string' && value.length > 0) {
    const timestamp = Date.parse(value);
    if (!Number.isNaN(timestamp)) {
      return timestamp;
    }
  }
  return Date.now();
}

function normalizeBooleanFlag(value: number | boolean): boolean {
  return typeof value === 'boolean' ? value : value === 1;
}

function normalizeUnreadCount(value: number | string | undefined): number {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

export class ChatServiceImpl implements ChatService {
  private readonly remoteClient: RemoteChatClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteChatClient = remoteChatClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  private isThreadParticipant(thread: ChatThreadRecord, userId: string): boolean {
    return userId === thread.buyerId || userId === thread.sellerId;
  }

  private buildTradeChatDeniedMessage(user: User | null): string {
    return getTradeAccessDeniedMessage(
      user,
      '管理员账号不支持参与商品沟通',
      '该账号已被停用，无法参与商品沟通'
    );
  }

  private resolveRemoteReadToken(viewerId: string): string {
    if (!this.stateService.isLoggedIn()) {
      return '';
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.id !== viewerId || !canViewTradeHistory(currentUser)) {
      return '';
    }
    return this.stateService.getToken();
  }

  private resolveRemoteWriteToken(operatorId: string): string {
    if (!this.stateService.isLoggedIn()) {
      return '';
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.id !== operatorId || !canCurrentUserSendTradeMessage(currentUser)) {
      return '';
    }
    return this.stateService.getToken();
  }

  private canRequestRemoteConversation(threadId: string): boolean {
    return /^\d+$/.test(threadId.trim());
  }

  private canRequestRemoteProduct(productId: string): boolean {
    return /^\d+$/.test(productId.trim());
  }

  private mapRemoteConversationToRecord(item: RemoteChatConversationItem): ChatThreadRecord {
    const fallbackTimestamp = parseTimestamp(item.created_at);
    return {
      id: String(item.id),
      productId: String(item.product_id),
      buyerId: String(item.buyer_id),
      sellerId: String(item.seller_id),
      createdAt: fallbackTimestamp,
      updatedAt: parseTimestamp(item.last_message_at) || fallbackTimestamp
    };
  }

  private mapRemoteConversationToThread(item: RemoteChatConversationItem, viewerId: string): ChatThread {
    const buyerId = String(item.buyer_id);
    const sellerId = String(item.seller_id);
    const peerUserId = viewerId === buyerId ? sellerId : buyerId;
    const peerNickname = viewerId === buyerId
      ? (item.seller_nickname ?? userRepository.getById(sellerId)?.nickname ?? '校园用户')
      : (item.buyer_nickname ?? userRepository.getById(buyerId)?.nickname ?? '校园用户');
    const lastMessageAt = item.last_message_at ? parseTimestamp(item.last_message_at) : parseTimestamp(item.created_at);

    return {
      id: String(item.id),
      productId: String(item.product_id),
      buyerId,
      sellerId,
      peerUserId,
      peerNickname,
      productTitle: item.product_title ?? productRepository.getById(String(item.product_id))?.title ?? '商品会话',
      lastMessage: item.last_message && item.last_message.length > 0 ? item.last_message : '点击开始沟通',
      lastMessageAt,
      unreadCount: normalizeUnreadCount(item.unread_count)
    };
  }

  private mapRemoteMessageItem(item: RemoteChatMessageItem, thread: ChatThreadRecord): ChatMessage {
    return {
      id: String(item.id),
      threadId: String(item.conversation_id),
      productId: thread.productId,
      orderId: '',
      fromUserId: String(item.from_user_id),
      toUserId: String(item.to_user_id),
      content: item.content,
      isRead: normalizeBooleanFlag(item.is_read),
      createdAt: parseTimestamp(item.created_at)
    };
  }

  private hydrateRemoteConversation(item: RemoteChatConversationItem): ChatThreadRecord {
    return chatRepository.saveThread(this.mapRemoteConversationToRecord(item));
  }

  private hydrateRemoteMessages(thread: ChatThreadRecord, items: RemoteChatMessageItem[]): ChatMessage[] {
    const messages = items
      .map((item: RemoteChatMessageItem) => this.mapRemoteMessageItem(item, thread))
      .sort((a: ChatMessage, b: ChatMessage) => a.createdAt - b.createdAt);

    messages.forEach((message: ChatMessage) => {
      chatRepository.saveMessage(message);
    });

    if (messages.length > 0) {
      const lastMessage = messages[messages.length - 1];
      chatRepository.saveThread({
        id: thread.id,
        productId: thread.productId,
        buyerId: thread.buyerId,
        sellerId: thread.sellerId,
        createdAt: thread.createdAt,
        updatedAt: lastMessage.createdAt
      });
    }

    return chatRepository.listMessages(thread.id);
  }

  private buildLocalThreads(userId: string): ChatThread[] {
    return chatRepository.listThreads()
      .filter((thread: ChatThreadRecord) => thread.buyerId === userId || thread.sellerId === userId)
      .map((thread: ChatThreadRecord) => this.toThreadView(thread, userId))
      .sort((a: ChatThread, b: ChatThread) => b.lastMessageAt - a.lastMessageAt);
  }

  async listThreads(userId: string): Promise<ChatThread[]> {
    const currentUser = userRepository.getById(userId);
    if (!canCurrentUserJoinTrade(currentUser)) {
      return [];
    }

    const token = this.resolveRemoteReadToken(userId);
    if (token.length === 0) {
      return this.buildLocalThreads(userId);
    }

    const remoteResult = await this.remoteClient.listConversations(token);
    if (remoteResult.ok && remoteResult.data) {
      return remoteResult.data
        .filter((item: RemoteChatConversationItem) => {
          const buyerId = String(item.buyer_id);
          const sellerId = String(item.seller_id);
          return buyerId === userId || sellerId === userId;
        })
        .map((item: RemoteChatConversationItem) => {
          this.hydrateRemoteConversation(item);
          return this.mapRemoteConversationToThread(item, userId);
        })
        .sort((a: ChatThread, b: ChatThread) => b.lastMessageAt - a.lastMessageAt);
    }

    return this.buildLocalThreads(userId);
  }

  async countUnread(userId: string): Promise<number> {
    const threads = await this.listThreads(userId);
    return threads.reduce((total: number, thread: ChatThread) => total + thread.unreadCount, 0);
  }

  getThread(threadId: string, viewerId: string): ChatThread | null {
    const viewer = userRepository.getById(viewerId);
    if (!canViewTradeHistory(viewer)) {
      return null;
    }

    const thread: ChatThreadRecord | null = chatRepository.getThreadById(threadId);
    if (!thread || !this.isThreadParticipant(thread, viewerId)) {
      return null;
    }
    return this.toThreadView(thread, viewerId);
  }

  async getMessages(threadId: string, viewerId: string): Promise<ChatMessage[]> {
    const viewer = userRepository.getById(viewerId);
    if (!canViewTradeHistory(viewer)) {
      return [];
    }

    const thread: ChatThreadRecord | null = chatRepository.getThreadById(threadId);
    if (!thread || !this.isThreadParticipant(thread, viewerId)) {
      return [];
    }

    const token = this.resolveRemoteReadToken(viewerId);
    if (token.length > 0 && this.canRequestRemoteConversation(threadId)) {
      const remoteResult = await this.remoteClient.getMessages(token, threadId);
      if (remoteResult.ok && remoteResult.data) {
        const messages = this.hydrateRemoteMessages(thread, remoteResult.data);
        this.publishMessageChange(viewerId);
        return messages;
      }
    }

    return chatRepository.listMessages(threadId);
  }

  async openProductThread(productId: string, buyerId: string, sellerId: string): Promise<OperationResult<string>> {
    if (productId.trim().length === 0 || buyerId.trim().length === 0 || sellerId.trim().length === 0) {
      return { ok: false, message: '会话参数不完整' };
    }

    const buyer = userRepository.getById(buyerId);
    const seller = userRepository.getById(sellerId);
    if (!canCurrentUserSendTradeMessage(buyer) || !canCurrentUserJoinTrade(seller)) {
      return {
        ok: false,
        message: !canCurrentUserSendTradeMessage(buyer)
          ? this.buildTradeChatDeniedMessage(buyer)
          : this.buildTradeChatDeniedMessage(seller)
      };
    }

    const existing: ChatThreadRecord | null = chatRepository.findThread(productId, buyerId, sellerId);
    if (existing) {
      return { ok: true, message: '会话已存在', data: existing.id };
    }

    const token = this.resolveRemoteWriteToken(buyerId);
    if (token.length > 0 && this.canRequestRemoteProduct(productId)) {
      const remoteResult = await this.remoteClient.createConversation(
        token,
        new RemoteCreateConversationPayload(productId)
      );
      if (remoteResult.ok && remoteResult.data) {
        const record = this.hydrateRemoteConversation(remoteResult.data);
        this.publishMessageChange(`${buyerId}:${sellerId}`);
        return {
          ok: true,
          message: remoteResult.message || '会话已创建',
          data: record.id
        };
      }
    }

    const now: number = Date.now();
    const thread: ChatThreadRecord = {
      id: newId('thread'),
      productId,
      buyerId,
      sellerId,
      createdAt: now,
      updatedAt: now
    };

    chatRepository.saveThread(thread);
    this.publishMessageChange(`${buyerId}:${sellerId}`);
    return { ok: true, message: '会话已创建', data: thread.id };
  }

  async sendMessage(threadId: string, fromUserId: string, content: string): Promise<OperationResult<ChatMessage>> {
    const trimmedContent = content.trim();
    if (trimmedContent.length === 0) {
      return { ok: false, message: '消息内容不能为空' };
    }

    const sender = userRepository.getById(fromUserId);
    if (!canCurrentUserSendTradeMessage(sender)) {
      return {
        ok: false,
        message: getTradeAccessDeniedMessage(
          sender,
          '管理员账号不支持发送交易沟通消息',
          '该账号已被停用，无法发送交易沟通消息'
        )
      };
    }

    const thread: ChatThreadRecord | null = chatRepository.getThreadById(threadId);
    if (!thread) {
      return { ok: false, message: '会话不存在' };
    }
    if (!this.isThreadParticipant(thread, fromUserId)) {
      return { ok: false, message: '仅交易双方可发送消息' };
    }

    const token = this.resolveRemoteWriteToken(fromUserId);
    if (token.length > 0 && this.canRequestRemoteConversation(threadId)) {
      const remoteResult = await this.remoteClient.sendMessage(token, threadId, trimmedContent);
      if (remoteResult.ok && remoteResult.data) {
        const message = this.mapRemoteMessageItem(remoteResult.data, thread);
        chatRepository.saveMessage(message);
        chatRepository.saveThread({
          id: thread.id,
          productId: thread.productId,
          buyerId: thread.buyerId,
          sellerId: thread.sellerId,
          createdAt: thread.createdAt,
          updatedAt: message.createdAt
        });
        this.publishMessageChange(`${fromUserId}:${message.toUserId}`);
        return {
          ok: true,
          message: remoteResult.message || '消息已发送',
          data: message
        };
      }
    }

    const toUserId: string = fromUserId === thread.buyerId ? thread.sellerId : thread.buyerId;
    const createdAt: number = Date.now();
    const message: ChatMessage = {
      id: newId('chat'),
      threadId,
      productId: thread.productId,
      orderId: '',
      fromUserId,
      toUserId,
      content: trimmedContent,
      isRead: false,
      createdAt
    };

    chatRepository.saveMessage(message);
    chatRepository.saveThread({
      id: thread.id,
      productId: thread.productId,
      buyerId: thread.buyerId,
      sellerId: thread.sellerId,
      createdAt: thread.createdAt,
      updatedAt: createdAt
    });
    this.publishMessageChange(`${fromUserId}:${toUserId}`);

    return {
      ok: true,
      message: '消息已发送',
      data: message
    };
  }

  markThreadRead(threadId: string, viewerId: string): void {
    if (threadId.trim().length === 0 || viewerId.trim().length === 0) {
      return;
    }

    const viewer = userRepository.getById(viewerId);
    if (!canViewTradeHistory(viewer)) {
      return;
    }

    const thread: ChatThreadRecord | null = chatRepository.getThreadById(threadId);
    if (!thread || !this.isThreadParticipant(thread, viewerId)) {
      return;
    }

    chatRepository.markMessagesRead(threadId, viewerId);
    this.publishMessageChange(viewerId);
  }

  private toThreadView(thread: ChatThreadRecord, viewerId: string): ChatThread {
    const product = productRepository.getById(thread.productId);
    const peerUserId: string = viewerId === thread.buyerId ? thread.sellerId : thread.buyerId;
    const peer = userRepository.getById(peerUserId);
    const messages: ChatMessage[] = chatRepository.listMessages(thread.id);
    const lastMessage: ChatMessage | null = messages.length > 0 ? messages[messages.length - 1] : null;
    const unreadCount: number = messages.filter((item: ChatMessage) => item.toUserId === viewerId && !item.isRead).length;

    return {
      id: thread.id,
      productId: thread.productId,
      buyerId: thread.buyerId,
      sellerId: thread.sellerId,
      peerUserId,
      peerNickname: peer?.nickname ?? '校园用户',
      productTitle: product?.title ?? '商品会话',
      lastMessage: lastMessage?.content ?? '点击开始沟通',
      lastMessageAt: lastMessage?.createdAt ?? thread.updatedAt,
      unreadCount
    };
  }

  private publishMessageChange(value: string): void {
    syncService.publish({
      key: 'messages:changed',
      value,
      updatedAt: Date.now()
    });
  }
}

export const chatService: ChatServiceImpl = new ChatServiceImpl();
