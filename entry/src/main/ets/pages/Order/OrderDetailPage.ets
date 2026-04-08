import { appContext } from '../../app/app-context';
import { ORDER_STATUS_TEXT } from '../../constants/config';
import { orderRepository } from '../../repositories/order.repo';
import { productRepository } from '../../repositories/product.repo';
import { reviewRepository } from '../../repositories/review.repo';
import { userRepository } from '../../repositories/user.repo';
import { Order, OrderStatus, Product, Review, User } from '../../types/domain';
import { formatTime } from '../../utils/time';
import { backByContext, getParamsByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';

@Entry
@Component
struct OrderDetailPage {
  @State orderId: string = '';
  @State source: string = '';
  @State order: Order | null = null;
  @State product: Product | null = null;
  @State reviews: Review[] = [];
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

  private refresh(): void {
    this.order = orderRepository.getById(this.orderId);
    this.product = this.order ? productRepository.getById(this.order.productId) : null;
    this.reviews = this.order ? reviewRepository.listByOrder(this.order.id) : [];
  }

  private currentUser(): User | null {
    return appContext.getCurrentUser();
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
      return this.isBuyer() ? '商品已经为本次订单锁定，请先完成模拟支付，再继续安排线下面交。' : '订单已创建，商品已进入交易中，等待买家完成模拟支付。';
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
      return this.isBuyer() ? '下一步建议：先完成模拟支付，再和卖家约好面交时间。商品当前已为你锁定。' : '下一步建议：等待买家支付后，再确认面交安排。商品当前不会继续公开售卖。';
    }
    if (this.order.status === OrderStatus.PAID_SIMULATED) {
      return '下一步建议：双方按约定到达面交地点，系统会记录到场状态。';
    }
    if (this.order.status === OrderStatus.READY_HANDOVER) {
      return '下一步建议：现场确认商品无误后，完成本次交易。';
    }
    if (this.order.status === OrderStatus.COMPLETED) {
      return this.order.reviewed ? '本次订单已经全部处理完毕。' : '下一步建议：补充评价，完善这次交易记录。';
    }
    return '本次订单已结束，无需继续处理。';
  }

  private runAction(action: 'pay' | 'cancel' | 'arrive' | 'complete'): void {
    const user: User | null = this.currentUser();
    if (!user || !this.order) {
      return;
    }

    let message: string = '';
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
    if (this.source === 'create') {
      replaceUrlByContext(this, { url: 'pages/Order/OrderListPage' });
      return;
    }
    backByContext(this);
  }

  @Builder
  private buildMissingState(): void {
    Column({ space: 10 }) {
      Text('未找到订单信息')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2D2A26')

      Text('请返回订单列表重新进入详情页，或确认订单是否已经被删除。')
        .fontSize(14)
        .fontColor('#8C867F')
        .textAlign(TextAlign.Center)

      Button('返回订单列表')
        .width('100%')
        .height(42)
        .onClick(() => this.goBack())
    }
    .width('100%')
    .padding(24)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildStatusCard(order: Order): void {
    Column({ space: 12 }) {
      Row() {
        Text('当前状态')
          .fontSize(14)
          .fontColor('#8C867F')
        Blank()
        Text(ORDER_STATUS_TEXT[order.status])
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStatusColor(order.status))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.getStatusBackground(order.status))
          .borderRadius(12)
      }
      .width('100%')

      Text(this.getStatusDescription())
        .width('100%')
        .fontSize(15)
        .fontColor('#4E4740')

      Text(`交易对象：${this.getCounterpartyName()}`)
        .fontSize(13)
        .fontColor('#6B655E')

      Text(this.getNextStepText())
        .fontSize(13)
        .fontColor('#6B655E')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
  }

  @Builder
  private buildProductCard(order: Order): void {
    Column({ space: 12 }) {
      Text('商品信息')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8C867F')

      Text(this.product?.title ?? '商品信息不可用')
        .width('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2D2A26')

      Row() {
        Text('成交金额')
          .fontSize(13)
          .fontColor('#8C867F')
        Blank()
        Text(`¥${order.amount.toFixed(2)}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E05A47')
      }
      .width('100%')

      if (this.product) {
        Text(`商品分类：${this.product.category}`)
          .fontSize(13)
          .fontColor('#6B655E')

        Text(`商品说明：${this.product.desc}`)
          .fontSize(13)
          .fontColor('#6B655E')
          .maxLines(3)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
  }

  @Builder
  private buildOrderInfoCard(order: Order): void {
    Column({ space: 12 }) {
      Text('订单信息')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8C867F')

      Text(`订单编号：${order.id}`)
        .fontSize(13)
        .fontColor('#6B655E')

      Text(`创建时间：${formatTime(order.createdAt)}`)
        .fontSize(13)
        .fontColor('#6B655E')

      Text(`更新时间：${formatTime(order.updatedAt)}`)
        .fontSize(13)
        .fontColor('#6B655E')

      Text(`约定地点：${order.locationTag}`)
        .fontSize(13)
        .fontColor('#6B655E')

      Text(`面交说明：${order.address}`)
        .fontSize(13)
        .fontColor('#6B655E')

      Text(`到场情况：买家${order.buyerArrived ? '已到达' : '未到达'} / 卖家${order.sellerArrived ? '已到达' : '未到达'}`)
        .fontSize(13)
        .fontColor('#6B655E')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
  }

  @Builder
  private buildReviewCard(order: Order): void {
    Column({ space: 12 }) {
      Text(order.reviewed ? '交易评价' : '补充评价')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8C867F')

      if (order.reviewed && this.getExistingReview() !== null) {
        Text(`评分：${this.getExistingReviewRatingText()}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2D2A26')

        Text(`标签：${this.getExistingReviewTag()}`)
          .fontSize(13)
          .fontColor('#6B655E')

        Text(`评价内容：${this.getExistingReviewComment()}`)
          .fontSize(13)
          .fontColor('#6B655E')
      } else {
        Text('用一句简短评价记录这次交易体验，方便完善个人信用与后续展示。')
          .width('100%')
          .fontSize(13)
          .fontColor('#6B655E')

        Row({ space: 8 }) {
          ForEach([1, 2, 3, 4, 5], (score: number) => {
            Button(`${score}星`)
              .layoutWeight(1)
              .height(36)
              .type(this.rating === score ? ButtonType.Capsule : ButtonType.Normal)
              .backgroundColor(this.rating === score ? '#1F6FDB' : '#FFFFFF')
              .fontColor(this.rating === score ? '#FFFFFF' : '#4E4740')
              .onClick(() => this.rating = score)
          }, (score: number) => `${score}`)
        }
        .width('100%')

        TextInput({ text: this.reviewTag, placeholder: '请输入评价标签，例如：沟通顺畅' })
          .height(44)
          .borderRadius(14)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E2D8CB' })
          .onChange((value: string) => this.reviewTag = value)

        TextInput({ text: this.reviewComment, placeholder: '写一句交易评价，方便后续查看' })
          .height(44)
          .borderRadius(14)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E2D8CB' })
          .onChange((value: string) => this.reviewComment = value)

        Button('提交评价')
          .width('100%')
          .height(42)
          .onClick(() => this.submitReview())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
  }

  @Builder
  private buildActionCard(order: Order): void {
    Column({ space: 10 }) {
      Text('交易操作')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8C867F')

      if (order.status === OrderStatus.PENDING_PAYMENT && this.isBuyer()) {
        Button('完成模拟支付')
          .width('100%')
          .height(42)
          .onClick(() => this.runAction('pay'))

        Button('取消订单')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .onClick(() => this.runAction('cancel'))
      }

      if (order.status === OrderStatus.PAID_SIMULATED) {
        Button('确认我已到达')
          .width('100%')
          .height(42)
          .onClick(() => this.runAction('arrive'))
      }

      if (order.status === OrderStatus.READY_HANDOVER) {
        Button('确认完成交易')
          .width('100%')
          .height(42)
          .onClick(() => this.runAction('complete'))
      }

      if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELED) {
        Text('当前订单没有额外待处理操作，你可以返回订单列表继续查看其他交易。')
          .width('100%')
          .fontSize(13)
          .fontColor('#6B655E')
      }

      Button('返回订单列表')
        .width('100%')
        .height(42)
        .type(ButtonType.Normal)
        .onClick(() => this.goBack())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Column({ space: 4 }) {
          Text('订单详情')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2D2A26')

          Text('查看当前交易状态、面交信息和后续操作。')
            .fontSize(13)
            .fontColor('#7B756E')
        }
        .width('100%')

        if (!this.order) {
          this.buildMissingState()
        } else {
          this.buildStatusCard(this.order)
          this.buildProductCard(this.order)
          this.buildOrderInfoCard(this.order)
          if (this.order.status === OrderStatus.COMPLETED) {
            this.buildReviewCard(this.order)
          }
          this.buildActionCard(this.order)
        }
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
