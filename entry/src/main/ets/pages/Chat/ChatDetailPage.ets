import { backByContext, getParamsByContext, pushUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { CAMPUS_TRADE_QUICK_REPLIES } from '../../constants/message-quick-replies';
import { replaceUrlByContext } from '../../utils/ui-context-actions';
import { chatRepository } from '../../repositories/chat.repo';
import { productRepository } from '../../repositories/product.repo';
import { userRepository } from '../../repositories/user.repo';
import { ChatMessage, ChatThread, Product, ProductStatus, User } from '../../types/domain';
import { formatTime } from '../../utils/time';
import {
  buildCampusTrustTonePalette,
  buildPublicCampusTrustPresentation,
  CampusTrustPresentation
} from '../../utils/campus-trust-ui';
import { buildChatDetailReturnTarget } from '../../utils/detail-return-route';
import { buildMarketplaceUserSyncKeys } from '../../utils/marketplace-audience-ui';
import {
  canAccessTradeRecord,
  canCurrentUserOperateTrade,
  canCurrentUserSendTradeMessage,
  canViewTradeHistory,
  getTradeReadOnlyHint,
  getTradeRecordUnavailableDescription,
  getTradeRecordUnavailableTitle,
  shouldTreatTradeRecordAsAccessDenied
} from '../../utils/trade-guard';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const PRIMARY_COLOR: string = '#2F6BFF';

function getProductStatusLabel(status: ProductStatus): string {
  if (status === 'pending_review') {
    return '审核中';
  }
  if (status === 'on_sale') {
    return '在售';
  }
  if (status === 'locked') {
    return '交易中';
  }
  if (status === 'sold') {
    return '已售出';
  }
  if (status === 'off_shelf') {
    return '已下架';
  }
  return '未通过';
}

function getProductStatusBackground(status: ProductStatus): string {
  if (status === 'on_sale') {
    return '#E8F5EA';
  }
  if (status === 'locked') {
    return '#E8F0FF';
  }
  if (status === 'pending_review' || status === 'rejected') {
    return '#F4E6DE';
  }
  return '#F1EDE7';
}

function getProductStatusColor(status: ProductStatus): string {
  if (status === 'on_sale') {
    return '#237B46';
  }
  if (status === 'locked') {
    return PRIMARY_COLOR;
  }
  if (status === 'pending_review' || status === 'rejected') {
    return '#B8643C';
  }
  return '#7B756E';
}

@Entry
@Component
struct ChatDetailPage {
  @State private threadId: string = '';
  @State private thread: ChatThread | null = null;
  @State private product: Product | null = null;
  @State private messages: ChatMessage[] = [];
  @State private draft: string = '';
  @State private accessDenied: boolean = false;
  private userSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.threadId = params?.threadId ?? '';
    void this.refresh();
    this.bindUserSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    this.userSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.userSyncUnsubscribers = [];
    if (this.threadId.length === 0) {
      return;
    }
    appContext.sync.publish({
      key: 'messages:changed',
      value: this.threadId,
      updatedAt: Date.now()
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
    const currentUser = this.getCurrentUser();
    if (!currentUser || this.threadId.length === 0) {
      this.thread = null;
      this.product = null;
      this.messages = [];
      this.accessDenied = this.threadId.length > 0
        && shouldTreatTradeRecordAsAccessDenied(currentUser, true, false);
      return;
    }

    const threadRecord = chatRepository.getThreadById(this.threadId);
    const canAccessThread = threadRecord !== null
      && canAccessTradeRecord(currentUser, [threadRecord.buyerId, threadRecord.sellerId]);
    if (!canViewTradeHistory(currentUser) || (threadRecord !== null && !canAccessThread)) {
      this.thread = null;
      this.product = null;
      this.messages = [];
      this.accessDenied = shouldTreatTradeRecordAsAccessDenied(currentUser, threadRecord !== null, canAccessThread);
      return;
    }

    appContext.chat.markThreadRead(this.threadId, currentUser.id);
    const thread = appContext.chat.getThread(this.threadId, currentUser.id);
    this.messages = thread ? await appContext.chat.getMessages(this.threadId, currentUser.id) : [];
    this.thread = appContext.chat.getThread(this.threadId, currentUser.id);
    this.product = this.thread ? productRepository.getById(this.thread.productId) : null;
    this.accessDenied = false;
  }

  private async send(): Promise<void> {
    const currentUser = this.getCurrentUser();
    if (!currentUser) {
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (this.isMessageComposerDisabled()) {
      return;
    }

    const result = await appContext.chat.sendMessage(this.threadId, currentUser.id, this.draft);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (!result.ok) {
      return;
    }

    this.draft = '';
    void this.refresh();
  }

  private sendQuickReply(reply: string): void {
    if (this.isMessageComposerDisabled()) {
      return;
    }
    this.draft = reply;
    void this.send();
  }

  private getCurrentUser(): User | null {
    return appContext.getCurrentUser();
  }

  private getCurrentUserId(): string {
    return this.getCurrentUser()?.id ?? '';
  }

  private isReadOnlyConversation(): boolean {
    return !canCurrentUserOperateTrade(this.getCurrentUser());
  }

  private isMessageComposerDisabled(): boolean {
    return !canCurrentUserSendTradeMessage(this.getCurrentUser());
  }

  private getComposerPlaceholder(): string {
    const currentUser = this.getCurrentUser();
    if (currentUser?.status === 'muted') {
      return '账号当前已被禁言，暂时不能发送新的交易消息';
    }
    if (this.isReadOnlyConversation()) {
      return '账号当前受限，聊天入口已切换为只读';
    }
    return '输入你想和对方确认的内容';
  }

  private getConversationTitle(): string {
    return this.thread?.peerNickname ?? '会话详情';
  }

  private getProductPriceText(): string {
    return '￥' + (this.product?.price ?? 0).toFixed(2);
  }

  private getPeerTrustPresentation(): CampusTrustPresentation {
    const peerUser = this.thread ? userRepository.getById(this.thread.peerUserId) : null;
    return buildPublicCampusTrustPresentation(peerUser);
  }

  private getPeerTrustCardBackground(): string {
    return buildCampusTrustTonePalette(this.getPeerTrustPresentation().tone).surfaceBackgroundColor;
  }

  private getPeerTrustRiskTextColor(): string {
    return buildCampusTrustTonePalette(this.getPeerTrustPresentation().tone).riskBadgeTextColor;
  }

  private getPeerTrustRiskBackground(): string {
    return buildCampusTrustTonePalette(this.getPeerTrustPresentation().tone).riskBadgeBackgroundColor;
  }

  private getPeerTrustTagTextColor(): string {
    return buildCampusTrustTonePalette(this.getPeerTrustPresentation().tone).tagTextColor;
  }

  private getPeerTrustTagBackground(): string {
    return buildCampusTrustTonePalette(this.getPeerTrustPresentation().tone).tagBackgroundColor;
  }

  private canCurrentUserSubmitModeration(_product: Product): boolean {
    const currentUser = this.getCurrentUser();
    return currentUser !== null && currentUser.role === 'user';
  }

  private leaveUnavailableState(): void {
    const target = buildChatDetailReturnTarget(this.getCurrentUser());
    replaceUrlByContext(this, { url: target.url, params: target.params });
  }

  private openReportPage(): void {
    if (!this.thread || this.isReadOnlyConversation()) {
      return;
    }
    pushUrlByContext(this, {
      url: 'pages/Moderation/SubmitModerationPage',
      params: {
        targetType: 'chat_report',
        targetId: this.thread.id,
        title: this.product?.title ?? this.thread.productTitle
      }
    });
  }

  @Builder
  private buildEmptyState(): void {
    Column({ space: 12 }) {
      Text(getTradeRecordUnavailableTitle('chat', this.getCurrentUser(), this.accessDenied))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(getTradeRecordUnavailableDescription('chat', this.getCurrentUser(), this.accessDenied))
        .fontSize(14)
        .fontColor(SUB_TEXT_COLOR)
        .textAlign(TextAlign.Center)

      Button('返回消息')
        .width('100%')
        .height(44)
        .backgroundColor(PRIMARY_COLOR)
        .onClick(() => this.leaveUnavailableState())
    }
    .width('100%')
    .padding(20)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(24)
  }

  @Builder
  private buildProductSummary(): void {
    if (this.thread) {
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Text(this.product?.title ?? this.thread.productTitle)
            .layoutWeight(1)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(getProductStatusLabel(this.product?.status ?? 'off_shelf'))
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(getProductStatusColor(this.product?.status ?? 'off_shelf'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(getProductStatusBackground(this.product?.status ?? 'off_shelf'))
            .borderRadius(12)
        }
        .width('100%')

        if (this.product) {
          Row({ space: 12 }) {
            Text(this.getProductPriceText())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E05A47')

            Text(this.product.locationTag)
              .fontSize(13)
              .fontColor('#5E5851')
          }
          .width('100%')
        } else {
          Text('该商品可能已下架或不可见，但你们仍可以继续完成这次沟通。')
            .width('100%')
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
        }

        Row({ space: 8 }) {
          Text('对方身份')
            .fontSize(12)
            .fontColor(SUB_TEXT_COLOR)

          Text(this.getPeerTrustPresentation().badgeText)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getPeerTrustPresentation().badgeTextColor)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.getPeerTrustPresentation().badgeBackgroundColor)
            .borderRadius(12)
        }
        .width('100%')

        Row({ space: 8 }) {
          Text(this.getPeerTrustPresentation().summary)
            .layoutWeight(1)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4E4740')

          Text(this.getPeerTrustPresentation().riskLabel)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getPeerTrustRiskTextColor())
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.getPeerTrustRiskBackground())
            .borderRadius(12)
        }
        .width('100%')

        if (this.getPeerTrustPresentation().trustTags.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
            ForEach(this.getPeerTrustPresentation().trustTags, (tag: string) => {
              Text(tag)
                .fontSize(11)
                .fontColor(this.getPeerTrustTagTextColor())
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(this.getPeerTrustTagBackground())
                .borderRadius(12)
                .margin({ right: 8, bottom: 8 })
            }, (tag: string) => tag)
          }
          .width('100%')
        }

        Text(this.getPeerTrustPresentation().helperText)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(SUB_TEXT_COLOR)

        Text(this.getPeerTrustPresentation().riskText)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8C867F')

        if (this.product && this.canCurrentUserSubmitModeration(this.product)) {
          Button('举报会话')
            .width('100%')
            .height(40)
            .type(ButtonType.Normal)
            .fontSize(13)
            .fontColor('#A86B00')
            .backgroundColor('#FFF6E6')
            .border({ width: 1, color: '#E8D8B6' })
            .borderRadius(14)
            .onClick(() => this.openReportPage())
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.getPeerTrustCardBackground())
      .borderRadius(20)
      .margin({ left: 16, right: 16 })
    }
  }

  @Builder
  private buildQuickReplies(): void {
    Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
      ForEach(CAMPUS_TRADE_QUICK_REPLIES, (item: string) => {
        Text(item)
          .fontSize(13)
          .fontColor(PRIMARY_COLOR)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(this.isMessageComposerDisabled() ? '#F1ECE5' : '#E8F0FF')
          .borderRadius(16)
          .margin({ right: 8, bottom: 8 })
          .opacity(this.isMessageComposerDisabled() ? 0.6 : 1)
          .onClick(() => this.sendQuickReply(item))
      }, (item: string) => item)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6 })
  }

  @Builder
  private buildMessageBubble(item: ChatMessage, isMine: boolean): void {
    Row() {
      if (isMine) {
        Blank().layoutWeight(1)
      }

      Column({ space: 6 }) {
        Text(item.content)
          .fontSize(15)
          .lineHeight(22)
          .fontColor(isMine ? '#FFFFFF' : '#2D2A26')

        Text(formatTime(item.createdAt))
          .fontSize(11)
          .fontColor(isMine ? '#DCE7FF' : '#9A938A')
      }
      .padding(14)
      .backgroundColor(isMine ? PRIMARY_COLOR : CARD_BACKGROUND)
      .borderRadius(18)
      .constraintSize({ minWidth: '28%', maxWidth: '78%' })

      if (!isMine) {
        Blank().layoutWeight(1)
      }
    }
    .width('100%')
  }

  build() {
    Column({ space: 12 }) {
      if (!this.thread || !this.getCurrentUser()) {
        this.buildEmptyState()
      } else {
        Column({ space: 4 }) {
          Text(this.getConversationTitle())
            .width('100%')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('围绕当前商品继续沟通时间、地点和交易细节。')
            .width('100%')
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

        this.buildProductSummary()
        if (this.isReadOnlyConversation()) {
          Column({ space: 8 }) {
            Text('当前会话已切换为只读')
              .width('100%')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#B8643C')

            Text(getTradeReadOnlyHint(this.getCurrentUser(), 'chat'))
              .width('100%')
              .fontSize(13)
              .lineHeight(20)
              .fontColor(SUB_TEXT_COLOR)
          }
          .width('100%')
          .padding(16)
          .margin({ left: 16, right: 16 })
          .backgroundColor('#F8ECE4')
          .borderRadius(20)
        } else {
          this.buildQuickReplies()
        }

        Scroll() {
          Column({ space: 10 }) {
            if (this.messages.length === 0) {
              Column({ space: 8 }) {
                Text('先打个招呼吧')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(TITLE_COLOR)

                Text('你们可以在这里确认面交时间、地点，以及商品细节。')
                  .fontSize(13)
                  .fontColor(SUB_TEXT_COLOR)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(18)
              .backgroundColor(CARD_BACKGROUND)
              .borderRadius(20)
            } else {
              ForEach(this.messages, (item: ChatMessage) => {
                this.buildMessageBubble(item, item.fromUserId === this.getCurrentUserId())
              }, (item: ChatMessage) => item.id)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 12 })
        }
        .layoutWeight(1)
        .width('100%')

        Row({ space: 10 }) {
          TextInput({ placeholder: this.getComposerPlaceholder(), text: this.draft })
            .layoutWeight(1)
            .height(46)
            .fontSize(15)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .enabled(!this.isMessageComposerDisabled())
            .onChange((value: string) => {
              this.draft = value;
            })

          Button('发送')
            .width(82)
            .height(46)
            .backgroundColor(this.isMessageComposerDisabled() ? '#D7D0C7' : PRIMARY_COLOR)
            .enabled(!this.isMessageComposerDisabled() && this.draft.trim().length > 0)
            .opacity(!this.isMessageComposerDisabled() && this.draft.trim().length > 0 ? 1 : 0.6)
            .onClick(() => {
              void this.send();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 18 })
        .backgroundColor('#FFFDFC')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
