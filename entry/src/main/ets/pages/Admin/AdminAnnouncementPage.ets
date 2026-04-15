import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { Announcement, User } from '../../types/domain';
import { buildAnnouncementRenderKey } from '../../utils/render-keys';
import { formatTime } from '../../utils/time';
import { buildMarketplaceUserSyncKeys } from '../../utils/marketplace-audience-ui';
import { canAccessAdmin, getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from '../../services/guard.service';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';

@Entry
@Component
struct AdminAnnouncementPage {
  @State title: string = '';
  @State content: string = '';
  @State list: Announcement[] = [];
  private announcementSyncUnsubscriber: (() => void) | null = null;
  private userSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    void this.refresh();
    this.bindAnnouncementSync();
    this.bindUserSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    if (this.announcementSyncUnsubscriber) {
      this.announcementSyncUnsubscriber();
      this.announcementSyncUnsubscriber = null;
    }
    this.userSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.userSyncUnsubscribers = [];
  }

  private bindAnnouncementSync(): void {
    if (this.announcementSyncUnsubscriber) {
      return;
    }
    this.announcementSyncUnsubscriber = appContext.sync.subscribe('announcements:changed', () => {
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
    if (!appContext.isAdmin()) {
      showToastByContext(this, { message: getAdminAccessDeniedMessage(appContext.getCurrentUser()), duration: 1500 });
      replaceUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
      return;
    }
    this.list = await appContext.announcement.list();
  }

  private async publish(): Promise<void> {
    const user: User | null = appContext.getCurrentUser();
    if (!user || !canAccessAdmin(user)) {
      showToastByContext(this, { message: getAdminActionDeniedMessage(user), duration: 1200 });
      return;
    }

    const result = await appContext.announcement.publish(this.title, this.content, user.id);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      this.title = '';
      this.content = '';
      void this.refresh();
    }
  }

  private async remove(announcementId: string): Promise<void> {
    const user: User | null = appContext.getCurrentUser();
    if (!user || !canAccessAdmin(user)) {
      showToastByContext(this, { message: getAdminActionDeniedMessage(user), duration: 1200 });
      return;
    }

    const result = await appContext.announcement.delete(announcementId, user.id);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      void this.refresh();
    }
  }

  @Builder
  private buildComposeCard(): void {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('发布新公告')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('首页公告会优先展示这里发布的内容。')
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('平台通知')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F6BFF')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#E8F0FF')
          .borderRadius(14)
      }
      .width('100%')

      TextInput({ text: this.title, placeholder: '输入公告标题' })
        .height(48)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .border({ width: 1, color: BORDER_COLOR })
        .onChange((value: string) => this.title = value)

      TextArea({ text: this.content, placeholder: '输入公告内容，建议清楚说明规则、活动或提醒事项' })
        .height(120)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding(14)
        .border({ width: 1, color: BORDER_COLOR })
        .onChange((value: string) => this.content = value)

      Button('发布公告')
        .width('100%')
        .height(44)
        .fontColor('#FFFFFF')
        .backgroundColor('#2F6BFF')
        .onClick(() => {
          void this.publish();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  private buildAnnouncementCard(item: Announcement): void {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(formatTime(item.createdAt))
            .fontSize(12)
            .fontColor('#8C867F')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('删除')
          .type(ButtonType.Normal)
          .height(32)
          .fontColor('#B8643C')
          .backgroundColor('#F4E6DE')
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            void this.remove(item.id);
          })
      }
      .width('100%')

      Text(item.content)
        .width('100%')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#4E4740')
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
          Text('公告管理')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('发布首页公告、活动提醒和平台规则，让用户第一时间看到重要信息。')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        this.buildComposeCard()

        Column({ space: 10 }) {
          Text('已发布公告')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          if (this.list.length === 0) {
            EmptyState({
              title: '还没有发布公告',
              description: '发布后的公告会出现在首页公告区和公告页，方便用户快速查看。'
            })
          } else {
            ForEach(this.list, (item: Announcement) => {
              this.buildAnnouncementCard(item);
            }, (item: Announcement) => buildAnnouncementRenderKey(item))
          }
        }
        .width('100%')
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
