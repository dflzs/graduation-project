import { pushUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import { PRODUCT_CATEGORIES } from '../../constants/config';
import { productRepository } from '../../repositories/product.repo';
import { remoteProductClient } from '../../services/product-remote.client';
import { Announcement, Product, User } from '../../types/domain';
import { resolveVisibleRemoteHomeProducts } from '../../utils/product-feed';
import { openPublishEntry } from '../../utils/publish-entry';
import { buildProductRowRenderKey } from '../../utils/render-keys';

const DEFAULT_EMPTY_TEXT: string = '\u6682\u65e0\u5546\u54c1';
const LOAD_FAILED_TEXT: string = '\u5546\u54c1\u52a0\u8f7d\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
const HOME_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const HERO_START: string = '#E7DED2';
const HERO_END: string = '#F4EEE6';
const HOME_RECOMMEND_CATEGORY: string = '\u63a8\u8350';
const HOME_CATEGORY_OPTIONS: string[] = [HOME_RECOMMEND_CATEGORY, ...PRODUCT_CATEGORIES];

function getStatusText(status: string): string {
  if (status === 'on_sale') {
    return '\u5728\u552e';
  }
  if (status === 'sold') {
    return '\u5df2\u552e\u51fa';
  }
  if (status === 'off_shelf') {
    return '\u5df2\u4e0b\u67b6';
  }
  return status;
}

function getStatusBackground(status: string): string {
  if (status === 'on_sale') {
    return '#E8F5EA';
  }
  if (status === 'sold') {
    return '#ECEAE7';
  }
  if (status === 'off_shelf') {
    return '#F4E6DE';
  }
  return '#ECEAE7';
}

function getStatusTextColor(status: string): string {
  if (status === 'on_sale') {
    return '#237B46';
  }
  if (status === 'sold') {
    return '#5E5851';
  }
  if (status === 'off_shelf') {
    return '#B8643C';
  }
  return '#5E5851';
}

@Component
export struct HomePage {
  @State keyword: string = '';
  @State products: Product[] = [];
  @State allProducts: Product[] = [];
  @State username: string = '';
  @State isLoading: boolean = false;
  @State errorText: string = '';
  @State emptyText: string = DEFAULT_EMPTY_TEXT;
  @State latestAnnouncements: Announcement[] = [];
  @State selectedCategory: string = HOME_RECOMMEND_CATEGORY;
  private homeFeedUnsubscriber: (() => void) | null = null;
  private knownRemoteProductIds: string[] = [];

  aboutToAppear(): void {
    this.refreshAnnouncements();
    this.bindLocalProductFeed();
    this.refreshProductsFromLocalState();
    void this.refreshProducts();
  }

  onPageShow(): void {
    this.refreshAnnouncements();
    this.refreshProductsFromLocalState();
    void this.refreshProducts();
  }

  aboutToDisappear(): void {
    if (this.homeFeedUnsubscriber) {
      this.homeFeedUnsubscriber();
      this.homeFeedUnsubscriber = null;
    }
  }

  private bindLocalProductFeed(): void {
    if (this.homeFeedUnsubscriber) {
      return;
    }

    this.homeFeedUnsubscriber = appContext.sync.subscribe('products:changed', () => {
      this.refreshProductsFromLocalState();
    });
  }

  private refreshAnnouncements(): void {
    this.latestAnnouncements = appContext.announcement.list()
      .sort((a: Announcement, b: Announcement) => b.createdAt - a.createdAt)
      .slice(0, 2);
  }

  private async refreshProducts(): Promise<void> {
    const user: User | null = appContext.getCurrentUser();
    this.username = user ? user.nickname : '';

    this.isLoading = true;
    try {
      const result = await remoteProductClient.listProducts({ status: 'on_sale' });
      if (!result.ok || !result.data) {
        this.knownRemoteProductIds = [];
        this.refreshProductsFromLocalState();
        this.errorText = this.allProducts.length === 0 ? (result.message || LOAD_FAILED_TEXT) : '';
        showToastByContext(this, {
          message: result.message || LOAD_FAILED_TEXT,
          duration: 1800
        });
        return;
      }

      const savedProducts: Product[] = result.data.map((item: Product) => productRepository.mergeRemote(item));
      this.knownRemoteProductIds = savedProducts.map((item: Product) => item.id);
      this.refreshProductsFromLocalState();
      this.errorText = '';
    } catch (error) {
      this.knownRemoteProductIds = [];
      this.refreshProductsFromLocalState();
      this.errorText = this.allProducts.length === 0 ? LOAD_FAILED_TEXT : '';
      showToastByContext(this, {
        message: LOAD_FAILED_TEXT,
        duration: 1800
      });
    } finally {
      this.isLoading = false;
    }
  }

  private refreshProductsFromLocalState(): void {
    this.allProducts = resolveVisibleRemoteHomeProducts(productRepository.list(), this.knownRemoteProductIds);
    this.applyFilters();
  }

  private applyFilters(): void {
    const keyword: string = this.keyword.trim().toLowerCase();
    const selectedCategory: string = this.selectedCategory;
    const isSearching: boolean = keyword.length > 0;

    this.products = this.allProducts
      .filter((item: Product) => {
        if (item.status !== 'on_sale') {
          return false;
        }
        if (!isSearching && selectedCategory !== HOME_RECOMMEND_CATEGORY && item.category !== selectedCategory) {
          return false;
        }
        if (!isSearching) {
          return true;
        }
        return item.title.toLowerCase().includes(keyword) || item.desc.toLowerCase().includes(keyword);
      })
      .sort((a: Product, b: Product) => b.createdAt - a.createdAt);

    if (this.products.length > 0) {
      this.emptyText = '';
    } else if (isSearching) {
      this.emptyText = '\u672a\u627e\u5230\u5339\u914d\u7684\u5728\u552e\u5546\u54c1';
    } else if (selectedCategory === HOME_RECOMMEND_CATEGORY) {
      this.emptyText = '\u6682\u65e0\u5728\u552e\u5546\u54c1';
    } else {
      this.emptyText = `${selectedCategory}\u6682\u65e0\u5728\u552e\u5546\u54c1`;
    }
  }

  private getProductRows(): Product[][] {
    const rows: Product[][] = [];
    for (let index = 0; index < this.products.length; index += 2) {
      rows.push(this.products.slice(index, index + 2));
    }
    return rows;
  }

  private getAnnouncementSummary(): string {
    if (this.latestAnnouncements.length === 0) {
      return '\u6682\u65e0\u6700\u65b0\u516c\u544a';
    }
    return this.latestAnnouncements.map((item: Announcement) => item.title).join('  |  ');
  }

  private openProductDetail(productId: string): void {
    pushUrlByContext(this, { url: 'pages/Product/ProductDetailPage', params: { productId } });
  }

  @Builder
  private buildSearchHeader(): void {
    Column({ space: 6 }) {
      Row() {
        Column({ space: 4 }) {
          Text('\u641c\u4f60\u60f3\u8981\u7684\u6821\u56ed\u95f2\u7f6e')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2D2A26')

          if (this.username.length > 0) {
            Text(`\u4eca\u5929\u4e5f\u53ef\u4ee5\u5728\u6821\u56ed\u91cc\u6377\u5f84\u6dd8\u5230\u597d\u4e1c\u897f\uff0c${this.username}`)
              .fontSize(13)
              .fontColor('#7B756E')
          } else {
            Text('\u4e8c\u624b\u6d41\u8f6c\u3001\u6821\u56ed\u9762\u4ea4\uff0c\u4ece\u641c\u7d22\u5f00\u59cb')
              .fontSize(13)
              .fontColor('#7B756E')
          }
        }
        .alignItems(HorizontalAlign.Start)

        Blank()
      }
      .width('100%')

      TextInput({
        text: this.keyword,
        placeholder: '\u641c\u7d22\u5546\u54c1\u6807\u9898\u6216\u63cf\u8ff0'
      })
        .height(48)
        .borderRadius(20)
        .backgroundColor('#FFFFFF')
        .border({
          width: 1.5,
          color: '#2D2A26'
        })
        .onChange((value: string) => {
          this.keyword = value;
          this.applyFilters();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .border({
      width: { bottom: 1 },
      color: '#E9E2D8'
    })
  }

  @Builder
  private buildAnnouncementStrip(): void {
    Row({ space: 10 }) {
      Text('\u516c\u544a')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#B8643C')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#F5E7DF')
        .borderRadius(12)

      Text(this.getAnnouncementSummary())
        .layoutWeight(1)
        .fontSize(13)
        .fontColor('#5E5851')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text('\u5168\u90e8')
        .fontSize(13)
        .fontColor('#2F6BFF')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
    .margin({ left: 16, right: 16, top: 8, bottom: 4 })
    .onClick(() => pushUrlByContext(this, { url: 'pages/Announcement/AnnouncementPage' }))
  }

  @Builder
  private buildFeedHeader(): void {
    Row() {
      Column() {
        Text(this.keyword.trim().length > 0
          ? '\u641c\u7d22\u7ed3\u679c'
          : (this.selectedCategory === HOME_RECOMMEND_CATEGORY ? '\u63a8\u8350\u5546\u54c1' : this.selectedCategory))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2D2A26')
      }
      Blank()
      Text(`${this.products.length}\u4ef6`)
        .fontSize(12)
        .fontColor('#8C867F')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 8 })
  }

  @Builder
  private buildCategoryRail(): void {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(HOME_CATEGORY_OPTIONS, (item: string) => {
          Text(item)
            .fontSize(13)
            .fontWeight(this.selectedCategory === item ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.selectedCategory === item ? '#FFFFFF' : '#5E5851')
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor(this.selectedCategory === item ? '#2D2A26' : '#FFFDFC')
            .borderRadius(16)
            .border(this.selectedCategory === item ? {
              width: 0
            } : {
              width: 1,
              color: '#D9D1C6'
            })
            .onClick(() => {
              this.selectedCategory = item;
              this.applyFilters();
            })
        }, (item: string) => item)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ top: 2, bottom: 4 })
  }

  @Builder
  private buildEmptyState(): void {
    Column({ space: 12 }) {
      EmptyState({
        title: '\u8fd9\u91cc\u8fd8\u6ca1\u6709\u627e\u5230\u5408\u9002\u7684\u5546\u54c1',
        description: this.emptyText.length > 0 ? this.emptyText : DEFAULT_EMPTY_TEXT
      })

      Button('\u53bb\u53d1\u5e03\u5546\u54c1')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#2F6BFF')
        .backgroundColor('#E8F0FF')
        .padding({ left: 14, right: 14 })
        .onClick(() => openPublishEntry(this, appContext.getCurrentUser()))
    }
    .width('100%')
  }

  @Builder
  private buildLoadingState(): void {
    LoadingState({
      title: '\u6b63\u5728\u4e3a\u4f60\u6574\u7406\u5728\u552e\u5546\u54c1',
      description: '\u7a0d\u7b49\u7247\u523b\uff0c\u9996\u9875\u4f1a\u4f18\u5148\u5c55\u793a\u5f53\u524d\u53ef\u4ea4\u6613\u7684\u5546\u54c1\u3002'
    })
  }

  @Builder
  private buildErrorState(): void {
    Column({ space: 12 }) {
      ErrorState({
        title: '\u9996\u9875\u5546\u54c1\u6682\u65f6\u6ca1\u6709\u52a0\u8f7d\u6210\u529f',
        description: this.errorText.length > 0 ? this.errorText : LOAD_FAILED_TEXT
      })

      Button('\u91cd\u8bd5\u5217\u65b0')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#B8643C')
        .backgroundColor('#F4E6DE')
        .padding({ left: 14, right: 14 })
        .onClick(() => {
          void this.refreshProducts();
        })
    }
    .width('100%')
  }

  @Builder
  private buildProductCard(product: Product): void {
    Column({ space: 8 }) {
      if (product.images.length > 0 && product.images[0].length > 0) {
        Image(product.images[0])
          .width('100%')
          .height(122)
          .objectFit(ImageFit.Cover)
          .borderRadius(18)
      } else {
        Column({ space: 10 }) {
          Text(product.category)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#3D342D')

          Text('\u6821\u56ed\u95f2\u7f6e')
            .fontSize(12)
            .fontColor('#7B756E')
        }
        .width('100%')
        .height(122)
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Start)
        .borderRadius(18)
        .padding(14)
        .linearGradient({
          angle: 135,
          colors: [[HERO_START, 0], [HERO_END, 1]]
        })
      }

      Row() {
        Text(getStatusText(product.status))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(getStatusTextColor(product.status))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(getStatusBackground(product.status))
          .borderRadius(12)
        Blank()
        Text(product.locationTag)
          .fontSize(12)
          .fontColor('#8C867F')
          .maxLines(1)
      }
      .width('100%')
      .height(24)
      .alignItems(VerticalAlign.Center)

      Column() {
        Text(product.title)
          .width('100%')
          .fontSize(16)
          .lineHeight(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2D2A26')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(38)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(product.desc)
          .width('100%')
          .fontSize(12)
          .lineHeight(15)
          .fontColor('#6B655E')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(18)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 4 }) {
        Text(`\uffe5${product.price.toFixed(2)}`)
          .width('100%')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E05A47')
          .maxLines(1)

        Row() {
          Text('\u652f\u6301\u9762\u4ea4')
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor('#7B756E')

          Blank()

          Text('\u8be6\u60c5 >')
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2F6BFF')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .height(288)
    .padding(12)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: '#E7DED2' })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.openProductDetail(product.id))
  }

  build() {
    Column() {
      this.buildSearchHeader()
      this.buildAnnouncementStrip()
      this.buildCategoryRail()
      this.buildFeedHeader()

      if (this.isLoading && this.allProducts.length === 0) {
        this.buildLoadingState()
      } else if (this.errorText.length > 0 && this.allProducts.length === 0) {
        this.buildErrorState()
      } else {
        Scroll() {
          Column({ space: 10 }) {
            if (this.products.length === 0) {
              this.buildEmptyState()
            } else {
              ForEach(this.getProductRows(), (row: Product[]) => {
                Row({ space: 10 }) {
                  this.buildProductCard(row[0])
                  if (row.length > 1) {
                    this.buildProductCard(row[1])
                  } else {
                    Blank()
                      .layoutWeight(1)
                  }
                }
                .width('100%')
              }, (row: Product[]) => buildProductRowRenderKey(row))
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 18 })
          .constraintSize({ minHeight: '100%' })
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor(HOME_BACKGROUND)
  }
}
