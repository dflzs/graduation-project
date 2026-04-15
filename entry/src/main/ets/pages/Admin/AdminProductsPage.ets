import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from '../../services/guard.service';
import { Product } from '../../types/domain';
import { buildAdminGuardSyncKeys } from '../../utils/admin-dashboard-sync';
import { buildProductRenderKey } from '../../utils/render-keys';
import { formatTime } from '../../utils/time';
import {
  getPolishDangerButtonTone,
  getPolishPrimaryButtonTone,
  getPolishSecondaryButtonTone
} from '../../utils/ui-polish-tokens';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';
const ACCENT_PANEL_BACKGROUND: string = '#F8F2E9';

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
  private productSyncUnsubscriber: (() => void) | null = null;
  private adminGuardSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    void this.refresh();
    this.bindProductSync();
    this.bindAdminGuardSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    if (this.productSyncUnsubscriber) {
      this.productSyncUnsubscriber();
      this.productSyncUnsubscriber = null;
    }
    this.adminGuardSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.adminGuardSyncUnsubscribers = [];
  }

  private bindProductSync(): void {
    if (this.productSyncUnsubscriber) {
      return;
    }
    this.productSyncUnsubscriber = appContext.sync.subscribe('products:changed', () => {
      void this.refresh();
    });
  }

  private bindAdminGuardSync(): void {
    if (this.adminGuardSyncUnsubscribers.length > 0) {
      return;
    }
    this.adminGuardSyncUnsubscribers = buildAdminGuardSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        void this.refresh();
      })
    );
  }

  private async refresh(): Promise<void> {
    if (!appContext.isAdmin()) {
      showToastByContext(this, { message: getAdminAccessDeniedMessage(appContext.getCurrentUser()), duration: 1500 });
      replaceUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
      return;
    }

    this.isLoading = true;
    const result = await appContext.adminProducts.listProducts();
    if (!result.ok) {
      this.products = [];
      this.errorText = result.message;
      this.isLoading = false;
      return;
    }

    this.products = result.data ?? [];
    this.errorText = '';
    this.isLoading = false;
  }

  private async approve(productId: string): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }
    const result = await appContext.adminProducts.approveProduct(productId);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      void this.refresh();
    }
  }

  private async reject(productId: string): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }
    const result = await appContext.adminProducts.rejectProduct(productId);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      void this.refresh();
    }
  }

  private async forceOffShelf(productId: string): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }
    const result = await appContext.adminProducts.forceOffShelfProduct(productId);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      void this.refresh();
    }
  }

  private getPendingCount(): number {
    return this.products.filter((item: Product) => item.status === 'pending_review').length;
  }

  @Builder
  private buildSummaryCard(label: string, value: number, accent: string): void {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUB_TEXT_COLOR)

      Text(`${value}`)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)

      Text(label === '待审核' ? '优先处理' : '当前总览')
        .fontSize(12)
        .fontColor('#9A9185')
    }
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
    .shadow({
      radius: 18,
      color: '#20120810',
      offsetX: 0,
      offsetY: 8
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildActionButton(label: string, tone: 'primary' | 'secondary' | 'danger', onPress: () => void): void {
    Button(label)
      .layoutWeight(1)
      .height(this.getActionButtonHeight(tone))
      .fontColor(this.getActionButtonTextColor(tone))
      .fontWeight(FontWeight.Bold)
      .backgroundColor(this.getActionButtonBackground(tone))
      .borderRadius(this.getActionButtonRadius(tone))
      .border({ width: 1, color: this.getActionButtonBorderColor(tone) })
      .onClick(onPress)
  }

  private getActionButtonBackground(tone: 'primary' | 'secondary' | 'danger'): string {
    if (tone === 'primary') {
      return getPolishPrimaryButtonTone().backgroundColor;
    }
    if (tone === 'secondary') {
      return getPolishSecondaryButtonTone().backgroundColor;
    }
    return getPolishDangerButtonTone().backgroundColor;
  }

  private getActionButtonBorderColor(tone: 'primary' | 'secondary' | 'danger'): string {
    if (tone === 'primary') {
      return getPolishPrimaryButtonTone().borderColor;
    }
    if (tone === 'secondary') {
      return getPolishSecondaryButtonTone().borderColor;
    }
    return getPolishDangerButtonTone().borderColor;
  }

  private getActionButtonTextColor(tone: 'primary' | 'secondary' | 'danger'): string {
    if (tone === 'primary') {
      return getPolishPrimaryButtonTone().textColor;
    }
    if (tone === 'secondary') {
      return getPolishSecondaryButtonTone().textColor;
    }
    return getPolishDangerButtonTone().textColor;
  }

  private getActionButtonHeight(tone: 'primary' | 'secondary' | 'danger'): number {
    if (tone === 'primary') {
      return getPolishPrimaryButtonTone().height;
    }
    if (tone === 'secondary') {
      return getPolishSecondaryButtonTone().height;
    }
    return getPolishDangerButtonTone().height;
  }

  private getActionButtonRadius(tone: 'primary' | 'secondary' | 'danger'): number {
    if (tone === 'primary') {
      return getPolishPrimaryButtonTone().radius;
    }
    if (tone === 'secondary') {
      return getPolishSecondaryButtonTone().radius;
    }
    return getPolishDangerButtonTone().radius;
  }

  @Builder
  private buildProductCard(item: Product): void {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Column({ space: 6 }) {
          Text(item.title)
            .fontSize(20)
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
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E05A47')
      }
      .width('100%')

      Row({ space: 8 }) {
        Text(item.category)
          .fontSize(12)
          .fontColor('#5E5851')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#F2ECE5')
          .borderRadius(14)

        Text(item.locationTag)
          .fontSize(12)
          .fontColor('#6E675F')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#F7F2EC')
          .borderRadius(14)
      }
      .width('100%')

      Text(item.desc)
        .width('100%')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#5E5851')
        .maxLines(2)

      Row() {
        Text('地点')
          .fontSize(12)
          .fontColor('#9A9185')
        Text(item.locationTag)
          .fontSize(12)
          .fontColor('#5E5851')
        Text('·')
          .fontSize(12)
          .fontColor('#B3AA9D')
        Text(`发布于 ${formatTime(item.createdAt)}`)
          .fontSize(12)
          .fontColor('#5E5851')
      }
      .width('100%')

      if (item.status === 'pending_review') {
        Row({ space: 10 }) {
          this.buildActionButton('审核通过', 'primary', () => {
            void this.approve(item.id);
          })

          this.buildActionButton('驳回', 'danger', () => {
            void this.reject(item.id);
          })
        }
        .width('100%')
      } else if (item.status === 'on_sale' || item.status === 'locked') {
        Row({ space: 10 }) {
          this.buildActionButton('强制下架', 'danger', () => {
            void this.forceOffShelf(item.id);
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(24)
    .border({ width: 1, color: BORDER_COLOR })
    .shadow({
      radius: 20,
      color: '#20120812',
      offsetX: 0,
      offsetY: 10
    })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          Text('商品管理')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('处理商品审核、在售状态和强制下架，让每一个状态切换都清晰可控。')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 8 }) {
          Text('审核动作已统一为一套按钮体系：通过是主操作，驳回和强制下架都归为风险动作。')
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#675F57')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ACCENT_PANEL_BACKGROUND)
        .borderRadius(20)
        .border({ width: 1, color: '#E9DAC9' })

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
            }, (item: Product) => buildProductRenderKey(item))
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
