import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { appContext } from '../../app/app-context';
import { PRODUCT_CATEGORIES } from '../../constants/config';
import { productRepository } from '../../repositories/product.repo';
import { notificationService } from '../../services/notification.service.impl';
import { remoteProductClient } from '../../services/product-remote.client';
import { uploadRemoteClient } from '../../services/upload-remote.client';
import { LocationGroup, TradeLocation, User } from '../../types/domain';
import { RemoteCreateProductPayload } from '../../types/product-remote';
import {
  buildTradeLocationHint,
  buildTradeLocationLabel,
  filterTradeLocationsForCategory,
  pickPreferredTradeLocation
} from '../../utils/campus-location-ui';
import { normalizeManualCoverUrl } from '../../utils/cover-image';
import { getPublishChipBackground, getPublishChipBorder, getPublishChipText } from '../../utils/publish-chip';
import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';

const COVER_PICKER_LIMIT: number = 1;
const COVER_PREVIEW_HEIGHT: number = 180;
const PAGE_BACKGROUND: string = '#F7F4EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2A2724';
const SUB_TEXT_COLOR: string = '#7B756E';
const INPUT_BORDER: string = '#DDD4C8';

@Entry
@Component
struct PublishProductPage {
  @State title: string = '';
  @State desc: string = '';
  @State priceText: string = '';
  @State category: string = PRODUCT_CATEGORIES[0];
  @State locationTag: string = '';
  @State coverLocalPath: string = '';
  @State coverPreviewUri: string = '';
  @State manualCoverUrl: string = '';
  @State isSubmitting: boolean = false;
  @State locationGroups: LocationGroup[] = [];
  @State tradeLocations: TradeLocation[] = [];
  @State schoolId: string = '';
  @State schoolName: string = '';
  @State campusId: string = '';
  @State campusName: string = '';
  @State selectedLocationGroupId: string = '';
  @State selectedTradeLocationId: string = '';
  @State locationHint: string = '\u8bf7\u5148\u5b8c\u5584\u6821\u56ed\u8d44\u6599\uff0c\u518d\u9009\u62e9\u53ef\u7528\u7684\u6821\u5185\u4ea4\u6613\u70b9\u3002';
  @State isCampusLocationLoading: boolean = false;

  aboutToAppear(): void {
    void this.refreshCampusLocations();
  }

  onPageShow(): void {
    void this.refreshCampusLocations();
  }

  private getSelectedLocationGroupName(): string {
    const group = this.locationGroups.find((item: LocationGroup) => item.id === this.selectedLocationGroupId);
    return group?.name ?? '';
  }

  private getVisibleTradeLocations(): TradeLocation[] {
    return filterTradeLocationsForCategory(this.tradeLocations, this.category, this.selectedLocationGroupId);
  }

  private getSelectedTradeLocation(): TradeLocation | null {
    const current = this.tradeLocations.find((item: TradeLocation) => item.id === this.selectedTradeLocationId);
    return current ?? null;
  }

  private hasCampusProfile(): boolean {
    return this.schoolId.length > 0 && this.campusId.length > 0;
  }

  private hasAvailableCampusLocations(): boolean {
    return this.getVisibleTradeLocations().length > 0;
  }

