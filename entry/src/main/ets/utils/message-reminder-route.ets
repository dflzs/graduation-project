import { MessageNotification, User } from '../types/domain';

export class MessageReminderRouteParams {
  productId?: string;
  orderId?: string;
  source?: string;

  constructor(productId?: string, orderId?: string, source?: string) {
    this.productId = productId;
    this.orderId = orderId;
    this.source = source;
  }
}

export class MessageReminderTarget {
  url: string;
  params?: MessageReminderRouteParams;

  constructor(url: string, params?: MessageReminderRouteParams) {
    this.url = url;
    this.params = params;
  }
}

export function buildMessageReminderTarget(
  item: MessageNotification,
  currentUser: User | null
): MessageReminderTarget {
  if (!currentUser) {
    return new MessageReminderTarget('pages/Auth/LoginPage');
  }

  if (item.type === 'system_notice') {
    return new MessageReminderTarget('pages/Announcement/AnnouncementPage');
  }

  if (currentUser.role === 'admin') {
    if (currentUser.status === 'active') {
      return new MessageReminderTarget('pages/Admin/AdminDashboardPage');
    }
    return new MessageReminderTarget('pages/Profile/ProfilePage');
  }

  if (item.type === 'product_submitted' || item.type === 'product_rejected') {
    return new MessageReminderTarget('pages/Product/MyPublishedProductsPage');
  }

  if (item.type === 'product_approved') {
    return new MessageReminderTarget(
      'pages/Product/ProductDetailPage',
      new MessageReminderRouteParams(item.relatedId)
    );
  }

  return new MessageReminderTarget(
    'pages/Order/OrderDetailPage',
    new MessageReminderRouteParams(undefined, item.relatedId, 'message')
  );
}

export function filterMessageHubReminders(
  currentUser: User | null,
  reminders: MessageNotification[]
): MessageNotification[] {
  if (!currentUser) {
    return [];
  }
  if (currentUser.role === 'user' && currentUser.status === 'active') {
    return reminders;
  }
  return reminders.filter((item: MessageNotification) => item.type === 'system_notice');
}

export function countVisibleMessageHubUnread(
  currentUser: User | null,
  reminders: MessageNotification[]
): number {
  return filterMessageHubReminders(currentUser, reminders)
    .filter((item: MessageNotification) => !item.isRead)
    .length;
}
