import { backByContext, getParamsByContext, pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { Product, User } from '../../types/domain';
import { canUserTradeProduct, isProductOwnedByUser } from '../../utils/trade-guard';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';

@Entry
@Component
struct CreateOrderPage {
  @State productId: string = '';
  @State product: Product | null = null;
  @State address: string = '图书馆大厅，当面交接';

  private getHandoverTips(): string[] {
    return [
      '尽量提前和卖家确认见面时间，减少来回等待。',
      '建议在人流较多的校园公共区域完成面交，更安全也更方便。',
      '如果临时变更地点，可以在订单详情里继续沟通并确认到达状态。'
    ];
  }

  aboutToAppear(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.productId = params?.productId ?? '';
    this.product = appContext.product.getProductById(this.productId);
    this.guardEntry();
  }

  private guardEntry(): void {
    const user: User | null = appContext.getCurrentUser();
    if (!user || !this.product) {
      return;
    }
    if (isProductOwnedByUser(this.product, user.id)) {
      showToastByContext(this, { message: '这是你发布的商品，不能给自己下单', duration: 1600 });
      backByContext(this);
      return;
    }
    if (!canUserTradeProduct(this.product, user.id)) {
      showToastByContext(this, { message: '当前商品暂不可下单', duration: 1500 });
      backByContext(this);
    }
  }

  private submit(): void {
    const user: User | null = appContext.getCurrentUser();
    if (!user) {
      showToastByContext(this, { message: '请先登录', duration: 1500 });
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (!this.product) {
      showToastByContext(this, { message: '商品不存在', duration: 1500 });
      return;
    }
    if (isProductOwnedByUser(this.product, user.id)) {
      showToastByContext(this, { message: '这是你发布的商品，不能给自己下单', duration: 1600 });
      backByContext(this);
      return;
    }
    if (!canUserTradeProduct(this.product, user.id)) {
      showToastByContext(this, { message: '当前商品暂不可下单', duration: 1500 });
      backByContext(this);
      return;
    }

    const result = appContext.order.createOrder(user.id, this.product.id, this.address);
    showToastByContext(this, { message: result.message, duration: 1600 });

    if (result.ok) {
      const productId: string = this.product.id;
      const cartItems = appContext.cart.listByUser(user.id)
        .filter((item) => item.productId === productId);
      cartItems.forEach((item) => appContext.cart.removeItem(user.id, item.id));
      replaceUrlByContext(this, {
        url: 'pages/Order/OrderDetailPage',
        params: { orderId: result.data?.id ?? '', source: 'create' }
      });
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Column({ space: 4 }) {
          Text('确认下单')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2D2A26')

          Text('核对商品、金额与交接说明后，即可提交订单。')
            .fontSize(13)
            .fontColor('#7B756E')
        }
        .width('100%')

        if (!this.product) {
          Column({ space: 8 }) {
            Text('未找到对应商品')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4E4740')

            Text('请返回重新选择商品后，再继续提交订单。')
              .fontSize(14)
              .fontColor('#8C867F')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(24)
          .backgroundColor(CARD_BACKGROUND)
          .borderRadius(18)
          .alignItems(HorizontalAlign.Center)
        } else {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Text('商品信息')
                .width('100%')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#8C867F')

              Text(this.product.title)
                .width('100%')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2D2A26')

              Row() {
                Text('订单金额')
                  .fontSize(13)
                  .fontColor('#8C867F')
                Blank()
                Text(`￥${this.product.price.toFixed(2)}`)
                  .fontSize(26)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E05A47')
              }
              .width('100%')

              Text(`分类：${this.product.category}`)
                .fontSize(13)
                .fontColor('#6B655E')

              Text(`默认面交地点：${this.product.locationTag}`)
                .fontSize(13)
                .fontColor('#6B655E')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BACKGROUND)
            .borderRadius(18)

            Column({ space: 10 }) {
              Text('交接说明')
                .width('100%')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#8C867F')

              Text('默认采用校园面交，你可以补充更具体的地点、时间提醒或联系方式说明。')
                .width('100%')
                .fontSize(13)
                .fontColor('#6B655E')

              TextInput({ text: this.address, placeholder: '请输入面交地点或备注说明' })
                .height(46)
                .borderRadius(14)
                .backgroundColor('#FFFFFF')
                .border({ width: 1, color: '#E2D8CB' })
                .onChange((value: string) => this.address = value)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BACKGROUND)
            .borderRadius(18)

            Column({ space: 10 }) {
              Text('交易提醒')
                .width('100%')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#8C867F')

              ForEach(this.getHandoverTips(), (tip: string) => {
                Row({ space: 8 }) {
                  Text('•')
                    .fontSize(13)
                    .fontColor('#8C867F')

                  Text(tip)
                    .layoutWeight(1)
                    .fontSize(13)
                    .fontColor('#6B655E')
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }, (tip: string) => tip)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BACKGROUND)
            .borderRadius(18)

            Column({ space: 8 }) {
              Button('提交订单并查看详情')
                .width('100%')
                .height(46)
                .onClick(() => this.submit())

              Text('提交后商品会先进入交易中，你会直接进入订单详情页继续完成支付、面交确认和评价。')
                .width('100%')
                .fontSize(12)
                .fontColor('#8C867F')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BACKGROUND)
            .borderRadius(18)
          }
          .width('100%')
        }
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}