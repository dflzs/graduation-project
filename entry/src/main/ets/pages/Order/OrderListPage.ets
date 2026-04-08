import { pushUrlByContext, replaceUrlByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ORDER_STATUS_TEXT } from '../../constants/config';
import { orderRepository } from '../../repositories/order.repo';
import { productRepository } from '../../repositories/product.repo';
import { Order, OrderStatus, Product, User } from '../../types/domain';
import { formatTime } from '../../utils/time';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';

@Entry
@Component
struct OrderListPage {
  @State orders: Order[] = [];

  onPageShow(): void {
    this.refresh();
  }

  aboutToAppear(): void {
    this.refresh();
  }

  private refresh(): void {
    const user: User | null = appContext.getCurrentUser();
    if (!user) {
      this.orders = [];
      return;
    }
    this.orders = orderRepository.listByUser(user.id);
  }

  private titleByOrder(order: Order): string {
    const product: Product | null = productRepository.getById(order.productId);
    return product?.title ?? `订单 ${order.id.slice(-6)}`;
  }

  private countByStatus(statuses: OrderStatus[]): number {
    return this.orders.filter((order: Order) => statuses.includes(order.status)).length;
  }

  private getStatusSummary(order: Order): string {
    if (order.status === OrderStatus.PENDING_PAYMENT) {
      return '订单已创建，等待买家完成模拟支付。';
    }
    if (order.status === OrderStatus.PAID_SIMULATED) {
      return '已完成模拟支付，等待双方到达约定地点。';
    }
    if (order.status === OrderStatus.READY_HANDOVER) {
      return '双方都已到场，可以准备现场交接商品。';
    }
    if (order.status === OrderStatus.COMPLETED) {
      return order.reviewed ? '交易与评价都已完成。' : '交易已完成，仍可补充本次评价。';
    }
    return '订单已取消，本次交易已经结束。';
  }

  private getPrimaryActionText(order: Order): string {
    if (order.status === OrderStatus.PENDING_PAYMENT) {
      return '去处理支付';
    }
    if (order.status === OrderStatus.PAID_SIMULATED) {
      return '查看到达状态';
    }
    if (order.status === OrderStatus.READY_HANDOVER) {
      return '去确认交接';
    }
    if (order.status === OrderStatus.COMPLETED) {
      return order.reviewed ? '查看评价详情' : '去补充评价';
    }
    return '查看订单详情';
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

  @Builder
  private buildHeader(): void {
    Column({ space: 4 }) {
      Text('我的订单')
        .width('100%')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text('这里会集中展示每一笔交易的状态、金额和后续操作。')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildEmptyState(): void {
    Column({ space: 12 }) {
      EmptyState({
        title: '还没有订单记录',
        description: '完成下单后，交易进度、面交信息和后续操作都会在这里集中展示。'
      })

      Button('去逛逛商品')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#2F6BFF')
        .backgroundColor('#E8F0FF')
        .padding({ left: 14, right: 14 })
        .onClick(() => replaceUrlByContext(this, { url: 'pages/Index' }))
    }
    .width('100%')
  }

  @Builder
  private buildSummaryCard(): void {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(`${this.orders.length}`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text('全部订单')
          .fontSize(12)
          .fontColor('#8C867F')
      }
      .layoutWeight(1)
      .padding(14)
      .backgroundColor(CARD_BACKGROUND)
      .borderRadius(16)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(`${this.countByStatus([OrderStatus.PENDING_PAYMENT, OrderStatus.PAID_SIMULATED, OrderStatus.READY_HANDOVER])}`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2F6BFF')

        Text('进行中')
          .fontSize(12)
          .fontColor('#8C867F')
      }
      .layoutWeight(1)
      .padding(14)
      .backgroundColor(CARD_BACKGROUND)
      .borderRadius(16)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(`${this.countByStatus([OrderStatus.COMPLETED])}`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#237B46')

        Text('已完成')
          .fontSize(12)
          .fontColor('#8C867F')
      }
      .layoutWeight(1)
      .padding(14)
      .backgroundColor(CARD_BACKGROUND)
      .borderRadius(16)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
  }

  @Builder
  private buildActionRow(order: Order): void {
    Row({ space: 8 }) {
      Text(this.getPrimaryActionText(order))
        .layoutWeight(1)
        .fontSize(12)
        .fontColor('#8C867F')

      Button('查看详情')
        .width(116)
        .height(38)
        .onClick(() => {
          pushUrlByContext(this, { url: 'pages/Order/OrderDetailPage', params: { orderId: order.id, source: 'list' } });
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private buildOrderMetaRow(order: Order): void {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text('订单金额')
          .fontSize(12)
          .fontColor('#8C867F')

        Text(`￥${order.amount.toFixed(2)}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E05A47')
      }

      Blank()

      Column({ space: 4 }) {
        Text('创建时间')
          .fontSize(12)
          .fontColor('#8C867F')

        Text(formatTime(order.createdAt))
          .fontSize(12)
          .fontColor('#6B655E')
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
  }

  @Builder
  private buildOrderCard(order: Order): void {
    Column({ space: 12 }) {
      Row() {
        Text(this.titleByOrder(order))
          .layoutWeight(1)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)
          .maxLines(2)

        Text(ORDER_STATUS_TEXT[order.status])
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStatusColor(order.status))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.getStatusBackground(order.status))
          .borderRadius(12)
      }
      .width('100%')

      this.buildOrderMetaRow(order)

      Text(`订单编号：${order.id}`)
        .fontSize(12)
        .fontColor('#8C867F')

      Text(this.getStatusSummary(order))
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#4E4740')

      Text(`面交地点：${order.locationTag}`)
        .fontSize(13)
        .fontColor('#6B655E')

      Text(`到达状态：买家${order.buyerArrived ? '已到达' : '未到达'} / 卖家${order.sellerArrived ? '已到达' : '未到达'}`)
        .fontSize(13)
        .fontColor('#6B655E')

      this.buildActionRow(order)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
    .border({
      width: 1,
      color: CARD_BORDER
    })
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        this.buildHeader()

        if (this.orders.length > 0) {
          this.buildSummaryCard()
        }

        if (this.orders.length === 0) {
          this.buildEmptyState()
        } else {
          ForEach(this.orders, (order: Order) => {
            this.buildOrderCard(order)
          }, (item: Order) => item.id)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 18 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .height('100%')
    .width('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
