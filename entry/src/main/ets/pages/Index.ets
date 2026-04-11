import { getParamsByContext, pushUrlByContext, showToastByContext } from '../utils/ui-context-actions';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { appContext } from '../app/app-context';
import { CartContent } from '../components/CartContent';
import { uploadRemoteClient } from '../services/upload-remote.client';
import { normalizeManualCoverUrl } from '../utils/cover-image';
import { resolveIndexRouteTab } from '../utils/detail-return-route';
import { openPublishEntry } from '../utils/publish-entry';
import { shouldShowMarketplaceUnreadBadge } from '../utils/marketplace-audience-ui';
import { MessageHubPage } from './Chat/MessageHubPage';
import { HomePage } from './Home/HomePage';
import { User } from '../types/domain';
import { getMarketplaceAudienceMode } from '../utils/trade-guard';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const AVATAR_PICKER_LIMIT: number = 1;

@Entry
@Component
struct Index {
  @State currentUser: User | null = null;
  @State currentTab: number = 0;
  @State messageUnreadCount: number = 0;
  @State avatarLocalPath: string = '';
  @State avatarPreviewUri: string = '';
  @State avatarManualUrl: string = '';
  @State isSavingAvatar: boolean = false;
  private shellNavigationUnsubscriber: (() => void) | null = null;
  private messageHubUnsubscriber: (() => void) | null = null;

  aboutToAppear(): void {
    this.applyRouteParams();
    this.refresh();
    this.bindShellNavigation();
    this.bindMessageHub();
  }

  onPageShow(): void {
    this.applyRouteParams();
    this.refresh();
  }

  aboutToDisappear(): void {
    if (this.shellNavigationUnsubscriber) {
      this.shellNavigationUnsubscriber();
      this.shellNavigationUnsubscriber = null;
    }
    if (this.messageHubUnsubscriber) {
      this.messageHubUnsubscriber();
      this.messageHubUnsubscriber = null;
    }
  }

  private refresh(): void {
    this.currentUser = appContext.getCurrentUser();
    this.refreshMessageUnreadCount();
    if (this.avatarLocalPath.length === 0 && this.avatarManualUrl.length === 0) {
      this.avatarPreviewUri = this.currentUser?.avatar ?? '';
    }
  }

  private applyRouteParams(): void {
    const params = getParamsByContext<Record<string, string>>(this);
    this.currentTab = resolveIndexRouteTab(params?.tab, this.currentTab);
  }

  private bindShellNavigation(): void {
    if (this.shellNavigationUnsubscriber) {
      return;
    }
    this.shellNavigationUnsubscriber = appContext.sync.subscribe('shell:navigate', (payload) => {
      if (payload.value === 'home') {
        this.currentTab = 0;
      }
    });
  }

  private bindMessageHub(): void {
    if (this.messageHubUnsubscriber) {
      return;
    }
    this.messageHubUnsubscriber = appContext.sync.subscribe('messages:changed', () => {
      this.refreshMessageUnreadCount();
    });
  }

  private refreshMessageUnreadCount(): void {
    if (!this.currentUser) {
      this.messageUnreadCount = 0;
      return;
    }
    if (!shouldShowMarketplaceUnreadBadge(getMarketplaceAudienceMode(this.currentUser))) {
      this.messageUnreadCount = 0;
      return;
    }
    this.messageUnreadCount = appContext.notification.countUnread(this.currentUser.id)
      + appContext.chat.countUnread(this.currentUser.id);
  }

  private buildMineAvatarText(): string {
    if (this.currentUser && this.currentUser.nickname.length > 0) {
      return this.currentUser.nickname.slice(0, 1);
    }
    return '\u6211';
  }

  private buildMineRoleText(): string {
    if (!this.currentUser) {
      return '';
    }
    return this.currentUser.role === 'admin' ? '\u7ba1\u7406\u5458' : '\u666e\u901a\u7528\u6237';
  }

  private buildMineStatusText(): string {
    if (!this.currentUser) {
      return '';
    }
    return this.currentUser.status === 'active'
      ? '\u8d26\u53f7\u72b6\u6001\u6b63\u5e38'
      : '\u8d26\u53f7\u5f53\u524d\u53d7\u9650';
  }

  private currentAvatarDisplayUri(): string {
    if (this.avatarPreviewUri.length > 0) {
      return this.avatarPreviewUri;
    }
    return this.currentUser?.avatar ?? '';
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
    this.avatarPreviewUri = this.currentUser?.avatar ?? '';
    if (showToast) {
      showToastByContext(this, { message: '\u5df2\u6e05\u7a7a\u5934\u50cf\u8349\u7a3f', duration: 1200 });
    }
  }

