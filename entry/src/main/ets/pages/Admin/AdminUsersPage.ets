import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from '../../services/guard.service';
import { GovernanceAction, GovernanceUserSummary, User, UserStatus, VerificationStatus } from '../../types/domain';
import {
  buildAdminUserGovernanceActionPresentation,
  buildAdminUserGovernanceSummaryPresentation,
  buildAdminUserStatusPresentation,
  getAdminUserNextStatusActions,
  getAdminUserStatusActionLabel
} from '../../utils/admin-user-governance-ui';
import { resolveDisplayedVerificationStatus } from '../../utils/campus-verification-lifecycle-ui';
import { buildCampusIdentityPresentation, CampusIdentityPresentation } from '../../utils/campus-identity-ui';
import { buildUserRenderKey } from '../../utils/render-keys';
import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';

@Entry
@Component
struct AdminUsersPage {
  @State users: User[] = [];
  @State governanceSummaries: GovernanceUserSummary[] = [];
  @State governanceActions: GovernanceAction[] = [];
  private verificationSyncUnsubscriber: (() => void) | null = null;
  private userStatusSyncUnsubscriber: (() => void) | null = null;
  private userSyncUnsubscriber: (() => void) | null = null;
  private governanceSyncUnsubscriber: (() => void) | null = null;
  private moderationSyncUnsubscriber: (() => void) | null = null;

  aboutToAppear(): void {
    void this.refresh();
    this.bindVerificationSync();
    this.bindUserStatusSync();
    this.bindUserSync();
    this.bindGovernanceSync();
    this.bindModerationSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    if (this.verificationSyncUnsubscriber) {
      this.verificationSyncUnsubscriber();
      this.verificationSyncUnsubscriber = null;
    }
    if (this.userStatusSyncUnsubscriber) {
      this.userStatusSyncUnsubscriber();
      this.userStatusSyncUnsubscriber = null;
    }
    if (this.userSyncUnsubscriber) {
      this.userSyncUnsubscriber();
      this.userSyncUnsubscriber = null;
    }
    if (this.governanceSyncUnsubscriber) {
      this.governanceSyncUnsubscriber();
      this.governanceSyncUnsubscriber = null;
    }
    if (this.moderationSyncUnsubscriber) {
      this.moderationSyncUnsubscriber();
      this.moderationSyncUnsubscriber = null;
    }
  }

  private bindVerificationSync(): void {
    if (this.verificationSyncUnsubscriber) {
      return;
    }
    this.verificationSyncUnsubscriber = appContext.sync.subscribe('admin:verification-changed', () => {
      void this.refresh();
    });
  }

  private bindUserStatusSync(): void {
    if (this.userStatusSyncUnsubscriber) {
      return;
    }
    this.userStatusSyncUnsubscriber = appContext.sync.subscribe('admin:user-status-changed', () => {
      void this.refresh();
    });
  }

  private bindUserSync(): void {
    if (this.userSyncUnsubscriber) {
      return;
    }
    this.userSyncUnsubscriber = appContext.sync.subscribe('users:changed', () => {
      void this.refresh();
    });
  }

  private bindGovernanceSync(): void {
    if (this.governanceSyncUnsubscriber) {
      return;
    }
    this.governanceSyncUnsubscriber = appContext.sync.subscribe('governance:changed', () => {
      void this.refresh();
    });
  }

  private bindModerationSync(): void {
    if (this.moderationSyncUnsubscriber) {
      return;
    }
    this.moderationSyncUnsubscriber = appContext.sync.subscribe('moderation:changed', () => {
      void this.refresh();
    });
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

    const result = await appContext.adminUsers.listUsers();
    if (!result.ok) {
      showToastByContext(this, { message: result.message, duration: 1200 });
      return;
    }
    this.users = result.data ?? [];
    await this.refreshGovernanceSummaries();
  }

