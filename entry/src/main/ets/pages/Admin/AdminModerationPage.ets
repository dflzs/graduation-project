import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import { chatRepository } from '../../repositories/chat.repo';
import { orderRepository } from '../../repositories/order.repo';
import { productRepository } from '../../repositories/product.repo';
import { userRepository } from '../../repositories/user.repo';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from '../../services/guard.service';
import { AppealRecord, ModerationRecord, OperationResult } from '../../types/domain';
import { buildAdminGuardSyncKeys } from '../../utils/admin-dashboard-sync';
import {
  AdminModerationAction,
  AdminModerationQueue,
  buildAdminModerationQueueSummary,
  buildAdminModerationRecordMetaSummary,
  getAdminModerationActionLabel,
  getAdminModerationAvailableActions,
  getAdminModerationRecommendedGovernanceAction,
  getAdminModerationPriorityLabel,
  getAdminModerationQueueDescription,
  getAdminModerationQueueLabel,
  getAdminModerationStatusLabel,
  getAdminModerationTargetLabel
} from '../../utils/admin-moderation-workbench';
import {
  AppealReviewAction,
  getAppealReviewActionLabel,
  getAppealReviewActions
} from '../../utils/appeal-ui';
import {
  buildAppealNextStepGuidance,
  buildDefaultAppealReviewComment,
  buildDefaultModerationAdminComment,
  buildAppealResultSummary,
  buildModerationRecoveryGuidance,
  buildModerationResultSummary
} from '../../utils/governance-resolution-copy';
import {
  buildAdminModerationBadgeLabel,
  buildAdminModerationCommentPlaceholder,
  buildAdminModerationDetailIntro,
  buildAdminModerationDetailTitle,
  buildAdminModerationEmptyState,
  buildAdminModerationErrorTitle,
  buildAdminModerationFactLabel,
  buildAdminModerationFactValue,
  buildAdminModerationGuidanceTitle,
  buildAdminModerationHeaderDescription,
  buildAdminModerationLinkedRecordReferenceValue,
  buildAdminModerationLinkedRecordMeta,
  buildAdminModerationListMetaSummary,
  buildAdminModerationLoadingCopy,
  buildAdminModerationPageTitle,
  buildAdminModerationReferenceValue,
  buildAdminModerationRecordDescription,
  buildAdminModerationRecordTitle,
  buildAdminModerationTargetReferenceValue,
  buildAdminModerationReviewCommentText,
  buildAdminModerationSelectionToast,
  buildAdminModerationSummaryCardCopy,
  buildAdminModerationUpdatedMeta,
  getAdminModerationAppealStatusLabel
} from '../../utils/admin-moderation-copy';
import { formatTime } from '../../utils/time';
import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';
const PANEL_BACKGROUND: string = '#F8F2E9';

@Entry
@Component
struct AdminModerationPage {
  @State moderationRecords: ModerationRecord[] = [];
  @State appealRecords: AppealRecord[] = [];
  @State activeQueue: AdminModerationQueue = AdminModerationQueue.PENDING;
  @State selectedRecordId: string = '';
  @State selectedAppealId: string = '';
  @State adminComment: string = '';
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
    const keys: string[] = [...buildAdminGuardSyncKeys(), 'moderation:changed', 'appeals:changed'];
    this.syncUnsubscribers = keys.map((key: string) => appContext.sync.subscribe(key, () => {
      void this.refresh();
    }));
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

    this.isLoading = true;
    const moderationResult = await appContext.moderation.listModerationRecords();
    const appealResult = await appContext.appeal.listAppeals();
    this.isLoading = false;

    if (!moderationResult.ok) {
      this.moderationRecords = [];
      this.appealRecords = [];
      this.errorText = moderationResult.message;
      return;
    }
    if (!appealResult.ok) {
      this.moderationRecords = [];
      this.appealRecords = [];
      this.errorText = appealResult.message;
      return;
    }

