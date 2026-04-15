import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import { Product, User } from '../../types/domain';
import {
  buildCampusTrustListSnippet,
  buildCampusTrustTonePalette,
  buildPublicCampusTrustPresentation,
  CampusTrustListSnippet,
  CampusTrustPresentation
} from '../../utils/campus-trust-ui';
import {
  buildMarketplaceUserSyncKeys,
  buildMyPublishedAudiencePresentation,
  MarketplacePrimaryAction,
  MyPublishedAudiencePresentation
} from '../../utils/marketplace-audience-ui';
import { openPublishEntry } from '../../utils/publish-entry';
import { buildProductRenderKey } from '../../utils/render-keys';
import { formatTime } from '../../utils/time';
import { canViewTradeHistory, getMarketplaceAudienceMode } from '../../utils/trade-guard';

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
  @State currentUser: User | null = null;
  @State products: Product[] = [];
  @State isLoading: boolean = false;
  @State errorText: string = '';
  private productSyncUnsubscriber: (() => void) | null = null;
  private userSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    void this.refresh();
    this.bindProductSync();
    this.bindUserSync();
  }

  onPageShow(): void {
    void this.refresh();
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
      void this.refresh();
    });
  }

  private bindUserSync(): void {
    if (this.userSyncUnsubscribers.length > 0) {
      return;
    }
    this.userSyncUnsubscribers = buildMarketplaceUserSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        void this.refresh();
      })
    );
  }

  private async refresh(): Promise<void> {
    this.currentUser = appContext.getCurrentUser();
    const session = appContext.getSession();
    if (!session) {
      showToastByContext(this, { message: '请先登录', duration: 1500 });
      replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (!canViewTradeHistory(this.currentUser)) {
      this.products = [];
      this.errorText = '';
      this.isLoading = false;
      return;
    }

    this.isLoading = true;
    const result = await appContext.marketplaceProducts.listMyPublishedProducts(session.currentUser.id);
    if (!result.ok || !result.data) {
      this.products = [];
      this.errorText = result.message;
      this.isLoading = false;
      return;
    }

    this.products = result.data;
    this.errorText = '';
    this.isLoading = false;
  }

  private audiencePresentation(): MyPublishedAudiencePresentation {
    return buildMyPublishedAudiencePresentation(getMarketplaceAudienceMode(this.currentUser));
  }

  private openAudiencePrimaryAction(): void {
    const action: MarketplacePrimaryAction = this.audiencePresentation().primaryAction;
    if (action === 'login') {
      replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (action === 'profile') {
      pushUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
      return;
    }
    if (action === 'admin') {
      pushUrlByContext(this, { url: 'pages/Admin/AdminDashboardPage' });
      return;
    }
    openPublishEntry(this, this.currentUser);
  }

  private getCurrentUserTrustPresentation(): CampusTrustPresentation {
    return buildPublicCampusTrustPresentation(this.currentUser);
  }

  private getCurrentUserTrustSnippet(): CampusTrustListSnippet {
    return buildCampusTrustListSnippet(this.currentUser, 3);
  }

  private getTrustOverviewBackground(): string {
    return buildCampusTrustTonePalette(this.getCurrentUserTrustPresentation().tone).surfaceBackgroundColor;
  }

  private getTrustOverviewTagsText(): string {
    const snippet = this.getCurrentUserTrustSnippet();
    const suffix = snippet.hasMoreTags ? ' · ...' : '';
    return `${snippet.tags.join(' · ')}${suffix}`;
  }

  private getTrustOverviewRiskTextColor(): string {
    return buildCampusTrustTonePalette(this.getCurrentUserTrustPresentation().tone).riskBadgeTextColor;
  }

  private getTrustOverviewRiskBackground(): string {
    return buildCampusTrustTonePalette(this.getCurrentUserTrustPresentation().tone).riskBadgeBackgroundColor;
  }

  @Builder
  private buildHeader(): void {
    Column({ space: 4 }) {
      Text('我发布的')
        .width('100%')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(this.audiencePresentation().headerDescription)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildTrustOverviewCard(): void {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('对外可信展示')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Blank()

        Text(this.getCurrentUserTrustPresentation().badgeText)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getCurrentUserTrustPresentation().badgeTextColor)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getCurrentUserTrustPresentation().badgeBackgroundColor)
          .borderRadius(12)

        Text(this.getCurrentUserTrustSnippet().riskLabel)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTrustOverviewRiskTextColor())
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getTrustOverviewRiskBackground())
          .borderRadius(12)
      }
      .width('100%')

      Text(this.getCurrentUserTrustPresentation().summary)
        .width('100%')
        .fontSize(13)
        .lineHeight(19)
        .fontColor(TITLE_COLOR)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.getCurrentUserTrustSnippet().tags.length > 0) {
        Text(this.getTrustOverviewTagsText())
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(SUB_TEXT_COLOR)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Text(this.getCurrentUserTrustPresentation().riskText)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(SUB_TEXT_COLOR)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.getTrustOverviewBackground())
    .borderRadius(18)
    .border({
      width: 1,
      color: '#E7DED2'
    })
  }

  @Builder
  private buildEmptyState(): void {
    Column({ space: 12 }) {
      EmptyState({
        title: this.audiencePresentation().emptyTitle,
        description: this.audiencePresentation().emptyDescription
      })

      Button(this.audiencePresentation().emptyPrimaryActionLabel)
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#2F6BFF')
        .backgroundColor('#E8F0FF')
        .padding({ left: 14, right: 14 })
        .onClick(() => this.openAudiencePrimaryAction())
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

        if (this.currentUser && canViewTradeHistory(this.currentUser)) {
          this.buildTrustOverviewCard()
        }

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
          }, (item: Product) => buildProductRenderKey(item))
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
