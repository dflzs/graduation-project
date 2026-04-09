import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { userRepository } from '../../repositories/user.repo';
import { User } from '../../types/domain';
import { buildUserRenderKey } from '../../utils/render-keys';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';

@Entry
@Component
struct AdminUsersPage {
  @State users: User[] = [];

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
    this.users = userRepository.list().sort((a: User, b: User) => b.createdAt - a.createdAt);
  }

  private toggleStatus(user: User): void {
    const status: 'active' | 'banned' = user.status === 'active' ? 'banned' : 'active';
    userRepository.updateStatus(user.id, status);
    showToastByContext(this, { message: status === 'banned' ? '已封禁该用户' : '已恢复该用户', duration: 1200 });
    this.refresh();
  }

  private getActiveCount(): number {
    return this.users.filter((item: User) => item.status === 'active').length;
  }

  private getBannedCount(): number {
    return this.users.filter((item: User) => item.status === 'banned').length;
  }

  private getAdminCount(): number {
    return this.users.filter((item: User) => item.role === 'admin').length;
  }

  private roleText(role: string): string {
    return role === 'admin' ? '管理员' : '校园用户';
  }

  private statusText(status: string): string {
    return status === 'banned' ? '已封禁' : '正常';
  }

  private statusTextColor(status: string): string {
    return status === 'banned' ? '#B8643C' : '#237B46';
  }

  private statusBgColor(status: string): string {
    return status === 'banned' ? '#F4E6DE' : '#E8F5EA';
  }

  @Builder
  private buildSummaryCard(label: string, value: number, accent: string): void {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      Text(`${value}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(18)
    .border({ width: 1, color: BORDER_COLOR })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildUserCard(item: User): void {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text(item.nickname)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(item.phone)
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.statusText(item.status))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.statusTextColor(item.status))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.statusBgColor(item.status))
          .borderRadius(14)
      }
      .width('100%')

      Row({ space: 8 }) {
        Text(this.roleText(item.role))
          .fontSize(12)
          .fontColor('#5E5851')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F2ECE5')
          .borderRadius(12)

        Text(`信用分 ${item.creditScore}`)
          .fontSize(12)
          .fontColor('#5E5851')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F2ECE5')
          .borderRadius(12)
      }
      .width('100%')

      if (item.role !== 'admin') {
        Button(item.status === 'active' ? '封禁用户' : '恢复账号')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .fontColor(item.status === 'active' ? '#B8643C' : '#237B46')
          .backgroundColor(item.status === 'active' ? '#F4E6DE' : '#E8F5EA')
          .onClick(() => this.toggleStatus(item))
      }
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
          Text('用户管理')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('查看平台账号状态，处理封禁与恢复，让校园交易环境保持稳定。')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 10 }) {
          Row({ space: 10 }) {
            this.buildSummaryCard('全部用户', this.users.length, '#2D2A26')
            this.buildSummaryCard('正常', this.getActiveCount(), '#237B46')
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildSummaryCard('封禁中', this.getBannedCount(), '#B8643C')
            this.buildSummaryCard('管理员', this.getAdminCount(), '#2F6BFF')
          }
          .width('100%')
        }
        .width('100%')

        if (this.users.length === 0) {
          EmptyState({
            title: '这里还没有可管理的用户',
            description: '当平台出现注册用户后，这里会集中显示账号身份、状态与信用分。'
          })
        } else {
          Column({ space: 10 }) {
            ForEach(this.users, (item: User) => {
              this.buildUserCard(item)
            }, (item: User) => buildUserRenderKey(item))
          }
          .width('100%')
        }
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