  private updateAvatarManualUrl(value: string): void {
    this.avatarManualUrl = value;
    if (this.avatarLocalPath.length > 0) {
      return;
    }

    const normalized = normalizeManualCoverUrl(value);
    this.avatarPreviewUri = normalized.length > 0 ? normalized : (this.currentUser?.avatar ?? '');
  }

  private async saveAvatar(): Promise<void> {
    if (this.isSavingAvatar) {
      return;
    }

    const session = appContext.getSession();
    if (!session) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u8bbe\u7f6e\u5934\u50cf', duration: 1500 });
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

    if (avatarUrl.length === 0) {
      showToastByContext(this, { message: '\u8bf7\u5148\u9009\u62e9\u5934\u50cf\u6216\u7c98\u8d34\u6709\u6548\u56fe\u7247\u94fe\u63a5', duration: 1500 });
      return;
    }

    this.isSavingAvatar = true;
    try {
      const result = await appContext.auth.updateAvatar(avatarUrl);
      showToastByContext(this, { message: result.message, duration: 1500 });
      if (result.ok) {
        this.avatarLocalPath = '';
        this.avatarManualUrl = '';
        this.refresh();
      }
    } finally {
      this.isSavingAvatar = false;
    }
  }

  private async selectAlbumImage(): Promise<string> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = AVATAR_PICKER_LIMIT;

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
  private buildMessageTab(): void {
    MessageHubPage()
  }

