import { chatRepository } from '../repositories/chat.repo';
import { productRepository } from '../repositories/product.repo';
import { userRepository } from '../repositories/user.repo';
import { ChatMessage, ChatThread, ChatThreadRecord, OperationResult } from '../types/domain';
import { ChatService } from '../types/service-contracts';
import { newId } from '../utils/id';
import { canCurrentUserJoinTrade } from '../utils/trade-guard';
import { syncService } from './sync.service.impl';

export class ChatServiceImpl implements ChatService {
  private isThreadParticipant(thread: ChatThreadRecord, userId: string): boolean {
    return userId === thread.buyerId || userId === thread.sellerId;
  }

  listThreads(userId: string): ChatThread[] {
    const currentUser = userRepository.getById(userId);
    if (!canCurrentUserJoinTrade(currentUser)) {
      return [];
    }

    return chatRepository.listThreads()
      .filter((thread: ChatThreadRecord) => thread.buyerId === userId || thread.sellerId === userId)
      .map((thread: ChatThreadRecord) => this.toThreadView(thread, userId))
      .sort((a: ChatThread, b: ChatThread) => b.lastMessageAt - a.lastMessageAt);
  }

  countUnread(userId: string): number {
    return this.listThreads(userId)
      .reduce((total: number, thread: ChatThread) => total + thread.unreadCount, 0);
  }

  getThread(threadId: string, viewerId: string): ChatThread | null {
    const viewer = userRepository.getById(viewerId);
    if (!canCurrentUserJoinTrade(viewer)) {
      return null;
    }

    const thread: ChatThreadRecord | null = chatRepository.getThreadById(threadId);
    if (!thread || !this.isThreadParticipant(thread, viewerId)) {
      return null;
    }
    return this.toThreadView(thread, viewerId);
  }

  getMessages(threadId: string): ChatMessage[] {
    return chatRepository.listMessages(threadId);
  }

  openProductThread(productId: string, buyerId: string, sellerId: string): OperationResult<string> {
    if (productId.trim().length === 0 || buyerId.trim().length === 0 || sellerId.trim().length === 0) {
      return { ok: false, message: '会话参数不完整' };
    }

    const buyer = userRepository.getById(buyerId);
    const seller = userRepository.getById(sellerId);
    if (!canCurrentUserJoinTrade(buyer) || !canCurrentUserJoinTrade(seller)) {
      return { ok: false, message: '管理员账号不支持参与商品沟通' };
    }

    const existing: ChatThreadRecord | null = chatRepository.findThread(productId, buyerId, sellerId);
    if (existing) {
      return { ok: true, message: '会话已存在', data: existing.id };
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

  sendMessage(threadId: string, fromUserId: string, content: string): OperationResult<ChatMessage> {
    if (content.trim().length === 0) {
      return { ok: false, message: '消息内容不能为空' };
    }

    const sender = userRepository.getById(fromUserId);
    if (!canCurrentUserJoinTrade(sender)) {
      return { ok: false, message: '管理员账号不支持发送交易沟通消息' };
    }

    const thread: ChatThreadRecord | null = chatRepository.getThreadById(threadId);
    if (!thread) {
      return { ok: false, message: '会话不存在' };
    }
    if (!this.isThreadParticipant(thread, fromUserId)) {
      return { ok: false, message: '仅交易双方可发送消息' };
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
      content: content.trim(),
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
    if (!canCurrentUserJoinTrade(viewer)) {
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
