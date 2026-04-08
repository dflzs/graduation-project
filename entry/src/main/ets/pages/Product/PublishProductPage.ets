import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { appContext } from '../../app/app-context';
import { CAMPUS_LOCATIONS, PRODUCT_CATEGORIES } from '../../constants/config';
import { productRepository } from '../../repositories/product.repo';
import { notificationService } from '../../services/notification.service.impl';
import { remoteProductClient } from '../../services/product-remote.client';
import { uploadRemoteClient } from '../../services/upload-remote.client';
import { User } from '../../types/domain';
import { RemoteCreateProductPayload } from '../../types/product-remote';
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
  @State locationTag: string = CAMPUS_LOCATIONS[0];
  @State coverLocalPath: string = '';
  @State coverPreviewUri: string = '';
  @State manualCoverUrl: string = '';
  @State isSubmitting: boolean = false;

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

    if (trimmedTitle.length === 0 || trimmedDesc.length === 0 || Number.isNaN(price) || price <= 0) {
      showToastByContext(this, { message: '请完整填写商品信息', duration: 1500 });
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
          coverImageUrl
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
                .onClick(() => this.category = item)
            }, (item: string) => item)
          }
          .width('100%')

          this.buildSectionTitle('面交地点')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(CAMPUS_LOCATIONS, (item: string) => {
              Button(item)
                .type(ButtonType.Normal)
                .height(34)
                .padding({ left: 12, right: 12 })
                .backgroundColor(getPublishChipBackground(this.locationTag === item))
                .fontColor(getPublishChipText(this.locationTag === item))
                .fontSize(13)
                .fontWeight(this.locationTag === item ? FontWeight.Medium : FontWeight.Normal)
                .borderRadius(12)
                .border({ width: 1, color: getPublishChipBorder(this.locationTag === item) })
                .margin({ right: 8, bottom: 8 })
                .onClick(() => this.locationTag = item)
            }, (item: string) => item)
          }
          .width('100%')
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