  private async applyStatus(user: User, status: UserStatus): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }

    const result = await appContext.adminUsers.updateUserStatus(user.id, status);
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      void this.refresh();
    }
  }

  private getActiveCount(): number {
    return this.users.filter((item: User) => item.status === 'active').length;
  }

  private getLimitedCount(): number {
    return this.users.filter((item: User) =>
      item.status === 'restricted' || item.status === 'suspended' || item.status === 'banned'
    ).length;
  }

  private getAdminCount(): number {
    return this.users.filter((item: User) => item.role === 'admin').length;
  }

  private getPendingVerificationCount(): number {
    return this.users
      .filter((item: User) => item.role !== 'admin')
      .filter((item: User) => resolveDisplayedVerificationStatus(item) === VerificationStatus.PENDING_REVIEW)
      .length;
  }

  private getVerifiedUserCount(): number {
    return this.users
      .filter((item: User) => item.role !== 'admin')
      .filter((item: User) => resolveDisplayedVerificationStatus(item) === VerificationStatus.VERIFIED)
      .length;
  }

  private getUserIdentityPresentation(item: User): CampusIdentityPresentation {
    return buildCampusIdentityPresentation(item);
  }

  private buildEmptyGovernanceSummary(userId: string): GovernanceUserSummary {
    return {
      userId,
      activeActionTypes: [],
      totalActionCount: 0,
      openCaseCount: 0,
      latestActionAt: 0
    };
  }

  private findGovernanceSummary(userId: string): GovernanceUserSummary {
    const found = this.governanceSummaries.find((item: GovernanceUserSummary) => item.userId === userId);
    return found ?? this.buildEmptyGovernanceSummary(userId);
  }

  private findActiveGovernanceActions(userId: string): GovernanceAction[] {
    return this.governanceActions
      .filter((item: GovernanceAction) => item.userId === userId && item.active)
      .sort((left: GovernanceAction, right: GovernanceAction) => right.updatedAt - left.updatedAt);
  }

  private async refreshGovernanceSummaries(): Promise<void> {
    const summaries: GovernanceUserSummary[] = [];
    const actions: GovernanceAction[] = [];
    for (let index = 0; index < this.users.length; index++) {
      const user = this.users[index];
      if (user.role === 'admin') {
        continue;
      }
      const result = await appContext.governance.getUserSummary(user.id);
      if (result.ok && result.data) {
        summaries.push(result.data);
      } else {
        summaries.push(this.buildEmptyGovernanceSummary(user.id));
      }

      const actionsResult = await appContext.governance.listActionsByUser(user.id);
      if (actionsResult.ok && actionsResult.data) {
        actions.push(...actionsResult.data.filter((item: GovernanceAction) => item.active));
      }
    }
    this.governanceSummaries = summaries;
    this.governanceActions = actions;
  }

  private async cancelGovernanceAction(item: GovernanceAction): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }

    const result = await appContext.governance.cancelAction(item.id, '后台用户治理页手动解除当前治理动作');
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      void this.refresh();
    }
  }

  private roleText(role: string): string {
    return role === 'admin' ? '管理员' : '校园用户';
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

  private getGovernanceActionTitleColor(action: GovernanceAction): string {
    const presentation = buildAdminUserGovernanceActionPresentation(action);
    if (presentation.tone === 'danger') {
      return '#8B2432';
    }
    if (presentation.tone === 'warning') {
      return '#A45A2A';
    }
    return '#5E5851';
  }

  private getGovernanceActionBackgroundColor(action: GovernanceAction): string {
    const presentation = buildAdminUserGovernanceActionPresentation(action);
    if (presentation.tone === 'danger') {
      return '#FBEEEE';
    }
    if (presentation.tone === 'warning') {
      return '#FFF3E8';
    }
    return '#F7F2EC';
  }

  @Builder
  private buildGovernanceActionBlock(user: User, action: GovernanceAction): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(buildAdminUserGovernanceActionPresentation(action).title)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getGovernanceActionTitleColor(action))

        Button(buildAdminUserGovernanceActionPresentation(action).cancelLabel)
          .height(32)
          .type(ButtonType.Normal)
          .fontSize(11)
          .fontColor('#7A4B17')
          .backgroundColor('#F5E9D7')
          .padding({ left: 10, right: 10 })
          .onClick(() => {
            void this.cancelGovernanceAction(action);
          })
      }
      .width('100%')

      Text(buildAdminUserGovernanceActionPresentation(action).detail)
        .width('100%')
        .fontSize(11)
        .lineHeight(17)
        .fontColor(SUB_TEXT_COLOR)
        .maxLines(3)

      Text(`作用账号：${user.nickname}`)
        .width('100%')
        .fontSize(11)
        .fontColor('#9A8F84')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.getGovernanceActionBackgroundColor(action))
    .borderRadius(14)
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

        Text(buildAdminUserStatusPresentation(item.status).label)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(buildAdminUserStatusPresentation(item.status).textColor)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(buildAdminUserStatusPresentation(item.status).backgroundColor)
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
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text(this.getUserIdentityPresentation(item).badgeText)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getUserIdentityPresentation(item).badgeTextColor)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor(this.getUserIdentityPresentation(item).badgeBackgroundColor)
              .borderRadius(14)

            Text(this.getUserIdentityPresentation(item).summaryText)
              .layoutWeight(1)
              .fontSize(12)
              .fontColor(SUB_TEXT_COLOR)
              .maxLines(2)
          }
          .width('100%')

          Text(this.getUserIdentityPresentation(item).helperText)
            .width('100%')
            .fontSize(12)
            .lineHeight(18)
            .fontColor('#8B847A')
            .maxLines(2)
        }
        .width('100%')
      }

      if (item.role !== 'admin') {
        Column({ space: 8 }) {
          Text(buildAdminUserGovernanceSummaryPresentation(this.findGovernanceSummary(item.id)).title)
            .width('100%')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(
              buildAdminUserGovernanceSummaryPresentation(this.findGovernanceSummary(item.id)).tone === 'warning'
                ? '#A45A2A'
                : '#237B46'
            )

          Text(buildAdminUserGovernanceSummaryPresentation(this.findGovernanceSummary(item.id)).description)
            .width('100%')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(SUB_TEXT_COLOR)

          if (buildAdminUserGovernanceSummaryPresentation(this.findGovernanceSummary(item.id)).badges.length > 0) {
            Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
              ForEach(buildAdminUserGovernanceSummaryPresentation(this.findGovernanceSummary(item.id)).badges, (badge: string) => {
                Text(badge)
                  .fontSize(11)
                  .fontColor('#8A5A13')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F8F0DF')
                  .borderRadius(12)
                  .margin({ right: 8, bottom: 8 })
              }, (badge: string) => `${item.id}-${badge}`)
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor(
          buildAdminUserGovernanceSummaryPresentation(this.findGovernanceSummary(item.id)).tone === 'warning'
            ? '#FFF6EE'
            : '#F4FBF5'
        )
        .borderRadius(16)
      }

      if (item.role !== 'admin' && this.findActiveGovernanceActions(item.id).length > 0) {
        Column({ space: 8 }) {
          Text('当前生效动作')
            .width('100%')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#7A4B17')

          ForEach(this.findActiveGovernanceActions(item.id), (action: GovernanceAction) => {
            this.buildGovernanceActionBlock(item, action)
          }, (action: GovernanceAction) => `${item.id}-${action.id}`)
        }
        .width('100%')
      }

      if (item.role !== 'admin') {
        Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
          ForEach(getAdminUserNextStatusActions(item.status), (nextStatus: UserStatus) => {
            Button(getAdminUserStatusActionLabel(nextStatus))
              .height(38)
              .type(ButtonType.Normal)
              .fontSize(12)
              .fontColor(nextStatus === 'active' ? '#237B46' : '#B8643C')
              .backgroundColor(nextStatus === 'active' ? '#E8F5EA' : '#F4E6DE')
              .padding({ left: 14, right: 14 })
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                void this.applyStatus(item, nextStatus);
              })
          }, (nextStatus: UserStatus) => `${item.id}-${nextStatus}`)
        }
        .width('100%')
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
          Text('用户治理')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('统一查看平台账号状态，集中处理限制交易、聊天禁言、暂停账号、封禁与恢复操作。')
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
            this.buildSummaryCard('受限中', this.getLimitedCount(), '#B8643C')
            this.buildSummaryCard('管理员', this.getAdminCount(), '#2F6BFF')
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildSummaryCard('待审核', this.getPendingVerificationCount(), '#A86B00')
            this.buildSummaryCard('已认证', this.getVerifiedUserCount(), '#237B46')
          }
          .width('100%')
        }
        .width('100%')

        if (this.users.length === 0) {
          EmptyState({
            title: '这里还没有可治理的用户',
            description: '当平台出现注册用户后，这里会集中展示账号身份、状态、认证进度与信用分。'
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
