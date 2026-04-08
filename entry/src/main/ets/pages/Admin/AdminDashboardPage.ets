import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext, DashboardStats } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';

@Entry
@Component
struct AdminDashboardPage {
  @State stats: DashboardStats = new DashboardStats();

  aboutToAppear(): void {
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  private refresh(): void {
    if (!appContext.isAdmin()) {
      showToastByContext(this, { message: '仅管理员可访问', duration: 1500 });
      replaceUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
      return;
    }
    this.stats = appContext.getDashboardStats();
  }

  private hasAnyStats(): boolean {
    return (this.stats.userCount ?? 0) > 0 ||
      (this.stats.productCount ?? 0) > 0 ||
      (this.stats.pendingOrderCount ?? 0) > 0 ||
      (this.stats.paidOrderCount ?? 0) > 0 ||
      (this.stats.completedOrderCount ?? 0) > 0;
  }

  @Builder
  private buildMetricCard(label: string, value: number, accentColor: string, helper: string): void {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(13)
        .fontColor(SUB_TEXT_COLOR)

      Text(`${value}`)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(accentColor)

      Text(helper)
        .fontSize(12)
        .fontColor('#9A938B')
        .maxLines(1)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  private buildEntryCard(title: string, description: string, url: string, accent: string): void {
    Row({ space: 12 }) {
      Column({ space: 5 }) {
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text(description)
          .fontSize(13)
          .lineHeight(20)
          .fontColor(SUB_TEXT_COLOR)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('进入')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(accent)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
    .onClick(() => pushUrlByContext(this, { url }))
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 6 }) {
            Text('后台管理')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(TITLE_COLOR)

            Text('从这里统一查看平台运行情况，处理商品审核、用户治理和公告维护。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor(SUB_TEXT_COLOR)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text('平台概览')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2F6BFF')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('#E8F0FF')
            .borderRadius(14)
        }
        .width('100%')

        if (!this.hasAnyStats()) {
          Column({ space: 12 }) {
            EmptyState({
              title: '后台数据正在准备中',
              description: '当商品、用户和订单逐步产生后，这里会集中展示平台的整体运行情况。'
            })

            Button('先去商品管理')
              .height(42)
              .type(ButtonType.Normal)
              .fontColor('#2F6BFF')
              .backgroundColor('#E8F0FF')
              .padding({ left: 16, right: 16 })
              .onClick(() => pushUrlByContext(this, { url: 'pages/Admin/AdminProductsPage' }))
          }
          .width('100%')
        } else {
          Row({ space: 10 }) {
            Column({ space: 10 }) {
              this.buildMetricCard('用户数', this.stats.userCount ?? 0, '#2D2A26', '当前注册账号')
              this.buildMetricCard('商品数', this.stats.productCount ?? 0, '#2F6BFF', '平台内商品总量')
            }
            .layoutWeight(1)

            Column({ space: 10 }) {
              this.buildMetricCard('待付款', this.stats.pendingOrderCount ?? 0, '#A86B00', '等待买家支付')
              this.buildMetricCard('已完成', this.stats.completedOrderCount ?? 0, '#237B46', '已结束交易')
            }
            .layoutWeight(1)
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildMetricCard('已支付', this.stats.paidOrderCount ?? 0, '#2F6BFF', '等待线下面交完成')
            this.buildMetricCard('封禁中', this.stats.bannedUserCount ?? 0, '#B8643C', '当前受限账号')
          }
          .width('100%')
        }

        Column({ space: 10 }) {
          Text('后台入口')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          this.buildEntryCard('商品管理', '审核新发布商品，处理在售状态与强制下架。', 'pages/Admin/AdminProductsPage', '#2F6BFF')
          this.buildEntryCard('用户管理', '查看用户身份、信用分与账号状态。', 'pages/Admin/AdminUsersPage', '#B8643C')
          this.buildEntryCard('公告管理', '维护平台公告，让首页通知和规则保持最新。', 'pages/Admin/AdminAnnouncementPage', '#2D2A26')
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