  @Builder
  private buildMineAvatarVisual(size: number): void {
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

        Text(this.buildMineAvatarText())
          .fontSize(size >= 64 ? 24 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2F6BFF')
      }
      .width(size)
      .height(size)
    }
  }

  @Builder
  private buildMineSectionTitle(title: string, description: string): void {
    Column({ space: 4 }) {
      Text(title)
        .width('100%')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(description)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(SUB_TEXT_COLOR)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildMineActionRow(title: string, summary: string, url: string, accentText: string): void {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(38)
          .height(38)
          .fill('#EEF3FF')

        Text(accentText.slice(0, 1))
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2F6BFF')
      }

      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text(summary)
          .fontSize(12)
          .lineHeight(18)
          .fontColor(SUB_TEXT_COLOR)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 3 }) {
        Text(accentText)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F6BFF')

        Text('>')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#A4B7E8')
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
    .border({ width: 1, color: CARD_BORDER })
    .onClick(() => pushUrlByContext(this, { url }))
  }

  @Builder
  private buildMineAvatarEditor(): void {
    Column({ space: 12 }) {
      Row() {
        Text('\u5934\u50cf\u8bbe\u7f6e')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Blank()

        Text('\u652f\u6301\u76f8\u518c\u9009\u62e9\uff0c\u4e5f\u652f\u6301\u6a21\u62df\u5668\u8d34\u56fe\u8c03\u8bd5')
          .fontSize(11)
          .fontColor(SUB_TEXT_COLOR)
      }
      .width('100%')

      Row({ space: 12 }) {
        Button(this.avatarLocalPath.length > 0 ? '\u91cd\u65b0\u9009\u62e9\u5934\u50cf' : '\u4ece\u76f8\u518c\u9009\u62e9')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#2F6BFF')
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => {
            void this.chooseAvatarImage();
          })

        if (this.hasPendingAvatarDraft()) {
          Button('\u6e05\u7a7a\u8349\u7a3f')
            .height(40)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#F4E7DE')
            .fontColor('#C76E43')
            .borderRadius(14)
            .onClick(() => this.removePendingAvatar())
        }
      }
      .width('100%')

      Column({ space: 6 }) {
        Text('\u6a21\u62df\u5668\u8d34\u94fe\u63a5')
          .fontSize(12)
          .fontColor(SUB_TEXT_COLOR)

        TextInput({
          text: this.avatarManualUrl,
          placeholder: '\u5728\u8fd9\u91cc\u7c98\u8d34\u5934\u50cf\u56fe\u7247 URL'
        })
          .width('100%')
          .height(46)
          .fontSize(13)
          .fontColor(TITLE_COLOR)
          .placeholderColor('#A79F95')
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .border({ width: 1, color: '#DDD4C8' })
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => this.updateAvatarManualUrl(value))
      }
      .width('100%')

      Button(this.isSavingAvatar ? '\u4fdd\u5b58\u4e2d...' : '\u4fdd\u5b58\u5934\u50cf')
        .width('100%')
        .height(42)
        .backgroundColor(this.isSavingAvatar ? '#BFD0FF' : '#E8F0FF')
        .fontColor('#2F6BFF')
        .borderRadius(14)
        .enabled(!this.isSavingAvatar)
        .onClick(() => {
          void this.saveAvatar();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(18)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildMineTab(): void {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 4 }) {
          Text('\u6211\u7684')
            .width('100%')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('\u8d26\u53f7\u4fe1\u606f\u3001\u8ba2\u5355\u8bb0\u5f55\u3001\u53d1\u5e03\u7ba1\u7406\u548c\u5e73\u53f0\u5165\u53e3\u90fd\u4f1a\u96c6\u4e2d\u5728\u8fd9\u91cc\u3002')
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (!this.currentUser) {
          Column({ space: 14 }) {
            Text('\u767b\u5f55\u540e\u7ba1\u7406\u4f60\u7684\u6821\u56ed\u4ea4\u6613')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(TITLE_COLOR)
              .textAlign(TextAlign.Center)

            Text('\u8ba2\u5355\u3001\u6211\u53d1\u5e03\u7684\u5546\u54c1\u3001\u5ba1\u6838\u7ed3\u679c\u548c\u6d88\u606f\u63d0\u9192\u90fd\u4f1a\u5728\u767b\u5f55\u540e\u540c\u6b65\u5230\u8fd9\u91cc\u3002')
              .fontSize(13)
              .lineHeight(20)
              .fontColor(SUB_TEXT_COLOR)
              .textAlign(TextAlign.Center)

            Button('\u53bb\u767b\u5f55')
              .height(42)
              .type(ButtonType.Normal)
              .fontColor('#2F6BFF')
              .backgroundColor('#E8F0FF')
              .padding({ left: 14, right: 14 })
              .onClick(() => pushUrlByContext(this, { url: 'pages/Auth/LoginPage' }))
          }
          .width('100%')
          .padding(20)
          .backgroundColor(CARD_BACKGROUND)
          .borderRadius(22)
          .alignItems(HorizontalAlign.Center)
          .border({ width: 1, color: CARD_BORDER })
        } else {
          Row({ space: 14 }) {
            this.buildMineAvatarVisual(64)

            Column({ space: 6 }) {
              Text(this.currentUser.nickname)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(TITLE_COLOR)

              Text(this.currentUser.phone)
                .fontSize(14)
                .fontColor('#5E5851')

              Row({ space: 8 }) {
                Text(`\u4fe1\u7528\u5206 ${this.currentUser.creditScore}`)
                  .fontSize(12)
                  .fontColor('#5E5851')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F2ECE5')
                  .borderRadius(12)

                Text(this.buildMineRoleText())
                  .fontSize(12)
                  .fontColor('#5E5851')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F2ECE5')
                  .borderRadius(12)
              }
              .width('100%')

              Text(this.buildMineStatusText())
                .fontSize(12)
                .fontColor(SUB_TEXT_COLOR)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 4 }) {
              Text('\u67e5\u770b\u8d44\u6599')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2F6BFF')

              Text('>')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#A4B7E8')
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding(18)
          .backgroundColor(CARD_BACKGROUND)
          .borderRadius(22)
          .border({ width: 1, color: CARD_BORDER })
          .onClick(() => pushUrlByContext(this, { url: 'pages/Profile/ProfilePage' }))

          if (appContext.isAdmin()) {
            Column({ space: 10 }) {
              this.buildMineSectionTitle('\u5e73\u53f0\u7ba1\u7406', '\u7ba1\u7406\u5458\u5165\u53e3\u653e\u5728\u8fd9\u91cc\uff0c\u65b9\u4fbf\u7edf\u4e00\u5904\u7406\u540e\u53f0\u4e8b\u52a1\u3002')
              this.buildMineActionRow('\u540e\u53f0\u7ba1\u7406', '\u67e5\u770b\u5e73\u53f0\u6982\u89c8\u3001\u5546\u54c1\u5ba1\u6838\u3001\u7528\u6237\u6cbb\u7406\u548c\u516c\u544a\u7ef4\u62a4\u3002', 'pages/Admin/AdminDashboardPage', '\u8fdb\u5165')
              this.buildMineActionRow('\u516c\u544a\u5386\u53f2', '\u67e5\u770b\u548c\u6838\u5bf9\u5e73\u53f0\u5f53\u524d\u5bf9\u5916\u5c55\u793a\u7684\u516c\u544a\u5185\u5bb9\u3002', 'pages/Announcement/AnnouncementPage', '\u67e5\u770b')
            }
            .width('100%')
          } else {
            Column({ space: 10 }) {
              this.buildMineSectionTitle('\u6211\u7684\u4ea4\u6613', '\u5e38\u7528\u4ea4\u6613\u5165\u53e3\u4f1a\u96c6\u4e2d\u5728\u8fd9\u91cc\uff0c\u65b9\u4fbf\u5feb\u901f\u7ee7\u7eed\u5904\u7406\u3002')
              this.buildMineActionRow('\u6211\u7684\u8ba2\u5355', '\u67e5\u770b\u4e0b\u5355\u8bb0\u5f55\u3001\u9762\u4ea4\u72b6\u6001\u548c\u4ea4\u6613\u5b8c\u6210\u60c5\u51b5\u3002', 'pages/Order/OrderListPage', '\u8fdb\u5165')
              this.buildMineActionRow('\u6211\u53d1\u5e03\u7684', '\u67e5\u770b\u5df2\u53d1\u5e03\u5546\u54c1\u3001\u5ba1\u6838\u72b6\u6001\u548c\u5728\u552e\u60c5\u51b5\u3002', 'pages/Product/MyPublishedProductsPage', '\u8fdb\u5165')
            }
            .width('100%')

            Column({ space: 10 }) {
              this.buildMineSectionTitle('\u5e73\u53f0\u4e0e\u8d26\u53f7', '\u5e73\u53f0\u516c\u544a\u548c\u8d26\u53f7\u64cd\u4f5c\u7edf\u4e00\u653e\u5728\u8fd9\u4e2a\u533a\u57df\u3002')
              this.buildMineActionRow('\u516c\u544a\u5386\u53f2', '\u67e5\u770b\u5e73\u53f0\u516c\u544a\u3001\u89c4\u5219\u63d0\u9192\u548c\u6d3b\u52a8\u901a\u77e5\u3002', 'pages/Announcement/AnnouncementPage', '\u67e5\u770b')
            }
            .width('100%')
          }

          Button('\u9000\u51fa\u767b\u5f55')
            .width('100%')
            .height(46)
            .type(ButtonType.Normal)
            .backgroundColor('#F4E6DE')
            .borderRadius(16)
            .fontColor('#B8643C')
            .onClick(() => {
              this.removePendingAvatar(false);
              appContext.logout();
              this.refresh();
              showToastByContext(this, { message: '\u5df2\u9000\u51fa\u767b\u5f55', duration: 1200 });
            })
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

  @Builder
  private buildTabContent(): void {
    if (this.currentTab === 0) {
      HomePage()
    } else if (this.currentTab === 1) {
      this.buildMessageTab()
    } else if (this.currentTab === 3) {
      CartContent({ shellMode: true })
    } else {
      this.buildMineTab()
    }
  }

  build() {
    Column() {
      Column() {
        this.buildTabContent()
      }
      .layoutWeight(1)
      .width('100%')

      Column({ space: 10 }) {
        Row() {
          Blank()
            .layoutWeight(1)
            .height(1)
            .backgroundColor('#E7DED2')

          Blank()
            .width(92)

          Blank()
            .layoutWeight(1)
            .height(1)
            .backgroundColor('#E7DED2')
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        Row() {
          Column({ space: 4 }) {
            Text('\u9996\u9875')
              .fontSize(13)
              .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 0 ? '#2F6BFF' : '#8C867F')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.currentTab = 0)

          Column({ space: 4 }) {
            Stack({ alignContent: Alignment.TopEnd }) {
              Text('\u6d88\u606f')
                .fontSize(13)
                .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentTab === 1 ? '#2F6BFF' : '#8C867F')

              if (this.messageUnreadCount > 0) {
                Text(this.messageUnreadCount > 99 ? '99+' : `${this.messageUnreadCount}`)
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .backgroundColor('#C64747')
                  .borderRadius(9)
                  .offset({ x: 16, y: -8 })
              }
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.currentTab = 1)

          Column({ space: 4 }) {
            Column() {
              Text('+')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
            .width(56)
            .height(56)
            .borderRadius(28)
            .backgroundColor('#2F6BFF')
            .shadow({ radius: 18, color: '#332F6BFF', offsetX: 0, offsetY: 8 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => openPublishEntry(this, this.currentUser))

            Text('\u53d1\u5e03')
              .fontSize(12)
              .fontColor('#5E5851')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .margin({ top: -20 })

          Column({ space: 4 }) {
            Text('\u8d2d\u7269\u8f66')
              .fontSize(13)
              .fontWeight(this.currentTab === 3 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 3 ? '#2F6BFF' : '#8C867F')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.currentTab = 3)

          Column({ space: 4 }) {
            Text('\u6211\u7684')
              .fontSize(13)
              .fontWeight(this.currentTab === 4 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 4 ? '#2F6BFF' : '#8C867F')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.currentTab = 4)
        }
        .width('100%')
        .padding({ left: 8, right: 8, bottom: 18 })
      }
      .width('100%')
      .padding({ top: 10 })
      .backgroundColor('#FFFDFC')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
