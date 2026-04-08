import { localDb } from '../data/db/local-db';
import { ChatMessage, ChatThreadRecord } from '../types/domain';

export class ChatRepository {
  listThreads(): ChatThreadRecord[] {
    return localDb.getChatThreads()
      .sort((a: ChatThreadRecord, b: ChatThreadRecord) => b.updatedAt - a.updatedAt);
  }

  getThreadById(threadId: string): ChatThreadRecord | null {
    const thread = localDb.getChatThreads().find((item: ChatThreadRecord) => item.id === threadId);
    return thread ?? null;
  }

  findThread(productId: string, buyerId: string, sellerId: string): ChatThreadRecord | null {
    const thread = localDb.getChatThreads().find((item: ChatThreadRecord) =>
      item.productId === productId
      && item.buyerId === buyerId
      && item.sellerId === sellerId
    );
    return thread ?? null;
  }

  saveThread(thread: ChatThreadRecord): ChatThreadRecord {
    const threads = localDb.getChatThreads();
    const index = threads.findIndex((item: ChatThreadRecord) => item.id === thread.id);
    if (index >= 0) {
      threads[index] = thread;
    } else {
      threads.push(thread);
    }
    localDb.setChatThreads(threads);
    return thread;
  }

  listMessages(threadId: string): ChatMessage[] {
    return localDb.getChats()
      .filter((item: ChatMessage) => item.threadId === threadId)
      .sort((a: ChatMessage, b: ChatMessage) => a.createdAt - b.createdAt);
  }

  saveMessage(message: ChatMessage): ChatMessage {
    const messages = localDb.getChats();
    const index = messages.findIndex((item: ChatMessage) => item.id === message.id);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.push(message);
    }
    localDb.setChats(messages);
    return message;
  }

  markMessagesRead(threadId: string, viewerId: string): void {
    const messages = localDb.getChats();
    const nextMessages: ChatMessage[] = [];
    messages.forEach((item: ChatMessage) => {
      if (item.threadId === threadId && item.toUserId === viewerId && !item.isRead) {
        nextMessages.push({
          id: item.id,
          threadId: item.threadId,
          productId: item.productId,
          orderId: item.orderId,
          fromUserId: item.fromUserId,
          toUserId: item.toUserId,
          content: item.content,
          isRead: true,
          createdAt: item.createdAt
        });
      } else {
        nextMessages.push(item);
      }
    });
    localDb.setChats(nextMessages);
  }
}

export const chatRepository: ChatRepository = new ChatRepository();
