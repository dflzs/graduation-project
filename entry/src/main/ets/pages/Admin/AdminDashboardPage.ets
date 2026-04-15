import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { DashboardStats } from '../../types/dashboard-stats';
import { getAdminAccessDeniedMessage } from '../../services/guard.service';
import { AdminNavEntry, getAdminDashboardEntries } from '../../utils/admin-navigation';
import { buildAdminDashboardSyncKeys } from '../../utils/admin-dashboard-sync';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';

@Entry
@Component
struct AdminDashboardPage {
  @State stats: DashboardStats = new DashboardStats();
  private dashboardSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    void this.refresh();
    this.bindDashboardSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    this.dashboardSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.dashboardSyncUnsubscribers = [];
  }

  private bindDashboardSync(): void {
    if (this.dashboardSyncUnsubscribers.length > 0) {
      return;
    }
    this.dashboardSyncUnsubscribers = buildAdminDashboardSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        void this.refresh();
      })
    );
  }

  private async refresh(): Promise<void> {
    if (!appContext.isAdmin()) {
      showToastByContext(this, {
        message: getAdminAccessDeniedMessage(appContext.getCurrentUser()),
        duration: 1500
      });
      replaceUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
      return;
    }
    const result = await appContext.adminDashboard.getStats();
    if (!result.ok) {
      showToastByContext(this, { message: result.message, duration: 1200 });
      return;
    }
    this.stats = result.data ?? new DashboardStats();
  }

  private hasAnyStats(): boolean {
    return (this.stats.userCount ?? 0) > 0 ||
      (this.stats.productCount ?? 0) > 0 ||
      (this.stats.pendingVerificationCount ?? 0) > 0 ||
      (this.stats.verifiedUserCount ?? 0) > 0 ||
      (this.stats.pendingOrderCount ?? 0) > 0 ||
      (this.stats.paidOrderCount ?? 0) > 0 ||
      (this.stats.completedOrderCount ?? 0) > 0 ||
      (this.stats.activeGovernanceCount ?? 0) > 0 ||
      (this.stats.openModerationCaseCount ?? 0) > 0;
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
  private buildEntryCard(item: AdminNavEntry): void {
    Row({ space: 12 }) {
      Column({ space: 5 }) {
        Text(item.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)

        Text(item.description)
          .fontSize(13)
          .lineHeight(20)
          .fontColor(SUB_TEXT_COLOR)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('进入')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(item.accent)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
    .onClick(() => pushUrlByContext(this, { url: item.url }))
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

            Text('从这里统一查看平台运行概况，处理商品审核、认证审核、用户治理和公告维护。')
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
              description: '当商品、用户、订单和治理记录逐步产生后，这里会集中展示平台的整体运行情况。'
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
            this.buildMetricCard('治理中', this.stats.activeGovernanceCount ?? 0, '#B8643C', '当前生效中的治理动作')
            this.buildMetricCard('未结案', this.stats.openModerationCaseCount ?? 0, '#8A5A13', '仍在流转的举报与投诉')
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildMetricCard('已支付', this.stats.paidOrderCount ?? 0, '#2F6BFF', '等待线下面交完成')
            this.buildMetricCard('受限中', this.stats.bannedUserCount ?? 0, '#B8643C', '当前受限账号')
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildMetricCard('待审核', this.stats.pendingVerificationCount ?? 0, '#237B46', '等待管理员处理')
            this.buildMetricCard('已认证', this.stats.verifiedUserCount ?? 0, '#2D2A26', '可公开展示校园可信身份')
          }
          .width('100%')
        }

        Column({ space: 10 }) {
          Text('后台入口')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          ForEach(getAdminDashboardEntries(), (item: AdminNavEntry) => {
            this.buildEntryCard(item)
          }, (item: AdminNavEntry) => item.url)
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
