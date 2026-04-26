import { pushUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { ChatThread, MessageNotification, NotificationType, User } from '../../types/domain';
import { orderRepository } from '../../repositories/order.repo';
import { formatTime } from '../../utils/time';
import { buildCompactHandoverSummary } from '../../utils/handover-scheduling';
import { buildReminderRenderKey, buildThreadRenderKey } from '../../utils/render-keys';
import {
  buildMarketplaceUserSyncKeys,
  buildMessageHubAudiencePresentation,
  MessageHubAudiencePresentation
} from '../../utils/marketplace-audience-ui';
import {
  buildMessageReminderTarget,
  countVisibleMessageHubUnread,
  filterMessageHubReminders,
  MessageReminderTarget
} from '../../utils/message-reminder-route';
import { getMarketplaceAudienceMode, MarketplaceAudienceMode } from '../../utils/trade-guard';
import {
  buildMessageThreadOrderActionLabel,
  buildMessageThreadTradeSnapshot
} from '../../utils/trade-progress-guidance';
import { buildTradeLinkedProductCompactActionLabel } from '../../utils/trade-cross-navigation';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const PRIMARY_COLOR: string = '#2F6BFF';

function getReminderTagLabel(type: NotificationType): string {
  if (type === 'product_submitted') {
    return '审核中';
  }
  if (type === 'product_approved') {
    return '已通过';
  }
  if (type === 'product_rejected') {
    return '未通过';
  }
  if (type === 'order_created') {
    return '新订单';
  }
  if (type === 'order_canceled') {
    return '已取消';
  }
  if (type === 'order_completed') {
    return '已完成';
  }
  return '系统';
}

function getReminderTagColor(type: NotificationType): string {
  if (type === 'product_approved') {
    return '#237B46';
  }
  if (type === 'order_created' || type === 'order_completed') {
    return PRIMARY_COLOR;
  }
  if (type === 'product_submitted' || type === 'product_rejected' || type === 'order_canceled') {
    return '#B8643C';
  }
  return '#7B756E';
}

function getReminderTagBackground(type: NotificationType): string {
  if (type === 'product_approved') {
    return '#E8F5EA';
  }
  if (type === 'order_created' || type === 'order_completed') {
    return '#E8F0FF';
  }
  if (type === 'product_submitted' || type === 'product_rejected' || type === 'order_canceled') {
    return '#F4E6DE';
  }
  return '#F2EEE8';
}

@Component
export struct MessageHubPage {
  @State private currentUser: User | null = null;
  @State private reminders: MessageNotification[] = [];
  @State private threads: ChatThread[] = [];
  private syncUnsubscriber: (() => void) | null = null;
  private userSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    void this.refresh();
    this.bindChanges();
    this.bindUserSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    if (this.syncUnsubscriber) {
      this.syncUnsubscriber();
      this.syncUnsubscriber = null;
    }
    this.userSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.userSyncUnsubscribers = [];
  }

  private bindChanges(): void {
    if (this.syncUnsubscriber) {
      return;
    }
    this.syncUnsubscriber = appContext.sync.subscribe('messages:changed', () => {
      void this.refresh();
    });
  }

  private bindUserSync(): void {
    if (this.userSyncUnsubscribers.length > 0) {
      return;
    }
    this.userSyncUnsubscribers = buildMarketplaceUserSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        void this.refresh();
      })
    );
  }

  private async refresh(): Promise<void> {
    this.currentUser = appContext.getCurrentUser();
    if (!this.currentUser) {
      this.reminders = [];
      this.threads = [];
      return;
    }

    this.reminders = filterMessageHubReminders(
      this.currentUser,
      appContext.notification.listByUser(this.currentUser.id)
    ).sort((a: MessageNotification, b: MessageNotification) => b.createdAt - a.createdAt);
    this.threads = await appContext.chat.listThreads(this.currentUser.id);
  }

  private audienceMode(): MarketplaceAudienceMode {
    return getMarketplaceAudienceMode(this.currentUser);
  }

  private audiencePresentation(): MessageHubAudiencePresentation {
    return buildMessageHubAudiencePresentation(this.audienceMode());
  }

  private openAudiencePrimaryAction(): void {
    const presentation: MessageHubAudiencePresentation = this.audiencePresentation();
    if (presentation.primaryAction === 'login') {
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (presentation.primaryAction === 'admin') {
      pushUrlByContext(this, { url: 'pages/Admin/AdminDashboardPage' });
      return;
    }
    if (presentation.primaryAction === 'profile') {
      pushUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
    }
  }

  private getReminderUnreadCount(): number {
    return countVisibleMessageHubUnread(this.currentUser, this.reminders);
  }

  private markAllRemindersRead(): void {
    if (!this.currentUser) {
      return;
    }
    if (this.getReminderUnreadCount() === 0) {
      return;
    }
    filterMessageHubReminders(this.currentUser, this.reminders)
      .filter((item: MessageNotification) => !item.isRead)
      .forEach((item: MessageNotification) => {
        appContext.notification.markRead(item.id);
      });
    void this.refresh();
    showToastByContext(this, {
      message: this.audienceMode() === 'admin'
        ? '后台提醒已全部设为已读'
        : this.audienceMode() === 'restricted'
          ? '账号提醒已全部设为已读'
          : '交易提醒已全部设为已读',
      duration: 1200
    });
  }

  private openReminder(item: MessageNotification): void {
    if (!this.currentUser) {
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }

    if (!item.isRead) {
      appContext.notification.markRead(item.id);
      void this.refresh();
    }

    const target: MessageReminderTarget = buildMessageReminderTarget(item, this.currentUser);
    pushUrlByContext(this, {
      url: target.url,
      params: target.params
    });
  }

  private openThread(thread: ChatThread): void {
    pushUrlByContext(this, {
      url: 'pages/Chat/ChatDetailPage',
      params: {
        threadId: thread.id
      }
    });
  }

  private getThreadTradeSnapshot(thread: ChatThread): string {
    const linkedOrder = orderRepository.findLatestByTradeContext(thread.productId, thread.buyerId, thread.sellerId);
    return linkedOrder ? buildMessageThreadTradeSnapshot(linkedOrder) : '';
  }

  private getThreadHandoverSummary(thread: ChatThread): string {
    const linkedOrder = orderRepository.findLatestByTradeContext(thread.productId, thread.buyerId, thread.sellerId);
    return linkedOrder ? buildCompactHandoverSummary(linkedOrder.locationTag, linkedOrder.address) : '';
  }

  private getThreadOrderActionLabel(thread: ChatThread): string {
    const linkedOrder = orderRepository.findLatestByTradeContext(thread.productId, thread.buyerId, thread.sellerId);
    return linkedOrder && this.currentUser
      ? buildMessageThreadOrderActionLabel(linkedOrder, this.currentUser.id)
      : '看订单';
  }

  private openThreadOrder(thread: ChatThread): void {
    const linkedOrder = orderRepository.findLatestByTradeContext(thread.productId, thread.buyerId, thread.sellerId);
    if (!linkedOrder) {
      return;
    }
    pushUrlByContext(this, {
      url: 'pages/Order/OrderDetailPage',
      params: {
        orderId: linkedOrder.id,
        source: 'message'
      }
    });
  }

  private openThreadProduct(thread: ChatThread): void {
    pushUrlByContext(this, {
      url: 'pages/Product/ProductDetailPage',
      params: { productId: thread.productId }
    });
  }

  @Builder
  private buildTopHeader(): void {
    Row() {
      Column({ space: 6 }) {
        Text('消息')
          .width('100%')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text(this.audiencePresentation().headerDescription)
          .width('100%')
          .fontSize(14)
          .lineHeight(22)
          .fontColor(SUB_TEXT_COLOR)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.getReminderUnreadCount() > 0) {
        Text('全部已读')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_COLOR)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .backgroundColor('#E8F0FF')
          .borderRadius(16)
          .onClick(() => this.markAllRemindersRead())
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildSectionTitle(title: string, description: string): void {
    Column({ space: 4 }) {
      Text(title)
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(description)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildInlineEmptyCard(title: string, description: string): void {
    Column({ space: 10 }) {
      Row({ space: 6 }) {
        Blank()
          .width(18)
          .height(4)
          .backgroundColor('#E7DED2')
          .borderRadius(3)

        Blank()
          .width(34)
          .height(4)
          .backgroundColor('#F0E8DE')
          .borderRadius(3)
      }

      Text(title)
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(description)
        .width('100%')
        .fontSize(14)
        .lineHeight(22)
        .fontColor(SUB_TEXT_COLOR)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({
      width: 1,
      color: CARD_BORDER
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildReminderCard(item: MessageNotification): void {
    Row({ space: 12 }) {
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Text(getReminderTagLabel(item.type))
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(getReminderTagColor(item.type))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(getReminderTagBackground(item.type))
            .borderRadius(12)

          if (!item.isRead) {
            Text('未读')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor('#C84D4D')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#FDECEC')
              .borderRadius(12)
          }
        }
        .width('100%')

        Text(item.title)
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text(item.summary)
          .width('100%')
          .fontSize(14)
          .lineHeight(22)
          .fontColor('#5E5851')

        Text(formatTime(item.createdAt))
          .width('100%')
          .fontSize(13)
          .fontColor('#9A938A')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('查看')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(PRIMARY_COLOR)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({
      width: 1,
      color: item.isRead ? CARD_BORDER : '#D8E5FF'
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.openReminder(item))
  }

  @Builder
  private buildThreadCard(thread: ChatThread): void {
    Row({ space: 12 }) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text(thread.peerNickname)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          if (thread.unreadCount > 0) {
            Text(`${thread.unreadCount}`)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor('#D85A5A')
              .borderRadius(10)
          }
        }
        .width('100%')

        Text(thread.productTitle)
          .width('100%')
          .fontSize(14)
          .lineHeight(21)
          .fontColor('#5E5851')

        if (this.getThreadTradeSnapshot(thread).length > 0) {
          Text(this.getThreadTradeSnapshot(thread))
            .width('100%')
            .fontSize(12)
            .lineHeight(19)
            .fontColor('#6B655E')
        }

        if (this.getThreadHandoverSummary(thread).length > 0) {
          Text(this.getThreadHandoverSummary(thread))
            .width('100%')
            .fontSize(12)
            .lineHeight(19)
            .fontColor('#7B756E')
        }

        Text(thread.lastMessage)
          .width('100%')
          .fontSize(14)
          .lineHeight(21)
          .fontColor(thread.unreadCount > 0 ? '#4B4540' : '#7B756E')
          .fontWeight(thread.unreadCount > 0 ? FontWeight.Medium : FontWeight.Regular)

        Text(formatTime(thread.lastMessageAt))
          .width('100%')
          .fontSize(13)
          .fontColor('#9A938A')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        if (this.getThreadTradeSnapshot(thread).length > 0) {
          Button(this.getThreadOrderActionLabel(thread))
            .height(34)
            .type(ButtonType.Normal)
            .fontSize(12)
            .fontColor(PRIMARY_COLOR)
            .backgroundColor('#E8F0FF')
            .border({ width: 1, color: '#D6E3FF' })
            .borderRadius(14)
            .padding({ left: 12, right: 12 })
            .onClick(() => this.openThreadOrder(thread))
        }

        Button(buildTradeLinkedProductCompactActionLabel())
          .height(34)
          .type(ButtonType.Normal)
          .fontSize(12)
          .fontColor('#6B655E')
          .backgroundColor('#F5F1EB')
          .border({ width: 1, color: '#E3D9CC' })
          .borderRadius(14)
          .padding({ left: 12, right: 12 })
          .onClick(() => this.openThreadProduct(thread))

        Text('进入')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_COLOR)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({
      width: 1,
      color: thread.unreadCount > 0 ? '#D8E5FF' : CARD_BORDER
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.openThread(thread))
  }

  @Builder
  private buildGuestState(): void {
    Column({ space: 16 }) {
      this.buildTopHeader()
      this.buildInlineEmptyCard(this.audiencePresentation().emptyReminderTitle, this.audiencePresentation().emptyReminderDescription)

      Button(this.audiencePresentation().emptyPrimaryActionLabel)
        .width('100%')
        .height(46)
        .backgroundColor(PRIMARY_COLOR)
        .borderRadius(18)
        .onClick(() => this.openAudiencePrimaryAction())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .padding({ left: 16, right: 16, top: 20, bottom: 24 })
  }

  build() {
    Scroll() {
      Column({ space: 24 }) {
        if (!this.currentUser) {
          this.buildGuestState()
        } else {
          Column({ space: 24 }) {
            this.buildTopHeader()

            Column({ space: 14 }) {
              this.buildSectionTitle(
                this.audiencePresentation().reminderSectionTitle,
                this.audiencePresentation().reminderSectionDescription
              )
              if (this.reminders.length === 0) {
                this.buildInlineEmptyCard(
                  this.audiencePresentation().emptyReminderTitle,
                  this.audiencePresentation().emptyReminderDescription
                )
                if (this.audiencePresentation().primaryAction !== 'none') {
                  Button(this.audiencePresentation().emptyPrimaryActionLabel)
                    .width('100%')
                    .height(44)
                    .type(ButtonType.Normal)
                    .backgroundColor('#E8F0FF')
                    .fontColor(PRIMARY_COLOR)
                    .borderRadius(16)
                    .onClick(() => this.openAudiencePrimaryAction())
                }
              } else {
                Column({ space: 12 }) {
                  ForEach(this.reminders, (item: MessageNotification) => {
                    this.buildReminderCard(item)
                  }, (item: MessageNotification) => buildReminderRenderKey(item))
                }
                .width('100%')
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            if (this.audiencePresentation().showThreads) {
              Column({ space: 14 }) {
                this.buildSectionTitle(
                  this.audiencePresentation().threadSectionTitle,
                  this.audiencePresentation().threadSectionDescription
                )
                if (this.threads.length === 0) {
                  this.buildInlineEmptyCard(
                    this.audiencePresentation().emptyThreadTitle,
                    this.audiencePresentation().emptyThreadDescription
                  )
                } else {
                  Column({ space: 12 }) {
                    ForEach(this.threads, (thread: ChatThread) => {
                      this.buildThreadCard(thread)
                    }, (thread: ChatThread) => buildThreadRenderKey(thread))
                  }
                  .width('100%')
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
      .padding({ left: 16, right: 16, top: 10, bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
