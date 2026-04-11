import { backByContext, getParamsByContext, pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { Product, User } from '../../types/domain';
import { canCurrentUserJoinTrade, canUserTradeProduct, isProductOwnedByUser } from '../../utils/trade-guard';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';

@Entry
@Component
struct CreateOrderPage {
  @State productId: string = '';
  @State product: Product | null = null;
  @State address: string = '\u56fe\u4e66\u9986\u5927\u5385\uff0c\u5f53\u9762\u4ea4\u63a5';

  private getRecommendedTradeLocationLabel(): string {
    if (!this.product) {
      return '';
    }
    if (this.product.tradeLocationName && this.product.tradeLocationName.length > 0) {
      return this.product.tradeLocationName;
    }
    return this.product.locationTag;
  }

  private getCampusScopeText(): string {
    if (!this.product) {
      return '';
    }
    const parts: string[] = [];
    if (this.product.schoolName && this.product.schoolName.length > 0) {
      parts.push(this.product.schoolName);
    }
    if (this.product.campusName && this.product.campusName.length > 0) {
      parts.push(this.product.campusName);
    }
    if (this.product.locationGroupName && this.product.locationGroupName.length > 0) {
      parts.push(this.product.locationGroupName);
    }
    return parts.join(' / ');
  }

  private getLocationSafetyTip(): string {
    if (!this.product || !this.product.locationSafetyTips || this.product.locationSafetyTips.length === 0) {
      return '\u5efa\u8bae\u4f18\u5148\u5728\u6821\u56ed\u516c\u5171\u533a\u57df\u5b8c\u6210\u9762\u4ea4\uff0c\u5e76\u5f53\u573a\u786e\u8ba4\u5546\u54c1\u72b6\u6001\u3002';
    }
    return this.product.locationSafetyTips;
  }

  private getHandoverTips(): string[] {
    return [
      '\u5c3d\u91cf\u63d0\u524d\u548c\u5356\u5bb6\u786e\u8ba4\u89c1\u9762\u65f6\u95f4\uff0c\u51cf\u5c11\u6765\u56de\u7b49\u5f85\u3002',
      '\u5efa\u8bae\u5728\u4eba\u6d41\u8f83\u591a\u7684\u6821\u56ed\u516c\u5171\u533a\u57df\u5b8c\u6210\u9762\u4ea4\uff0c\u66f4\u5b89\u5168\u4e5f\u66f4\u65b9\u4fbf\u3002',
      '\u5982\u679c\u4e34\u65f6\u53d8\u66f4\u5730\u70b9\uff0c\u53ef\u4ee5\u5728\u8ba2\u5355\u8be6\u60c5\u91cc\u7ee7\u7eed\u6c9f\u901a\u5e76\u786e\u8ba4\u5230\u8fbe\u72b6\u6001\u3002',
      this.getLocationSafetyTip()
    ];
  }

  aboutToAppear(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.productId = params?.productId ?? '';
    this.product = appContext.product.getProductById(this.productId);
    const recommendedLocation = this.getRecommendedTradeLocationLabel();
    if (recommendedLocation.length > 0) {
      this.address = `${recommendedLocation}\uff0c\u5f53\u9762\u4ea4\u63a5`;
    }
    this.guardEntry();
  }

  private guardEntry(): void {
    const user: User | null = appContext.getCurrentUser();
    if (!user || !this.product) {
      return;
    }
    if (!canCurrentUserJoinTrade(user)) {
      showToastByContext(this, { message: '管理员账号不支持下单', duration: 1500 });
      backByContext(this);
      return;
    }
    if (isProductOwnedByUser(this.product, user.id)) {
      showToastByContext(this, { message: '\u8fd9\u662f\u4f60\u53d1\u5e03\u7684\u5546\u54c1\uff0c\u4e0d\u80fd\u7ed9\u81ea\u5df1\u4e0b\u5355', duration: 1600 });
      backByContext(this);
      return;
    }
    if (!canUserTradeProduct(this.product, user.id, user.role)) {
      showToastByContext(this, { message: '\u5f53\u524d\u5546\u54c1\u6682\u4e0d\u53ef\u4e0b\u5355', duration: 1500 });
      backByContext(this);
    }
  }

  private submit(): void {
    const user: User | null = appContext.getCurrentUser();
    if (!user) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55', duration: 1500 });
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (!canCurrentUserJoinTrade(user)) {
      showToastByContext(this, { message: '管理员账号不支持下单', duration: 1500 });
      backByContext(this);
      return;
    }
    if (!this.product) {
      showToastByContext(this, { message: '\u5546\u54c1\u4e0d\u5b58\u5728', duration: 1500 });
      return;
    }
    if (isProductOwnedByUser(this.product, user.id)) {
      showToastByContext(this, { message: '\u8fd9\u662f\u4f60\u53d1\u5e03\u7684\u5546\u54c1\uff0c\u4e0d\u80fd\u7ed9\u81ea\u5df1\u4e0b\u5355', duration: 1600 });
      backByContext(this);
      return;
    }
    if (!canUserTradeProduct(this.product, user.id, user.role)) {
      showToastByContext(this, { message: '\u5f53\u524d\u5546\u54c1\u6682\u4e0d\u53ef\u4e0b\u5355', duration: 1500 });
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
          Text('\u786e\u8ba4\u4e0b\u5355')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2D2A26')

          Text('\u6838\u5bf9\u5546\u54c1\u3001\u91d1\u989d\u4e0e\u4ea4\u63a5\u8bf4\u660e\u540e\uff0c\u5373\u53ef\u63d0\u4ea4\u8ba2\u5355\u3002')
            .fontSize(13)
            .fontColor('#7B756E')
        }
        .width('100%')

        if (!this.product) {
          Column({ space: 8 }) {
            Text('\u672a\u627e\u5230\u5bf9\u5e94\u5546\u54c1')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4E4740')

            Text('\u8bf7\u8fd4\u56de\u91cd\u65b0\u9009\u62e9\u5546\u54c1\u540e\uff0c\u518d\u7ee7\u7eed\u63d0\u4ea4\u8ba2\u5355\u3002')
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
              Text('\u5546\u54c1\u4fe1\u606f')
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
                Text('\u8ba2\u5355\u91d1\u989d')
                  .fontSize(13)
                  .fontColor('#8C867F')
                Blank()
                Text(`¥${this.product.price.toFixed(2)}`)
                  .fontSize(26)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E05A47')
              }
              .width('100%')

              Text(`\u5206\u7c7b\uff1a${this.product.category}`)
                .fontSize(13)
                .fontColor('#6B655E')

              Text(`\u63a8\u8350\u4ea4\u6613\u70b9\uff1a${this.getRecommendedTradeLocationLabel()}`)
                .fontSize(13)
                .fontColor('#6B655E')

              if (this.getCampusScopeText().length > 0) {
                Text(`\u6821\u56ed\u8303\u56f4\uff1a${this.getCampusScopeText()}`)
                  .fontSize(13)
                  .fontColor('#6B655E')
              }

              Text(this.getLocationSafetyTip())
                .width('100%')
                .fontSize(12)
                .fontColor('#8C867F')
                .lineHeight(18)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BACKGROUND)
            .borderRadius(18)

            Column({ space: 10 }) {
              Text('\u4ea4\u63a5\u8bf4\u660e')
                .width('100%')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#8C867F')

              Text('\u7cfb\u7edf\u5df2\u6839\u636e\u5546\u54c1\u7ed1\u5b9a\u7684\u6821\u56ed\u5730\u70b9\u4e3a\u4f60\u9884\u586b\u9ed8\u8ba4\u9762\u4ea4\u5730\u70b9\uff0c\u4f60\u53ef\u4ee5\u8865\u5145\u65f6\u95f4\u3001\u697c\u5c42\u6216\u8054\u7cfb\u8bf4\u660e\u3002')
                .width('100%')
                .fontSize(13)
                .fontColor('#6B655E')

              TextInput({ text: this.address, placeholder: '\u8bf7\u8f93\u5165\u89c1\u9762\u65f6\u95f4\u6216\u8865\u5145\u8bf4\u660e' })
                .height(46)
                .borderRadius(14)
                .backgroundColor('#FFFFFF')
                .border({ width: 1, color: '#E2D8CB' })
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => this.address = value)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BACKGROUND)
            .borderRadius(18)

            Column({ space: 10 }) {
              Text('\u4ea4\u6613\u63d0\u9192')
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
              Button('\u63d0\u4ea4\u8ba2\u5355\u5e76\u67e5\u770b\u8be6\u60c5')
                .width('100%')
                .height(46)
                .onClick(() => this.submit())

              Text('\u63d0\u4ea4\u540e\u5546\u54c1\u4f1a\u5148\u8fdb\u5165\u4ea4\u6613\u4e2d\uff0c\u4f60\u4f1a\u76f4\u63a5\u8fdb\u5165\u8ba2\u5355\u8be6\u60c5\u9875\u7ee7\u7eed\u5b8c\u6210\u6a21\u62df\u652f\u4ed8\u3001\u9762\u4ea4\u786e\u8ba4\u548c\u8bc4\u4ef7\u3002')
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
