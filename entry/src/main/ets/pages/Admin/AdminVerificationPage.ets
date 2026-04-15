import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { ErrorState } from '../../components/ErrorState';
import { LoadingState } from '../../components/LoadingState';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from '../../services/guard.service';
import { StudentVerification, VerificationStatus } from '../../types/domain';
import { formatTime } from '../../utils/time';
import {
  getVerificationMaterialPreviewUrls,
  groupVerificationByReviewTab
} from '../../utils/verification-review';
import {
  buildVerificationAcademicSummaryFromValues,
  buildVerificationCampusSummaryFromTexts
} from '../../utils/campus-verification-lifecycle-ui';
import {
  getPolishDangerButtonTone,
  getPolishPrimaryButtonTone
} from '../../utils/ui-polish-tokens';
import { buildAdminGuardSyncKeys } from '../../utils/admin-dashboard-sync';

const PAGE_BACKGROUND: string = '#F7F3EE';
const SURFACE_BACKGROUND: string = '#FFFDFC';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const BORDER_COLOR: string = '#E7DED2';
const DETAIL_BACKGROUND: string = '#F8F2E9';

enum VerificationTab {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected'
}

class NameCacheEntry {
  key: string;
  value: string;

  constructor(key: string, value: string) {
    this.key = key;
    this.value = value;
  }
}

function getVerificationStatusText(status: VerificationStatus): string {
  if (status === VerificationStatus.VERIFIED) {
    return '已通过';
  }
  if (status === VerificationStatus.REJECTED) {
    return '已驳回';
  }
  if (status === VerificationStatus.SUSPENDED) {
    return '已暂停';
  }
  if (status === VerificationStatus.UNVERIFIED) {
    return '未认证';
  }
  return '待审核';
}

function getVerificationStatusTextColor(status: VerificationStatus): string {
  if (status === VerificationStatus.VERIFIED) {
    return '#237B46';
  }
  if (status === VerificationStatus.REJECTED || status === VerificationStatus.SUSPENDED) {
    return '#B8643C';
  }
  if (status === VerificationStatus.UNVERIFIED) {
    return '#5E5851';
  }
  return '#A86B00';
}

function getVerificationStatusBackground(status: VerificationStatus): string {
  if (status === VerificationStatus.VERIFIED) {
    return '#E8F5EA';
  }
  if (status === VerificationStatus.REJECTED || status === VerificationStatus.SUSPENDED) {
    return '#F4E6DE';
  }
  if (status === VerificationStatus.UNVERIFIED) {
    return '#F1EEEA';
  }
  return '#F5EBDD';
}

function buildVerificationRenderKey(item: StudentVerification): string {
  return `${item.id}-${item.status}-${item.updatedAt}`;
}

function buildCampusCacheKey(schoolId: string, campusId: string): string {
  return `${schoolId}::${campusId}`;
}

