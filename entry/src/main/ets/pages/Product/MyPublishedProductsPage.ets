import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import { productRepository } from '../../repositories/product.repo';
import { remoteProductClient } from '../../services/product-remote.client';
import { Product } from '../../types/domain';
import { formatTime } from '../../utils/time';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';

function getPublishedStatusText(status: string): string {
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
  if (status === 'rejected') {
    return '审核未通过';
  }
  return status;
}

function getPublishedStatusColor(status: string): string {
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
    return '#8C867F';
  }
  if (status === 'rejected') {
    return '#C64747';
  }
  return '#5E5851';
}

function getPublishedStatusBackground(status: string): string {
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
    return '#F2EFEB';
  }
  if (status === 'rejected') {
    return '#FCE8E8';
  }
  return '#ECEAE7';
}

@Entry
@Component
struct MyPublishedProductsPage {
  @State products: Product[] = [];
  @State isLoading: boolean = false;
  @State errorText: string = '';

  aboutToAppear(): void {
    void this.refresh();
  }

  onPageShow(): void {
    void this.refresh();
  }

  private async refresh(): Promise<void> {
    const session = appContext.getSession();
    if (!session) {
      showToastByContext(this, { message: '请先登录', duration: 1500 });
      replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }

    this.isLoading = true;
    const result = await remoteProductClient.listMyProducts(session.token);
    if (!result.ok || !result.data) {
      this.products = productRepository.list()
        .filter((item: Product) => item.sellerId === session.currentUser.id && !item.isDeleted)
        .sort((a: Product, b: Product) => b.createdAt - a.createdAt);
      this.errorText = result.message;
      this.isLoading = false;
      return;
    }

    this.products = result.data.sort((a: Product, b: Product) => b.createdAt - a.createdAt);
    this.products.forEach((item: Product) => productRepository.mergeRemote(item));
    this.errorText = '';
    this.isLoading = false;
  }

  @Builder
  private buildHeader(): void {
    Column({ space: 4 }) {
      Text('我发布的')
        .width('100%')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text('这里会显示你的商品审核状态、交易状态和最近发布时间。')
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
        title: '你还没有发布过商品',
        description: '发布后会先进入审核，审核通过后才会显示在首页。'
      })

      Button('去发布商品')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#2F6BFF')
        .backgroundColor('#E8F0FF')
        .padding({ left: 14, right: 14 })
        .onClick(() => pushUrlByContext(this, { url: 'pages/Product/PublishProductPage' }))
    }
    .width('100%')
  }

  @Builder
  private buildLoadingState(): void {
    LoadingState({
      title: '正在整理你的发布记录',
      description: '审核状态、在售状态和发布时间会在这里集中显示。'
    })
  }

  @Builder
  private buildErrorState(): void {
    Column({ space: 12 }) {
      ErrorState({
        title: '我的发布暂时加载失败',
        description: this.errorText.length > 0 ? this.errorText : '请稍后重试。'
      })

      Button('重试刷新')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#B8643C')
        .backgroundColor('#F4E6DE')
        .padding({ left: 14, right: 14 })
        .onClick(() => {
          void this.refresh();
        })
    }
    .width('100%')
  }

  @Builder
  private buildProductCard(item: Product): void {
    Column({ space: 10 }) {
      Row() {
        Text(item.title)
          .layoutWeight(1)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text(getPublishedStatusText(item.status))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(getPublishedStatusColor(item.status))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(getPublishedStatusBackground(item.status))
          .borderRadius(14)
      }
      .width('100%')

      Text(`价格 ￥${item.price.toFixed(2)}`)
        .width('100%')
        .fontSize(16)
        .fontColor('#E05A47')
        .fontWeight(FontWeight.Medium)

      Text(`${item.category} · ${item.locationTag}`)
        .width('100%')
        .fontSize(13)
        .fontColor(SUB_TEXT_COLOR)

      Text(`发布时间 ${formatTime(item.createdAt)}`)
        .width('100%')
        .fontSize(12)
        .fontColor('#8C867F')
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

        if (this.errorText.length > 0 && this.products.length > 0) {
          Text(this.errorText)
            .width('100%')
            .fontSize(13)
            .fontColor('#B8643C')
        }

        if (this.isLoading && this.products.length === 0) {
          this.buildLoadingState()
        } else if (this.errorText.length > 0 && this.products.length === 0) {
          this.buildErrorState()
        } else if (this.products.length === 0) {
          this.buildEmptyState()
        } else {
          ForEach(this.products, (item: Product) => {
            this.buildProductCard(item)
          }, (item: Product) => item.id)
        }
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 18 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
