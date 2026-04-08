import { localDb } from '../data/db/local-db';
import { MessageNotification } from '../types/domain';

export class NotificationRepository {
  listByUser(userId: string): MessageNotification[] {
    return localDb.getNotifications()
      .filter((item: MessageNotification) => item.userId === userId)
      .sort((a: MessageNotification, b: MessageNotification) => b.createdAt - a.createdAt);
  }

  countUnread(userId: string): number {
    return this.listByUser(userId).filter((item: MessageNotification) => !item.isRead).length;
  }

  save(notification: MessageNotification): MessageNotification {
    const items: MessageNotification[] = localDb.getNotifications();
    const index: number = items.findIndex((item: MessageNotification) => item.id === notification.id);
    if (index >= 0) {
      items[index] = notification;
    } else {
      items.push(notification);
    }
    localDb.setNotifications(items);
    return notification;
  }

  markRead(notificationId: string): void {
    const items: MessageNotification[] = localDb.getNotifications();
    const nextItems: MessageNotification[] = [];
    items.forEach((item: MessageNotification) => {
      if (item.id === notificationId && !item.isRead) {
        nextItems.push({
          id: item.id,
          userId: item.userId,
          type: item.type,
          title: item.title,
          summary: item.summary,
          relatedId: item.relatedId,
          isRead: true,
          createdAt: item.createdAt
        });
      } else {
        nextItems.push(item);
      }
    });
    localDb.setNotifications(nextItems);
  }

  markAllRead(userId: string): void {
    const items: MessageNotification[] = localDb.getNotifications();
    const nextItems: MessageNotification[] = [];
    items.forEach((item: MessageNotification) => {
      if (item.userId === userId) {
        nextItems.push({
          id: item.id,
          userId: item.userId,
          type: item.type,
          title: item.title,
          summary: item.summary,
          relatedId: item.relatedId,
          isRead: true,
          createdAt: item.createdAt
        });
      } else {
        nextItems.push(item);
      }
    });
    localDb.setNotifications(nextItems);
  }
}

export const notificationRepository: NotificationRepository = new NotificationRepository();
