import { appContext } from '../../app/app-context';
import { ORDER_STATUS_TEXT } from '../../constants/config';
import { orderRepository } from '../../repositories/order.repo';
import { productRepository } from '../../repositories/product.repo';
import { reviewRepository } from '../../repositories/review.repo';
import { userRepository } from '../../repositories/user.repo';
import { Order, OrderStatus, Product, Review, User } from '../../types/domain';
import { formatTime } from '../../utils/time';
import { canUserAccessOrder } from '../../utils/trade-guard';
import { backByContext, getParamsByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { buildOrderDetailReturnTarget } from '../../utils/detail-return-route';
import { buildPublicCampusTrustPresentation, CampusTrustPresentation } from '../../utils/campus-trust-ui';

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

  aboutToAppear(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.orderId = params?.orderId ?? '';
    this.source = params?.source ?? '';
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    this.publishReturnRefreshSignals();
  }

  private refresh(): void {
    const currentUser: User | null = this.currentUser();
    const order: Order | null = orderRepository.getById(this.orderId);
    if (!currentUser || !order || !canUserAccessOrder(order, currentUser.id)) {
      this.accessDenied = order !== null && currentUser !== null;
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
    if (!this.order) {
      return '';
    }
    if (this.order.status === OrderStatus.PENDING_PAYMENT) {
      return this.isBuyer()
        ? '商品已为本次订单锁定，请先完成模拟支付，再继续安排线下面交。'
        : '订单已创建，商品已进入交易中，等待买家完成模拟支付。';
    }
    if (this.order.status === OrderStatus.PAID_SIMULATED) {
      return '双方到达约定地点后，订单会自动进入待交接状态。';
    }
    if (this.order.status === OrderStatus.READY_HANDOVER) {
      return '双方均已到场，可以现场完成商品验收与交接。';
    }
    if (this.order.status === OrderStatus.COMPLETED) {
      return this.order.reviewed ? '本次交易已完成，评价也已经提交。' : '交易已完成，可以补充本次交易评价。';
    }
    return '订单已经取消，本次交易流程结束。';
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
    if (!this.order) {
      return '';
    }
    if (this.order.status === OrderStatus.PENDING_PAYMENT) {
      return this.isBuyer()
        ? '下一步建议：完成模拟支付后，和卖家确认面交时间。'
        : '下一步建议：等待买家支付后，再确认面交安排。';
    }
    if (this.order.status === OrderStatus.PAID_SIMULATED) {
      return '下一步建议：双方按约定到达面交地点，系统会记录到场状态。';
    }
    if (this.order.status === OrderStatus.READY_HANDOVER) {
      return '下一步建议：现场确认商品无误后，完成本次交易。';
    }
    if (this.order.status === OrderStatus.COMPLETED) {
      return this.order.reviewed
        ? '本次订单已全部处理完毕。'
        : '下一步建议：补充评价，完善这次交易记录。';
    }
    return '本次订单已结束，无需继续处理。';
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
    onClickHandler: () => void
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
      .onClick(onClickHandler)
  }

  private runAction(action: 'pay' | 'cancel' | 'arrive' | 'complete'): void {
    const user: User | null = this.currentUser();
    if (!user || !this.order) {
      return;
    }

    let message = '';
    if (action === 'pay') {
      message = appContext.order.simulatePay(this.order.id, user.id).message;
    } else if (action === 'cancel') {
      message = appContext.order.cancelOrder(this.order.id, user.id).message;
    } else if (action === 'arrive') {
      message = appContext.order.markArrived(this.order.id, user.id).message;
    } else if (action === 'complete') {
      message = appContext.order.completeOrder(this.order.id, user.id).message;
    }

    showToastByContext(this, { message, duration: 1500 });
    this.refresh();
  }

  private submitReview(): void {
    const user: User | null = this.currentUser();
    if (!user || !this.order) {
      return;
    }
    const result = appContext.order.addReview(this.order.id, user.id, this.rating, this.reviewTag, this.reviewComment);
    showToastByContext(this, { message: result.message, duration: 1500 });
    if (result.ok) {
      this.refresh();
    }
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
      Text(this.accessDenied ? '无权查看该订单' : '未找到订单信息')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_COLOR)

      Text(this.accessDenied
        ? '这笔订单不属于当前账号，请返回订单列表查看你自己的交易记录。'
        : '请返回订单列表重新进入详情页，或确认订单是否已经被删除。')
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

      Text(this.getCounterpartyTrustPresentation().summary)
        .width('100%')
        .fontSize(14)
        .fontColor('#4E4740')

      Text(this.getCounterpartyTrustPresentation().helperText)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(MUTED_COLOR)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
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

      if (order.status === OrderStatus.PENDING_PAYMENT && this.isBuyer()) {
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

        this.buildActionButton('返回订单列表', '#FFFFFF', PRIMARY_COLOR, SECONDARY_BORDER, () => this.goBack())
      }
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
