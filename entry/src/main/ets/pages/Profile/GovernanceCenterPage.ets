import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import {
  AppealRecord,
  GovernanceAction,
  GovernanceUserSummary,
  ModerationRecord,
  User
} from '../../types/domain';
import { canSubmitAppealForModerationRecord } from '../../utils/appeal-ui';
import {
  GovernanceTimelineStep,
  buildAppealTimelineSteps,
  buildAppealTimelineSummary,
  buildGovernanceCenterTimelineLabel,
  buildModerationTimelineSteps
} from '../../utils/governance-timeline';
import {
  GovernanceActiveActionPresentation,
  GovernanceSummaryPresentation,
  buildGovernanceActiveActionPresentation,
  buildGovernanceSummaryPresentation
} from '../../utils/governance-summary-ui';
import {
  buildGovernanceCenterBadgeRecordTitle,
  buildGovernanceCenterAppealBadgeLabel,
  buildGovernanceCenterAppealButtonLabel,
  buildGovernanceCenterAppealEmptyState,
  buildGovernanceCenterAppealMetaSummary,
  buildGovernanceCenterAppealSubmitTitle,
  buildGovernanceCenterErrorTitle,
  buildGovernanceCenterLinkedRecordMeta,
  buildGovernanceCenterLoadingCopy,
  buildGovernanceCenterPageTitle,
  buildGovernanceCenterRecordDescription,
  buildGovernanceCenterRecordTitle,
  buildGovernanceCenterReviewCommentText,
  buildGovernanceCenterSectionTitle,
  buildGovernanceCenterSubmittedMeta,
  buildGovernanceCenterSummaryCardCopy,
  buildGovernanceCenterTimelineTitle,
  getGovernanceCenterAppealStatusLabel,
  getGovernanceCenterModerationStatusLabel,
  getGovernanceCenterTargetLabel
} from '../../utils/governance-center-copy';
import {
  buildGovernanceCenterAudiencePresentation,
  buildMarketplaceUserSyncKeys
} from '../../utils/marketplace-audience-ui';
import { getMarketplaceAudienceMode } from '../../utils/trade-guard';
import { formatTime } from '../../utils/time';
import { pushUrlByContext } from '../../utils/ui-context-actions';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';