    this.moderationRecords = moderationResult.data ?? [];
    this.appealRecords = appealResult.data ?? [];
    this.errorText = '';
    this.ensureSelection();
  }

  private ensureSelection(): void {
    if (this.activeQueue === AdminModerationQueue.APPEAL) {
      const appealItems = this.getActiveAppealItems();
      if (!appealItems.some((item: AppealRecord) => item.id === this.selectedAppealId)) {
        this.selectedAppealId = appealItems.length > 0 ? appealItems[0].id : '';
        this.adminComment = '';
      }
      return;
    }

    const moderationItems = this.getActiveModerationItems();
    if (!moderationItems.some((item: ModerationRecord) => item.id === this.selectedRecordId)) {
      this.selectedRecordId = moderationItems.length > 0 ? moderationItems[0].id : '';
      this.adminComment = '';
    }
  }

  private switchQueue(queue: AdminModerationQueue): void {
    this.activeQueue = queue;
    this.ensureSelection();
  }

  private getModerationItemsByQueue(queue: AdminModerationQueue): ModerationRecord[] {
    return buildAdminModerationQueueSummary(this.moderationRecords).get(queue) ?? [];
  }

  private getActiveModerationItems(): ModerationRecord[] {
    return this.getModerationItemsByQueue(this.activeQueue);
  }

  private getActiveAppealItems(): AppealRecord[] {
    return this.appealRecords
      .slice()
      .sort((left: AppealRecord, right: AppealRecord) => right.updatedAt - left.updatedAt);
  }

  private getSelectedModerationRecord(): ModerationRecord | null {
    return this.getActiveModerationItems().find((item: ModerationRecord) => item.id === this.selectedRecordId) ?? null;
  }

  private getSelectedAppealRecord(): AppealRecord | null {
    return this.getActiveAppealItems().find((item: AppealRecord) => item.id === this.selectedAppealId) ?? null;
  }

  private getQueueCount(queue: AdminModerationQueue): number {
    if (queue === AdminModerationQueue.APPEAL) {
      return this.appealRecords.length;
    }
    return this.getModerationItemsByQueue(queue).length;
  }

  private getOpenModerationCount(): number {
    return this.moderationRecords.filter((record: ModerationRecord) => record.status !== 'closed').length;
  }

  private getOpenAppealCount(): number {
    return this.appealRecords.filter((record: AppealRecord) => record.status !== 'closed').length;
  }

  private buildSharedModerationComment(action: AdminModerationAction, record: ModerationRecord): string {
    return buildDefaultModerationAdminComment(action, record.targetType);
  }

  private buildSharedAppealComment(action: AppealReviewAction): string {
    return buildDefaultAppealReviewComment(action);
  }

  private async executeModerationAction(
    action: AdminModerationAction,
    record: ModerationRecord,
    comment: string
  ): Promise<OperationResult<ModerationRecord>> {
    const governanceAction = getAdminModerationRecommendedGovernanceAction(record.targetType, action);
    if (action === 'triage') {
      return appContext.moderation.triageModerationRecord(record.id, comment);
    }
    if (action === 'request_evidence') {
      return appContext.moderation.requestModerationEvidence(record.id, comment);
    }
    if (action === 'resolve_valid') {
      return appContext.moderation.reviewModerationRecordWithGovernance(
        record.id,
        'resolved_valid',
        comment,
        governanceAction
      );
    }
    if (action === 'resolve_partial') {
      return appContext.moderation.reviewModerationRecordWithGovernance(
        record.id,
        'resolved_partial',
        comment,
        governanceAction
      );
    }
    if (action === 'resolve_rejected') {
      return appContext.moderation.reviewModerationRecord(record.id, 'resolved_rejected', comment);
    }
    return appContext.moderation.closeModerationRecord(record.id, comment);
  }

  private async handleModerationAction(action: AdminModerationAction): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }

    const selected = this.getSelectedModerationRecord();
    if (!selected) {
      showToastByContext(this, { message: buildAdminModerationSelectionToast('moderation'), duration: 1200 });
      return;
    }

    const comment = this.adminComment.trim().length > 0
      ? this.adminComment.trim()
      : this.buildSharedModerationComment(action, selected);
    const result = await this.executeModerationAction(action, selected, comment);
    showToastByContext(this, { message: result.message, duration: 1500 });
    if (result.ok) {
      this.adminComment = '';
      void this.refresh();
    }
  }

  private async handleAppealAction(action: AppealReviewAction): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }

    const selected = this.getSelectedAppealRecord();
    if (!selected) {
      showToastByContext(this, { message: buildAdminModerationSelectionToast('appeal'), duration: 1200 });
      return;
    }

    const comment = this.adminComment.trim().length > 0
      ? this.adminComment.trim()
      : this.buildSharedAppealComment(action);
    let result: OperationResult<AppealRecord>;
    if (action === 'accept') {
      result = await appContext.appeal.reviewAppeal(selected.id, 'accepted', comment);
    } else if (action === 'reject') {
      result = await appContext.appeal.reviewAppeal(selected.id, 'rejected', comment);
    } else {
      result = await appContext.appeal.reviewAppeal(selected.id, 'closed', comment);
    }

    showToastByContext(this, { message: result.message, duration: 1500 });
    if (result.ok) {
      this.adminComment = '';
      void this.refresh();
    }
  }

  private getModerationActionBackground(action: AdminModerationAction): string {
    if (action === 'resolve_valid') {
      return '#2F6BFF';
    }
    if (action === 'resolve_rejected') {
      return '#F8ECE4';
    }
    if (action === 'close') {
      return '#F3EEE8';
    }
    return '#E8F0FF';
  }

  private getModerationActionTextColor(action: AdminModerationAction): string {
    if (action === 'resolve_valid') {
      return '#FFFFFF';
    }
    if (action === 'resolve_rejected') {
      return '#B8643C';
    }
    if (action === 'close') {
      return '#5E5851';
    }
    return '#2F6BFF';
  }

  private getModerationActionBorderColor(action: AdminModerationAction): string {
    if (action === 'resolve_valid') {
      return '#2F6BFF';
    }
    if (action === 'resolve_rejected') {
      return '#E8D1C2';
    }
    if (action === 'close') {
      return '#DED5CC';
    }
    return '#C9D8FF';
  }

  private getAppealActionBackground(action: AppealReviewAction): string {
    if (action === 'accept') {
      return '#237B46';
    }
    if (action === 'reject') {
      return '#F8ECE4';
    }
    return '#F3EEE8';
  }

  private getAppealActionTextColor(action: AppealReviewAction): string {
    if (action === 'accept') {
      return '#FFFFFF';
    }
    if (action === 'reject') {
      return '#B8643C';
    }
    return '#5E5851';
  }

  private getAppealActionBorderColor(action: AppealReviewAction): string {
    if (action === 'accept') {
      return '#237B46';
    }
    if (action === 'reject') {
      return '#E8D1C2';
    }
    return '#DED5CC';
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
  private buildQueueTab(queue: AdminModerationQueue): void {
    const selected = this.activeQueue === queue;
    Text(`${getAdminModerationQueueLabel(queue)} ${this.getQueueCount(queue)}`)
      .fontSize(13)
      .fontWeight(selected ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(selected ? '#2F6BFF' : '#5E5851')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(selected ? '#E8F0FF' : '#F7F2EC')
      .borderRadius(16)
      .onClick(() => this.switchQueue(queue))
  }

  @Builder
  private buildFactRow(label: string, value: string): void {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(12)
        .fontColor('#9A9185')

      Text(value)
        .layoutWeight(1)
        .fontSize(12)
        .fontColor('#4F4942')
        .maxLines(2)
    }
    .width('100%')
  }

  private resolveUserReference(userId: string): string {
    const nickname = userRepository.getById(userId)?.nickname ?? '';
    return buildAdminModerationReferenceValue(nickname, userId);
  }

  private resolveTargetReference(record: ModerationRecord): string {
    if (record.targetType === 'product_report') {
      const productId = record.relatedProductId ?? record.targetId;
      const productTitle = productRepository.getById(productId)?.title ?? '';
      return buildAdminModerationTargetReferenceValue(productTitle, record.targetId);
    }

    if (record.targetType === 'user_report') {
      const reportedUserId = record.reportedUserId ?? record.targetId;
      const nickname = userRepository.getById(reportedUserId)?.nickname ?? '';
      return buildAdminModerationTargetReferenceValue(nickname, record.targetId);
    }

    if (record.targetType === 'order_complaint') {
      const orderId = record.relatedOrderId ?? record.targetId;
      const order = orderRepository.getById(orderId);
      const productTitle = order ? (productRepository.getById(order.productId)?.title ?? '') : '';
      return buildAdminModerationTargetReferenceValue(productTitle, record.targetId);
    }

    const threadId = record.relatedThreadId ?? record.targetId;
    const thread = chatRepository.getThreadById(threadId);
    const productTitle = thread ? (productRepository.getById(thread.productId)?.title ?? '') : '';
    return buildAdminModerationTargetReferenceValue(productTitle, record.targetId);
  }

  private resolveLinkedModerationRecordReference(recordId: string): string {
    const linkedRecord = this.moderationRecords.find((item: ModerationRecord) => item.id === recordId) ?? null;
    if (linkedRecord === null) {
      return buildAdminModerationLinkedRecordReferenceValue('', recordId);
    }
    const title = buildAdminModerationRecordTitle(getAdminModerationTargetLabel(linkedRecord.targetType), linkedRecord.reason);
    return buildAdminModerationLinkedRecordReferenceValue(title, recordId);
  }

  @Builder
  private buildGuidancePanel(title: string, summary: string, guidance: string, background: string, border: string, accent: string): void {
    Column({ space: 8 }) {
      Text(title)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)

      Text(summary)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#4F4942')

      Text(guidance)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8A837B')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(background)
    .borderRadius(18)
    .border({ width: 1, color: border })
  }

  @Builder
  private buildModerationCard(record: ModerationRecord): void {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(getAdminModerationTargetLabel(record.targetType))
          .fontSize(12)
          .fontColor('#A86B00')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F5EBDD')
          .borderRadius(12)

        Text(getAdminModerationStatusLabel(record.status))
          .fontSize(12)
          .fontColor('#5E5851')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F2ECE5')
          .borderRadius(12)

        Text(getAdminModerationPriorityLabel(record.priority))
          .fontSize(12)
          .fontColor('#2F6BFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E8F0FF')
          .borderRadius(12)
      }
      .width('100%')

      Text(buildAdminModerationRecordTitle(getAdminModerationTargetLabel(record.targetType), record.reason))
        .width('100%')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)
        .maxLines(2)

      Text(buildAdminModerationRecordMetaSummary(record))
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8A837B')

      Text(buildAdminModerationRecordDescription(record.description))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
        .maxLines(3)

      Text(buildAdminModerationListMetaSummary('moderation', formatTime(record.updatedAt)))
        .width('100%')
        .fontSize(12)
        .fontColor('#9A9185')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.selectedRecordId === record.id ? '#F4F8FF' : SURFACE_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: this.selectedRecordId === record.id ? '#BFD2FF' : BORDER_COLOR })
    .onClick(() => this.selectedRecordId = record.id)
  }

  @Builder
  private buildAppealCard(record: AppealRecord): void {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(buildAdminModerationBadgeLabel('appeal'))
          .fontSize(12)
          .fontColor('#237B46')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E8F5EA')
          .borderRadius(12)

        Text(getAdminModerationAppealStatusLabel(record.status))
          .fontSize(12)
          .fontColor('#5E5851')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F2ECE5')
          .borderRadius(12)
      }
      .width('100%')

      Text(buildAdminModerationRecordTitle(buildAdminModerationBadgeLabel('appeal'), record.reason))
        .width('100%')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(buildAdminModerationRecordDescription(record.description))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
        .maxLines(3)

      Text(buildAdminModerationListMetaSummary('appeal', formatTime(record.updatedAt), record.moderationRecordId))
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8A837B')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.selectedAppealId === record.id ? '#EEF7F0' : SURFACE_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: this.selectedAppealId === record.id ? '#BEDBC7' : BORDER_COLOR })
    .onClick(() => this.selectedAppealId = record.id)
  }

  @Builder
  private buildModerationActionButton(action: AdminModerationAction): void {
    Button(getAdminModerationActionLabel(action))
      .layoutWeight(1)
      .height(42)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.getModerationActionTextColor(action))
      .backgroundColor(this.getModerationActionBackground(action))
      .border({ width: 1, color: this.getModerationActionBorderColor(action) })
      .borderRadius(16)
      .onClick(() => {
        void this.handleModerationAction(action);
      })
  }

  @Builder
  private buildAppealActionButton(action: AppealReviewAction): void {
    Button(getAppealReviewActionLabel(action))
      .layoutWeight(1)
      .height(42)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.getAppealActionTextColor(action))
      .backgroundColor(this.getAppealActionBackground(action))
      .border({ width: 1, color: this.getAppealActionBorderColor(action) })
      .borderRadius(16)
      .onClick(() => {
        void this.handleAppealAction(action);
      })
  }

  @Builder
  private buildModerationDetail(record: ModerationRecord): void {
    const availableActions = getAdminModerationAvailableActions(record.status);
    Column({ space: 12 }) {
      Text(buildAdminModerationDetailTitle('moderation'))
        .width('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(buildAdminModerationDetailIntro('moderation'))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)

      Column({ space: 8 }) {
        this.buildFactRow(buildAdminModerationFactLabel('target_type'), getAdminModerationTargetLabel(record.targetType))
        this.buildFactRow(buildAdminModerationFactLabel('status'), getAdminModerationStatusLabel(record.status))
        this.buildFactRow(buildAdminModerationFactLabel('priority'), getAdminModerationPriorityLabel(record.priority))
        this.buildFactRow(buildAdminModerationFactLabel('target_id'), this.resolveTargetReference(record))
        this.buildFactRow(buildAdminModerationFactLabel('reporter'), this.resolveUserReference(record.reporterId))
        if (record.reportedUserId !== undefined && record.reportedUserId.length > 0) {
          this.buildFactRow(buildAdminModerationFactLabel('reported_user'), this.resolveUserReference(record.reportedUserId))
        }
        this.buildFactRow(buildAdminModerationFactLabel('evidence_count'), buildAdminModerationFactValue('evidence_count', record.evidenceItems?.length ?? 0))
        this.buildFactRow(buildAdminModerationFactLabel('submitted_at'), buildAdminModerationFactValue('submitted_at', formatTime(record.createdAt)))
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#FFF8F2')
      .borderRadius(18)
      .border({ width: 1, color: '#E9DAC9' })

      Text(buildAdminModerationRecordTitle(getAdminModerationTargetLabel(record.targetType), record.reason))
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(buildAdminModerationRecordDescription(record.description))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)

      this.buildGuidancePanel(
        buildAdminModerationGuidanceTitle('moderation'),
        buildModerationResultSummary(record.status, record.targetType),
        buildModerationRecoveryGuidance(record.status, record.targetType),
        '#FFF8F2',
        '#E9DAC9',
        '#7A4B17'
      )

      if (record.adminComment !== undefined && record.adminComment.length > 0) {
        Text(buildAdminModerationReviewCommentText(record.adminComment))
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor(SUB_TEXT_COLOR)
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .border({ width: 1, color: BORDER_COLOR })
      }

      if (availableActions.length > 0) {
        TextArea({
          text: this.adminComment,
          placeholder: buildAdminModerationCommentPlaceholder('moderation')
        })
          .height(120)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .border({ width: 1, color: BORDER_COLOR })
          .padding(12)
          .onChange((value: string) => this.adminComment = value)

        Column({ space: 10 }) {
          ForEach(availableActions, (action: AdminModerationAction) => {
            Row({ space: 10 }) {
              this.buildModerationActionButton(action)
            }
            .width('100%')
          }, (action: AdminModerationAction) => action)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PANEL_BACKGROUND)
    .borderRadius(24)
    .border({ width: 1, color: '#E9DAC9' })
  }

  @Builder
  private buildAppealDetail(record: AppealRecord): void {
    const availableActions = getAppealReviewActions(record.status);
    Column({ space: 12 }) {
      Text(buildAdminModerationDetailTitle('appeal'))
        .width('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(buildAdminModerationDetailIntro('appeal'))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)

      Column({ space: 8 }) {
        this.buildFactRow(buildAdminModerationFactLabel('appeal_status'), getAdminModerationAppealStatusLabel(record.status))
        this.buildFactRow(buildAdminModerationFactLabel('linked_record'), this.resolveLinkedModerationRecordReference(record.moderationRecordId))
        this.buildFactRow(buildAdminModerationFactLabel('appellant'), this.resolveUserReference(record.appellantId))
        this.buildFactRow(buildAdminModerationFactLabel('evidence_count'), buildAdminModerationFactValue('evidence_count', record.evidenceItems.length))
        this.buildFactRow(buildAdminModerationFactLabel('submitted_at'), buildAdminModerationFactValue('submitted_at', formatTime(record.createdAt)))
        this.buildFactRow(buildAdminModerationFactLabel('updated_at'), buildAdminModerationFactValue('updated_at', formatTime(record.updatedAt)))
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#F3FAF4')
      .borderRadius(18)
      .border({ width: 1, color: '#D8EAD9' })

      Text(buildAdminModerationRecordTitle(buildAdminModerationBadgeLabel('appeal'), record.reason))
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text(buildAdminModerationRecordDescription(record.description))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)

      this.buildGuidancePanel(
        buildAdminModerationGuidanceTitle('appeal'),
        buildAppealResultSummary(record.status),
        buildAppealNextStepGuidance(record.status),
        '#F3FAF4',
        '#D8EAD9',
        '#237B46'
      )

      if (record.reviewComment !== undefined && record.reviewComment.length > 0) {
        Text(buildAdminModerationReviewCommentText(record.reviewComment))
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor(SUB_TEXT_COLOR)
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .border({ width: 1, color: BORDER_COLOR })
      }

      if (availableActions.length > 0) {
        TextArea({
          text: this.adminComment,
          placeholder: buildAdminModerationCommentPlaceholder('appeal')
        })
          .height(120)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .border({ width: 1, color: BORDER_COLOR })
          .padding(12)
          .onChange((value: string) => this.adminComment = value)

        Column({ space: 10 }) {
          ForEach(availableActions, (action: AppealReviewAction) => {
            Row({ space: 10 }) {
              this.buildAppealActionButton(action)
            }
            .width('100%')
          }, (action: AppealReviewAction) => action)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PANEL_BACKGROUND)
    .borderRadius(24)
    .border({ width: 1, color: '#E9DAC9' })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          Text(buildAdminModerationPageTitle())
            .width('100%')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(buildAdminModerationHeaderDescription())
            .width('100%')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Row({ space: 10 }) {
          this.buildSummaryCard(
            buildAdminModerationSummaryCardCopy('moderation').label,
            this.moderationRecords.length,
            '#2D2A26',
            buildAdminModerationSummaryCardCopy('moderation').helper
          )
          this.buildSummaryCard(
            buildAdminModerationSummaryCardCopy('appeal').label,
            this.appealRecords.length,
            '#237B46',
            buildAdminModerationSummaryCardCopy('appeal').helper
          )
        }
        .width('100%')

        Row({ space: 10 }) {
          this.buildSummaryCard(
            buildAdminModerationSummaryCardCopy('open_moderation').label,
            this.getOpenModerationCount(),
            '#A86B00',
            buildAdminModerationSummaryCardCopy('open_moderation').helper
          )
          this.buildSummaryCard(
            buildAdminModerationSummaryCardCopy('open_appeal').label,
            this.getOpenAppealCount(),
            '#B8643C',
            buildAdminModerationSummaryCardCopy('open_appeal').helper
          )
        }
        .width('100%')

        Row({ space: 10 }) {
          this.buildQueueTab(AdminModerationQueue.PENDING)
          this.buildQueueTab(AdminModerationQueue.AWAITING_EVIDENCE)
          this.buildQueueTab(AdminModerationQueue.APPEAL)
          this.buildQueueTab(AdminModerationQueue.CLOSED)
        }
        .width('100%')

        Column({ space: 8 }) {
          Text(getAdminModerationQueueLabel(this.activeQueue))
            .width('100%')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(getAdminModerationQueueDescription(this.activeQueue))
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(PANEL_BACKGROUND)
        .borderRadius(20)
        .border({ width: 1, color: '#E9DAC9' })

        if (this.isLoading) {
          LoadingState(buildAdminModerationLoadingCopy())
        } else if (this.errorText.length > 0) {
          ErrorState({
            title: buildAdminModerationErrorTitle(),
            description: this.errorText
          })
        } else if (
          (this.activeQueue === AdminModerationQueue.APPEAL && this.getActiveAppealItems().length === 0)
          || (this.activeQueue !== AdminModerationQueue.APPEAL && this.getActiveModerationItems().length === 0)
        ) {
          EmptyState(buildAdminModerationEmptyState(
            getAdminModerationQueueLabel(this.activeQueue),
            getAdminModerationQueueDescription(this.activeQueue)
          ))
        } else if (this.activeQueue === AdminModerationQueue.APPEAL) {
          const selectedAppeal = this.getSelectedAppealRecord();
          if (selectedAppeal) {
            this.buildAppealDetail(selectedAppeal)
          }

          Column({ space: 10 }) {
            ForEach(this.getActiveAppealItems(), (record: AppealRecord) => {
              this.buildAppealCard(record)
            }, (record: AppealRecord) => `${record.id}-${record.status}-${record.updatedAt}`)
          }
          .width('100%')
        } else {
          const selectedModeration = this.getSelectedModerationRecord();
          if (selectedModeration) {
            this.buildModerationDetail(selectedModeration)
          }

          Column({ space: 10 }) {
            ForEach(this.getActiveModerationItems(), (record: ModerationRecord) => {
              this.buildModerationCard(record)
            }, (record: ModerationRecord) => `${record.id}-${record.status}-${record.updatedAt}`)
          }
          .width('100%')
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
