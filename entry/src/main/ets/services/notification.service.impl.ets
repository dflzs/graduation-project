import { notificationRepository } from '../repositories/notification.repo';
import { MessageNotification, NotificationType, OperationResult } from '../types/domain';
import { NotificationService } from '../types/service-contracts';
import { newId } from '../utils/id';
import { syncService } from './sync.service.impl';

export class NotificationServiceImpl implements NotificationService {
  listByUser(userId: string): MessageNotification[] {
    return notificationRepository.listByUser(userId);
  }

  countUnread(userId: string): number {
    return notificationRepository.countUnread(userId);
  }

  create(
    userId: string,
    type: NotificationType,
    title: string,
    summary: string,
    relatedId: string
  ): OperationResult<MessageNotification> {
    if (userId.trim().length === 0) {
      return { ok: false, message: '通知接收者不能为空' };
    }
    if (title.trim().length === 0 || summary.trim().length === 0) {
      return { ok: false, message: '通知标题和摘要不能为空' };
    }

    const createdAt = Date.now() + this.listByUser(userId).length;
    const notification: MessageNotification = {
      id: newId('notification'),
      userId,
      type,
      title: title.trim(),
      summary: summary.trim(),
      relatedId,
      isRead: false,
      createdAt
    };

    notificationRepository.save(notification);
    this.publishMessageChange(userId, createdAt);
    return {
      ok: true,
      message: '通知已创建',
      data: notification
    };
  }

  markRead(notificationId: string): void {
    if (notificationId.trim().length === 0) {
      return;
    }
    notificationRepository.markRead(notificationId);
    this.publishMessageChange(notificationId, Date.now());
  }

  markAllRead(userId: string): void {
    notificationRepository.markAllRead(userId);
    this.publishMessageChange(userId, Date.now());
  }

  notifyOrderCreated(buyerId: string, productTitle: string, orderId: string): void {
    this.create(
      buyerId,
      'order_created',
      '订单已创建',
      `${productTitle} 已进入交易流程，请继续完成支付和面交安排。`,
      orderId
    );
  }

  notifyOrderCanceled(buyerId: string, productTitle: string, orderId: string): void {
    this.create(
      buyerId,
      'order_canceled',
      '订单已取消',
      `${productTitle} 已恢复在售，本次交易流程已结束。`,
      orderId
    );
  }

  notifyOrderCompleted(userId: string, productTitle: string, orderId: string): void {
    this.create(
      userId,
      'order_completed',
      '订单已完成',
      `${productTitle} 的交易已经完成，可前往订单详情补充评价。`,
      orderId
    );
  }

  notifyProductSubmitted(sellerId: string, productTitle: string, productId: string): void {
    this.create(
      sellerId,
      'product_submitted',
      '商品已提交审核',
      `${productTitle} 已进入审核流程，审核通过后才会显示在首页。`,
      productId
    );
  }

  notifyProductApproved(sellerId: string, productTitle: string, productId: string): void {
    this.create(
      sellerId,
      'product_approved',
      '商品审核通过',
      `${productTitle} 已通过审核，现在已在首页公开展示。`,
      productId
    );
  }

  notifyProductRejected(sellerId: string, productTitle: string, productId: string): void {
    this.create(
      sellerId,
      'product_rejected',
      '商品未通过审核',
      `${productTitle} 审核未通过，可修改后重新提交。`,
      productId
    );
  }

  private publishMessageChange(value: string, updatedAt: number): void {
    syncService.publish({
      key: 'messages:changed',
      value,
      updatedAt
    });
  }
}

export const notificationService: NotificationServiceImpl = new NotificationServiceImpl();
