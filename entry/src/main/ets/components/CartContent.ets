import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../utils/ui-context-actions';
import { appContext } from '../app/app-context';
import { EmptyState } from './EmptyState';
import { CartItem, Product, User } from '../types/domain';
import {
  calculateSelectedCartAmount,
  resolveCartCheckoutState,
  syncSelectedCartItemIds
} from '../utils/cart-selection';
import {
  getCartCardBackground,
  getCartCardBorder
} from '../utils/cart-visuals';
import { canUserTradeProduct, isProductOwnedByUser } from '../utils/trade-guard';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const PRIMARY_COLOR: string = '#2F6BFF';
const BORDER_COLOR: string = '#E7DED2';
const DANGER_COLOR: string = '#C64747';

@Component
export struct CartContent {
  @Prop shellMode: boolean = false;
  @State private currentUser: User | null = null;
  @State private cartItems: CartItem[] = [];
  @State private selectedItemIds: string[] = [];
  @State private manageMode: boolean = false;
  private unsubscriber: (() => void) | null = null;
  private subscribedUserId: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    if (this.unsubscriber) {
      this.unsubscriber();
      this.unsubscriber = null;
    }
    this.subscribedUserId = '';
  }

  private bindSync(userId: string): void {
    if (this.subscribedUserId === userId) {
      return;
    }
    if (this.unsubscriber) {
      this.unsubscriber();
      this.unsubscriber = null;
      this.subscribedUserId = '';
    }
    if (userId.length === 0) {
      return;
    }
    this.unsubscriber = appContext.sync.subscribe(`cart:${userId}`, () => {
      this.refreshDataOnly();
    });
    this.subscribedUserId = userId;
  }

  private refresh(): void {
    this.currentUser = appContext.getCurrentUser();
    const userId: string = this.currentUser?.id ?? '';
    this.bindSync(userId);
    this.refreshDataOnly();
  }

  private refreshDataOnly(): void {
    const previousCartIds: string[] = this.cartItems.map((item: CartItem) => item.id);
    const previousSelectedIds: string[] = [...this.selectedItemIds];
    const hadAllSelected: boolean = previousCartIds.length > 0
      && previousSelectedIds.length === previousCartIds.length;

    if (!this.currentUser) {
      this.cartItems = [];
      this.selectedItemIds = [];
      this.manageMode = false;
      return;
    }

    this.cartItems = appContext.cart.listByUser(this.currentUser.id);
    this.selectedItemIds = syncSelectedCartItemIds(this.cartItems, previousSelectedIds);
    if (!this.manageMode) {
      this.selectedItemIds = this.selectedItemIds.filter((itemId: string) => {
        const cartItem = this.cartItems.find((item: CartItem) => item.id === itemId);
        return !!cartItem && this.canSettleItem(cartItem);
      });
    }

    if (previousCartIds.length === 0 && this.cartItems.length > 0 && this.selectedItemIds.length === 0) {
      this.selectedItemIds = this.getSelectableItemIds();
    } else if (hadAllSelected && this.cartItems.length > previousCartIds.length) {
      this.selectedItemIds = this.getSelectableItemIds();
    }

    if (this.cartItems.length === 0) {
      this.manageMode = false;
    }
  }

  private getProduct(item: CartItem): Product | null {
    return appContext.product.getProductById(item.productId);
  }

  private canSettleItem(item: CartItem): boolean {
    const userId: string = this.currentUser?.id ?? '';
    return canUserTradeProduct(this.getProduct(item), userId);
  }

  private isSelfOwnedCartItem(item: CartItem): boolean {
    const userId: string = this.currentUser?.id ?? '';
    return isProductOwnedByUser(this.getProduct(item), userId);
  }

  private getSelectableItemIds(): string[] {
    if (this.manageMode) {
      return this.cartItems.map((item: CartItem) => item.id);
    }
    return this.cartItems
      .filter((item: CartItem) => this.canSettleItem(item))
      .map((item: CartItem) => item.id);
  }

  private getProductTitle(item: CartItem): string {
    return this.getProduct(item)?.title ?? '商品暂不可用';
  }

  private getItemMeta(item: CartItem): string {
    const product: Product | null = this.getProduct(item);
    if (!product) {
      return '商品信息暂不可用';
    }
    return `${product.category} · ${product.locationTag}`;
  }

  private getItemStatus(item: CartItem): string {
    const product: Product | null = this.getProduct(item);
    if (!product) {
      return '已失效';
    }
    if (this.isSelfOwnedCartItem(item)) {
      return '自己发布';
    }
    if (product.status === 'on_sale') {
      return '在售';
    }
    if (product.status === 'locked') {
      return '交易中';
    }
    if (product.status === 'pending_review') {
      return '审核中';
    }
    if (product.status === 'sold') {
      return '已售出';
    }
    return '不可结算';
  }

  private getItemStatusColor(item: CartItem): string {
    if (this.isSelfOwnedCartItem(item)) {
      return '#B8643C';
    }
    const status: string = this.getProduct(item)?.status ?? '';
    if (status === 'on_sale') {
      return '#237B46';
    }
    if (status === 'locked') {
      return PRIMARY_COLOR;
    }
    if (status === 'pending_review') {
      return '#B8643C';
    }
    return '#5E5851';
  }

  private getItemStatusBackground(item: CartItem): string {
    if (this.isSelfOwnedCartItem(item)) {
      return '#F4E6DE';
    }
    const status: string = this.getProduct(item)?.status ?? '';
    if (status === 'on_sale') {
      return '#E8F5EA';
    }
    if (status === 'locked') {
      return '#E8F0FF';
    }
    if (status === 'pending_review') {
      return '#F4E6DE';
    }
    return '#ECEAE7';
  }

  private getItemSubtotal(item: CartItem): string {
    return (item.snapshotPrice * item.qty).toFixed(2);
  }

  private getSelectedCount(): number {
    return this.selectedItemIds.length;
  }

  private getSelectedTotal(): number {
    return calculateSelectedCartAmount(this.cartItems, this.selectedItemIds);
  }

  private isSelected(itemId: string): boolean {
    return this.selectedItemIds.includes(itemId);
  }

  private isAllSelected(): boolean {
    const selectableIds: string[] = this.getSelectableItemIds();
    if (selectableIds.length === 0) {
      return false;
    }
    return selectableIds.every((itemId: string) => this.selectedItemIds.includes(itemId));
  }

  private getCartItemRenderKey(itemId: string): string {
    return `${itemId}:${this.isSelected(itemId) ? 'selected' : 'idle'}`;
  }

  private setItemSelection(itemId: string, selected: boolean): void {
    const targetItem: CartItem | undefined = this.cartItems.find((item: CartItem) => item.id === itemId);
    if (!this.manageMode && targetItem && !this.canSettleItem(targetItem)) {
      return;
    }

    if (selected) {
      if (!this.isSelected(itemId)) {
        this.selectedItemIds = [...this.selectedItemIds, itemId];
      }
      return;
    }

    if (this.isSelected(itemId)) {
      this.selectedItemIds = this.selectedItemIds.filter((currentId: string) => currentId !== itemId);
    }
  }

  private setAllSelection(selected: boolean): void {
    if (selected) {
      this.selectedItemIds = this.getSelectableItemIds();
      return;
    }

    this.selectedItemIds = [];
  }

  private toggleManageMode(): void {
    if (this.cartItems.length === 0) {
      return;
    }
    this.manageMode = !this.manageMode;
  }

  private toggleSelect(itemId: string): void {
    const targetItem: CartItem | undefined = this.cartItems.find((item: CartItem) => item.id === itemId);
    if (!this.manageMode && targetItem && !this.canSettleItem(targetItem)) {
      showToastByContext(this, {
        message: this.isSelfOwnedCartItem(targetItem)
          ? '这是你发布的商品，请切换到管理后删除'
          : '当前商品暂不可结算，请重新选择',
        duration: 1500
      });
      return;
    }
    this.setItemSelection(itemId, !this.isSelected(itemId));
  }

  private goToHome(): void {
    if (this.shellMode) {
      appContext.sync.publish({
        key: 'shell:navigate',
        value: 'home',
        updatedAt: Date.now()
      });
      return;
    }
    replaceUrlByContext(this, { url: 'pages/Index' });
  }

  private goToLogin(): void {
    pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
  }

  private deleteSelectedItems(): void {
    const user: User | null = this.currentUser;
    if (!user) {
      this.goToLogin();
      return;
    }
    if (this.selectedItemIds.length === 0) {
      showToastByContext(this, { message: '请先选择要删除的商品', duration: 1200 });
      return;
    }

    this.selectedItemIds.forEach((itemId: string) => {
      appContext.cart.removeItem(user.id, itemId);
    });
    this.selectedItemIds = [];
    this.refreshDataOnly();
    showToastByContext(this, { message: '已从购物车移除所选商品', duration: 1200 });
  }

  private proceedToCheckout(): void {
    if (!this.currentUser) {
      this.goToLogin();
      return;
    }

    const checkoutState = resolveCartCheckoutState(this.selectedItemIds.length);
    if (checkoutState === 'none') {
      showToastByContext(this, { message: '请先选择要结算的商品', duration: 1200 });
      return;
    }
    if (checkoutState === 'multiple') {
      showToastByContext(this, { message: '当前版本一次仅支持结算 1 件商品，请先保留 1 件后继续', duration: 1800 });
      return;
    }

    const selectedItemId: string | undefined = this.selectedItemIds[0];
    if (!selectedItemId) {
      showToastByContext(this, { message: '没有找到对应商品，请重新选择', duration: 1200 });
      return;
    }
    const selectedItem: CartItem | undefined = this.cartItems.find((item: CartItem) => item.id === selectedItemId);
    if (!selectedItem) {
      showToastByContext(this, { message: '没有找到对应商品，请重新选择', duration: 1200 });
      return;
    }
    if (this.isSelfOwnedCartItem(selectedItem)) {
      showToastByContext(this, { message: '这是你发布的商品，请先从购物车移除', duration: 1600 });
      return;
    }
    if (!this.canSettleItem(selectedItem)) {
      showToastByContext(this, { message: '当前商品暂不可结算，请重新选择', duration: 1500 });
      return;
    }

    pushUrlByContext(this, {
      url: 'pages/Order/CreateOrderPage',
      params: { productId: selectedItem.productId }
    });
  }

  @Builder
  private buildItemSelectionControl(itemId: string): void {
    Checkbox()
      .select(this.isSelected(itemId))
      .width(18)
      .height(18)
      .margin({ top: 2 })
      .enabled(this.manageMode || !!this.cartItems.find((item: CartItem) => item.id === itemId && this.canSettleItem(item)))
      .onChange((value: boolean) => this.setItemSelection(itemId, value))
  }

  @Builder
  private buildSelectAllControl(): void {
    Checkbox()
      .select(this.isAllSelected())
      .width(18)
      .height(18)
      .onChange((value: boolean) => this.setAllSelection(value))
  }

  @Builder
  private buildHeader(): void {
    Row() {
      Column({ space: 4 }) {
        Text('购物车')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text(this.currentUser
          ? `已加入 ${this.cartItems.length} 件商品，勾选后可统一管理和结算`
          : '登录后可同步你想买的商品，并集中管理待结算内容')
          .fontSize(13)
          .fontColor(SUB_TEXT_COLOR)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.currentUser) {
        Text(this.manageMode ? '完成' : '管理')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.cartItems.length > 0 ? PRIMARY_COLOR : '#B8B1A9')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(this.cartItems.length > 0 ? '#E8F0FF' : '#F1ECE5')
          .borderRadius(16)
          .onClick(() => {
            if (this.cartItems.length === 0) {
              showToastByContext(this, { message: '购物车还是空的，先去加几件商品吧', duration: 1200 });
              return;
            }
            this.toggleManageMode();
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 12 })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildGuestBody(): void {
    Column({ space: 14 }) {
      EmptyState({
        title: '登录后同步你的购物车',
        description: '把想买的商品先加入购物车，再统一勾选、删除和去结算，流程会更顺。'
      })

      Button('去登录')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor(PRIMARY_COLOR)
        .backgroundColor('#E8F0FF')
        .padding({ left: 16, right: 16 })
        .onClick(() => this.goToLogin())
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16, bottom: 12 })
  }

  @Builder
  private buildEmptyBody(): void {
    Column({ space: 14 }) {
      EmptyState({
        title: '购物车还是空的',
        description: '把想买的商品先加入购物车，之后就能在这里统一勾选、管理和去结算。'
      })

      Button('去首页继续挑选')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor(PRIMARY_COLOR)
        .backgroundColor('#E8F0FF')
        .padding({ left: 16, right: 16 })
        .onClick(() => this.goToHome())
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16, bottom: 12 })
  }

  @Builder
  private buildCartItem(item: CartItem): void {
    Row({ space: 10 }) {
      Column() {
        this.buildItemSelectionControl(item.id)
      }
      .width(22)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      Column({ space: 8 }) {
        Row({ space: 10 }) {
          Text(this.getProductTitle(item))
            .layoutWeight(1)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)
            .maxLines(2)

          Text(this.getItemStatus(item))
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getItemStatusColor(item))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.getItemStatusBackground(item))
            .borderRadius(12)
        }
        .width('100%')

        Text(this.getItemMeta(item))
          .width('100%')
          .fontSize(12)
          .fontColor('#8C867F')

        Row() {
          Column({ space: 4 }) {
            Text(`￥${item.snapshotPrice.toFixed(2)}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E05A47')

            Text('小计')
              .fontSize(11)
              .fontColor('#8C867F')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column({ space: 6 }) {
            Text(`x${item.qty}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#5E5851')

            Text(`￥${this.getItemSubtotal(item)}`)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E05A47')
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .onClick(() => this.toggleSelect(item.id))
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .padding({ left: 14, right: 14, top: 16, bottom: 16 })
    .backgroundColor(getCartCardBackground(this.isSelected(item.id)))
    .borderRadius(18)
    .border({
      width: 1,
      color: getCartCardBorder(this.isSelected(item.id))
    })
  }

  @Builder
  private buildGuestBottomBar(): void {
    Row({ space: 12 }) {
      Text('登录后可同步购物车并继续结算')
        .layoutWeight(1)
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)

      Button('去登录')
        .width(112)
        .height(44)
        .fontColor('#FFFFFF')
        .backgroundColor(PRIMARY_COLOR)
        .onClick(() => this.goToLogin())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: this.shellMode ? 18 : 12 })
    .backgroundColor(CARD_BACKGROUND)
    .border({
      width: { top: 1 },
      color: BORDER_COLOR
    })
  }

  @Builder
  private buildSettlementBar(): void {
    Column({ space: 8 }) {
      if (!this.manageMode && this.getSelectedCount() > 1) {
        Text('当前版本一次仅支持确认 1 件商品，我们先保留多选管理能力，结算时请先选定 1 件。')
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8C867F')
      }

      Row({ space: 12 }) {
        Row({ space: 8 }) {
          this.buildSelectAllControl()
          Text('全选')
            .fontSize(14)
            .fontColor(TITLE_COLOR)
            .onClick(() => this.setAllSelection(!this.isAllSelected()))
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        if (this.manageMode) {
          Button('删除')
            .width(120)
            .height(44)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getSelectedCount() > 0 ? DANGER_COLOR : '#D7D0C7')
            .enabled(this.getSelectedCount() > 0)
            .onClick(() => this.deleteSelectedItems())
        } else {
          Column({ space: 2 }) {
            Text(`合计 ￥${this.getSelectedTotal().toFixed(2)}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E05A47')

            Text(`已选 ${this.getSelectedCount()} 件`)
              .fontSize(12)
              .fontColor('#8C867F')
          }
          .alignItems(HorizontalAlign.End)

          Button('结算')
            .width(120)
            .height(44)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getSelectedCount() > 0 ? PRIMARY_COLOR : '#C7D7FF')
            .enabled(this.getSelectedCount() > 0)
            .onClick(() => this.proceedToCheckout())
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: this.shellMode ? 18 : 12 })
    .backgroundColor(CARD_BACKGROUND)
    .border({
      width: { top: 1 },
      color: BORDER_COLOR
    })
  }

  build() {
    Column() {
      this.buildHeader()

      if (!this.currentUser) {
        this.buildGuestBody()
      } else if (this.cartItems.length === 0) {
        this.buildEmptyBody()
      } else {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.cartItems, (item: CartItem) => {
              this.buildCartItem(item)
            }, (item: CartItem) => this.getCartItemRenderKey(item.id))
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 6, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
          .constraintSize({ minHeight: '100%' })
        }
        .layoutWeight(1)
        .width('100%')
      }

      if (!this.currentUser) {
        this.buildGuestBottomBar()
      } else {
        this.buildSettlementBar()
      }
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor(PAGE_BACKGROUND)
  }
}