  private async refreshCampusLocations(): Promise<void> {
    const currentUser = appContext.getCurrentUser();
    this.schoolId = currentUser?.schoolId ?? '';
    this.schoolName = currentUser?.schoolName ?? '';
    this.campusId = currentUser?.campusId ?? '';
    this.campusName = currentUser?.campusName ?? '';

    if (!this.hasCampusProfile()) {
      this.locationGroups = [];
      this.tradeLocations = [];
      this.selectedLocationGroupId = '';
      this.selectedTradeLocationId = '';
      this.locationTag = '';
      this.locationHint = '\u8bf7\u5148\u5728\u4e2a\u4eba\u8d44\u6599\u9875\u5b8c\u6210\u5b66\u6821\u548c\u6821\u533a\u4fe1\u606f\uff0c\u53d1\u5e03\u5546\u54c1\u540e\u624d\u80fd\u9009\u62e9\u6821\u56ed\u4ea4\u6613\u70b9\u3002';
      return;
    }

    this.isCampusLocationLoading = true;

    try {
      const groupsResult = await appContext.campus.listLocationGroups(this.schoolId, this.campusId);
      const locationsResult = await appContext.campus.listTradeLocations({
        schoolId: this.schoolId,
        campusId: this.campusId,
        enabledOnly: true
      });

      this.locationGroups = (groupsResult.data ?? []).filter((item: LocationGroup) => item.isEnabled);
      this.tradeLocations = (locationsResult.data ?? []).filter((item: TradeLocation) => item.isEnabled);

      if (this.tradeLocations.length === 0) {
        this.selectedLocationGroupId = '';
        this.selectedTradeLocationId = '';
        this.locationTag = '';
        this.locationHint = '\u5f53\u524d\u6821\u533a\u6682\u65e0\u53ef\u7528\u4ea4\u6613\u70b9\uff0c\u8bf7\u8054\u7cfb\u7ba1\u7406\u5458\u5148\u914d\u7f6e\u6821\u56ed\u5730\u70b9\u3002';
        return;
      }

      const currentGroupValid = this.locationGroups.some((item: LocationGroup) => item.id === this.selectedLocationGroupId);
      if (!currentGroupValid) {
        const preferredLocation = pickPreferredTradeLocation(this.tradeLocations, this.category);
        this.selectedLocationGroupId = preferredLocation?.groupId
          ?? this.locationGroups[0]?.id
          ?? this.tradeLocations[0].groupId;
      }

      this.syncSelectedTradeLocation();
    } finally {
      this.isCampusLocationLoading = false;
    }
  }

  private syncSelectedTradeLocation(): void {
    const visibleLocations = this.getVisibleTradeLocations();
    if (visibleLocations.length === 0) {
      this.selectedTradeLocationId = '';
      this.locationTag = '';
      this.locationHint = '\u5f53\u524d\u5206\u7ec4\u4e0b\u6682\u65e0\u9002\u5408\u6b64\u5546\u54c1\u7684\u4ea4\u6613\u70b9\uff0c\u53ef\u5c1d\u8bd5\u5207\u6362\u5206\u7ec4\u6216\u7c7b\u522b\u3002';
      return;
    }

    const current = visibleLocations.find((item: TradeLocation) => item.id === this.selectedTradeLocationId)
      ?? pickPreferredTradeLocation(visibleLocations, this.category);
    if (!current) {
      this.selectedTradeLocationId = '';
      this.locationTag = '';
      this.locationHint = '\u6682\u65e0\u53ef\u7528\u4ea4\u6613\u70b9';
      return;
    }

    this.selectedTradeLocationId = current.id;
    this.selectedLocationGroupId = current.groupId;
    this.locationTag = buildTradeLocationLabel(current, this.getSelectedLocationGroupName());
    this.locationHint = buildTradeLocationHint(current);
  }

  private openCampusProfile(): void {
    pushUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
  }

  private updateLocationGroup(groupId: string): void {
    this.selectedLocationGroupId = groupId;
    this.selectedTradeLocationId = '';
    this.syncSelectedTradeLocation();
  }

  private updateTradeLocation(location: TradeLocation): void {
    this.selectedLocationGroupId = location.groupId;
    this.selectedTradeLocationId = location.id;
    this.locationTag = buildTradeLocationLabel(location, this.getSelectedLocationGroupName());
    this.locationHint = buildTradeLocationHint(location);
  }

  private async submit(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }

    const user: User | null = appContext.getCurrentUser();
    const session = appContext.getSession();
    if (!user || !session) {
      showToastByContext(this, { message: '请先登录后再发布商品', duration: 1500 });
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }

    const trimmedTitle = this.title.trim();
    const trimmedDesc = this.desc.trim();
    const price = Number.parseFloat(this.priceText);
    const selectedLocation = this.getSelectedTradeLocation();

    if (trimmedTitle.length === 0 || trimmedDesc.length === 0 || Number.isNaN(price) || price <= 0) {
      showToastByContext(this, { message: '请完整填写商品信息', duration: 1500 });
      return;
    }

    if (!this.hasCampusProfile()) {
      showToastByContext(this, { message: '\u8bf7\u5148\u5b8c\u6210\u5b66\u6821\u548c\u6821\u533a\u8d44\u6599', duration: 1600 });
      this.openCampusProfile();
      return;
    }
    if (!selectedLocation || this.locationTag.length === 0) {
      showToastByContext(this, { message: '\u8bf7\u5148\u9009\u62e9\u4e00\u4e2a\u53ef\u7528\u7684\u6821\u56ed\u4ea4\u6613\u70b9', duration: 1600 });
      return;
    }

