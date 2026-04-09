import { backByContext, getParamsByContext, pushUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { CAMPUS_TRADE_QUICK_REPLIES } from '../../constants/message-quick-replies';
import { productRepository } from '../../repositories/product.repo';
import { ChatMessage, ChatThread, Product, ProductStatus, User } from '../../types/domain';
import { formatTime } from '../../utils/time';

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

  aboutToAppear(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.threadId = params?.threadId ?? '';
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    if (this.threadId.length === 0) {
      return;
    }
    appContext.sync.publish({
      key: 'messages:changed',
      value: this.threadId,
      updatedAt: Date.now()
    });
  }

  private refresh(): void {
    const currentUser = this.getCurrentUser();
    if (!currentUser || this.threadId.length === 0) {
      this.thread = null;
      this.product = null;
      this.messages = [];
      return;
    }

    appContext.chat.markThreadRead(this.threadId, currentUser.id);
    this.thread = appContext.chat.getThread(this.threadId, currentUser.id);
    this.messages = this.thread ? appContext.chat.getMessages(this.threadId) : [];
    this.product = this.thread ? productRepository.getById(this.thread.productId) : null;
  }

  private send(): void {
    const currentUser = this.getCurrentUser();
    if (!currentUser) {
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }

    const result = appContext.chat.sendMessage(this.threadId, currentUser.id, this.draft);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (!result.ok) {
      return;
    }

    this.draft = '';
    this.refresh();
  }

  private sendQuickReply(reply: string): void {
    this.draft = reply;
    this.send();
  }

  private getCurrentUser(): User | null {
    return appContext.getCurrentUser();
  }

  private getCurrentUserId(): string {
    return this.getCurrentUser()?.id ?? '';
  }

  private getConversationTitle(): string {
    return this.thread?.peerNickname ?? '会话详情';
  }

  private getProductPriceText(): string {
    return '￥' + (this.product?.price ?? 0).toFixed(2);
  }

  @Builder
  private buildEmptyState(): void {
    Column({ space: 12 }) {
      Text('会话暂时不可用')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text('当前会话不存在或已失效，请返回消息页重新进入。')
        .fontSize(14)
        .fontColor(SUB_TEXT_COLOR)
        .textAlign(TextAlign.Center)

      Button('返回消息')
        .width('100%')
        .height(44)
        .backgroundColor(PRIMARY_COLOR)
        .onClick(() => backByContext(this))
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
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BACKGROUND)
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
          .backgroundColor('#E8F0FF')
          .borderRadius(16)
          .margin({ right: 8, bottom: 8 })
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
        this.buildQuickReplies()

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
          TextInput({ placeholder: '输入你想和对方确认的内容', text: this.draft })
            .layoutWeight(1)
            .height(46)
            .fontSize(15)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .onChange((value: string) => {
              this.draft = value;
            })

          Button('发送')
            .width(82)
            .height(46)
            .backgroundColor(PRIMARY_COLOR)
            .enabled(this.draft.trim().length > 0)
            .opacity(this.draft.trim().length > 0 ? 1 : 0.6)
            .onClick(() => this.send())
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