@Entry
@Component
struct AdminVerificationPage {
  @State pendingItems: StudentVerification[] = [];
  @State approvedItems: StudentVerification[] = [];
  @State rejectedItems: StudentVerification[] = [];
  @State pendingSummaryCount: number = 0;
  @State approvedSummaryCount: number = 0;
  @State rejectedSummaryCount: number = 0;
  @State summaryRenderVersion: number = 0;
  @State activeTab: VerificationTab = VerificationTab.PENDING;
  @State selectedVerificationId: string = '';
  @State reviewComment: string = '';
  @State rejectReason: string = '';
  @State isLoading: boolean = false;
  @State errorText: string = '';
  @State schoolNameCache: NameCacheEntry[] = [];
  @State campusNameCache: NameCacheEntry[] = [];
  private isRefreshing: boolean = false;
  private adminGuardSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    void this.refresh();
    this.bindAdminGuardSync();
  }

  onPageShow(): void {
    void this.refresh();
  }

  aboutToDisappear(): void {
    this.adminGuardSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.adminGuardSyncUnsubscribers = [];
  }

  private bindAdminGuardSync(): void {
    if (this.adminGuardSyncUnsubscribers.length > 0) {
      return;
    }
    this.adminGuardSyncUnsubscribers = buildAdminGuardSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        void this.refresh();
      })
    );
  }

  private async refresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }

    if (!appContext.isAdmin()) {
      showToastByContext(this, { message: getAdminAccessDeniedMessage(appContext.getCurrentUser()), duration: 1500 });
      replaceUrlByContext(this, { url: 'pages/Profile/ProfilePage' });
      return;
    }

    this.isRefreshing = true;
    this.isLoading = true;
    try {
      const allResult = await appContext.campus.listVerificationApplications();
      if (allResult.ok) {
        this.applyVerificationData(allResult.data ?? []);
        this.errorText = '';
      } else {
        this.applyVerificationData([]);
        this.errorText = allResult.message;
      }

      await this.refreshNameCaches();
    } catch (error) {
      this.applyVerificationData([]);
      this.errorText = this.toErrorMessage(error as Object);
    } finally {
      this.syncSelectedVerification();
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  private applyVerificationData(items: StudentVerification[]): void {
    const grouped = groupVerificationByReviewTab(items);
    this.pendingItems = grouped.pending;
    this.approvedItems = grouped.approved;
    this.rejectedItems = grouped.rejected;
    this.pendingSummaryCount = grouped.pending.length;
    this.approvedSummaryCount = grouped.approved.length;
    this.rejectedSummaryCount = grouped.rejected.length;
    this.summaryRenderVersion += 1;
  }

  private toErrorMessage(error: Object): string {
    const maybeError = error as Record<string, Object>;
    if (typeof maybeError.message === 'string' && maybeError.message.length > 0) {
      return maybeError.message;
    }
    return '加载审核列表失败，请稍后重试';
  }

  private async refreshNameCaches(): Promise<void> {
    const allItems = this.getAllVisibleItems();
    const schoolIds: string[] = [];
    allItems.forEach((item: StudentVerification) => {
      const schoolId = `${item.schoolId ?? ''}`.trim();
      if (schoolId.length > 0 && !schoolIds.includes(schoolId)) {
        schoolIds.push(schoolId);
      }
    });

    if (schoolIds.length === 0) {
      this.schoolNameCache = [];
      this.campusNameCache = [];
      return;
    }

    const schoolResult = await appContext.campus.listSchools();
    const schoolEntries: NameCacheEntry[] = [];
    if (schoolResult.ok) {
      (schoolResult.data ?? []).forEach((school) => {
        if (schoolIds.includes(school.id)) {
          schoolEntries.push(new NameCacheEntry(school.id, school.name));
        }
      });
    }
    this.schoolNameCache = schoolEntries;

    const campusEntries: NameCacheEntry[] = [];
    for (let index = 0; index < schoolIds.length; index += 1) {
      const schoolId = schoolIds[index];
      const campusResult = await appContext.campus.listCampuses(schoolId);
      if (!campusResult.ok) {
        continue;
      }
      (campusResult.data ?? []).forEach((campus) => {
        campusEntries.push(new NameCacheEntry(buildCampusCacheKey(schoolId, campus.id), campus.name));
      });
    }
    this.campusNameCache = campusEntries;
  }

  private syncSelectedVerification(): void {
    const activeItems = this.getActiveItems();
    const hasSelected = activeItems.some((item: StudentVerification) => item.id === this.selectedVerificationId);
    if (hasSelected) {
      return;
    }
    this.selectedVerificationId = activeItems.length > 0 ? activeItems[0].id : '';
    this.reviewComment = '';
    this.rejectReason = '';
  }

  private getActiveItems(): StudentVerification[] {
    if (this.activeTab === VerificationTab.APPROVED) {
      return this.approvedItems;
    }
    if (this.activeTab === VerificationTab.REJECTED) {
      return this.rejectedItems;
    }
    return this.pendingItems;
  }

  private countItems(items: StudentVerification[]): number {
    let total: number = 0;
    items.forEach((_item: StudentVerification) => {
      total += 1;
    });
    return total;
  }

  private getPendingCount(): number {
    return this.pendingSummaryCount;
  }

  private getApprovedCount(): number {
    return this.approvedSummaryCount;
  }

  private getRejectedCount(): number {
    return this.rejectedSummaryCount;
  }

  private getAllVisibleItems(): StudentVerification[] {
    const merged: StudentVerification[] = [];
    this.pendingItems.forEach((item: StudentVerification) => merged.push(item));
    this.approvedItems.forEach((item: StudentVerification) => merged.push(item));
    this.rejectedItems.forEach((item: StudentVerification) => merged.push(item));
    return merged;
  }

  private getSelectedVerification(): StudentVerification | null {
    const selected = this.getActiveItems().find((item: StudentVerification) => item.id === this.selectedVerificationId);
    return selected ?? null;
  }

  private hasSelectedVerification(): boolean {
    return this.getSelectedVerification() !== null;
  }

  private isSelectedVerification(id: string): boolean {
    return this.selectedVerificationId === id;
  }

  private isTabSelected(tab: VerificationTab): boolean {
    return this.activeTab === tab;
  }

  private resolveSchoolName(item: StudentVerification): string {
    if (item.schoolName && item.schoolName.trim().length > 0) {
      return item.schoolName;
    }
    const found = this.schoolNameCache.find((entry: NameCacheEntry) => entry.key === item.schoolId);
    if (found) {
      return found.value;
    }
    if (item.schoolId.length > 0) {
      return item.schoolId;
    }
    return '学校未设置';
  }

  private resolveCampusName(item: StudentVerification): string {
    if (item.campusName && item.campusName.trim().length > 0) {
      return item.campusName;
    }
    if (item.schoolId.length > 0 && item.campusId.length > 0) {
      const cacheKey = buildCampusCacheKey(item.schoolId, item.campusId);
      const found = this.campusNameCache.find((entry: NameCacheEntry) => entry.key === cacheKey);
      if (found) {
        return found.value;
      }
    }
    if (item.campusId.length > 0) {
      return item.campusId;
    }
    return '校区未设置';
  }

  private getSchoolCampusText(item: StudentVerification): string {
    return buildVerificationCampusSummaryFromTexts(
      this.resolveSchoolName(item),
      this.resolveCampusName(item)
    );
  }

  private getStudentSummaryText(item: StudentVerification): string {
    const collegeName = item.collegeName && item.collegeName.trim().length > 0 ? item.collegeName : '院系未设置';
    const majorName = item.majorName && item.majorName.trim().length > 0 ? item.majorName : '专业未设置';
    const gradeText = item.gradeYear !== undefined && item.gradeYear > 0 ? `${item.gradeYear}` : '年级未设置';
    return `${collegeName} / ${majorName} / ${gradeText}`;
  }

  private getRejectReasonText(item: StudentVerification): string {
    return `驳回原因：${item.rejectReason ?? ''}`;
  }

  private getStudentNoText(item: StudentVerification): string {
    return `学号：${item.studentNo}`;
  }

  private getMaterialCountText(item: StudentVerification): string {
    return `材料数量：${item.materialUrls.length}`;
  }

  private getSubmittedAtText(item: StudentVerification): string {
    return `提交时间 ${formatTime(item.submittedAt)}`;
  }

  private getReviewedAtText(item: StudentVerification): string {
    if (item.reviewedAt === undefined) {
      return '';
    }
    return `审核时间 ${formatTime(item.reviewedAt)}`;
  }

  private getReviewCommentText(item: StudentVerification): string {
    if (!item.reviewComment || item.reviewComment.trim().length === 0) {
      return '';
    }
    return `审核备注：${item.reviewComment.trim()}`;
  }

  private hasMaterialPreview(item: StudentVerification): boolean {
    return getVerificationMaterialPreviewUrls(item).length > 0;
  }

  private switchTab(tab: VerificationTab): void {
    this.activeTab = tab;
    this.syncSelectedVerification();
  }

  private async approveSelected(): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }
    const selected = this.getSelectedVerification();
    if (!selected) {
      showToastByContext(this, { message: '请先选择一条申请', duration: 1200 });
      return;
    }

    const result = await appContext.campus.reviewVerification(
      selected.id,
      VerificationStatus.VERIFIED,
      this.reviewComment.trim().length > 0 ? this.reviewComment.trim() : '审核通过',
      ''
    );
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      this.reviewComment = '';
      this.rejectReason = '';
      void this.refresh();
    }
  }

  private async rejectSelected(): Promise<void> {
    const deniedMessage = getAdminActionDeniedMessage(appContext.getCurrentUser());
    if (deniedMessage.length > 0) {
      showToastByContext(this, { message: deniedMessage, duration: 1200 });
      return;
    }
    const selected = this.getSelectedVerification();
    if (!selected) {
      showToastByContext(this, { message: '请先选择一条申请', duration: 1200 });
      return;
    }
    if (this.rejectReason.trim().length === 0) {
      showToastByContext(this, { message: '请填写驳回原因', duration: 1200 });
      return;
    }

    const result = await appContext.campus.reviewVerification(
      selected.id,
      VerificationStatus.REJECTED,
      this.reviewComment.trim().length > 0 ? this.reviewComment.trim() : '审核驳回',
      this.rejectReason.trim()
    );
    showToastByContext(this, { message: result.message, duration: 1200 });
    if (result.ok) {
      this.reviewComment = '';
      this.rejectReason = '';
      void this.refresh();
    }
  }

  @Builder
  private buildSummaryCard(label: string, value: number, accent: string): void {
    Column({ space: 6 }) {
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
  private buildTabButton(tab: VerificationTab, label: string): void {
    Text(label)
      .fontSize(13)
      .fontWeight(this.isTabSelected(tab) ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.isTabSelected(tab) ? '#2F6BFF' : '#5E5851')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(this.isTabSelected(tab) ? '#E8F0FF' : '#F7F2EC')
      .borderRadius(16)
      .onClick(() => this.switchTab(tab))
  }

  @Builder
  private buildVerificationCard(item: StudentVerification): void {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text(item.studentNo)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(this.getSchoolCampusText(item))
            .fontSize(12)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(getVerificationStatusText(item.status))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(getVerificationStatusTextColor(item.status))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(getVerificationStatusBackground(item.status))
          .borderRadius(14)
      }
      .width('100%')

      Text(this.getStudentSummaryText(item))
        .width('100%')
        .fontSize(13)
        .fontColor('#5E5851')

      Text(`提交时间 ${formatTime(item.submittedAt)}`)
        .width('100%')
        .fontSize(12)
        .fontColor('#8C867F')

      if (item.rejectReason && item.rejectReason.length > 0) {
        Text(this.getRejectReasonText(item))
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#B8643C')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isSelectedVerification(item.id) ? '#F4F8FF' : SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: this.isSelectedVerification(item.id) ? '#BFD2FF' : BORDER_COLOR })
    .onClick(() => this.selectedVerificationId = item.id)
  }

  @Builder
  private buildDetailPanel(item: StudentVerification): void {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('审核详情')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('填写审核备注并完成通过或驳回操作。')
            .fontSize(13)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(getVerificationStatusText(item.status))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(getVerificationStatusTextColor(item.status))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(getVerificationStatusBackground(item.status))
          .borderRadius(14)
      }
      .width('100%')

      Text(this.getStudentNoText(item))
        .width('100%')
        .fontSize(13)
        .fontColor('#4E4740')

      Text(this.getMaterialCountText(item))
        .width('100%')
        .fontSize(13)
        .fontColor('#4E4740')
      Text(this.getSubmittedAtText(item))
        .width('100%')
        .fontSize(12)
        .fontColor('#8C867F')

      if (this.getReviewedAtText(item).length > 0) {
        Text(this.getReviewedAtText(item))
          .width('100%')
          .fontSize(12)
          .fontColor('#8C867F')
      }

      if (this.getReviewCommentText(item).length > 0) {
        Text(this.getReviewCommentText(item))
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8C867F')
      }

      Text('以下内容是用户提交时冻结的审核快照，不会随资料页当前编辑内容实时变化。')
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(SUB_TEXT_COLOR)

      Column({ space: 6 }) {
        Text('申请快照')
          .width('100%')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#4E4740')

        Text(this.getSchoolCampusText(item))
          .width('100%')
          .fontSize(12)
          .fontColor(SUB_TEXT_COLOR)

        Text(this.getStudentSummaryText(item))
          .width('100%')
          .fontSize(12)
          .fontColor(SUB_TEXT_COLOR)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .border({ width: 1, color: '#E7DED2' })

      Column({ space: 8 }) {
        Text('材料预览')
          .width('100%')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#4E4740')

        if (this.hasMaterialPreview(item)) {
          Scroll() {
            Row({ space: 10 }) {
              ForEach(getVerificationMaterialPreviewUrls(item), (url: string) => {
                Image(url)
                  .width(94)
                  .height(94)
                  .borderRadius(14)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#F2EADD')
                  .border({ width: 1, color: '#E4D7C6' })
              }, (url: string) => `material-${item.id}-${url}`)
            }
            .width('100%')
          }
          .width('100%')
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        } else {
          Text('暂无可预览材料')
            .width('100%')
            .fontSize(12)
            .fontColor('#8C867F')
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .border({ width: 1, color: '#E7DED2' })

      TextInput({ text: this.reviewComment, placeholder: '可选：填写审核备注（通过或驳回）' })
        .height(48)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .border({ width: 1, color: BORDER_COLOR })
        .onChange((value: string) => this.reviewComment = value)

      TextArea({ text: this.rejectReason, placeholder: '驳回必填：请写明需要修改的内容' })
        .height(110)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding(14)
        .border({ width: 1, color: BORDER_COLOR })
        .onChange((value: string) => this.rejectReason = value)

      if (item.status === VerificationStatus.PENDING_REVIEW) {
        Row({ space: 10 }) {
          Button('审核通过')
            .layoutWeight(1)
            .height(getPolishPrimaryButtonTone().height)
            .fontWeight(FontWeight.Bold)
            .fontColor(getPolishPrimaryButtonTone().textColor)
            .backgroundColor(getPolishPrimaryButtonTone().backgroundColor)
            .borderRadius(getPolishPrimaryButtonTone().radius)
            .border({ width: 1, color: getPolishPrimaryButtonTone().borderColor })
            .onClick(() => {
              void this.approveSelected();
            })

          Button('驳回')
            .layoutWeight(1)
            .height(getPolishDangerButtonTone().height)
            .fontWeight(FontWeight.Bold)
            .fontColor(getPolishDangerButtonTone().textColor)
            .backgroundColor(getPolishDangerButtonTone().backgroundColor)
            .borderRadius(getPolishDangerButtonTone().radius)
            .border({ width: 1, color: getPolishDangerButtonTone().borderColor })
            .onClick(() => {
              void this.rejectSelected();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(DETAIL_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: '#E9DAC9' })
  }

  @Builder
  private buildSelectedVerificationPanel(): void {
    if (this.hasSelectedVerification()) {
      ForEach(this.getActiveItems(), (item: StudentVerification) => {
        if (this.isSelectedVerification(item.id)) {
          this.buildDetailPanel(item);
        }
      }, (item: StudentVerification) => `detail-${buildVerificationRenderKey(item)}`);
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          Text('学生认证审核')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text('核验学生身份材料，保障校园交易身份可信。')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        ForEach([this.summaryRenderVersion], (_version: number) => {
          Row({ space: 10 }) {
            Column({ space: 6 }) {
              Text('待审核')
                .fontSize(12)
                .fontColor(SUB_TEXT_COLOR)

              Text(`${this.pendingSummaryCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#A86B00')
            }
            .layoutWeight(1)
            .padding(14)
            .backgroundColor(SURFACE_BACKGROUND)
            .borderRadius(18)
            .border({ width: 1, color: BORDER_COLOR })
            .alignItems(HorizontalAlign.Start)

            Column({ space: 6 }) {
              Text('已通过')
                .fontSize(12)
                .fontColor(SUB_TEXT_COLOR)

              Text(`${this.approvedSummaryCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#237B46')
            }
            .layoutWeight(1)
            .padding(14)
            .backgroundColor(SURFACE_BACKGROUND)
            .borderRadius(18)
            .border({ width: 1, color: BORDER_COLOR })
            .alignItems(HorizontalAlign.Start)

            Column({ space: 6 }) {
              Text('已驳回')
                .fontSize(12)
                .fontColor(SUB_TEXT_COLOR)

              Text(`${this.rejectedSummaryCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#B8643C')
            }
            .layoutWeight(1)
            .padding(14)
            .backgroundColor(SURFACE_BACKGROUND)
            .borderRadius(18)
            .border({ width: 1, color: BORDER_COLOR })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }, (_version: number) => `summary-${_version}`)

        Row({ space: 10 }) {
          this.buildTabButton(VerificationTab.PENDING, '待审核');
          this.buildTabButton(VerificationTab.APPROVED, '已通过');
          this.buildTabButton(VerificationTab.REJECTED, '已驳回');
        }
        .width('100%')

        if (this.isLoading) {
          LoadingState({
            title: '正在加载审核申请',
            description: '正在按状态整理审核列表，请稍候。'
          });
        } else if (this.errorText.length > 0 && this.getAllVisibleItems().length === 0) {
          ErrorState({
            title: '加载审核申请失败',
            description: this.errorText
          });
        } else if (this.getActiveItems().length === 0) {
          EmptyState({
            title: '当前标签暂无申请',
            description: '用户提交的认证申请会显示在这里。'
          });
        } else {
          this.buildSelectedVerificationPanel();

          Column({ space: 10 }) {
            ForEach(this.getActiveItems(), (item: StudentVerification) => {
              this.buildVerificationCard(item);
            }, (item: StudentVerification) => buildVerificationRenderKey(item));
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 24 })
      .justifyContent(FlexAlign.Start)
      .constraintSize({ minHeight: '100%' })
    }
    .height('100%')
    .width('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