    this.isSubmitting = true;
    let coverImageUrl = '';

    try {
      if (this.coverLocalPath.length > 0) {
        const uploadResult = await uploadRemoteClient.uploadProductCover(session.token, this.coverLocalPath);
        if (!uploadResult.ok || !uploadResult.data) {
          showToastByContext(this, {
            message: uploadResult.message.length > 0 ? uploadResult.message : '商品封面上传失败',
            duration: 1800
          });
          return;
        }
        coverImageUrl = uploadResult.data;
      } else {
        coverImageUrl = normalizeManualCoverUrl(this.manualCoverUrl);
      }

      const result = await remoteProductClient.createProduct(
        session.token,
        new RemoteCreateProductPayload(
          trimmedTitle,
          trimmedDesc,
          price,
          this.category,
          this.locationTag,
          coverImageUrl,
          this.schoolId,
          this.campusId,
          selectedLocation.groupId,
          selectedLocation.id
        )
      );

      showToastByContext(this, { message: result.message, duration: 1500 });
      if (result.ok && result.data) {
        productRepository.mergeRemote(result.data);
        notificationService.notifyProductSubmitted(user.id, result.data.title, result.data.id);
        replaceUrlByContext(this, { url: 'pages/Product/MyPublishedProductsPage' });
      }
    } finally {
      this.isSubmitting = false;
    }
  }

  private async chooseCoverImage(): Promise<void> {
    try {
      const selectedUri = await this.selectAlbumImage();
      if (selectedUri.length === 0) {
        return;
      }

      const cachePath = this.copyImageToCache(selectedUri);
      this.removeCoverImage(false);
      this.coverLocalPath = cachePath;
      this.coverPreviewUri = this.buildDisplayUri(cachePath);
      this.manualCoverUrl = '';
    } catch (_error) {
      showToastByContext(this, { message: '选择图片失败，请稍后重试', duration: 1500 });
    }
  }

  private removeCoverImage(showToast: boolean = true): void {
    if (this.coverLocalPath.length > 0) {
      try {
        fileIo.unlinkSync(this.coverLocalPath);
      } catch (_error) {
      }
    }

    this.coverLocalPath = '';
    this.coverPreviewUri = '';
    this.manualCoverUrl = '';
    if (showToast) {
      showToastByContext(this, { message: '已移除封面草稿', duration: 1200 });
    }
  }

  private updateManualCoverUrl(value: string): void {
    const normalized = normalizeManualCoverUrl(value);
    this.manualCoverUrl = normalized.length > 0 ? normalized : value;
    if (this.coverLocalPath.length > 0) {
      return;
    }
    this.coverPreviewUri = normalized;
  }

  private async selectAlbumImage(): Promise<string> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = COVER_PICKER_LIMIT;

    const result = await new photoAccessHelper.PhotoViewPicker().select(options);
    if (!result.photoUris || result.photoUris.length === 0) {
      return '';
    }

    return result.photoUris[0];
  }

  private copyImageToCache(sourceUri: string): string {
    const cacheDir = this.getUIContext().getHostContext()?.cacheDir ?? '';
    if (cacheDir.length === 0) {
      throw new Error('Cache directory unavailable');
    }

    const extension = this.extractImageExtension(sourceUri);
    const cachePath = `${cacheDir}/product_cover_${Date.now()}${extension}`;
    fileIo.copyFileSync(sourceUri, cachePath);
    return cachePath;
  }

  private extractImageExtension(value: string): string {
    const normalized = value.split('?')[0];
    const lastDot = normalized.lastIndexOf('.');
    if (lastDot < 0) {
      return '.jpg';
    }

    const extension = normalized.substring(lastDot).toLowerCase();
    if (extension === '.png' || extension === '.webp' || extension === '.gif'
      || extension === '.jpeg' || extension === '.jpg') {
      return extension;
    }
    return '.jpg';
  }

  private buildDisplayUri(filePath: string): string {
    if (filePath.startsWith('file://') || filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    return `file://${filePath}`;
  }

  private hasSelectedCover(): boolean {
    return this.coverLocalPath.length > 0;
  }

  @Builder
  private buildSectionTitle(title: string): void {
    Text(title)
      .width('100%')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#4A433B')
  }

  @Builder
  private buildRoundedInput(placeholder: string, text: string, onChange: (value: string) => void): void {
    TextInput({ text, placeholder })
      .width('100%')
      .height(52)
      .fontSize(14)
      .fontColor(TITLE_COLOR)
      .placeholderColor('#A79F95')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .border({ width: 1, color: INPUT_BORDER })
      .padding({ left: 14, right: 14 })
      .onChange(onChange)
  }

  @Builder
  private buildCoverPreview(): void {
    Column() {
      if (this.coverPreviewUri.length > 0) {
        Image(this.coverPreviewUri)
          .width('100%')
          .height(COVER_PREVIEW_HEIGHT)
          .objectFit(ImageFit.Cover)
          .borderRadius(18)
      } else {
        Column({ space: 8 }) {
          Text('上传商品封面')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(TITLE_COLOR)

          Text('选择 1 张清晰封面图。审核通过后，会显示在首页商品流和详情页里。')
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
            .textAlign(TextAlign.Center)
            .lineHeight(20)
        }
        .width('100%')
        .height(COVER_PREVIEW_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 20, right: 20 })
        .backgroundColor('#F7F2EA')
        .borderRadius(18)
      }
    }
    .width('100%')
  }

  @Builder
  private buildDebugSection(): void {
    Column({ space: 10 }) {
      Text('模拟器调试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text('如果模拟器相册里没有测试图片，可以在这里粘贴一张封面图片 URL。')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(SUB_TEXT_COLOR)

      this.buildRoundedInput('在这里粘贴封面图片 URL', this.manualCoverUrl, (value: string) => this.updateManualCoverUrl(value))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildCampusLocationSection(): void {
    Column({ space: 12 }) {
      this.buildSectionTitle('\u6821\u56ed\u4ea4\u6613\u5730\u70b9')

      if (!this.hasCampusProfile()) {
        Column({ space: 8 }) {
          Text('\u53d1\u5e03\u524d\u9700\u5148\u5b8c\u6210\u5b66\u6821\u3001\u6821\u533a\u8d44\u6599\uff0c\u5e73\u53f0\u624d\u80fd\u4e3a\u4f60\u5206\u914d\u6b63\u5f0f\u7684\u6821\u5185\u4ea4\u6613\u70b9\u3002')
            .width('100%')
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
            .lineHeight(20)

          Button('\u53bb\u5b8c\u5584\u6821\u56ed\u8d44\u6599')
            .height(40)
            .backgroundColor('#2563EB')
            .fontColor('#FFFFFF')
            .borderRadius(14)
            .padding({ left: 18, right: 18 })
            .onClick(() => this.openCampusProfile())
        }
        .width('100%')
      } else if (this.isCampusLocationLoading) {
        Text('\u6b63\u5728\u52a0\u8f7d\u5f53\u524d\u6821\u533a\u7684\u4ea4\u6613\u70b9...')
          .width('100%')
          .fontSize(13)
          .fontColor(SUB_TEXT_COLOR)
      } else if (!this.hasAvailableCampusLocations()) {
        Text(this.locationHint)
          .width('100%')
          .fontSize(13)
          .fontColor(SUB_TEXT_COLOR)
          .lineHeight(20)
      } else {
        Text(`${this.schoolName} / ${this.campusName}`)
          .width('100%')
          .fontSize(13)
          .fontColor(SUB_TEXT_COLOR)

        if (this.locationGroups.length > 0) {
          Column({ space: 8 }) {
            Text('\u5730\u70b9\u5206\u7ec4')
              .width('100%')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#4A433B')

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.locationGroups, (group: LocationGroup) => {
                Button(group.name)
                  .type(ButtonType.Normal)
                  .height(34)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor(getPublishChipBackground(this.selectedLocationGroupId === group.id))
                  .fontColor(getPublishChipText(this.selectedLocationGroupId === group.id))
                  .fontSize(13)
                  .fontWeight(this.selectedLocationGroupId === group.id ? FontWeight.Medium : FontWeight.Normal)
                  .borderRadius(12)
                  .border({ width: 1, color: getPublishChipBorder(this.selectedLocationGroupId === group.id) })
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => this.updateLocationGroup(group.id))
              }, (group: LocationGroup) => group.id)
            }
            .width('100%')
          }
          .width('100%')
        }

        Column({ space: 8 }) {
          Text('\u5177\u4f53\u4ea4\u6613\u70b9')
            .width('100%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A433B')

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.getVisibleTradeLocations(), (location: TradeLocation) => {
              Button(buildTradeLocationLabel(location, this.getSelectedLocationGroupName()))
                .type(ButtonType.Normal)
                .height(34)
                .padding({ left: 12, right: 12 })
                .backgroundColor(getPublishChipBackground(this.selectedTradeLocationId === location.id))
                .fontColor(getPublishChipText(this.selectedTradeLocationId === location.id))
                .fontSize(13)
                .fontWeight(this.selectedTradeLocationId === location.id ? FontWeight.Medium : FontWeight.Normal)
                .borderRadius(12)
                .border({ width: 1, color: getPublishChipBorder(this.selectedTradeLocationId === location.id) })
                .margin({ right: 8, bottom: 8 })
                .onClick(() => this.updateTradeLocation(location))
            }, (location: TradeLocation) => location.id)
          }
          .width('100%')
        }
        .width('100%')

        Text(this.locationHint)
          .width('100%')
          .fontSize(12)
          .fontColor('#8C867F')
          .lineHeight(18)
      }
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 4 }) {
          Text('发布商品')
            .width('100%')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('新发布的商品会先进入审核，审核通过后才会出现在首页和商品详情里。')
            .width('100%')
            .fontSize(14)
            .fontColor(SUB_TEXT_COLOR)
            .lineHeight(22)
        }
        .width('100%')

        Column({ space: 14 }) {
          this.buildSectionTitle('商品封面')
          this.buildCoverPreview()

          Row({ space: 12 }) {
            Button(this.hasSelectedCover() ? '重新选择' : '从相册选择')
              .layoutWeight(1)
              .height(42)
              .backgroundColor('#2563EB')
              .fontColor('#FFFFFF')
              .borderRadius(14)
              .onClick(() => {
                void this.chooseCoverImage();
              })

            if (this.hasSelectedCover()) {
              Button('移除')
                .height(42)
                .padding({ left: 18, right: 18 })
                .backgroundColor('#F4E7DE')
                .fontColor('#C76E43')
                .borderRadius(14)
                .onClick(() => this.removeCoverImage())
            }
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor(CARD_BACKGROUND)
        .borderRadius(22)
        .border({ width: 1, color: CARD_BORDER })

        this.buildDebugSection()

        Column({ space: 12 }) {
          this.buildSectionTitle('商品标题')
          this.buildRoundedInput('给商品起一个清楚的标题', this.title, (value: string) => this.title = value)

          this.buildSectionTitle('商品描述')
          TextArea({ text: this.desc, placeholder: '补充成色、配件、使用情况和交易提醒' })
            .width('100%')
            .height(120)
            .fontSize(14)
            .fontColor(TITLE_COLOR)
            .placeholderColor('#A79F95')
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .border({ width: 1, color: INPUT_BORDER })
            .padding(14)
            .onChange((value: string) => this.desc = value)

          this.buildSectionTitle('价格')
          TextInput({ text: this.priceText, placeholder: '请输入价格，例如 88' })
            .width('100%')
            .height(52)
            .type(InputType.Number)
            .fontSize(14)
            .fontColor(TITLE_COLOR)
            .placeholderColor('#A79F95')
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .border({ width: 1, color: INPUT_BORDER })
            .padding({ left: 14, right: 14 })
            .onChange((value: string) => this.priceText = value)

          this.buildSectionTitle('商品分类')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(PRODUCT_CATEGORIES, (item: string) => {
              Button(item)
                .type(ButtonType.Normal)
                .height(34)
                .padding({ left: 12, right: 12 })
                .backgroundColor(getPublishChipBackground(this.category === item))
                .fontColor(getPublishChipText(this.category === item))
                .fontSize(13)
                .fontWeight(this.category === item ? FontWeight.Medium : FontWeight.Normal)
                .borderRadius(12)
                .border({ width: 1, color: getPublishChipBorder(this.category === item) })
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.category = item;
                  this.syncSelectedTradeLocation();
                })
            }, (item: string) => item)
          }
          .width('100%')

          this.buildCampusLocationSection()
        }
        .width('100%')

        Button(this.isSubmitting ? '提交中...' : '提交审核')
          .width('100%')
          .height(46)
          .backgroundColor(this.isSubmitting ? '#BFD0FF' : '#2563EB')
          .fontColor('#FFFFFF')
          .borderRadius(16)
          .enabled(!this.isSubmitting)
          .onClick(() => {
            void this.submit();
          })
      }
      .padding({ left: 16, right: 16, top: 22, bottom: 28 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