@Entry
@Component
struct GovernanceCenterPage {
  @State currentUser: User | null = null;
  @State governanceSummary: GovernanceUserSummary | null = null;
  @State governanceActions: GovernanceAction[] = [];
  @State moderationRecords: ModerationRecord[] = [];
  @State appealRecords: AppealRecord[] = [];
  @State isLoading: boolean = false;
  @State errorText: string = '';
  private syncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    void this.refresh();
    this.bindSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    this.syncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.syncUnsubscribers = [];
  }

  private bindSync(): void {
    if (this.syncUnsubscribers.length > 0) {
      return;
    }
    const keys = [...buildMarketplaceUserSyncKeys(), 'moderation:changed', 'appeals:changed', 'governance:changed'];
    this.syncUnsubscribers = keys.map((key: string) => appContext.sync.subscribe(key, () => {
      void this.refresh();
    }));
  }

  private async refresh(): Promise<void> {
    this.currentUser = appContext.getCurrentUser();
    if (!this.currentUser || this.currentUser.role === 'admin') {
      this.governanceSummary = null;
      this.governanceActions = [];
      this.moderationRecords = [];
      this.appealRecords = [];
      this.errorText = '';
      return;
    }

    this.isLoading = true;
    const governanceResult = await appContext.governance.getUserSummary(this.currentUser.id);
    const governanceActionsResult = await appContext.governance.listActionsByUser(this.currentUser.id);
    const moderationResult = await appContext.moderation.listMyModerationRecords(this.currentUser.id);
    const appealResult = await appContext.appeal.listMyAppeals(this.currentUser.id);
    this.isLoading = false;

    this.governanceSummary = governanceResult.ok ? governanceResult.data ?? null : null;
    this.governanceActions = governanceActionsResult.ok
      ? (governanceActionsResult.data ?? []).filter((item: GovernanceAction) => item.active)
      : [];
    this.moderationRecords = moderationResult.ok ? (moderationResult.data ?? []) : [];
    this.appealRecords = appealResult.ok ? (appealResult.data ?? []) : [];

    if (!governanceResult.ok) {
      this.errorText = governanceResult.message;
      return;
    }
    if (!governanceActionsResult.ok) {
      this.errorText = governanceActionsResult.message;
      return;
    }
    if (!moderationResult.ok) {
      this.errorText = moderationResult.message;
      return;
    }
    if (!appealResult.ok) {
      this.errorText = appealResult.message;
      return;
    }
    this.errorText = '';
  }

  private getAudiencePresentation() {
    return buildGovernanceCenterAudiencePresentation(getMarketplaceAudienceMode(this.currentUser));
  }

  private getGovernanceSummaryPresentation(): GovernanceSummaryPresentation {
    return buildGovernanceSummaryPresentation(this.governanceSummary ?? {
      userId: this.currentUser?.id ?? '',
      activeActionTypes: [],
      totalActionCount: 0,
      openCaseCount: 0,
      latestActionAt: 0
    });
  }

  private getGovernanceActionPresentation(record: GovernanceAction): GovernanceActiveActionPresentation {
    return buildGovernanceActiveActionPresentation(record);
  }

  private openPrimaryAction(): void {
    const presentation = this.getAudiencePresentation();
    if (presentation.primaryAction === 'login') {
      pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
      return;
    }
    if (presentation.primaryAction === 'admin') {
      pushUrlByContext(this, { url: 'pages/Admin/AdminModerationPage' });
    }
  }

  private getOpenCaseCount(): number {
    return this.moderationRecords.filter((item: ModerationRecord) => item.status !== 'closed').length;
  }

  private getOpenAppealCount(): number {
    return this.appealRecords.filter((item: AppealRecord) => item.status === 'pending' || item.status === 'in_review').length;
  }

  private getActiveGovernanceCount(): number {
    return this.governanceActions.length;
  }

  private getRelatedAppeals(recordId: string): AppealRecord[] {
    return this.appealRecords.filter((item: AppealRecord) => item.moderationRecordId === recordId);
  }

  private getModerationTimelineSteps(record: ModerationRecord): GovernanceTimelineStep[] {
    return buildModerationTimelineSteps(record, this.getRelatedAppeals(record.id));
  }

  private getModerationTimelineSummary(record: ModerationRecord): string {
    return buildGovernanceCenterTimelineLabel(record, this.getRelatedAppeals(record.id));
  }

  private getAppealTimelineSteps(record: AppealRecord): GovernanceTimelineStep[] {
    return buildAppealTimelineSteps(record);
  }

  private getAppealTimelineSummary(record: AppealRecord): string {
    return buildAppealTimelineSummary(record);
  }

  private resolveLinkedModerationRecordTitle(record: AppealRecord): string {
    const linkedRecord = this.moderationRecords.find((item: ModerationRecord) => item.id === record.moderationRecordId) ?? null;
    if (linkedRecord === null) {
      return '';
    }
    return buildGovernanceCenterRecordTitle(linkedRecord.targetType, linkedRecord.reason);
  }

  private openSubmitAppealPage(record: ModerationRecord): void {
    pushUrlByContext(this, {
      url: 'pages/Moderation/SubmitAppealPage',
      params: {
        moderationRecordId: record.id,
        title: buildGovernanceCenterAppealSubmitTitle(record.reason)
      }
    });
  }

  @Builder
  private buildSummaryCard(label: string, value: number, accent: string, helper: string): void {
    Column({ space: 6 }) {
      Text(label)
        .width('100%')
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      Text(`${value}`)
        .width('100%')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)

      Text(helper)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8F877D')
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildGovernanceSummaryPanel(): void {
    const presentation = this.getGovernanceSummaryPresentation();
    const background = presentation.tone === 'warning' ? '#F8F2E9' : '#EEF6F1';
    const border = presentation.tone === 'warning' ? '#E9DAC9' : '#D8EAD9';
    const titleColor = presentation.tone === 'warning' ? '#7A4B17' : '#237B46';

    Column({ space: 8 }) {
      Text(presentation.title)
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(titleColor)

      Text(presentation.description)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#6F665D')

      if (presentation.badges.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
          ForEach(presentation.badges, (badge: string) => {
            Text(badge)
              .fontSize(11)
              .fontColor(titleColor)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#FFFDFC')
              .borderRadius(12)
              .border({ width: 1, color: border })
              .margin({ right: 8, bottom: 8 })
          }, (badge: string) => badge)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(background)
    .borderRadius(18)
    .border({ width: 1, color: border })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildActiveGovernanceActionCard(record: GovernanceAction): void {
    const presentation = this.getGovernanceActionPresentation(record);
    const backgroundColor = presentation.tone === 'warning' ? '#FFF4EA' : '#F2F8F3';
    const borderColor = presentation.tone === 'warning' ? '#F0DEC9' : '#D8EAD9';
    const titleColor = presentation.tone === 'warning' ? '#9A5B1F' : '#237B46';

    Column({ space: 8 }) {
      Text(presentation.title)
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(titleColor)

      Text(presentation.detail)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#6F665D')

      Text(presentation.hint)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8F877D')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(backgroundColor)
    .borderRadius(18)
    .border({ width: 1, color: borderColor })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildTimelineStep(step: GovernanceTimelineStep): void {
    const isCurrent: boolean = step.state === 'current';
    const isDone: boolean = step.state === 'done';
    const background: string = isCurrent ? '#E8F0FF' : (isDone ? '#F2ECE5' : '#F8F5F1');
    const border: string = isCurrent ? '#C9D8FF' : (isDone ? '#DDD3C8' : '#E8DED2');
    const textColor: string = isCurrent ? '#2F6BFF' : (isDone ? '#5E5851' : '#A59C92');

    Text(step.label)
      .fontSize(11)
      .fontColor(textColor)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor(background)
      .borderRadius(12)
      .border({ width: 1, color: border })
  }

  @Builder
  private buildTimelineSection(title: string, summary: string, steps: GovernanceTimelineStep[]): void {
    Column({ space: 8 }) {
      Text(title)
        .width('100%')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#5E5851')

      Text(summary)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8F877D')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
        ForEach(steps, (step: GovernanceTimelineStep) => {
          Row() {
            this.buildTimelineStep(step)
          }
          .margin({ right: 8, bottom: 8 })
        }, (step: GovernanceTimelineStep) => `${step.key}-${step.state}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FBF8F4')
    .borderRadius(16)
    .border({ width: 1, color: '#EEE4D8' })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildModerationCard(record: ModerationRecord): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(getGovernanceCenterTargetLabel(record.targetType))
          .fontSize(12)
          .fontColor('#A86B00')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F5EBDD')
          .borderRadius(12)

        Text(getGovernanceCenterModerationStatusLabel(record.status))
          .fontSize(12)
          .fontColor('#2F6BFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E8F0FF')
          .borderRadius(12)
      }
      .width('100%')

      Text(buildGovernanceCenterRecordTitle(record.targetType, record.reason))
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(buildGovernanceCenterRecordDescription(record.description))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
        .maxLines(3)

      this.buildTimelineSection(
        buildGovernanceCenterTimelineTitle('moderation'),
        this.getModerationTimelineSummary(record),
        this.getModerationTimelineSteps(record)
      )

      Text(buildGovernanceCenterSubmittedMeta(formatTime(record.createdAt), formatTime(record.updatedAt)))
        .width('100%')
        .fontSize(12)
        .fontColor('#8F877D')

      if (canSubmitAppealForModerationRecord(record, this.getRelatedAppeals(record.id))) {
        Button(buildGovernanceCenterAppealButtonLabel())
          .width('100%')
          .height(40)
          .backgroundColor('#E8F0FF')
          .fontColor('#2F6BFF')
          .borderRadius(14)
          .onClick(() => this.openSubmitAppealPage(record))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  private buildAppealCard(record: AppealRecord): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(buildGovernanceCenterAppealBadgeLabel())
          .fontSize(12)
          .fontColor('#237B46')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E8F5EA')
          .borderRadius(12)

        Text(getGovernanceCenterAppealStatusLabel(record.status))
          .fontSize(12)
          .fontColor('#5E5851')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F2ECE5')
          .borderRadius(12)
      }
      .width('100%')

      Text(buildGovernanceCenterBadgeRecordTitle(buildGovernanceCenterAppealBadgeLabel(), record.reason))
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(buildGovernanceCenterRecordDescription(record.description))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
        .maxLines(3)

      this.buildTimelineSection(
        buildGovernanceCenterTimelineTitle('appeal'),
        this.getAppealTimelineSummary(record),
        this.getAppealTimelineSteps(record)
      )

      if (record.reviewComment !== undefined && record.reviewComment.length > 0) {
        Text(buildGovernanceCenterReviewCommentText(record.reviewComment))
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8F877D')
      }

      Text(buildGovernanceCenterAppealMetaSummary(
        this.resolveLinkedModerationRecordTitle(record),
        formatTime(record.createdAt),
        formatTime(record.updatedAt)
      ))
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8F877D')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_COLOR })
  }

  build() {
    const presentation = this.getAudiencePresentation();
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          Text(buildGovernanceCenterPageTitle())
            .width('100%')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(presentation.headerDescription)
            .width('100%')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (presentation.readOnlyHint.length > 0) {
          Text(presentation.readOnlyHint)
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#8C867F')
            .padding(16)
            .backgroundColor('#F8F2E9')
            .borderRadius(18)
            .border({ width: 1, color: '#E9DAC9' })
        }

        if (this.currentUser && this.currentUser.role !== 'admin') {
          this.buildGovernanceSummaryPanel()
        }

        if (!this.currentUser || this.currentUser.role === 'admin') {
          EmptyState({
            title: presentation.emptyTitle,
            description: presentation.emptyDescription
          })
          if (presentation.primaryAction !== 'none') {
            Button(presentation.primaryActionLabel)
              .width('100%')
              .height(44)
              .backgroundColor('#2F6BFF')
              .fontColor('#FFFFFF')
              .borderRadius(16)
              .onClick(() => this.openPrimaryAction())
          }
        } else if (this.isLoading) {
          LoadingState(buildGovernanceCenterLoadingCopy())
        } else if (this.errorText.length > 0) {
          ErrorState({
            title: buildGovernanceCenterErrorTitle(),
            description: this.errorText
          })
        } else if (this.moderationRecords.length === 0 && this.appealRecords.length === 0 && this.governanceActions.length === 0) {
          EmptyState({
            title: presentation.emptyTitle,
            description: presentation.emptyDescription
          })
        } else {
          Row({ space: 10 }) {
            this.buildSummaryCard(
              buildGovernanceCenterSummaryCardCopy('moderation').label,
              this.moderationRecords.length,
              '#A86B00',
              buildGovernanceCenterSummaryCardCopy('moderation').helper
            )
            this.buildSummaryCard(
              buildGovernanceCenterSummaryCardCopy('open_case').label,
              this.getOpenCaseCount(),
              '#2F6BFF',
              buildGovernanceCenterSummaryCardCopy('open_case').helper
            )
          }
          .width('100%')

          if (presentation.showAppealSection) {
            Row({ space: 10 }) {
              this.buildSummaryCard(
                buildGovernanceCenterSummaryCardCopy('appeal').label,
                this.appealRecords.length,
                '#237B46',
                buildGovernanceCenterSummaryCardCopy('appeal').helper
              )
              this.buildSummaryCard(
                buildGovernanceCenterSummaryCardCopy('open_appeal').label,
                this.getOpenAppealCount(),
                '#B8643C',
                buildGovernanceCenterSummaryCardCopy('open_appeal').helper
              )
            }
            .width('100%')
          }

          if (this.getActiveGovernanceCount() > 0) {
            Column({ space: 10 }) {
              Text(buildGovernanceCenterSectionTitle('actions'))
                .width('100%')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(TITLE_COLOR)

              this.buildSummaryCard(
                buildGovernanceCenterSummaryCardCopy('active_action').label,
                this.getActiveGovernanceCount(),
                '#B8643C',
                buildGovernanceCenterSummaryCardCopy('active_action').helper
              )

              ForEach(this.governanceActions, (record: GovernanceAction) => {
                this.buildActiveGovernanceActionCard(record)
              }, (record: GovernanceAction) => `${record.id}-${record.updatedAt}`)
            }
            .width('100%')
          }

          Column({ space: 10 }) {
            Text(buildGovernanceCenterSectionTitle('moderation'))
              .width('100%')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(TITLE_COLOR)

            ForEach(this.moderationRecords, (record: ModerationRecord) => {
              this.buildModerationCard(record)
            }, (record: ModerationRecord) => `${record.id}-${record.status}-${record.updatedAt}`)
          }
          .width('100%')

          if (presentation.showAppealSection) {
            Column({ space: 10 }) {
              Text(buildGovernanceCenterSectionTitle('appeals'))
                .width('100%')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(TITLE_COLOR)

              if (this.appealRecords.length === 0) {
                EmptyState(buildGovernanceCenterAppealEmptyState())
              } else {
                ForEach(this.appealRecords, (record: AppealRecord) => {
                  this.buildAppealCard(record)
                }, (record: AppealRecord) => `${record.id}-${record.status}-${record.updatedAt}`)
              }
            }
            .width('100%')
          }
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
