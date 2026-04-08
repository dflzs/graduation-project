import { pushUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { uploadRemoteClient } from '../../services/upload-remote.client';
import { User } from '../../types/domain';
import { normalizeManualCoverUrl } from '../../utils/cover-image';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const PROFILE_INPUT_BACKGROUND: string = '#FFFFFF';
const PROFILE_INPUT_BORDER: string = '#DDD4C8';
const PROFILE_PICKER_LIMIT: number = 1;

@Entry
@Component
struct ProfilePage {
  @State user: User | null = null;
  @State nicknameDraft: string = '';
  @State avatarLocalPath: string = '';
  @State avatarPreviewUri: string = '';
  @State avatarManualUrl: string = '';
  @State isSaving: boolean = false;

  aboutToAppear(): void {
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  private refresh(): void {
    this.user = appContext.getCurrentUser();
    if (!this.user) {
      this.nicknameDraft = '';
      this.avatarPreviewUri = '';
      return;
    }

    this.nicknameDraft = this.user.nickname;
    if (this.avatarLocalPath.length === 0 && this.avatarManualUrl.length === 0) {
      this.avatarPreviewUri = this.user.avatar ?? '';
    }
  }

  private currentAvatarDisplayUri(): string {
    if (this.avatarPreviewUri.length > 0) {
      return this.avatarPreviewUri;
    }
    return this.user?.avatar ?? '';
  }

  private buildAvatarText(): string {
    if (this.nicknameDraft.trim().length > 0) {
      return this.nicknameDraft.trim().slice(0, 1);
    }
    if (this.user && this.user.nickname.length > 0) {
      return this.user.nickname.slice(0, 1);
    }
    return '\u6211';
  }

  private buildRoleText(user: User): string {
    return user.role === 'admin' ? '\u7ba1\u7406\u5458' : '\u666e\u901a\u7528\u6237';
  }

  private buildStatusText(user: User): string {
    return user.status === 'active' ? '\u8d26\u53f7\u72b6\u6001\u6b63\u5e38' : '\u8d26\u53f7\u5f53\u524d\u53d7\u9650';
  }

  private hasPendingAvatarDraft(): boolean {
    if (this.avatarLocalPath.length > 0) {
      return true;
    }
    return normalizeManualCoverUrl(this.avatarManualUrl).length > 0;
  }

  private async chooseAvatarImage(): Promise<void> {
    try {
      const selectedUri = await this.selectAlbumImage();
      if (selectedUri.length === 0) {
        return;
      }

      const cachePath = this.copyImageToCache(selectedUri);
      this.removePendingAvatar(false);
      this.avatarLocalPath = cachePath;
      this.avatarPreviewUri = this.buildDisplayUri(cachePath);
      this.avatarManualUrl = '';
    } catch (_error) {
      showToastByContext(this, { message: '\u9009\u62e9\u5934\u50cf\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5', duration: 1500 });
    }
  }

  private removePendingAvatar(showToast: boolean = true): void {
    if (this.avatarLocalPath.length > 0) {
      try {
        fileIo.unlinkSync(this.avatarLocalPath);
      } catch (_error) {
      }
    }

    this.avatarLocalPath = '';
    this.avatarManualUrl = '';
    this.avatarPreviewUri = this.user?.avatar ?? '';
    if (showToast) {
      showToastByContext(this, { message: '\u5df2\u6e05\u7a7a\u5934\u50cf\u8349\u7a3f', duration: 1200 });
    }
  }

  private updateAvatarManualUrl(value: string): void {
    const normalized = normalizeManualCoverUrl(value);
    this.avatarManualUrl = normalized.length > 0 ? normalized : value;
    if (this.avatarLocalPath.length > 0) {
      return;
    }
    this.avatarPreviewUri = normalized.length > 0 ? normalized : (this.user?.avatar ?? '');
  }

  private async saveProfile(): Promise<void> {
    if (this.isSaving) {
      return;
    }

    const session = appContext.getSession();
    if (!session) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u4fdd\u5b58\u8d44\u6599', duration: 1500 });
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }

    let avatarUrl = '';
    if (this.avatarLocalPath.length > 0) {
      const uploadResult = await uploadRemoteClient.uploadProductCover(session.token, this.avatarLocalPath);
      if (!uploadResult.ok || !uploadResult.data) {
        showToastByContext(this, {
          message: uploadResult.message.length > 0 ? uploadResult.message : '\u5934\u50cf\u4e0a\u4f20\u5931\u8d25',
          duration: 1800
        });
        return;
      }
      avatarUrl = uploadResult.data;
    } else {
      avatarUrl = normalizeManualCoverUrl(this.avatarManualUrl);
    }

    this.isSaving = true;
    try {
      const result = await appContext.auth.updateProfile(this.nicknameDraft, avatarUrl);
      showToastByContext(this, { message: result.message, duration: 1500 });
      if (result.ok) {
        this.avatarLocalPath = '';
        this.avatarManualUrl = '';
        this.refresh();
      }
    } finally {
      this.isSaving = false;
    }
  }

  private async selectAlbumImage(): Promise<string> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = PROFILE_PICKER_LIMIT;

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
    const cachePath = `${cacheDir}/user_avatar_${Date.now()}${extension}`;
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

  @Builder
  private buildAvatarVisual(size: number): void {
    if (this.currentAvatarDisplayUri().length > 0) {
      Image(this.currentAvatarDisplayUri())
        .width(size)
        .height(size)
        .borderRadius(size / 2)
        .objectFit(ImageFit.Cover)
    } else {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(size)
          .height(size)
          .fill('#E8F0FF')

        Text(this.buildAvatarText())
          .fontSize(size >= 88 ? 28 : 22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2F6BFF')
      }
      .width(size)
      .height(size)
    }
  }

  @Builder
  private buildReadonlyField(label: string, value: string): void {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      Text(value)
        .fontSize(15)
        .fontColor(TITLE_COLOR)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(PROFILE_INPUT_BACKGROUND)
    .borderRadius(16)
    .border({ width: 1, color: PROFILE_INPUT_BORDER })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildEditableNicknameField(): void {
    Column({ space: 6 }) {
      Text('\u6635\u79f0')
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      TextInput({ text: this.nicknameDraft, placeholder: '\u8bf7\u8f93\u5165\u4f60\u60f3\u5c55\u793a\u7684\u6635\u79f0' })
        .width('100%')
        .height(46)
        .fontSize(14)
        .fontColor(TITLE_COLOR)
        .placeholderColor('#A79F95')
        .backgroundColor(PROFILE_INPUT_BACKGROUND)
        .borderRadius(14)
        .border({ width: 1, color: PROFILE_INPUT_BORDER })
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => this.nicknameDraft = value)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildProfileHeader(): void {
    Column({ space: 4 }) {
      Text('\u4e2a\u4eba\u8d44\u6599')
        .width('100%')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text('\u5728\u8fd9\u91cc\u7edf\u4e00\u7ef4\u62a4\u4f60\u7684\u5934\u50cf\u3001\u6635\u79f0\u548c\u57fa\u672c\u8d26\u53f7\u4fe1\u606f\u3002')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildGuestState(): void {
    Column({ space: 14 }) {
      EmptyState({
        title: '\u767b\u5f55\u540e\u7ef4\u62a4\u4f60\u7684\u4e2a\u4eba\u8d44\u6599',
        description: '\u5934\u50cf\u3001\u6635\u79f0\u548c\u57fa\u672c\u8d26\u53f7\u4fe1\u606f\u4f1a\u5728\u767b\u5f55\u540e\u540c\u6b65\u5230\u8fd9\u91cc\u3002'
      })

      Button('\u53bb\u767b\u5f55')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#2F6BFF')
        .backgroundColor('#E8F0FF')
        .padding({ left: 14, right: 14 })
        .onClick(() => pushUrlByContext(this, { url: 'pages/Auth/LoginPage' }))
    }
    .width('100%')
  }

  @Builder
  private buildProfileForm(user: User): void {
    Column({ space: 16 }) {
      Column({ space: 16 }) {
        Column({ space: 10 }) {
          this.buildAvatarVisual(88)

          Button(this.avatarLocalPath.length > 0 ? '\u91cd\u65b0\u9009\u62e9\u5934\u50cf' : '\u4ece\u76f8\u518c\u9009\u62e9')
            .height(40)
            .padding({ left: 18, right: 18 })
            .backgroundColor('#2F6BFF')
            .fontColor('#FFFFFF')
            .borderRadius(14)
            .onClick(() => {
              void this.chooseAvatarImage();
            })

          Text('\u5934\u50cf\u548c\u6635\u79f0\u4f1a\u5728\u201c\u6211\u7684\u201d\u9875\u3001\u804a\u5929\u548c\u4ea4\u6613\u6d41\u7a0b\u91cc\u4f7f\u7528\u3002')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(SUB_TEXT_COLOR)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        this.buildEditableNicknameField()

        this.buildReadonlyField('\u624b\u673a\u53f7', user.phone)

        Row({ space: 10 }) {
          this.buildReadonlyField('\u4fe1\u7528\u5206', `${user.creditScore}`)
          this.buildReadonlyField('\u8d26\u53f7\u7c7b\u578b', this.buildRoleText(user))
        }
        .width('100%')

        this.buildReadonlyField('\u8d26\u53f7\u72b6\u6001', this.buildStatusText(user))
      }
      .width('100%')
      .padding(18)
      .backgroundColor(CARD_BACKGROUND)
      .borderRadius(22)
      .border({ width: 1, color: CARD_BORDER })

      Column({ space: 10 }) {
        Row() {
          Text('\u6a21\u62df\u5668\u8f85\u52a9')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Blank()

          if (this.hasPendingAvatarDraft()) {
            Button('\u6e05\u7a7a\u8349\u7a3f')
              .height(34)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F4E7DE')
              .fontColor('#C76E43')
              .borderRadius(12)
              .fontSize(13)
              .onClick(() => this.removePendingAvatar())
          }
        }
        .width('100%')

        Text('\u5982\u679c\u6a21\u62df\u5668\u76f8\u518c\u91cc\u6ca1\u6709\u6d4b\u8bd5\u56fe\u7247\uff0c\u53ef\u4ee5\u5728\u8fd9\u91cc\u7c98\u8d34\u4e00\u5f20\u5934\u50cf URL\u3002')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(SUB_TEXT_COLOR)

        TextInput({ text: this.avatarManualUrl, placeholder: '\u5728\u8fd9\u91cc\u7c98\u8d34\u5934\u50cf\u56fe\u7247 URL' })
          .width('100%')
          .height(46)
          .fontSize(13)
          .fontColor(TITLE_COLOR)
          .placeholderColor('#A79F95')
          .backgroundColor(PROFILE_INPUT_BACKGROUND)
          .borderRadius(14)
          .border({ width: 1, color: PROFILE_INPUT_BORDER })
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => this.updateAvatarManualUrl(value))
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FAF7F3')
      .borderRadius(18)
      .border({ width: 1, color: '#EEE4D9' })

      Button(this.isSaving ? '\u4fdd\u5b58\u4e2d...' : '\u4fdd\u5b58\u8d44\u6599')
        .width('100%')
        .height(46)
        .backgroundColor(this.isSaving ? '#BFD0FF' : '#2F6BFF')
        .fontColor('#FFFFFF')
        .borderRadius(16)
        .enabled(!this.isSaving)
        .onClick(() => {
          void this.saveProfile();
        })
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.buildProfileHeader()

        if (!this.user) {
          this.buildGuestState()
        } else {
          this.buildProfileForm(this.user)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 18 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
