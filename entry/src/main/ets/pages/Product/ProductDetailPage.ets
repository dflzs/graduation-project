import { backByContext, getParamsByContext, pushUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { userRepository } from '../../repositories/user.repo';
import { Product, User } from '../../types/domain';
import { formatTime } from '../../utils/time';
import {
  canCurrentUserJoinTrade,
  canShowProductDetailContactAction,
  canUserTradeProduct,
  getProductDetailTradeHint,
  getTradeEntryDeniedMessage,
  isProductOwnedByUser
} from '../../utils/trade-guard';
import {
  buildCampusTrustTonePalette,
  buildPublicCampusTrustPresentation,
  CampusTrustPresentation
} from '../../utils/campus-trust-ui';
import { buildMarketplaceUserSyncKeys } from '../../utils/marketplace-audience-ui';

const PRODUCT_PARAM_INVALID_TEXT: string = '\u5546\u54c1\u53c2\u6570\u65e0\u6548';
const PRODUCT_LOAD_FAILED_TEXT: string = '\u5546\u54c1\u4e0d\u5b58\u5728\u6216\u52a0\u8f7d\u5931\u8d25';
const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFFFF';
const HERO_PLACEHOLDER_START: string = '#E8DDD0';
const HERO_PLACEHOLDER_END: string = '#F3ECE3';
const PRICE_COLOR: string = '#E05A47';
const SUB_TEXT_COLOR: string = '#7B756E';
const TITLE_COLOR: string = '#2D2A26';
const DISABLED_BUTTON_COLOR: string = '#D8D1C7';
const DISABLED_BUTTON_TEXT_COLOR: string = '#8C867F';

function getStatusText(status: string): string {
  if (status === 'pending_review') {
    return '\u5ba1\u6838\u4e2d';
  }
  if (status === 'on_sale') {
    return '\u5728\u552e';
  }
  if (status === 'locked') {
    return '\u4ea4\u6613\u4e2d';
  }
  if (status === 'sold') {
    return '\u5df2\u552e\u51fa';
  }
  if (status === 'off_shelf') {
    return '\u5df2\u4e0b\u67b6';
  }
  if (status === 'rejected') {
    return '\u5ba1\u6838\u672a\u901a\u8fc7';
  }
  return status;
}

function canTrade(status: string): boolean {
  return status === 'on_sale';
}

function getStatusBackgroundColor(status: string): string {
  if (status === 'pending_review') {
    return '#F4E6DE';
  }
  if (status === 'on_sale') {
    return '#E8F5EA';
  }
  if (status === 'locked') {
    return '#E7EEFF';
  }
  if (status === 'sold') {
    return '#ECEAE7';
  }
  if (status === 'off_shelf') {
    return '#F4E6DE';
  }
  if (status === 'rejected') {
    return '#FCE8E8';
  }
  return '#ECEAE7';
}

function getStatusTextColor(status: string): string {
  if (status === 'pending_review') {
    return '#B8643C';
  }
  if (status === 'on_sale') {
    return '#237B46';
  }
  if (status === 'locked') {
    return '#2F6BFF';
  }
  if (status === 'sold') {
    return '#5E5851';
  }
  if (status === 'off_shelf') {
    return '#B8643C';
  }
  if (status === 'rejected') {
    return '#C64747';
  }
  return '#5E5851';
}

function getStatusHintText(status: string): string {
  if (status === 'pending_review') {
    return '\u5546\u54c1\u6b63\u5728\u5ba1\u6838\u4e2d\uff0c\u6682\u65f6\u4e0d\u4f1a\u5728\u9996\u9875\u5bf9\u5916\u5c55\u793a';
  }
  if (status === 'on_sale') {
    return '\u5546\u54c1\u53ef\u6b63\u5e38\u52a0\u5165\u8d2d\u7269\u8f66\u5e76\u4e0b\u5355';
  }
  if (status === 'locked') {
    return '\u5546\u54c1\u5df2\u8fdb\u5165\u4ea4\u6613\u4e2d\uff0c\u6682\u65f6\u4e0d\u53ef\u88ab\u5176\u4ed6\u7528\u6237\u8d2d\u4e70';
  }
  if (status === 'sold') {
    return '\u5546\u54c1\u5df2\u552e\u51fa\uff0c\u5f53\u524d\u4ec5\u53ef\u6d4f\u89c8';
  }
  if (status === 'off_shelf') {
    return '\u5546\u54c1\u5df2\u4e0b\u67b6\uff0c\u5f53\u524d\u4e0d\u53ef\u8d2d\u4e70';
  }
  if (status === 'rejected') {
    return '\u5546\u54c1\u5ba1\u6838\u672a\u901a\u8fc7\uff0c\u8bf7\u4fee\u6539\u540e\u91cd\u65b0\u63d0\u4ea4';
  }
  return '\u5546\u54c1\u72b6\u6001\u6682\u4e0d\u652f\u6301\u4ea4\u6613';
}

function getSelfOwnedHintText(): string {
  return '\u8fd9\u662f\u4f60\u53d1\u5e03\u7684\u5546\u54c1\uff0c\u53ef\u5728\u201c\u6211\u53d1\u5e03\u7684\u201d\u4e2d\u67e5\u770b\u5ba1\u6838\u548c\u4ea4\u6613\u72b6\u6001';
}

function getPrimaryButtonText(status: string): string {
  if (status === 'pending_review') {
    return '\u5ba1\u6838\u4e2d\uff0c\u6682\u4e0d\u53ef\u4e0b\u5355';
  }
  if (status === 'on_sale') {
    return '\u7acb\u5373\u4e0b\u5355';
  }
  if (status === 'locked') {
    return '\u4ea4\u6613\u4e2d\uff0c\u6682\u4e0d\u53ef\u4e0b\u5355';
  }
  if (status === 'sold') {
    return '\u5df2\u552e\u51fa\uff0c\u4e0d\u53ef\u4e0b\u5355';
  }
  if (status === 'off_shelf') {
    return '\u5df2\u4e0b\u67b6\uff0c\u6682\u4e0d\u53ef\u4e0b\u5355';
  }
  if (status === 'rejected') {
    return '\u5ba1\u6838\u672a\u901a\u8fc7';
  }
  return '\u6682\u4e0d\u53ef\u4e0b\u5355';
}

function getSecondaryButtonText(status: string): string {
  if (status === 'pending_review') {
    return '\u5ba1\u6838\u4e2d';
  }
  if (status === 'on_sale') {
    return '\u52a0\u5165\u8d2d\u7269\u8f66';
  }
  if (status === 'locked') {
    return '\u4ea4\u6613\u4e2d';
  }
  if (status === 'sold') {
    return '\u5df2\u552e\u51fa';
  }
  if (status === 'off_shelf') {
    return '\u6682\u4e0d\u53ef\u52a0\u5165';
  }
  if (status === 'rejected') {
    return '\u5ba1\u6838\u672a\u901a\u8fc7';
  }
  return '\u6682\u4e0d\u53ef\u52a0\u5165';
}

@Entry
@Component
struct ProductDetailPage {
  @State productId: string = '';
  @State product: Product | null = null;
  @State isLoading: boolean = false;
  @State errorText: string = '';
  private productSyncUnsubscriber: (() => void) | null = null;
  private userSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.productId = params?.productId ?? '';
    void this.loadProduct();
    this.bindProductSync();
    this.bindUserSync();
  }

  onPageShow(): void {
    void this.loadProduct();
  }

  aboutToDisappear(): void {
    if (this.productSyncUnsubscriber) {
      this.productSyncUnsubscriber();
      this.productSyncUnsubscriber = null;
    }
    this.userSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.userSyncUnsubscribers = [];
  }

  private bindProductSync(): void {
    if (this.productSyncUnsubscriber) {
      return;
    }
    this.productSyncUnsubscriber = appContext.sync.subscribe('products:changed', () => {
      void this.loadProduct();
    });
  }

  private bindUserSync(): void {
    if (this.userSyncUnsubscribers.length > 0) {
      return;
    }
    this.userSyncUnsubscribers = buildMarketplaceUserSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        void this.loadProduct();
      })
    );
  }

  private async loadProduct(): Promise<void> {
    if (!this.productId) {
      this.product = null;
      this.errorText = PRODUCT_PARAM_INVALID_TEXT;
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.marketplaceProducts.getProductDetail(this.productId);
      if (!result.ok || !result.data) {
        this.product = null;
        this.errorText = result.message || PRODUCT_LOAD_FAILED_TEXT;
        showToastByContext(this, { message: this.errorText, duration: 1800 });
        return;
      }

      this.product = result.data;
      this.errorText = '';
    } catch (error) {
      this.product = null;
      this.errorText = PRODUCT_LOAD_FAILED_TEXT;
      showToastByContext(this, { message: this.errorText, duration: 1800 });
    } finally {
      this.isLoading = false;
    }
  }

  private addToCart(): void {
    const user: User | null = appContext.getCurrentUser();
    if (!user) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55', duration: 1500 });
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (!canCurrentUserJoinTrade(user)) {
      showToastByContext(this, { message: getTradeEntryDeniedMessage(user, 'cart'), duration: 1500 });
      return;
    }

    if (!this.product) {
      return;
    }

    if (isProductOwnedByUser(this.product, user.id)) {
      showToastByContext(this, {
        message: '\u8fd9\u662f\u4f60\u53d1\u5e03\u7684\u5546\u54c1\uff0c\u4e0d\u9700\u8981\u518d\u52a0\u5165\u8d2d\u7269\u8f66',
        duration: 1600
      });
      return;
    }

    if (!canUserTradeProduct(this.product, user.id, user.role, user.status)) {
      showToastByContext(this, {
        message: '\u5f53\u524d\u5546\u54c1\u4e0d\u53ef\u52a0\u5165\u8d2d\u7269\u8f66',
        duration: 1500
      });
      return;
    }

    const result = appContext.cart.addToCart(user.id, this.product.id);
    showToastByContext(this, { message: result.message, duration: 1500 });
  }

  private orderNow(): void {
    const currentUser: User | null = appContext.getCurrentUser();
    if (!currentUser) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55', duration: 1500 });
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (!canCurrentUserJoinTrade(currentUser)) {
      showToastByContext(this, { message: getTradeEntryDeniedMessage(currentUser, 'order'), duration: 1500 });
      return;
    }
    if (!this.product) {
      return;
    }
    if (isProductOwnedByUser(this.product, currentUser.id)) {
      showToastByContext(this, {
        message: '\u8fd9\u662f\u4f60\u53d1\u5e03\u7684\u5546\u54c1\uff0c\u4e0d\u80fd\u7ed9\u81ea\u5df1\u4e0b\u5355',
        duration: 1600
      });
      return;
    }
    if (!canUserTradeProduct(this.product, currentUser.id, currentUser.role, currentUser.status)) {
      showToastByContext(this, {
        message: '\u5f53\u524d\u5546\u54c1\u4e0d\u53ef\u4e0b\u5355',
        duration: 1500
      });
      return;
    }

    pushUrlByContext(this, {
      url: 'pages/Order/CreateOrderPage',
      params: { productId: this.product.id }
    });
  }

  private currentUserOwnsProduct(product: Product): boolean {
    return isProductOwnedByUser(product, appContext.getCurrentUser()?.id ?? '');
  }

  private canCurrentUserTrade(product: Product): boolean {
    const currentUser = appContext.getCurrentUser();
    return canUserTradeProduct(product, currentUser?.id ?? '', currentUser?.role, currentUser?.status ?? 'active');
  }

  private async contactSeller(): Promise<void> {
    const currentUser: User | null = appContext.getCurrentUser();
    if (!currentUser) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55', duration: 1500 });
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (!canCurrentUserJoinTrade(currentUser)) {
      showToastByContext(this, { message: getTradeEntryDeniedMessage(currentUser, 'chat'), duration: 1500 });
      return;
    }

    if (!this.product) {
      return;
    }

    if (currentUser.id === this.product.sellerId) {
      showToastByContext(this, { message: '\u8fd9\u662f\u4f60\u53d1\u5e03\u7684\u5546\u54c1', duration: 1500 });
      return;
    }

    const threadResult = await appContext.chat.openProductThread(this.product.id, currentUser.id, this.product.sellerId);
    if (!threadResult.ok || !threadResult.data) {
      showToastByContext(this, { message: threadResult.message, duration: 1500 });
      return;
    }

    pushUrlByContext(this, {
      url: 'pages/Chat/ChatDetailPage',
      params: { threadId: threadResult.data }
    });
  }

  private canCurrentUserSubmitModeration(product: Product): boolean {
    const currentUser = appContext.getCurrentUser();
    return currentUser !== null
      && canCurrentUserJoinTrade(currentUser)
      && currentUser.id !== product.sellerId;
  }

  private openProductReportPage(): void {
    if (!this.product || !this.canCurrentUserSubmitModeration(this.product)) {
      return;
    }
    pushUrlByContext(this, {
      url: 'pages/Moderation/SubmitModerationPage',
      params: {
        targetType: 'product_report',
        targetId: this.product.id,
        title: this.product.title
      }
    });
  }

  private openSellerReportPage(): void {
    if (!this.product || !this.canCurrentUserSubmitModeration(this.product)) {
      return;
    }
    const sellerNickname = userRepository.getById(this.product.sellerId)?.nickname ?? '当前卖家';
    pushUrlByContext(this, {
      url: 'pages/Moderation/SubmitModerationPage',
      params: {
        targetType: 'user_report',
        targetId: this.product.sellerId,
        title: sellerNickname
      }
    });
  }

  private getSellerTrustPresentation(): CampusTrustPresentation {
    const seller = this.product ? userRepository.getById(this.product.sellerId) : null;
    return buildPublicCampusTrustPresentation(seller);
  }

  private getSellerTrustCardBackground(): string {
    return buildCampusTrustTonePalette(this.getSellerTrustPresentation().tone).surfaceBackgroundColor;
  }

  private getSellerTrustRiskTextColor(): string {
    return buildCampusTrustTonePalette(this.getSellerTrustPresentation().tone).riskBadgeTextColor;
  }

  private getSellerTrustRiskBackground(): string {
    return buildCampusTrustTonePalette(this.getSellerTrustPresentation().tone).riskBadgeBackgroundColor;
  }

  private getSellerTrustTagTextColor(): string {
    return buildCampusTrustTonePalette(this.getSellerTrustPresentation().tone).tagTextColor;
  }

  private getSellerTrustTagBackground(): string {
    return buildCampusTrustTonePalette(this.getSellerTrustPresentation().tone).tagBackgroundColor;
  }

  @Builder
  private buildTag(text: string): void {
    Text(text)
      .fontSize(13)
      .fontColor('#5E5851')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .margin({ right: 8, bottom: 8 })
      .backgroundColor('#F3EEE7')
      .borderRadius(14)
  }

  @Builder
  private buildInfoRow(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(SUB_TEXT_COLOR)
      Blank()
      Text(value)
        .fontSize(15)
        .fontColor(TITLE_COLOR)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
  }

  @Builder
  private buildSellerTrustCard(): void {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('卖家身份')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(this.getSellerTrustPresentation().headline)
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.getSellerTrustPresentation().badgeText)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getSellerTrustPresentation().badgeTextColor)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.getSellerTrustPresentation().badgeBackgroundColor)
          .borderRadius(14)
      }
      .width('100%')

      Row({ space: 8 }) {
        Text(this.getSellerTrustPresentation().summary)
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(TITLE_COLOR)

        Text(this.getSellerTrustPresentation().riskLabel)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getSellerTrustRiskTextColor())
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getSellerTrustRiskBackground())
          .borderRadius(12)
      }
      .width('100%')

      if (this.getSellerTrustPresentation().trustTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
          ForEach(this.getSellerTrustPresentation().trustTags, (tag: string) => {
            Text(tag)
              .fontSize(11)
              .fontColor(this.getSellerTrustTagTextColor())
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.getSellerTrustTagBackground())
              .borderRadius(12)
              .margin({ right: 8, bottom: 8 })
          }, (tag: string) => tag)
        }
        .width('100%')
      }

      Text(this.getSellerTrustPresentation().helperText)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)

      Text(this.getSellerTrustPresentation().riskText)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8C867F')

      if (this.product && this.canCurrentUserSubmitModeration(this.product)) {
        Row({ space: 10 }) {
          Button('举报商品')
            .layoutWeight(1)
            .height(40)
            .type(ButtonType.Normal)
            .fontSize(13)
            .fontColor('#A86B00')
            .backgroundColor('#FFF6E6')
            .border({ width: 1, color: '#E8D8B6' })
            .borderRadius(14)
            .onClick(() => this.openProductReportPage())

          Button('举报卖家')
            .layoutWeight(1)
            .height(40)
            .type(ButtonType.Normal)
            .fontSize(13)
            .fontColor('#A86B00')
            .backgroundColor('#FFF6E6')
            .border({ width: 1, color: '#E8D8B6' })
            .borderRadius(14)
            .onClick(() => this.openSellerReportPage())
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.getSellerTrustCardBackground())
    .borderRadius(22)
  }

  @Builder
  private buildLoadingState(): void {
    Column({ space: 14 }) {
      Column()
        .width('100%')
        .height(260)
        .borderRadius(24)
        .linearGradient({
          angle: 135,
          colors: [[HERO_PLACEHOLDER_START, 0], [HERO_PLACEHOLDER_END, 1]]
        })

      Column({ space: 10 }) {
        Column()
          .width('72%')
          .height(28)
          .borderRadius(10)
          .backgroundColor('#E9E2D8')

        Column()
          .width('36%')
          .height(34)
          .borderRadius(12)
          .backgroundColor('#F0D7D1')

        Row({ space: 8 }) {
          Column()
            .width(88)
            .height(30)
            .borderRadius(15)
            .backgroundColor('#ECE6DE')
          Column()
            .width(108)
            .height(30)
            .borderRadius(15)
            .backgroundColor('#ECE6DE')
        }
      }
      .width('100%')
      .padding(18)
      .backgroundColor(CARD_BACKGROUND)
      .borderRadius(22)
    }
    .width('100%')
  }

  @Builder
  private buildErrorState(): void {
    Column({ space: 14 }) {
      Text('\u5546\u54c1\u8be6\u60c5\u52a0\u8f7d\u5931\u8d25')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(this.errorText.length > 0 ? this.errorText : PRODUCT_LOAD_FAILED_TEXT)
        .fontSize(15)
        .fontColor(SUB_TEXT_COLOR)
        .textAlign(TextAlign.Center)

      Row({ space: 10 }) {
        Button('\u8fd4\u56de')
          .type(ButtonType.Normal)
          .backgroundColor('#ECE6DE')
          .fontColor('#5E5851')
          .onClick(() => backByContext(this))

        Button('\u91cd\u8bd5\u52a0\u8f7d')
          .backgroundColor('#2F6BFF')
          .onClick(() => {
            void this.loadProduct();
          })
      }
    }
    .width('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildProductHero(product: Product): void {
    Column() {
      if (product.images.length > 0 && product.images[0].length > 0) {
        Image(product.images[0])
          .width('100%')
          .height(280)
          .objectFit(ImageFit.Cover)
          .borderRadius(24)
      } else {
        Column({ space: 12 }) {
          Text('\u6821\u56ed\u4f18\u9009')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#7A6B5E')

          Text(product.category)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#3F362F')

          Text('\u65e0\u5546\u54c1\u56fe\u7247\uff0c\u5f53\u524d\u5c55\u793a\u4e3a\u5360\u4f4d\u6a21\u5f0f')
            .fontSize(14)
            .fontColor('#7B756E')
        }
        .width('100%')
        .height(280)
        .padding(24)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(24)
        .linearGradient({
          angle: 135,
          colors: [[HERO_PLACEHOLDER_START, 0], [HERO_PLACEHOLDER_END, 1]]
        })
      }
    }
    .width('100%')
  }

  @Builder
  private buildDetailView(product: Product): void {
    Scroll() {
      Column({ space: 14 }) {
        this.buildProductHero(product)

        Column({ space: 12 }) {
          Text(product.title)
            .width('100%')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(`\u00a5${product.price.toFixed(2)}`)
            .width('100%')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRICE_COLOR)

          Flex({ wrap: FlexWrap.Wrap }) {
            Text(getStatusText(product.status))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(getStatusTextColor(product.status))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(getStatusBackgroundColor(product.status))
              .borderRadius(14)
              .margin({ right: 8, bottom: 8 })

            this.buildTag(product.category)
            this.buildTag(product.locationTag)
          }
          .width('100%')

          Text(isProductOwnedByUser(product, appContext.getCurrentUser()?.id ?? '')
            ? getSelfOwnedHintText()
            : getProductDetailTradeHint(product, appContext.getCurrentUser()))
            .width('100%')
            .fontSize(14)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .padding(18)
        .backgroundColor(CARD_BACKGROUND)
        .borderRadius(22)

        Column({ space: 10 }) {
          Text('\u5546\u54c1\u8bf4\u660e')
            .width('100%')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(product.desc)
            .width('100%')
            .fontSize(15)
            .lineHeight(24)
            .fontColor('#4E4740')
        }
        .width('100%')
        .padding(18)
        .backgroundColor(CARD_BACKGROUND)
        .borderRadius(22)

        if (isProductOwnedByUser(product, appContext.getCurrentUser()?.id ?? '')) {
          Column({ space: 10 }) {
            Text('\u5356\u5bb6\u63d0\u9192')
              .width('100%')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(TITLE_COLOR)

            Text(getSelfOwnedHintText())
              .width('100%')
              .fontSize(14)
              .lineHeight(22)
              .fontColor(SUB_TEXT_COLOR)

            Button('\u53bb\u6211\u53d1\u5e03\u7684')
              .width('100%')
              .height(44)
              .type(ButtonType.Normal)
              .backgroundColor('#E8F0FF')
              .fontColor('#2F6BFF')
              .onClick(() => pushUrlByContext(this, { url: 'pages/Product/MyPublishedProductsPage' }))
          }
          .width('100%')
          .padding(18)
          .backgroundColor(CARD_BACKGROUND)
          .borderRadius(22)
        }

        Column({ space: 14 }) {
          Text('\u4ea4\u6613\u4fe1\u606f')
            .width('100%')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          this.buildInfoRow('\u5f53\u524d\u72b6\u6001', getStatusText(product.status))
          this.buildInfoRow('\u9762\u4ea4\u5730\u70b9', product.locationTag)
          this.buildInfoRow('\u53d1\u5e03\u65f6\u95f4', formatTime(product.createdAt))

          if (canShowProductDetailContactAction(product, appContext.getCurrentUser())) {
            Button('\u8054\u7cfb\u5356\u5bb6')
              .width('100%')
              .height(44)
              .type(ButtonType.Normal)
              .backgroundColor('#E8F0FF')
              .fontColor('#2F6BFF')
                  .onClick(() => {
                    void this.contactSeller();
                  })
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor(CARD_BACKGROUND)
        .borderRadius(22)

        this.buildSellerTrustCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 132 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildBottomBar(product: Product): void {
    Row({ space: 10 }) {
      Button(this.currentUserOwnsProduct(product) ? '\u81ea\u5df1\u7684\u5546\u54c1' : getSecondaryButtonText(product.status))
        .layoutWeight(1)
        .height(48)
        .enabled(this.canCurrentUserTrade(product))
        .backgroundColor(this.canCurrentUserTrade(product) ? '#E8F0FF' : DISABLED_BUTTON_COLOR)
        .fontColor(this.canCurrentUserTrade(product) ? '#2F6BFF' : DISABLED_BUTTON_TEXT_COLOR)
        .onClick(() => this.addToCart())

      Button(this.currentUserOwnsProduct(product) ? '\u4e0d\u80fd\u81ea\u5df1\u4e0b\u5355' : getPrimaryButtonText(product.status))
        .layoutWeight(1)
        .height(48)
        .enabled(this.canCurrentUserTrade(product))
        .backgroundColor(this.canCurrentUserTrade(product) ? '#2F6BFF' : DISABLED_BUTTON_COLOR)
        .fontColor(this.canCurrentUserTrade(product) ? '#FFFFFF' : DISABLED_BUTTON_TEXT_COLOR)
        .onClick(() => this.orderNow())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 18 })
    .backgroundColor('#FFFDFC')
    .border({
      width: { top: 1 },
      color: '#E9E2D8'
    })
  }

  build() {
    Column() {
      if (this.isLoading) {
        Scroll() {
          Column() {
            this.buildLoadingState()
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .height('100%')
      } else if (!this.product) {
        this.buildErrorState()
      } else {
        Stack({ alignContent: Alignment.Bottom }) {
          this.buildDetailView(this.product as Product)
          Column() {
            this.buildBottomBar(this.product as Product)
          }
          .width('100%')
        }
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
