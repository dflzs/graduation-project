import { pushUrlByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { Announcement } from '../../types/domain';
import { formatTime } from '../../utils/time';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';

@Entry
@Component
struct AnnouncementPage {
  @State list: Announcement[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  private refresh(): void {
    this.list = appContext.announcement.list();
  }

  @Builder
  private buildHeader(): void {
    Row() {
      Column({ space: 4 }) {
        Text('系统公告')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text('平台规则、交易提醒和重要通知都会集中显示在这里。')
          .fontSize(13)
          .lineHeight(20)
          .fontColor(SUB_TEXT_COLOR)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (appContext.isAdmin()) {
        Text('发布')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F6BFF')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#E8F0FF')
          .borderRadius(16)
          .onClick(() => pushUrlByContext(this, { url: 'pages/Admin/AdminAnnouncementPage' }))
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildEmptyState(): void {
    EmptyState({
      title: '暂时还没有新的公告',
      description: '后续的系统通知、平台规则更新和重要提醒会优先出现在这里。'
    })
  }

  @Builder
  private buildAnnouncementCard(item: Announcement): void {
    Column({ space: 8 }) {
      Text(item.title)
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(item.content)
        .width('100%')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#4E4740')

      Text(formatTime(item.createdAt))
        .width('100%')
        .fontSize(12)
        .fontColor('#9A938A')
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
      Column({ space: 16 }) {
        this.buildHeader()

        if (this.list.length === 0) {
          this.buildEmptyState()
        } else {
          ForEach(this.list, (item: Announcement) => {
            this.buildAnnouncementCard(item)
          }, (item: Announcement) => item.id)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 18 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .height('100%')
    .width('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
