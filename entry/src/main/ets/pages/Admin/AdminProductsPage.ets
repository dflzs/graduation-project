import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import { productRepository } from '../../repositories/product.repo';
import { notificationService } from '../../services/notification.service.impl';
import { remoteProductClient } from '../../services/product-remote.client';
import { Product } from '../../types/domain';
import { formatTime } from '../../utils/time';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';

function getAdminStatusText(status: string): string {
  if (status === 'pending_review') {
    return '待审核';
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
    return '已驳回';
  }
  return status;
}

function getAdminStatusTextColor(status: string): string {
  if (status === 'pending_review') {
    return '#A86B00';
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
  if (status === 'off_shelf' || status === 'rejected') {
    return '#B8643C';
  }
  return '#5E5851';
}

function getAdminStatusBgColor(status: string): string {
  if (status === 'pending_review') {
    return '#F5EBDD';
  }
  if (status === 'on_sale') {
    return '#E8F5EA';
  }
  if (status === 'locked') {
    return '#E8F0FF';
  }
  if (status === 'sold') {
    return '#F1EEEA';
  }
  if (status === 'off_shelf' || status === 'rejected') {
    return '#F4E6DE';
  }
  return '#F1EEEA';
}

@Entry
@Component
struct AdminProductsPage {
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
    if (!appContext.isAdmin()) {
      showToastByContext(this, { message: '仅管理员可访问', duration: 1500 });
      replaceUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
      return;
    }

    const session = appContext.getSession();
    if (!session) {
      replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }

    this.isLoading = true;
    const result = await remoteProductClient.listAdminProducts(session.token);
    if (!result.ok || !result.data) {
      this.products = productRepository.list()
        .filter((item: Product) => !item.isDeleted)
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

  private async approve(productId: string): Promise<void> {
    const session = appContext.getSession();
    if (!session) {
      return;
    }
    const result = await remoteProductClient.approveProduct(session.token, productId);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok && result.data) {
      productRepository.mergeRemote(result.data);
      notificationService.notifyProductApproved(result.data.sellerId, result.data.title, result.data.id);
      void this.refresh();
    }
  }

  private async reject(productId: string): Promise<void> {
    const session = appContext.getSession();
    if (!session) {
      return;
    }
    const result = await remoteProductClient.rejectProduct(session.token, productId);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok && result.data) {
      productRepository.mergeRemote(result.data);
      notificationService.notifyProductRejected(result.data.sellerId, result.data.title, result.data.id);
      void this.refresh();
    }
  }

  private async forceOffShelf(productId: string): Promise<void> {
    const session = appContext.getSession();
    if (!session) {
      return;
    }
    const result = await remoteProductClient.forceOffShelfProduct(session.token, productId);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok && result.data) {
      productRepository.mergeRemote(result.data);
      void this.refresh();
    }
  }

  private getPendingCount(): number {
    return this.products.filter((item: Product) => item.status === 'pending_review').length;
  }

  @Builder
  private buildSummaryCard(label: string, value: number, accent: string): void {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      Text(`${value}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(18)
    .border({ width: 1, color: BORDER_COLOR })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildProductCard(item: Product): void {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Column({ space: 6 }) {
          Text(item.title)
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)
            .maxLines(2)

          Row({ space: 8 }) {
            Text(getAdminStatusText(item.status))
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(getAdminStatusTextColor(item.status))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(getAdminStatusBgColor(item.status))
              .borderRadius(14)

            Text(item.category)
              .fontSize(12)
              .fontColor('#5E5851')
              .padding({ left: 8, right: 8, top: 5, bottom: 5 })
              .backgroundColor('#F2ECE5')
              .borderRadius(12)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`￥${item.price.toFixed(2)}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E05A47')
      }
      .width('100%')

      Text(item.desc)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#5E5851')
        .maxLines(2)

      Text(`地点：${item.locationTag} · 发布时间：${formatTime(item.createdAt)}`)
        .width('100%')
        .fontSize(12)
        .fontColor('#8C867F')

      if (item.status === 'pending_review') {
        Row({ space: 10 }) {
          Button('审核通过')
            .layoutWeight(1)
            .height(42)
            .fontColor('#FFFFFF')
            .backgroundColor('#2F6BFF')
            .onClick(() => {
              void this.approve(item.id);
            })

          Button('驳回')
            .layoutWeight(1)
            .height(42)
            .type(ButtonType.Normal)
            .fontColor('#B8643C')
            .backgroundColor('#F4E6DE')
            .onClick(() => {
              void this.reject(item.id);
            })
        }
        .width('100%')
      } else if (item.status === 'on_sale' || item.status === 'locked') {
        Button('强制下架')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .fontColor('#B8643C')
          .backgroundColor('#F4E6DE')
          .onClick(() => {
            void this.forceOffShelf(item.id);
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          Text('商品管理')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('处理商品审核、在售状态和强制下架，让首页展示保持清晰可控。')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Row({ space: 10 }) {
          this.buildSummaryCard('全部商品', this.products.length, '#2D2A26')
          this.buildSummaryCard('待审核', this.getPendingCount(), '#A86B00')
        }
        .width('100%')

        if (this.isLoading) {
          LoadingState({
            title: '正在整理后台商品列表',
            description: '稍等片刻，审核中的商品和在售商品会显示在这里。'
          })
        } else if (this.errorText.length > 0 && this.products.length === 0) {
          ErrorState({
            title: '后台商品列表暂时加载失败',
            description: this.errorText
          })
        } else if (this.products.length === 0) {
          EmptyState({
            title: '当前没有可处理的商品',
            description: '当用户开始发布商品后，这里会集中展示待审核和在售中的商品。'
          })
        } else {
          Column({ space: 10 }) {
            ForEach(this.products, (item: Product) => {
              this.buildProductCard(item)
            }, (item: Product) => item.id)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 20 })
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .height('100%')
    .width('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
