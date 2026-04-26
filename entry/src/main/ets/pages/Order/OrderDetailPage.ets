import { appContext } from '../../app/app-context';
import { ORDER_STATUS_TEXT } from '../../constants/config';
import { chatRepository } from '../../repositories/chat.repo';
import { orderRepository } from '../../repositories/order.repo';
import { productRepository } from '../../repositories/product.repo';
import { reviewRepository } from '../../repositories/review.repo';
import { userRepository } from '../../repositories/user.repo';
import { Order, OrderStatus, Product, Review, User } from '../../types/domain';
import { formatTime } from '../../utils/time';
import {
  canAccessTradeRecord,
  canCurrentUserOperateTrade,
  getTradeReadOnlyHint,
  getTradeRecordUnavailableDescription,
  getTradeRecordUnavailableTitle,
  shouldTreatTradeRecordAsAccessDenied
} from '../../utils/trade-guard';
import { backByContext, getParamsByContext, pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { buildOrderDetailReturnTarget } from '../../utils/detail-return-route';
import {
  buildCampusTrustTonePalette,
  buildPublicCampusTrustPresentation,
  CampusTrustPresentation
} from '../../utils/campus-trust-ui';
import { buildMarketplaceUserSyncKeys } from '../../utils/marketplace-audience-ui';
import {
  buildModerationEntryActionLabel,
  buildModerationEntryDescription,
  buildModerationEntryTitle,
  buildModerationTargetFallbackTitle
} from '../../utils/moderation-submit-copy';
import { buildHandoverStatusSummary } from '../../utils/handover-scheduling';
import {
  buildOrderConversationActionLabel,
  buildOrderConversationPrompt,
  buildTradeProgressNextStep,
  buildTradeProgressStatusDescription
} from '../../utils/trade-progress-guidance';
import {
  buildCampusTradeSafetyHeadline,
  buildCampusTradeSafetyPrompts
} from '../../utils/trade-safety-prompts';
import {
  buildTradeLinkedProductActionLabel,
  buildTradeLinkedProductPrompt
} from '../../utils/trade-cross-navigation';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFCF8';
const CARD_BORDER: string = '#E4D9CC';
const CARD_SOFT_BACKGROUND: string = '#F7F1E9';
const PRIMARY_COLOR: string = '#2F6BFF';
const MUTED_COLOR: string = '#7B756E';
const FIELD_LABEL_COLOR: string = '#8C867F';
const TEXT_COLOR: string = '#2D2A26';
const SECONDARY_BACKGROUND: string = '#EDF3FF';
const SECONDARY_BORDER: string = '#D6E3FF';
const DANGER_BACKGROUND: string = '#F8ECE4';
const DANGER_BORDER: string = '#E8D1C2';
const DANGER_TEXT_COLOR: string = '#B8643C';

@Entry
@Component
struct OrderDetailPage {
  @State orderId: string = '';
  @State source: string = '';
  @State order: Order | null = null;
  @State product: Product | null = null;
  @State reviews: Review[] = [];
  @State accessDenied: boolean = false;
  @State rating: number = 5;
  @State reviewTag: string = '交易顺利';
  @State reviewComment: string = '';
  private orderSyncUnsubscriber: (() => void) | null = null;
  private userSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.orderId = params?.orderId ?? '';
    this.source = params?.source ?? '';
    this.refresh();
    this.bindOrderSync();
    this.bindUserSync();
  }

  onPageShow(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    if (this.orderSyncUnsubscriber) {
      this.orderSyncUnsubscriber();
      this.orderSyncUnsubscriber = null;
    }
    this.userSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.userSyncUnsubscribers = [];
    this.publishReturnRefreshSignals();
  }

  private bindOrderSync(): void {
    if (this.orderSyncUnsubscriber) {
      return;
    }
    this.orderSyncUnsubscriber = appContext.sync.subscribe('orders:changed', () => {
      this.refresh();
    });
  }

  private bindUserSync(): void {
    if (this.userSyncUnsubscribers.length > 0) {
      return;
    }
    this.userSyncUnsubscribers = buildMarketplaceUserSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        this.refresh();
      })
    );
  }

  private async refresh(): Promise<void> {
    const currentUser: User | null = this.currentUser();
    let order: Order | null = orderRepository.getById(this.orderId);
    if (currentUser) {
      const refreshed = await appContext.order.getOrderDetail(this.orderId, currentUser.id);
      order = refreshed.data ?? orderRepository.getById(this.orderId);
    }
    const canAccessOrder: boolean = order !== null
      && canAccessTradeRecord(currentUser, [order.buyerId, order.sellerId]);
    if (!currentUser || !order || !canAccessOrder) {
      this.accessDenied = shouldTreatTradeRecordAsAccessDenied(currentUser, order !== null, canAccessOrder);
      this.order = null;
      this.product = null;
      this.reviews = [];
      return;
    }

    this.accessDenied = false;
    this.order = order;
    this.product = productRepository.getById(order.productId);
    this.reviews = reviewRepository.listByOrder(order.id);
  }

  private currentUser(): User | null {
    return appContext.getCurrentUser();
  }

  private publishReturnRefreshSignals(): void {
    const updatedAt = Date.now();
    appContext.sync.publish({
      key: 'orders:changed',
      value: this.orderId,
      updatedAt
    });

    if (this.source === 'message') {
      appContext.sync.publish({
        key: 'messages:changed',
        value: this.orderId,
        updatedAt
      });
    }
  }

  private isBuyer(): boolean {
    const user: User | null = this.currentUser();
    return user !== null && this.order !== null && user.id === this.order.buyerId;
  }

  private isReadOnlyTradeView(): boolean {
    return !canCurrentUserOperateTrade(this.currentUser());
  }

  private getStatusColor(status: OrderStatus): string {
    if (status === OrderStatus.PENDING_PAYMENT) {
      return '#A86B00';
    }
    if (status === OrderStatus.PAID_SIMULATED) {
      return '#1F6FDB';
    }
    if (status === OrderStatus.READY_HANDOVER) {
      return '#237B46';
    }
    if (status === OrderStatus.COMPLETED) {
      return '#5E5851';
    }
    return '#8A4B4B';
  }

  private getStatusBackground(status: OrderStatus): string {
    if (status === OrderStatus.PENDING_PAYMENT) {
      return '#F8E8BF';
    }
    if (status === OrderStatus.PAID_SIMULATED) {
      return '#E4EEFF';
    }
    if (status === OrderStatus.READY_HANDOVER) {
      return '#E7F5EA';
    }
    if (status === OrderStatus.COMPLETED) {
      return '#ECEAE7';
    }
    return '#F6E4E4';
  }

  private getStatusDescription(): string {
    return this.order ? buildTradeProgressStatusDescription(this.order, this.currentUser()?.id ?? '') : '';
  }

  private getConversationThreadId(): string {
    return this.order ? chatRepository.findThreadByOrder(this.order)?.id ?? '' : '';
  }

  private canOpenConversation(): boolean {
    return this.getConversationThreadId().length > 0;
  }

  private openConversation(): void {
    const threadId = this.getConversationThreadId();
    if (threadId.length === 0) {
      return;
    }
    pushUrlByContext(this, {
      url: 'pages/Chat/ChatDetailPage',
      params: { threadId }
    });
  }

  private getCounterpartyName(): string {
    if (!this.order) {
      return '未知用户';
    }
    const userId: string = this.isBuyer() ? this.order.sellerId : this.order.buyerId;
    return userRepository.getById(userId)?.nickname ?? '校园用户';
  }

  private getCounterpartyTrustPresentation(): CampusTrustPresentation {
    if (!this.order) {
      return buildPublicCampusTrustPresentation(null);
    }
    const counterpartyId: string = this.isBuyer() ? this.order.sellerId : this.order.buyerId;
    return buildPublicCampusTrustPresentation(userRepository.getById(counterpartyId));
  }

  private getCounterpartyTrustCardBackground(): string {
    return buildCampusTrustTonePalette(this.getCounterpartyTrustPresentation().tone).surfaceBackgroundColor;
  }

  private getCounterpartyTrustRiskTextColor(): string {
    return buildCampusTrustTonePalette(this.getCounterpartyTrustPresentation().tone).riskBadgeTextColor;
  }

  private getCounterpartyTrustRiskBackground(): string {
    return buildCampusTrustTonePalette(this.getCounterpartyTrustPresentation().tone).riskBadgeBackgroundColor;
  }

  private getCounterpartyTrustTagTextColor(): string {
    return buildCampusTrustTonePalette(this.getCounterpartyTrustPresentation().tone).tagTextColor;
  }

  private getCounterpartyTrustTagBackground(): string {
    return buildCampusTrustTonePalette(this.getCounterpartyTrustPresentation().tone).tagBackgroundColor;
  }

  private getExistingReview(): Review | null {
    return this.reviews.length > 0 ? this.reviews[0] : null;
  }

  private getExistingReviewRatingText(): string {
    const review: Review | null = this.getExistingReview();
    return review ? `${review.rating} 星` : '--';
  }

  private getExistingReviewTag(): string {
    const review: Review | null = this.getExistingReview();
    return review ? review.tag : '--';
  }

  private getExistingReviewComment(): string {
    const review: Review | null = this.getExistingReview();
    return review ? review.comment : '--';
  }

  private getNextStepText(): string {
    return this.order ? buildTradeProgressNextStep(this.order, this.currentUser()?.id ?? '') : '';
  }

  private getTradeSafetyPrompts(): string[] {
    return buildCampusTradeSafetyPrompts(this.product?.category ?? '其他', 'order_detail');
  }

  private openLinkedProductDetail(): void {
    if (!this.product) {
      return;
    }
    pushUrlByContext(this, {
      url: 'pages/Product/ProductDetailPage',
      params: { productId: this.product.id }
    });
  }

  @Builder
  private buildPageHeader(): void {
    Column({ space: 6 }) {
      Text('订单详情')
        .width('100%')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_COLOR)

      Text('查看当前交易状态、面交信息和后续操作。')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(MUTED_COLOR)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildBadge(text: string, background: string, color: string): void {
    Text(text)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(color)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(background)
      .borderRadius(12)
  }

  @Builder
  private buildFieldRow(label: string, value: string, emphasize: boolean = false): void {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(FIELD_LABEL_COLOR)

      Blank()

      Text(value)
        .fontSize(13)
        .fontWeight(emphasize ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(TEXT_COLOR)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  private buildActionButton(
    text: string,
    backgroundColor: string,
    textColor: string,
    borderColor: string,
    onClickHandler: () => void,
    enabled: boolean = true
  ): void {
    Button(text)
      .width('100%')
      .height(46)
      .type(ButtonType.Normal)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(textColor)
      .backgroundColor(backgroundColor)
      .borderRadius(16)
      .border({ width: 1, color: borderColor })
      .enabled(enabled)
      .opacity(enabled ? 1 : 0.6)
      .onClick(onClickHandler)
  }

  private async runAction(action: 'pay' | 'cancel' | 'arrive' | 'complete'): Promise<void> {
    const user: User | null = this.currentUser();
    if (!user || !this.order || this.isReadOnlyTradeView()) {
      return;
    }

    let message = '';
    if (action === 'pay') {
      message = (await appContext.order.simulatePay(this.order.id, user.id)).message;
    } else if (action === 'cancel') {
      message = (await appContext.order.cancelOrder(this.order.id, user.id)).message;
    } else if (action === 'arrive') {
      message = (await appContext.order.markArrived(this.order.id, user.id)).message;
    } else if (action === 'complete') {
      message = (await appContext.order.completeOrder(this.order.id, user.id)).message;
    }

    showToastByContext(this, { message, duration: 1500 });
    this.refresh();
  }

  private submitReview(): void {
    const user: User | null = this.currentUser();
    if (!user || !this.order || this.isReadOnlyTradeView()) {
      return;
    }
    const result = appContext.order.addReview(this.order.id, user.id, this.rating, this.reviewTag, this.reviewComment);
    showToastByContext(this, { message: result.message, duration: 1500 });
    if (result.ok) {
      this.refresh();
    }
  }

  private openComplaintPage(): void {
    if (!this.order || this.isReadOnlyTradeView()) {
      return;
    }
    pushUrlByContext(this, {
      url: 'pages/Moderation/SubmitModerationPage',
      params: {
        targetType: 'order_complaint',
        targetId: this.order.id,
        title: this.product?.title ?? buildModerationTargetFallbackTitle('order_complaint')
      }
    });
  }

  private goBack(): void {
    const returnTarget = buildOrderDetailReturnTarget(this.source);
    if (returnTarget) {
      replaceUrlByContext(this, { url: returnTarget.url, params: returnTarget.params });
      return;
    }
    backByContext(this);
  }

  @Builder
  private buildMissingState(): void {
    Column({ space: 10 }) {
      Text(getTradeRecordUnavailableTitle('order', this.currentUser(), this.accessDenied))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_COLOR)

      Text(getTradeRecordUnavailableDescription('order', this.currentUser(), this.accessDenied))
        .fontSize(14)
        .fontColor(MUTED_COLOR)
        .textAlign(TextAlign.Center)

      Button('返回订单列表')
        .width('100%')
        .height(46)
        .type(ButtonType.Normal)
        .fontColor(PRIMARY_COLOR)
        .backgroundColor(SECONDARY_BACKGROUND)
        .borderRadius(16)
        .border({ width: 1, color: SECONDARY_BORDER })
        .onClick(() => this.goBack())
    }
    .width('100%')
    .padding(20)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildStatusCard(order: Order): void {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('当前状态')
            .fontSize(13)
            .fontColor(FIELD_LABEL_COLOR)

          Text(ORDER_STATUS_TEXT[order.status])
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        this.buildBadge(ORDER_STATUS_TEXT[order.status], this.getStatusBackground(order.status), this.getStatusColor(order.status))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.getStatusDescription())
        .width('100%')
        .fontSize(16)
        .lineHeight(24)
        .fontColor('#4E4740')

      Row({ space: 10 }) {
        Column({ space: 3 }) {
          Text('交易对象')
            .fontSize(12)
            .fontColor(FIELD_LABEL_COLOR)
          Text(this.getCounterpartyName())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 3 }) {
          Text('成交金额')
            .fontSize(12)
            .fontColor(FIELD_LABEL_COLOR)
          Text(`￥${order.amount.toFixed(2)}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E05A47')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('下一步建议')
          .fontSize(12)
          .fontColor(FIELD_LABEL_COLOR)

        Text(this.getNextStepText())
          .fontSize(13)
          .lineHeight(21)
          .fontColor('#5B554F')
      }
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_SOFT_BACKGROUND)
      .borderRadius(16)

      Column({ space: 8 }) {
        Text('面交安排')
          .width('100%')
          .fontSize(12)
          .fontColor(FIELD_LABEL_COLOR)

        Text(buildHandoverStatusSummary(order.locationTag, order.address))
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor('#5B554F')
      }
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_SOFT_BACKGROUND)
      .borderRadius(16)

      Column({ space: 8 }) {
        Text(buildCampusTradeSafetyHeadline('order_detail'))
          .width('100%')
          .fontSize(12)
          .fontColor(FIELD_LABEL_COLOR)

        ForEach(this.getTradeSafetyPrompts(), (tip: string) => {
          Row({ space: 8 }) {
            Text('·')
              .fontSize(12)
              .fontColor(FIELD_LABEL_COLOR)

            Text(tip)
              .layoutWeight(1)
              .fontSize(13)
              .lineHeight(20)
              .fontColor('#5B554F')
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (tip: string) => tip)
      }
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_SOFT_BACKGROUND)
      .borderRadius(16)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildProductCard(order: Order): void {
    Column({ space: 12 }) {
      Text('商品信息')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(FIELD_LABEL_COLOR)

      Row() {
        Column({ space: 6 }) {
          Text(this.product?.title ?? '商品信息不可用')
            .width('100%')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLOR)
            .maxLines(2)

          if (this.product) {
            Row({ space: 8 }) {
              this.buildBadge(this.product.category, '#E8F5EA', '#237B46')
              this.buildBadge(this.product.locationTag, '#F2EEE7', '#6B655E')
            }
            .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`￥${order.amount.toFixed(2)}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E05A47')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.product) {
        Column({ space: 10 }) {
          Text('商品说明')
            .fontSize(12)
            .fontColor(FIELD_LABEL_COLOR)

          Text(this.product.desc)
            .fontSize(14)
            .lineHeight(22)
            .fontColor('#5B554F')
            .maxLines(3)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(CARD_SOFT_BACKGROUND)
        .borderRadius(16)

        Text(buildTradeLinkedProductPrompt('order'))
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(MUTED_COLOR)

        this.buildActionButton(
          buildTradeLinkedProductActionLabel(),
          '#FFFFFF',
          PRIMARY_COLOR,
          SECONDARY_BORDER,
          () => this.openLinkedProductDetail()
        )
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildOrderInfoCard(order: Order): void {
    Column({ space: 12 }) {
      Text('订单信息')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(FIELD_LABEL_COLOR)

      Column({ space: 12 }) {
        this.buildFieldRow('订单编号', order.id)
        this.buildFieldRow('创建时间', formatTime(order.createdAt))
        this.buildFieldRow('更新时间', formatTime(order.updatedAt))
        this.buildFieldRow('约定地点', order.locationTag)
        this.buildFieldRow('面交说明', order.address)
        this.buildFieldRow('到场情况', `买家${order.buyerArrived ? '已到达' : '未到达'} / 卖家${order.sellerArrived ? '已到达' : '未到达'}`)
      }
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_SOFT_BACKGROUND)
      .borderRadius(16)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildCounterpartyTrustCard(): void {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('交易对象身份')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(FIELD_LABEL_COLOR)

          Text(this.getCounterpartyTrustPresentation().headline)
            .fontSize(13)
            .fontColor(MUTED_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        this.buildBadge(
          this.getCounterpartyTrustPresentation().badgeText,
          this.getCounterpartyTrustPresentation().badgeBackgroundColor,
          this.getCounterpartyTrustPresentation().badgeTextColor
        )
      }
      .width('100%')

      Text(this.getCounterpartyName())
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_COLOR)

      Row({ space: 8 }) {
        Text(this.getCounterpartyTrustPresentation().summary)
          .layoutWeight(1)
          .fontSize(14)
          .fontColor('#4E4740')

        Text(this.getCounterpartyTrustPresentation().riskLabel)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getCounterpartyTrustRiskTextColor())
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getCounterpartyTrustRiskBackground())
          .borderRadius(12)
      }
      .width('100%')

      if (this.getCounterpartyTrustPresentation().trustTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
          ForEach(this.getCounterpartyTrustPresentation().trustTags, (tag: string) => {
            Text(tag)
              .fontSize(11)
              .fontColor(this.getCounterpartyTrustTagTextColor())
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.getCounterpartyTrustTagBackground())
              .borderRadius(12)
              .margin({ right: 8, bottom: 8 })
          }, (tag: string) => tag)
        }
        .width('100%')
      }

      Text(this.getCounterpartyTrustPresentation().helperText)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(MUTED_COLOR)

      Text(this.getCounterpartyTrustPresentation().riskText)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8C867F')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.getCounterpartyTrustCardBackground())
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildReviewCard(order: Order): void {
    Column({ space: 12 }) {
      Text(order.reviewed ? '交易评价' : '补充评价')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(FIELD_LABEL_COLOR)

      if (order.reviewed && this.getExistingReview() !== null) {
        Column({ space: 10 }) {
          this.buildFieldRow('评分', this.getExistingReviewRatingText(), true)
          this.buildFieldRow('标签', this.getExistingReviewTag())
          this.buildFieldRow('内容', this.getExistingReviewComment())
        }
        .width('100%')
        .padding(14)
        .backgroundColor(CARD_SOFT_BACKGROUND)
        .borderRadius(16)
      } else if (this.isReadOnlyTradeView()) {
        Column({ space: 8 }) {
          Text('当前订单已切换为只读')
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(DANGER_TEXT_COLOR)

          Text(getTradeReadOnlyHint(this.currentUser(), 'order'))
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(MUTED_COLOR)
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#F8ECE4')
        .borderRadius(16)
      } else {
        Text('用一句简短评价记录这次交易体验，方便后续查看。')
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor(MUTED_COLOR)

        Row({ space: 8 }) {
          ForEach([1, 2, 3, 4, 5], (score: number) => {
            Button(`${score}星`)
              .layoutWeight(1)
              .height(38)
              .type(ButtonType.Normal)
              .borderRadius(14)
              .backgroundColor(this.rating === score ? PRIMARY_COLOR : '#FFFFFF')
              .fontColor(this.rating === score ? '#FFFFFF' : '#4E4740')
              .border({
                width: 1,
                color: this.rating === score ? PRIMARY_COLOR : '#E2D8CB'
              })
              .onClick(() => this.rating = score)
          }, (score: number) => `${score}`)
        }
        .width('100%')

        TextInput({ text: this.reviewTag, placeholder: '请输入评价标签，例如：沟通顺畅' })
          .height(46)
          .borderRadius(14)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E2D8CB' })
          .onChange((value: string) => this.reviewTag = value)

        TextInput({ text: this.reviewComment, placeholder: '写一句交易评价，方便后续查看' })
          .height(46)
          .borderRadius(14)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E2D8CB' })
          .onChange((value: string) => this.reviewComment = value)

        this.buildActionButton('提交评价', PRIMARY_COLOR, '#FFFFFF', PRIMARY_COLOR, () => this.submitReview())
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildActionCard(order: Order): void {
    Column({ space: 10 }) {
      Text('交易操作')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(FIELD_LABEL_COLOR)

      if (this.isReadOnlyTradeView()) {
        Column({ space: 8 }) {
          Text('当前订单已切换为只读')
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(DANGER_TEXT_COLOR)

          Text(getTradeReadOnlyHint(this.currentUser(), 'order'))
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(MUTED_COLOR)
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#F8ECE4')
        .borderRadius(16)

        if (this.canOpenConversation()) {
          Text(buildOrderConversationPrompt(order))
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(MUTED_COLOR)

          this.buildActionButton(buildOrderConversationActionLabel(order), '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.openConversation())
        }

        this.buildActionButton('返回订单列表', '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.goBack())
      } else if (order.status === OrderStatus.PENDING_PAYMENT && this.isBuyer()) {
        this.buildActionButton('完成模拟支付', PRIMARY_COLOR, '#FFFFFF', PRIMARY_COLOR, () => this.runAction('pay'))
        this.buildActionButton('取消订单', DANGER_BACKGROUND, DANGER_TEXT_COLOR, DANGER_BORDER, () => this.runAction('cancel'))
      } else if (order.status === OrderStatus.PAID_SIMULATED) {
        this.buildActionButton('确认我已到达', PRIMARY_COLOR, '#FFFFFF', PRIMARY_COLOR, () => this.runAction('arrive'))
        this.buildActionButton('返回订单列表', '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.goBack())
      } else if (order.status === OrderStatus.READY_HANDOVER) {
        this.buildActionButton('确认完成交易', PRIMARY_COLOR, '#FFFFFF', PRIMARY_COLOR, () => this.runAction('complete'))
        this.buildActionButton('返回订单列表', '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.goBack())
      } else {
        Column({ space: 8 }) {
          Text('当前订单没有额外待处理操作，你可以返回订单列表继续查看其他交易。')
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(MUTED_COLOR)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(CARD_SOFT_BACKGROUND)
        .borderRadius(16)

        if (this.canOpenConversation()) {
          Text(buildOrderConversationPrompt(order))
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(MUTED_COLOR)

          this.buildActionButton(buildOrderConversationActionLabel(order), '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.openConversation())
        }

        this.buildActionButton('返回订单列表', '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.goBack())
      }

      if (!this.isReadOnlyTradeView() && order.status !== OrderStatus.CANCELED && this.canOpenConversation()) {
        Text(buildOrderConversationPrompt(order))
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor(MUTED_COLOR)

        this.buildActionButton(buildOrderConversationActionLabel(order), '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.openConversation())
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildModerationCard(order: Order): void {
    Column({ space: 10 }) {
      Text('订单投诉')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(FIELD_LABEL_COLOR)

      Text(`如果这笔订单存在沟通失约、到场纠纷或异常交易情况，可以提交投诉，平台会进入人工处理。`)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(MUTED_COLOR)

      this.buildActionButton('提交投诉', '#FFFFFF', '#A86B00', '#E8D8B6', () => this.openComplaintPage())
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildGovernanceEntryCard(): void {
    Column({ space: 10 }) {
      Text(buildModerationEntryTitle('order_complaint'))
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(FIELD_LABEL_COLOR)
      Text(buildModerationEntryDescription('order_complaint'))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(MUTED_COLOR)
      this.buildActionButton(buildModerationEntryActionLabel('order_complaint'), '#FFFFFF', '#A86B00', '#E8D8B6', () => this.openComplaintPage())
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }
  build() {
    Scroll() {
      Column({ space: 14 }) {
        this.buildPageHeader()

        if (!this.order) {
          this.buildMissingState()
        } else {
          this.buildStatusCard(this.order)
          this.buildProductCard(this.order)
          this.buildCounterpartyTrustCard()
          this.buildOrderInfoCard(this.order)
          if (!this.isReadOnlyTradeView()) {
            this.buildGovernanceEntryCard()
          }
          if (this.order.status === OrderStatus.COMPLETED) {
            this.buildReviewCard(this.order)
          }
          this.buildActionCard(this.order)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 18 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
