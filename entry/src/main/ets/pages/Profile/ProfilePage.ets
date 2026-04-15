import { pushUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { appContext } from '../../app/app-context';
import { EmptyState } from '../../components/EmptyState';
import { uploadRemoteClient } from '../../services/upload-remote.client';
import { Campus, School, StudentVerification, User, VerificationMethod, VerificationStatus } from '../../types/domain';
import { normalizeManualCoverUrl } from '../../utils/cover-image';
import {
  buildCampusVerificationDraft,
  buildCampusIdentityPresentation,
  CampusVerificationMethodOption,
  CampusVerificationDraftInput,
  getCampusVerificationMethodLabel,
  getCampusVerificationMethodOptions,
  pickDefaultCampus,
  pickDefaultSchool,
  resolveCampusForSchoolSelection,
  validateCampusVerificationDraft
} from '../../utils/campus-identity-ui';
import {
  FALLBACK_ACADEMIC_OPTION,
  findExactSchoolSelection,
  filterAcademicOptions,
  findSchoolSuggestions,
  listCollegeOptions,
  listMajorOptions,
  normalizeCollegeInput,
  normalizeMajorInput,
  shouldShowAcademicSuggestionPanel,
  shouldShowSchoolSuggestionPanel
} from '../../utils/campus-academics';
import {
  buildProfileVerificationLifecyclePresentation,
  buildVerificationEditorPresentation,
  resolveDisplayedVerificationStatus
} from '../../utils/campus-verification-lifecycle-ui';
import {
  buildCampusTrustTonePalette,
  buildPublicCampusTrustPresentation
} from '../../utils/campus-trust-ui';
import { formatTime } from '../../utils/time';
import {
  buildGovernanceCenterAudiencePresentation,
  buildMarketplaceUserSyncKeys
} from '../../utils/marketplace-audience-ui';
import { buildGovernanceCenterEntryActionLabel } from '../../utils/governance-center-copy';
import { getMarketplaceAudienceMode } from '../../utils/trade-guard';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const CARD_BORDER: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const PROFILE_INPUT_BACKGROUND: string = '#FFFFFF';
const PROFILE_INPUT_BORDER: string = '#DDD4C8';
const PROFILE_PICKER_LIMIT: number = 1;

@Entry
@Component
struct ProfilePage {
  @State user: User | null = null;
  @State nicknameDraft: string = '';
  @State avatarLocalPath: string = '';
  @State avatarPreviewUri: string = '';
  @State avatarManualUrl: string = '';
  @State isSaving: boolean = false;
  @State schoolOptions: School[] = [];
  @State campusOptions: Campus[] = [];
  @State schoolIdDraft: string = '';
  @State schoolNameDraft: string = '';
  @State campusIdDraft: string = '';
  @State campusNameDraft: string = '';
  @State studentNoDraft: string = '';
  @State gradeYearDraft: string = '';
  @State collegeNameDraft: string = '';
  @State majorNameDraft: string = '';
  @State schoolInputVersion: number = 0;
  @State collegeInputVersion: number = 0;
  @State majorInputVersion: number = 0;
  @State isCampusLoading: boolean = false;
  @State isCampusSaving: boolean = false;
  @State currentVerification: StudentVerification | null = null;
  @State verificationMethodDraft: VerificationMethod = 'MANUAL_STUDENT_CARD';
  @State verificationMaterialLocalPath: string = '';
  @State verificationMaterialPreviewUri: string = '';
  @State verificationMaterialManualUrl: string = '';
  @State isVerificationSubmitting: boolean = false;
  private schoolInputController: TextInputController = new TextInputController();
  private collegeInputController: TextInputController = new TextInputController();
  private majorInputController: TextInputController = new TextInputController();
  private suppressSchoolDraftChange: boolean = false;
  private suppressCollegeDraftChange: boolean = false;
  private suppressMajorDraftChange: boolean = false;
  private pendingSchoolDraftValue: string = '';
  private pendingCollegeDraftValue: string = '';
  private pendingMajorDraftValue: string = '';
  private userSyncUnsubscribers: Array<() => void> = [];

  aboutToAppear(): void {
    this.refresh();
    this.bindUserSync();
  }

  onPageShow(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    this.userSyncUnsubscribers.forEach((unsubscribe: () => void) => unsubscribe());
    this.userSyncUnsubscribers = [];
  }

  private bindUserSync(): void {
    if (this.userSyncUnsubscribers.length > 0) {
      return;
    }
    this.userSyncUnsubscribers = buildMarketplaceUserSyncKeys().map((key: string) =>
      appContext.sync.subscribe(key, () => {
        this.refresh();
      })
    );
  }

  private refresh(): void {
    this.user = appContext.getCurrentUser();
    if (!this.user) {
      this.nicknameDraft = '';
      this.avatarPreviewUri = '';
      this.resetCampusDrafts();
      this.resetVerificationDrafts();
      return;
    }

    this.nicknameDraft = this.user.nickname;
    if (this.avatarLocalPath.length === 0 && this.avatarManualUrl.length === 0) {
      this.avatarPreviewUri = this.user.avatar ?? '';
    }
    this.syncCampusDraftsFromUser(this.user);
    void this.refreshCampusProfile();
  }

  private resetCampusDrafts(): void {
    this.schoolOptions = [];
    this.campusOptions = [];
    this.schoolIdDraft = '';
    this.schoolNameDraft = '';
    this.campusIdDraft = '';
    this.campusNameDraft = '';
    this.studentNoDraft = '';
    this.gradeYearDraft = '';
    this.collegeNameDraft = '';
    this.majorNameDraft = '';
  }

  private resetVerificationDrafts(): void {
    this.currentVerification = null;
    this.verificationMethodDraft = 'MANUAL_STUDENT_CARD';
    this.verificationMaterialLocalPath = '';
    this.verificationMaterialPreviewUri = '';
    this.verificationMaterialManualUrl = '';
    this.isVerificationSubmitting = false;
  }

  private syncCampusDraftsFromUser(user: User): void {
    this.schoolIdDraft = user.schoolId ?? this.schoolIdDraft;
    this.schoolNameDraft = user.schoolName ?? this.schoolNameDraft;
    this.campusIdDraft = user.campusId ?? this.campusIdDraft;
    this.campusNameDraft = user.campusName ?? this.campusNameDraft;
    this.studentNoDraft = user.studentNo ?? '';
    this.gradeYearDraft = user.gradeYear ? `${user.gradeYear}` : '';
    this.collegeNameDraft = user.collegeName ?? '';
    this.majorNameDraft = user.majorName ?? '';
  }

  private syncVerificationDraftsFromRecord(verification: StudentVerification | null): void {
    this.currentVerification = verification;
    if (!verification) {
      if (this.verificationMaterialLocalPath.length === 0 && this.verificationMaterialManualUrl.length === 0) {
        this.verificationMethodDraft = 'MANUAL_STUDENT_CARD';
        this.verificationMaterialPreviewUri = '';
        this.verificationMaterialManualUrl = '';
      }
      return;
    }

    this.verificationMethodDraft = verification.verificationMethod;
    if (this.verificationMaterialLocalPath.length === 0 && this.verificationMaterialManualUrl.length === 0) {
      const primaryMaterial = verification.materialUrls.length > 0 ? verification.materialUrls[0] : '';
      this.verificationMaterialPreviewUri = primaryMaterial;
      this.verificationMaterialManualUrl = primaryMaterial;
    }
  }

  private async refreshCampusProfile(): Promise<void> {
    if (!this.user) {
      return;
    }

    this.isCampusLoading = true;
    if (this.user.role === 'admin') {
      this.isCampusLoading = false;
      return;
    }
    const profileResult = await appContext.campus.getCurrentCampusProfile();
    if (profileResult.ok && profileResult.data) {
      this.user = profileResult.data;
      this.syncCampusDraftsFromUser(profileResult.data);
    }

    const verificationResult = await appContext.campus.getCurrentVerification();
    if (verificationResult.ok) {
      this.syncVerificationDraftsFromRecord(verificationResult.data ?? null);
    }

    const schoolsResult = await appContext.campus.listSchools();
    if (schoolsResult.ok) {
      this.schoolOptions = schoolsResult.data ?? [];
      this.applyDefaultSchool();
    }

    if (this.schoolIdDraft.length > 0) {
      await this.loadCampusesForSchool(this.schoolIdDraft, this.campusIdDraft);
      this.applyDefaultCampus();
    }
    this.isCampusLoading = false;
  }

  private applyDefaultSchool(): void {
    if (this.schoolIdDraft.length > 0 && this.schoolNameDraft.length > 0) {
      return;
    }
    const defaultSchool = pickDefaultSchool(this.schoolOptions);
    if (!defaultSchool) {
      return;
    }
    this.schoolIdDraft = defaultSchool.id;
    this.schoolNameDraft = defaultSchool.name;
  }

  private applyDefaultCampus(): void {
    if (this.campusIdDraft.length > 0 && this.campusNameDraft.length > 0) {
      return;
    }
    const defaultCampus = pickDefaultCampus(this.campusOptions);
    if (!defaultCampus) {
      return;
    }
    this.campusIdDraft = defaultCampus.id;
    this.campusNameDraft = defaultCampus.name;
  }

  private async loadCampusesForSchool(schoolId: string, preferredCampusId?: string): Promise<void> {
    if (schoolId.length === 0) {
      this.campusOptions = [];
      this.campusIdDraft = '';
      this.campusNameDraft = '';
      return;
    }

    const campusesResult = await appContext.campus.listCampuses(schoolId);
    if (!campusesResult.ok) {
      this.campusOptions = [];
      this.campusIdDraft = '';
      this.campusNameDraft = '';
      return;
    }

    this.campusOptions = campusesResult.data ?? [];
    const resolvedCampus = resolveCampusForSchoolSelection(this.campusOptions, schoolId, preferredCampusId);
    this.campusIdDraft = resolvedCampus?.id ?? '';
    this.campusNameDraft = resolvedCampus?.name ?? '';
  }

  private async selectSchool(school: School): Promise<void> {
    const previousSchoolName = this.schoolNameDraft;
    this.schoolIdDraft = school.id;
    this.schoolNameDraft = school.name;
    this.collegeNameDraft = '';
    this.majorNameDraft = '';
    this.schoolInputVersion += 1;
    this.collegeInputVersion += 1;
    this.majorInputVersion += 1;
    this.replaceInputValue(this.schoolInputController, previousSchoolName, this.schoolNameDraft, 'school');
    this.replaceInputValue(this.collegeInputController, '', this.collegeNameDraft, 'college');
    this.replaceInputValue(this.majorInputController, '', this.majorNameDraft, 'major');
    await this.loadCampusesForSchool(school.id, '');
  }

  private getSchoolSuggestions(): School[] {
    return findSchoolSuggestions(this.schoolOptions, this.schoolNameDraft);
  }

  private shouldShowSchoolSuggestions(): boolean {
    return shouldShowSchoolSuggestionPanel(this.schoolOptions, this.schoolNameDraft);
  }

  private getCollegeOptions(): string[] {
    return listCollegeOptions(this.schoolIdDraft, this.schoolNameDraft);
  }

  private getCollegeSuggestions(): string[] {
    return filterAcademicOptions(this.getCollegeOptions(), this.collegeNameDraft);
  }

  private shouldShowCollegeSuggestions(): boolean {
    return shouldShowAcademicSuggestionPanel(this.getCollegeOptions(), this.collegeNameDraft);
  }

  private getMajorOptions(): string[] {
    return listMajorOptions(this.schoolIdDraft, this.schoolNameDraft, this.collegeNameDraft);
  }

  private getMajorSuggestions(): string[] {
    return filterAcademicOptions(this.getMajorOptions(), this.majorNameDraft);
  }

  private shouldShowMajorSuggestions(): boolean {
    return shouldShowAcademicSuggestionPanel(this.getMajorOptions(), this.majorNameDraft);
  }

  private updateSchoolDraft(value: string): void {
    if (this.suppressSchoolDraftChange) {
      this.schoolNameDraft = value;
      if (value === this.pendingSchoolDraftValue) {
        this.suppressSchoolDraftChange = false;
        this.pendingSchoolDraftValue = '';
      }
      return;
    }
    const trimmedValue = value.trim();
    this.schoolNameDraft = value;
    const matched = findExactSchoolSelection(this.schoolOptions, trimmedValue);
    if (matched) {
      void this.selectSchool(matched);
      return;
    }
    this.schoolIdDraft = '';
    this.campusOptions = [];
    this.campusIdDraft = '';
    this.campusNameDraft = '';
    this.collegeNameDraft = '';
    this.majorNameDraft = '';
  }

  private updateCampusDraft(value: string): void {
    this.campusNameDraft = value;
    const trimmedValue = value.trim();
    const matched = this.campusOptions.find((item: Campus) => item.name === trimmedValue || (item.shortName ?? '') === trimmedValue);
    if (matched) {
      this.campusIdDraft = matched.id;
      this.campusNameDraft = matched.name;
      return;
    }
    this.campusIdDraft = '';
  }

  private selectCollegeSuggestion(value: string): void {
    const previousCollegeName = this.collegeNameDraft;
    const previousMajorName = this.majorNameDraft;
    this.collegeNameDraft = value;
    this.collegeInputVersion += 1;
    this.replaceInputValue(this.collegeInputController, previousCollegeName, this.collegeNameDraft, 'college');
    const majors = this.getMajorOptions();
    if (!majors.includes(this.majorNameDraft)) {
      this.majorNameDraft = '';
      this.majorInputVersion += 1;
      this.replaceInputValue(this.majorInputController, previousMajorName, this.majorNameDraft, 'major');
    }
  }

  private selectMajorSuggestion(value: string): void {
    const previousMajorName = this.majorNameDraft;
    this.majorNameDraft = value;
    this.majorInputVersion += 1;
    this.replaceInputValue(this.majorInputController, previousMajorName, this.majorNameDraft, 'major');
  }

  private replaceInputValue(
    controller: TextInputController,
    previousText: string,
    nextText: string,
    field: 'school' | 'college' | 'major'
  ): void {
    this.setFieldSuppression(field, true);
    this.setPendingFieldValue(field, nextText);
    const clearLength = Math.max(previousText.length, nextText.length) + 64;
    controller.caretPosition(0);
    controller.deleteText({ start: 0, end: clearLength });
    if (nextText.length > 0) {
      controller.addText(nextText);
      controller.caretPosition(nextText.length);
    }
  }

  private setFieldSuppression(field: 'school' | 'college' | 'major', enabled: boolean): void {
    if (field === 'school') {
      this.suppressSchoolDraftChange = enabled;
      return;
    }
    if (field === 'college') {
      this.suppressCollegeDraftChange = enabled;
      return;
    }
    this.suppressMajorDraftChange = enabled;
  }

  private setPendingFieldValue(field: 'school' | 'college' | 'major', value: string): void {
    if (field === 'school') {
      this.pendingSchoolDraftValue = value;
      return;
    }
    if (field === 'college') {
      this.pendingCollegeDraftValue = value;
      return;
    }
    this.pendingMajorDraftValue = value;
  }

  private getNormalizedCollegeDraft(): string {
    return normalizeCollegeInput(this.schoolIdDraft, this.schoolNameDraft, this.collegeNameDraft);
  }

  private getNormalizedMajorDraft(): string {
    return normalizeMajorInput(
      this.schoolIdDraft,
      this.schoolNameDraft,
      this.getNormalizedCollegeDraft(),
      this.majorNameDraft
    );
  }

  private currentAvatarDisplayUri(): string {
    if (this.avatarPreviewUri.length > 0) {
      return this.avatarPreviewUri;
    }
    return this.user?.avatar ?? '';
  }

  private buildAvatarText(): string {
    if (this.nicknameDraft.trim().length > 0) {
      return this.nicknameDraft.trim().slice(0, 1);
    }
    if (this.user && this.user.nickname.length > 0) {
      return this.user.nickname.slice(0, 1);
    }
    return '\u6211';
  }

  private buildRoleText(user: User): string {
    return user.role === 'admin' ? '\u7ba1\u7406\u5458' : '\u666e\u901a\u7528\u6237';
  }

  private buildStatusText(user: User): string {
    return user.status === 'active' ? '\u8d26\u53f7\u72b6\u6001\u6b63\u5e38' : '\u8d26\u53f7\u5f53\u524d\u53d7\u9650';
  }

  private openGovernanceCenter(): void {
    pushUrlByContext(this, { url: 'pages/Profile/GovernanceCenterPage' });
  }

  private getGovernanceCenterHelperText(): string {
    return buildGovernanceCenterAudiencePresentation(getMarketplaceAudienceMode(this.user)).headerDescription;
  }

  private getGovernanceCenterActionLabel(): string {
    const presentation = buildGovernanceCenterAudiencePresentation(getMarketplaceAudienceMode(this.user));
    if (presentation.primaryAction === 'login') {
      return buildGovernanceCenterEntryActionLabel('guest');
    }
    if (presentation.primaryAction === 'admin') {
      return buildGovernanceCenterEntryActionLabel('admin');
    }
    return buildGovernanceCenterEntryActionLabel('trader');
  }

  private hasPendingAvatarDraft(): boolean {
    if (this.avatarLocalPath.length > 0) {
      return true;
    }
    return normalizeManualCoverUrl(this.avatarManualUrl).length > 0;
  }

  private getCampusBadgeText(): string {
    return buildCampusIdentityPresentation(this.user).badgeText;
  }

  private getCampusBadgeTextColor(): string {
    return buildCampusIdentityPresentation(this.user).badgeTextColor;
  }

  private getCampusBadgeBackgroundColor(): string {
    return buildCampusIdentityPresentation(this.user).badgeBackgroundColor;
  }

  private getCampusSummaryText(): string {
    return buildCampusIdentityPresentation(this.user).summaryText;
  }

  private getCampusHelperText(): string {
    return buildCampusIdentityPresentation(this.user).helperText;
  }

  private getCampusRejectReasonText(): string {
    return buildCampusIdentityPresentation(this.user).rejectReasonText;
  }

  private getCampusTrustSummary(): string {
    if (!this.user) {
      return '';
    }
    return buildPublicCampusTrustPresentation(this.user).trustTags.join(' / ');
  }

  private getCampusTrustRiskText(): string {
    if (!this.user) {
      return '';
    }
    return buildPublicCampusTrustPresentation(this.user).riskText;
  }

  private getCampusTrustRiskLabel(): string {
    if (!this.user) {
      return '';
    }
    return buildPublicCampusTrustPresentation(this.user).riskLabel;
  }

  private getCampusTrustTone(): 'calm' | 'caution' | 'warning' {
    if (!this.user) {
      return 'calm';
    }
    return buildPublicCampusTrustPresentation(this.user).tone;
  }

  private getCampusTrustRiskTextColor(): string {
    return buildCampusTrustTonePalette(this.getCampusTrustTone()).riskBadgeTextColor;
  }

  private getCampusTrustRiskBackground(): string {
    return buildCampusTrustTonePalette(this.getCampusTrustTone()).riskBadgeBackgroundColor;
  }

  private hasPendingVerificationMaterialDraft(): boolean {
    if (this.verificationMaterialLocalPath.length > 0) {
      return true;
    }
    return normalizeManualCoverUrl(this.verificationMaterialManualUrl).length > 0;
  }

  private currentVerificationMaterialDisplayUri(): string {
    if (this.verificationMaterialPreviewUri.length > 0) {
      return this.verificationMaterialPreviewUri;
    }
    if (this.currentVerification && this.currentVerification.materialUrls.length > 0) {
      return this.currentVerification.materialUrls[0];
    }
    return '';
  }

  private currentVerificationStatusText(): string {
    const displayedStatus = resolveDisplayedVerificationStatus(this.user);
    if (!this.currentVerification) {
      return '\u8fd8\u6ca1\u6709\u63d0\u4ea4\u5b66\u751f\u8eab\u4efd\u6750\u6599';
    }
    if (this.currentVerification.status === VerificationStatus.VERIFIED && displayedStatus !== VerificationStatus.VERIFIED) {
      return '\u6821\u56ed\u8d44\u6599\u5df2\u53d8\u66f4\uff0c\u8bf7\u91cd\u65b0\u63d0\u4ea4\u5b66\u751f\u8eab\u4efd\u8ba4\u8bc1\uff0c\u5ba1\u6838\u901a\u8fc7\u540e\u624d\u4f1a\u6062\u590d\u516c\u5f00\u53ef\u4fe1\u8eab\u4efd\u5c55\u793a\u3002';
    }
    if (this.currentVerification.status === VerificationStatus.PENDING_REVIEW) {
      return '\u5df2\u63d0\u4ea4\u8ba4\u8bc1\u6750\u6599\uff0c\u7b49\u5f85\u5e73\u53f0\u5ba1\u6838';
    }
    if (this.currentVerification.status === VerificationStatus.VERIFIED) {
      return '\u8ba4\u8bc1\u5df2\u901a\u8fc7\uff0c\u5f53\u524d\u53ef\u5728\u524d\u53f0\u5c55\u793a\u6821\u5185\u53ef\u4fe1\u8eab\u4efd';
    }
    if (this.currentVerification.status === VerificationStatus.REJECTED) {
      return '\u6750\u6599\u88ab\u9a73\u56de\uff0c\u53ef\u4ee5\u4fee\u6539\u540e\u91cd\u65b0\u63d0\u4ea4';
    }
    return '\u8ba4\u8bc1\u72b6\u6001\u5df2\u66f4\u65b0\uff0c\u8bf7\u8054\u7cfb\u7ba1\u7406\u5458\u786e\u8ba4';
  }

  private getEffectiveVerificationEditorStatus(): VerificationStatus | null {
    const displayedStatus = resolveDisplayedVerificationStatus(this.user);
    if (!this.currentVerification) {
      return displayedStatus;
    }
    if (this.currentVerification.status === VerificationStatus.VERIFIED && displayedStatus !== VerificationStatus.VERIFIED) {
      return displayedStatus;
    }
    return this.currentVerification.status;
  }

  private currentVerificationRejectReasonText(): string {
    if (!this.currentVerification || !this.currentVerification.rejectReason || this.currentVerification.rejectReason.length === 0) {
      return '';
    }
    return `\u9a73\u56de\u539f\u56e0\uff1a${this.currentVerification.rejectReason}`;
  }

  private canEditVerificationSubmission(): boolean {
    return buildVerificationEditorPresentation(this.getEffectiveVerificationEditorStatus()).canEdit;
  }

  private canSubmitVerification(): boolean {
    return buildVerificationEditorPresentation(this.getEffectiveVerificationEditorStatus()).canSubmit;
  }

  private getVerificationSubmitButtonLabel(): string {
    if (this.isVerificationSubmitting) {
      return '\u63d0\u4ea4\u4e2d...';
    }
    if (
      this.currentVerification
      && this.currentVerification.status === VerificationStatus.VERIFIED
      && this.getEffectiveVerificationEditorStatus() === VerificationStatus.UNVERIFIED
    ) {
      return '\u91cd\u65b0\u63d0\u4ea4\u5b66\u751f\u8eab\u4efd\u8ba4\u8bc1';
    }
    return buildVerificationEditorPresentation(this.getEffectiveVerificationEditorStatus()).submitButtonLabel;
  }

  private getVerificationEditorLockedHint(): string {
    return buildVerificationEditorPresentation(this.getEffectiveVerificationEditorStatus()).lockedHintText;
  }

  private getVerificationMethodHint(): string {
    const matched = getCampusVerificationMethodOptions()
      .find((item) => item.method === this.verificationMethodDraft);
    return matched ? matched.hint : '';
  }

  private shouldShowVerificationSnapshot(): boolean {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).shouldShowSnapshot;
  }

  private getVerificationSnapshotTitle(): string {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).snapshotTitle;
  }

  private getVerificationSnapshotStatusText(): string {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).snapshotStatusText;
  }

  private getVerificationSnapshotCampusSummary(): string {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).snapshotCampusSummary;
  }

  private getVerificationSnapshotAcademicSummary(): string {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).snapshotAcademicSummary;
  }

  private getVerificationSnapshotDraftHelperText(): string {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).draftHelperText;
  }

  private getVerificationSnapshotReviewHintText(): string {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).reviewHintText;
  }

  private getVerificationSnapshotMaterialCountText(): string {
    return buildProfileVerificationLifecyclePresentation(this.user, this.currentVerification).materialCountText;
  }

  private getVerificationSnapshotSubmittedText(): string {
    if (!this.currentVerification) {
      return '';
    }
    return `提交时间 ${formatTime(this.currentVerification.submittedAt)}`;
  }

  private getVerificationSnapshotReviewedText(): string {
    if (!this.currentVerification || this.currentVerification.reviewedAt === undefined) {
      return '';
    }
    return `审核时间 ${formatTime(this.currentVerification.reviewedAt)}`;
  }

  private getVerificationSnapshotReviewCommentText(): string {
    if (!this.currentVerification || !this.currentVerification.reviewComment || this.currentVerification.reviewComment.trim().length === 0) {
      return '';
    }
    return `审核备注：${this.currentVerification.reviewComment.trim()}`;
  }

  private async chooseVerificationMaterialImage(): Promise<void> {
    try {
      const selectedUri = await this.selectAlbumImage();
      if (selectedUri.length === 0) {
        return;
      }

      const cachePath = this.copyImageToCache(selectedUri);
      this.removePendingVerificationMaterial(false);
      this.verificationMaterialLocalPath = cachePath;
      this.verificationMaterialPreviewUri = this.buildDisplayUri(cachePath);
      this.verificationMaterialManualUrl = '';
    } catch (_error) {
      showToastByContext(this, { message: '\u9009\u62e9\u8ba4\u8bc1\u6750\u6599\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5', duration: 1500 });
    }
  }

  private removePendingVerificationMaterial(showToast: boolean = true): void {
    if (this.verificationMaterialLocalPath.length > 0) {
      try {
        fileIo.unlinkSync(this.verificationMaterialLocalPath);
      } catch (_error) {
      }
    }

    this.verificationMaterialLocalPath = '';
    this.verificationMaterialPreviewUri = this.currentVerification && this.currentVerification.materialUrls.length > 0
      ? this.currentVerification.materialUrls[0]
      : '';
    this.verificationMaterialManualUrl = '';
    if (showToast) {
      showToastByContext(this, { message: '\u5df2\u6e05\u7a7a\u8ba4\u8bc1\u6750\u6599\u8349\u7a3f', duration: 1200 });
    }
  }

  private updateVerificationMaterialManualUrl(value: string): void {
    const normalized = normalizeManualCoverUrl(value);
    this.verificationMaterialManualUrl = normalized.length > 0 ? normalized : value;
    if (this.verificationMaterialLocalPath.length > 0) {
      return;
    }
    this.verificationMaterialPreviewUri = normalized;
  }

  private async submitVerification(): Promise<void> {
    if (this.isVerificationSubmitting) {
      return;
    }
    if (!this.user) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u63d0\u4ea4\u8ba4\u8bc1', duration: 1500 });
      return;
    }

    let materialUrl = '';
    if (this.verificationMaterialLocalPath.length > 0) {
      const session = appContext.getSession();
      if (!session) {
        showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u63d0\u4ea4\u8ba4\u8bc1', duration: 1500 });
        pushUrlByContext(this, { url: 'pages/Auth/LoginPage' });
        return;
      }
      const uploadResult = await uploadRemoteClient.uploadProductCover(session.token, this.verificationMaterialLocalPath);
      if (!uploadResult.ok || !uploadResult.data) {
        showToastByContext(this, {
          message: uploadResult.message.length > 0 ? uploadResult.message : '\u8ba4\u8bc1\u6750\u6599\u4e0a\u4f20\u5931\u8d25',
          duration: 1800
        });
        return;
      }
      materialUrl = uploadResult.data;
    } else {
      materialUrl = normalizeManualCoverUrl(this.verificationMaterialManualUrl);
    }

    const validationMessage = validateCampusVerificationDraft(new CampusVerificationDraftInput(
      this.schoolIdDraft,
      this.campusIdDraft,
      this.campusNameDraft,
      this.studentNoDraft,
      this.verificationMethodDraft,
      materialUrl.length > 0 ? [materialUrl] : [],
      this.parseGradeYear(),
      this.getNormalizedCollegeDraft(),
      this.getNormalizedMajorDraft()
    ));
    if (validationMessage.length > 0) {
      showToastByContext(this, { message: validationMessage, duration: 1500 });
      return;
    }

    this.isVerificationSubmitting = true;
    try {
      const result = await appContext.campus.submitVerification(buildCampusVerificationDraft(
        this.user,
        new CampusVerificationDraftInput(
          this.schoolIdDraft,
          this.campusIdDraft,
          this.campusNameDraft,
          this.studentNoDraft,
          this.verificationMethodDraft,
          [materialUrl],
          this.parseGradeYear(),
          this.getNormalizedCollegeDraft(),
          this.getNormalizedMajorDraft()
        )
      ));
      showToastByContext(this, { message: result.message, duration: 1500 });
      if (result.ok && result.data) {
        this.currentVerification = result.data;
        this.syncVerificationDraftsFromRecord(result.data);
        this.verificationMaterialLocalPath = '';
        this.verificationMaterialManualUrl = materialUrl;
        this.verificationMaterialPreviewUri = materialUrl;
        const refreshedUser = appContext.getCurrentUser();
        if (refreshedUser) {
          this.user = refreshedUser;
          this.syncCampusDraftsFromUser(refreshedUser);
        }
      }
    } finally {
      this.isVerificationSubmitting = false;
    }
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
    this.avatarPreviewUri = this.user?.avatar ?? '';
    if (showToast) {
      showToastByContext(this, { message: '\u5df2\u6e05\u7a7a\u5934\u50cf\u8349\u7a3f', duration: 1200 });
    }
  }

  private updateAvatarManualUrl(value: string): void {
    const normalized = normalizeManualCoverUrl(value);
    this.avatarManualUrl = normalized.length > 0 ? normalized : value;
    if (this.avatarLocalPath.length > 0) {
      return;
    }
    this.avatarPreviewUri = normalized.length > 0 ? normalized : (this.user?.avatar ?? '');
  }

  private parseGradeYear(): number | undefined {
    if (this.gradeYearDraft.trim().length === 0) {
      return undefined;
    }
    const value = Number(this.gradeYearDraft.trim());
    if (Number.isNaN(value) || value <= 0) {
      return undefined;
    }
    return Math.trunc(value);
  }

  private async saveProfile(): Promise<void> {
    if (this.isSaving) {
      return;
    }

    const session = appContext.getSession();
    if (!session) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u4fdd\u5b58\u8d44\u6599', duration: 1500 });
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

    this.isSaving = true;
    try {
      const result = await appContext.auth.updateProfile(this.nicknameDraft, avatarUrl);
      showToastByContext(this, { message: result.message, duration: 1500 });
      if (result.ok) {
        this.avatarLocalPath = '';
        this.avatarManualUrl = '';
        this.refresh();
      }
    } finally {
      this.isSaving = false;
    }
  }

  private async saveCampusProfile(): Promise<void> {
    if (this.isCampusSaving) {
      return;
    }
    if (!this.user) {
      showToastByContext(this, { message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u5b8c\u5584\u6821\u56ed\u8d44\u6599', duration: 1500 });
      return;
    }
    if (this.schoolIdDraft.length === 0) {
      showToastByContext(this, { message: '\u8bf7\u5148\u4ece\u8054\u60f3\u5217\u8868\u4e2d\u786e\u8ba4\u5b66\u6821', duration: 1500 });
      return;
    }
    if (this.campusNameDraft.trim().length === 0) {
      showToastByContext(this, { message: '\u8bf7\u5148\u586b\u5199\u6821\u533a\u540d\u79f0', duration: 1500 });
      return;
    }
    if (this.studentNoDraft.trim().length < 6) {
      showToastByContext(this, { message: '\u8bf7\u5148\u586b\u5199\u6b63\u786e\u7684\u5b66\u53f7', duration: 1500 });
      return;
    }

    this.isCampusSaving = true;
    try {
      const result = await appContext.campus.updateCampusProfile(
        this.schoolIdDraft,
        this.campusIdDraft,
        this.campusNameDraft.trim(),
        this.studentNoDraft.trim(),
        this.parseGradeYear(),
        this.getNormalizedCollegeDraft(),
        this.getNormalizedMajorDraft()
      );
      showToastByContext(this, { message: result.message, duration: 1500 });
      if (result.ok && result.data) {
        this.user = result.data;
        this.syncCampusDraftsFromUser(result.data);
      }
    } finally {
      this.isCampusSaving = false;
    }
  }

  private async selectAlbumImage(): Promise<string> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = PROFILE_PICKER_LIMIT;

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
  private buildAvatarVisual(size: number): void {
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

        Text(this.buildAvatarText())
          .fontSize(size >= 88 ? 28 : 22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2F6BFF')
      }
      .width(size)
      .height(size)
    }
  }

  @Builder
  private buildReadonlyField(label: string, value: string): void {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      Text(value)
        .fontSize(15)
        .fontColor(TITLE_COLOR)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(PROFILE_INPUT_BACKGROUND)
    .borderRadius(16)
    .border({ width: 1, color: PROFILE_INPUT_BORDER })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildReadonlyFieldCell(label: string, value: string): void {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      Text(value)
        .fontSize(15)
        .fontColor(TITLE_COLOR)
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(PROFILE_INPUT_BACKGROUND)
    .borderRadius(16)
    .border({ width: 1, color: PROFILE_INPUT_BORDER })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildEditableField(label: string, text: string, placeholder: string, onChange: (value: string) => void): void {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontColor(SUB_TEXT_COLOR)

      TextInput({ text, placeholder })
        .width('100%')
        .height(46)
        .fontSize(14)
        .fontColor(TITLE_COLOR)
        .placeholderColor('#A79F95')
        .backgroundColor(PROFILE_INPUT_BACKGROUND)
        .borderRadius(14)
        .border({ width: 1, color: PROFILE_INPUT_BORDER })
        .padding({ left: 12, right: 12 })
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildVersionedEditableField(
    label: string,
    text: string,
    placeholder: string,
    version: number,
    controller: TextInputController,
    onChange: (value: string) => void
  ): void {
    ForEach([version], (item: number) => {
      Column({ space: 6 }) {
        Text(label)
          .fontSize(12)
          .fontColor(SUB_TEXT_COLOR)

        TextInput({ text, placeholder, controller })
          .width('100%')
          .height(46)
          .fontSize(14)
          .fontColor(TITLE_COLOR)
          .placeholderColor('#A79F95')
          .backgroundColor(PROFILE_INPUT_BACKGROUND)
          .borderRadius(14)
          .border({ width: 1, color: PROFILE_INPUT_BORDER })
          .padding({ left: 12, right: 12 })
          .onChange(onChange)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }, (item: number) => `${label}-${item}`)
  }

  @Builder
  private buildSelectionChip(
    label: string,
    isSelected: boolean,
    onClick: () => void
  ): void {
    Button(label)
      .type(ButtonType.Normal)
      .height(36)
      .padding({ left: 14, right: 14 })
      .backgroundColor(isSelected ? '#E8F0FF' : '#FFFFFF')
      .fontColor(isSelected ? '#2F6BFF' : '#5E5851')
      .fontSize(13)
      .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
      .borderRadius(14)
      .border({ width: 1, color: isSelected ? '#C9D8FF' : PROFILE_INPUT_BORDER })
      .margin({ right: 8, bottom: 8 })
      .onClick(onClick)
  }

  @Builder
  private buildProfileHeader(): void {
    Column({ space: 4 }) {
      Text('\u4e2a\u4eba\u8d44\u6599')
        .width('100%')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)

      Text('\u5728\u8fd9\u91cc\u7edf\u4e00\u7ef4\u62a4\u4f60\u7684\u5934\u50cf\u3001\u6635\u79f0\u3001\u6821\u56ed\u8eab\u4efd\u548c\u8d26\u53f7\u57fa\u7840\u4fe1\u606f\u3002')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(SUB_TEXT_COLOR)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildGuestState(): void {
    Column({ space: 14 }) {
      EmptyState({
        title: '\u767b\u5f55\u540e\u7ef4\u62a4\u4f60\u7684\u4e2a\u4eba\u8d44\u6599',
        description: '\u5934\u50cf\u3001\u6635\u79f0\u548c\u6821\u56ed\u8eab\u4efd\u4fe1\u606f\u4f1a\u5728\u767b\u5f55\u540e\u540c\u6b65\u5230\u8fd9\u91cc\u3002'
      })

      Button('\u53bb\u767b\u5f55')
        .height(42)
        .type(ButtonType.Normal)
        .fontColor('#2F6BFF')
        .backgroundColor('#E8F0FF')
        .padding({ left: 14, right: 14 })
        .onClick(() => pushUrlByContext(this, { url: 'pages/Auth/LoginPage' }))
    }
    .width('100%')
  }

  @Builder
  private buildCampusIdentityCard(): void {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('\u6821\u56ed\u8eab\u4efd')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(this.getCampusSummaryText())
            .fontSize(13)
            .lineHeight(20)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.getCampusBadgeText())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getCampusBadgeTextColor())
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.getCampusBadgeBackgroundColor())
          .borderRadius(14)
      }
      .width('100%')

      Text(this.getCampusHelperText())
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8C867F')

      if (this.getCampusRejectReasonText().length > 0) {
        Text(this.getCampusRejectReasonText())
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#B8643C')
      }

      this.buildVersionedEditableField(
        '\u5b66\u6821',
        this.schoolNameDraft,
        '\u8f93\u5165\u5b66\u6821\u5173\u952e\u5b57',
        this.schoolInputVersion,
        this.schoolInputController,
        (value: string) => this.updateSchoolDraft(value)
      )

      if (this.shouldShowSchoolSuggestions()) {
        Column({ space: 8 }) {
          Text('\u5b66\u6821\u8054\u60f3')
            .fontSize(12)
            .fontColor(SUB_TEXT_COLOR)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.getSchoolSuggestions(), (school: School) => {
              this.buildSelectionChip(school.name, this.schoolIdDraft === school.id, () => {
                void this.selectSchool(school);
              })
            }, (school: School) => school.id)
          }
          .width('100%')
        }
        .width('100%')
      }

      this.buildEditableField('\u6821\u533a', this.campusNameDraft, '\u4f8b\u5982 \u4e3b\u6821\u533a / \u4e1c\u6821\u533a / \u5357\u533a', (value: string) => this.updateCampusDraft(value))

      this.buildEditableField('\u5b66\u53f7', this.studentNoDraft, '\u8bf7\u8f93\u5165\u5b66\u53f7', (value: string) => this.studentNoDraft = value)
      this.buildEditableField('\u5e74\u7ea7', this.gradeYearDraft, '\u4f8b\u5982 2024', (value: string) => this.gradeYearDraft = value)

      this.buildVersionedEditableField('\u9662\u7cfb', this.collegeNameDraft, '\u8f93\u5165\u9662\u7cfb\u5173\u952e\u5b57', this.collegeInputVersion, this.collegeInputController, (value: string) => {
        if (this.suppressCollegeDraftChange) {
          this.collegeNameDraft = value;
          if (value === this.pendingCollegeDraftValue) {
            this.suppressCollegeDraftChange = false;
            this.pendingCollegeDraftValue = '';
          }
          return;
        }
        this.collegeNameDraft = value;
        this.majorNameDraft = '';
      })

      if (this.shouldShowCollegeSuggestions()) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.getCollegeSuggestions(), (college: string) => {
            this.buildSelectionChip(college, this.collegeNameDraft === college, () => this.selectCollegeSuggestion(college))
          }, (college: string) => college)
        }
        .width('100%')
      }

      if (this.collegeNameDraft.trim().length > 0 && this.getNormalizedCollegeDraft() === FALLBACK_ACADEMIC_OPTION) {
        Text('\u5f53\u524d\u9662\u7cfb\u672a\u5339\u914d\u5230\u9884\u7f6e\u9879\uff0c\u4fdd\u5b58\u540e\u5c06\u6309\u201c\u5176\u4ed6\u201d\u5f52\u6863\u3002')
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8C867F')
      }

      this.buildVersionedEditableField('\u4e13\u4e1a', this.majorNameDraft, '\u8f93\u5165\u4e13\u4e1a\u5173\u952e\u5b57', this.majorInputVersion, this.majorInputController, (value: string) => {
        if (this.suppressMajorDraftChange) {
          this.majorNameDraft = value;
          if (value === this.pendingMajorDraftValue) {
            this.suppressMajorDraftChange = false;
            this.pendingMajorDraftValue = '';
          }
          return;
        }
        this.majorNameDraft = value;
      })

      if (this.shouldShowMajorSuggestions()) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.getMajorSuggestions(), (major: string) => {
            this.buildSelectionChip(major, this.majorNameDraft === major, () => this.selectMajorSuggestion(major))
          }, (major: string) => major)
        }
        .width('100%')
      }

      if (this.majorNameDraft.trim().length > 0 && this.getNormalizedMajorDraft() === FALLBACK_ACADEMIC_OPTION) {
        Text('\u5f53\u524d\u4e13\u4e1a\u672a\u5339\u914d\u5230\u9884\u7f6e\u9879\uff0c\u4fdd\u5b58\u540e\u5c06\u6309\u201c\u5176\u4ed6\u201d\u5f52\u6863\u3002')
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8C867F')
      }

      Text(this.getCampusTrustSummary())
        .width('100%')
        .fontSize(12)
        .fontColor('#8C867F')

      Text(this.getCampusTrustRiskLabel())
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getCampusTrustRiskTextColor())
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(this.getCampusTrustRiskBackground())
        .borderRadius(12)

      Text(this.getCampusTrustRiskText())
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8C867F')

      Row({ space: 10 }) {
        Button(this.isCampusSaving ? '\u4fdd\u5b58\u4e2d...' : '\u4fdd\u5b58\u6821\u56ed\u8d44\u6599')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.isCampusSaving ? '#BFD0FF' : '#2F6BFF')
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .enabled(!this.isCampusSaving)
          .onClick(() => {
            void this.saveCampusProfile();
          })

        Button(this.isCampusLoading ? '\u5237\u65b0\u4e2d...' : '\u5237\u65b0\u72b6\u6001')
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#E8F0FF')
          .fontColor('#2F6BFF')
          .borderRadius(14)
          .enabled(!this.isCampusLoading)
          .onClick(() => {
            void this.refreshCampusProfile();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildVerificationMethodOption(method: VerificationMethod, label: string): void {
    Text(label)
      .fontSize(13)
      .fontWeight(this.verificationMethodDraft === method ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.verificationMethodDraft === method ? '#2F6BFF' : '#5E5851')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(this.verificationMethodDraft === method ? '#E8F0FF' : '#F7F2EC')
      .borderRadius(16)
      .border({ width: 1, color: this.verificationMethodDraft === method ? '#C9D8FF' : '#E7DED2' })
      .onClick(() => this.verificationMethodDraft = method)
  }

  @Builder
  private buildVerificationMaterialPreview(): void {
    if (this.currentVerificationMaterialDisplayUri().length > 0) {
      Image(this.currentVerificationMaterialDisplayUri())
        .width('100%')
        .height(146)
        .borderRadius(18)
        .objectFit(ImageFit.Cover)
    } else {
      Column({ space: 10 }) {
        Text(getCampusVerificationMethodLabel(this.verificationMethodDraft))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#3D342D')

        Text('\u8fd8\u6ca1\u6709\u4e0a\u4f20\u8ba4\u8bc1\u6750\u6599\uff0c\u5f53\u524d\u663e\u793a\u4e3a\u63d0\u4ea4\u5360\u4f4d\u533a\u57df')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#7B756E')
      }
      .width('100%')
      .height(146)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .borderRadius(18)
      .linearGradient({
        angle: 135,
        colors: [['#E7DED2', 0], ['#F4EEE6', 1]]
      })
    }
  }

  @Builder
  private buildVerificationCard(): void {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('\u5b66\u751f\u8eab\u4efd\u8ba4\u8bc1')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(this.currentVerificationStatusText())
            .fontSize(13)
            .lineHeight(20)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.currentVerification) {
          Text(this.getCampusBadgeText())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getCampusBadgeTextColor())
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(this.getCampusBadgeBackgroundColor())
            .borderRadius(14)
        }
      }
      .width('100%')

      if (this.currentVerificationRejectReasonText().length > 0) {
        Text(this.currentVerificationRejectReasonText())
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#B8643C')
      }

      Text(this.getVerificationSnapshotDraftHelperText())
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8C867F')

      if (this.shouldShowVerificationSnapshot()) {
        Column({ space: 8 }) {
          Row() {
            Text(this.getVerificationSnapshotTitle())
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(TITLE_COLOR)

            Blank()

            Text(this.getVerificationSnapshotStatusText())
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getCampusBadgeTextColor())
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.getCampusBadgeBackgroundColor())
              .borderRadius(12)
          }
          .width('100%')

          Text(this.getVerificationSnapshotCampusSummary())
            .width('100%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(TITLE_COLOR)

          Text(this.getVerificationSnapshotAcademicSummary())
            .width('100%')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(SUB_TEXT_COLOR)

          Text(this.getVerificationSnapshotMaterialCountText())
            .width('100%')
            .fontSize(12)
            .fontColor('#8C867F')

          Text(this.getVerificationSnapshotSubmittedText())
            .width('100%')
            .fontSize(12)
            .fontColor('#8C867F')

          if (this.getVerificationSnapshotReviewedText().length > 0) {
            Text(this.getVerificationSnapshotReviewedText())
              .width('100%')
              .fontSize(12)
              .fontColor('#8C867F')
          }

          if (this.getVerificationSnapshotReviewCommentText().length > 0) {
            Text(this.getVerificationSnapshotReviewCommentText())
              .width('100%')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#8C867F')
          }

          if (this.getVerificationSnapshotReviewHintText().length > 0) {
            Text(this.getVerificationSnapshotReviewHintText())
              .width('100%')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#8C867F')
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FAF7F3')
        .borderRadius(16)
        .border({ width: 1, color: '#EEE4D9' })
      }

      if (this.canEditVerificationSubmission()) {
        Scroll() {
          Row({ space: 10 }) {
            ForEach(getCampusVerificationMethodOptions(), (item: CampusVerificationMethodOption) => {
              this.buildVerificationMethodOption(item.method, item.label)
            }, (item: CampusVerificationMethodOption) => item.method)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        Text(this.getVerificationMethodHint())
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8C867F')

        this.buildVerificationMaterialPreview()

        Row({ space: 10 }) {
          Button(this.verificationMaterialLocalPath.length > 0 ? '\u91cd\u65b0\u9009\u62e9\u6750\u6599' : '\u4ece\u76f8\u518c\u9009\u62e9')
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#2F6BFF')
            .fontColor('#FFFFFF')
            .borderRadius(14)
            .onClick(() => {
              void this.chooseVerificationMaterialImage();
            })

          if (this.hasPendingVerificationMaterialDraft()) {
            Button('\u6e05\u7a7a')
              .height(40)
              .padding({ left: 16, right: 16 })
              .backgroundColor('#F4E7DE')
              .fontColor('#C76E43')
              .borderRadius(14)
              .onClick(() => this.removePendingVerificationMaterial())
          }
        }
        .width('100%')

        TextInput({ text: this.verificationMaterialManualUrl, placeholder: '\u5728\u8fd9\u91cc\u7c98\u8d34\u8ba4\u8bc1\u56fe\u7247 URL' })
          .width('100%')
          .height(46)
          .fontSize(13)
          .fontColor(TITLE_COLOR)
          .placeholderColor('#A79F95')
          .backgroundColor(PROFILE_INPUT_BACKGROUND)
          .borderRadius(14)
          .border({ width: 1, color: PROFILE_INPUT_BORDER })
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => this.updateVerificationMaterialManualUrl(value))
      } else {
        Text(this.getVerificationEditorLockedHint())
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#8C867F')

        this.buildVerificationMaterialPreview()
      }

      Button(this.getVerificationSubmitButtonLabel())
        .width('100%')
        .height(44)
        .backgroundColor(this.isVerificationSubmitting || !this.canSubmitVerification() ? '#BFD0FF' : '#2F6BFF')
        .fontColor('#FFFFFF')
        .borderRadius(14)
        .enabled(!this.isVerificationSubmitting && this.canSubmitVerification())
        .onClick(() => {
          void this.submitVerification();
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildGovernanceEntryCard(): void {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('\u6cbb\u7406\u4e2d\u5fc3')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(this.getGovernanceCenterHelperText())
            .fontSize(13)
            .lineHeight(20)
            .fontColor(SUB_TEXT_COLOR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('\u8bb0\u5f55')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#237B46')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#E8F5EA')
          .borderRadius(14)
      }
      .width('100%')

      Text('\u4f60\u63d0\u4ea4\u8fc7\u7684\u4e3e\u62a5\u3001\u6295\u8bc9\u548c\u7533\u8bc9\uff0c\u4f1a\u5728\u8fd9\u91cc\u6301\u7eed\u66f4\u65b0\u5904\u7406\u72b6\u6001\u3001\u8865\u8bc1\u8981\u6c42\u548c\u590d\u6838\u7ed3\u679c\u3002')
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#8C867F')

      Button(this.getGovernanceCenterActionLabel())
        .width('100%')
        .height(44)
        .backgroundColor('#E8F0FF')
        .fontColor('#2F6BFF')
        .borderRadius(14)
        .onClick(() => this.openGovernanceCenter())
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BACKGROUND)
    .borderRadius(22)
    .border({ width: 1, color: CARD_BORDER })
  }

  @Builder
  private buildProfileForm(user: User): void {
    Column({ space: 16 }) {
      Column({ space: 16 }) {
        Column({ space: 10 }) {
          this.buildAvatarVisual(88)

          Button(this.avatarLocalPath.length > 0 ? '\u91cd\u65b0\u9009\u62e9\u5934\u50cf' : '\u4ece\u76f8\u518c\u9009\u62e9')
            .height(40)
            .padding({ left: 18, right: 18 })
            .backgroundColor('#2F6BFF')
            .fontColor('#FFFFFF')
            .borderRadius(14)
            .onClick(() => {
              void this.chooseAvatarImage();
            })

          Text('\u5934\u50cf\u548c\u6635\u79f0\u4f1a\u5728\u201c\u6211\u7684\u201d\u9875\u3001\u804a\u5929\u548c\u4ea4\u6613\u6d41\u7a0b\u91cc\u4f7f\u7528\u3002')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(SUB_TEXT_COLOR)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        this.buildEditableField('\u6635\u79f0', this.nicknameDraft, '\u8bf7\u8f93\u5165\u4f60\u60f3\u5c55\u793a\u7684\u6635\u79f0', (value: string) => this.nicknameDraft = value)
        this.buildReadonlyField('\u624b\u673a\u53f7', user.phone)

        Row({ space: 10 }) {
          this.buildReadonlyFieldCell('\u4fe1\u7528\u5206', `${user.creditScore}`)
          this.buildReadonlyFieldCell('\u8d26\u53f7\u7c7b\u578b', this.buildRoleText(user))
        }
        .width('100%')

        this.buildReadonlyField('\u8d26\u53f7\u72b6\u6001', this.buildStatusText(user))
      }
      .width('100%')
      .padding(18)
      .backgroundColor(CARD_BACKGROUND)
      .borderRadius(22)
      .border({ width: 1, color: CARD_BORDER })

      if (user.role !== 'admin') {
        this.buildCampusIdentityCard()
        this.buildVerificationCard()
        this.buildGovernanceEntryCard()
      }

      Column({ space: 10 }) {
        Row() {
          Text('\u6a21\u62df\u5668\u8f85\u52a9')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Blank()

          if (this.hasPendingAvatarDraft()) {
            Button('\u6e05\u7a7a\u8349\u7a3f')
              .height(34)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F4E7DE')
              .fontColor('#C76E43')
              .borderRadius(12)
              .fontSize(13)
              .onClick(() => this.removePendingAvatar())
          }
        }
        .width('100%')

        Text('\u5982\u679c\u6a21\u62df\u5668\u76f8\u518c\u91cc\u6ca1\u6709\u6d4b\u8bd5\u56fe\u7247\uff0c\u53ef\u4ee5\u5728\u8fd9\u91cc\u7c98\u8d34\u4e00\u5f20\u5934\u50cf URL\u3002')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(SUB_TEXT_COLOR)

        TextInput({ text: this.avatarManualUrl, placeholder: '\u5728\u8fd9\u91cc\u7c98\u8d34\u5934\u50cf\u56fe\u7247 URL' })
          .width('100%')
          .height(46)
          .fontSize(13)
          .fontColor(TITLE_COLOR)
          .placeholderColor('#A79F95')
          .backgroundColor(PROFILE_INPUT_BACKGROUND)
          .borderRadius(14)
          .border({ width: 1, color: PROFILE_INPUT_BORDER })
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => this.updateAvatarManualUrl(value))
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FAF7F3')
      .borderRadius(18)
      .border({ width: 1, color: '#EEE4D9' })

      Button(this.isSaving ? '\u4fdd\u5b58\u4e2d...' : '\u4fdd\u5b58\u57fa\u7840\u8d44\u6599')
        .width('100%')
        .height(46)
        .backgroundColor(this.isSaving ? '#BFD0FF' : '#2F6BFF')
        .fontColor('#FFFFFF')
        .borderRadius(16)
        .enabled(!this.isSaving)
        .onClick(() => {
          void this.saveProfile();
        })
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.buildProfileHeader()

        if (!this.user) {
          this.buildGuestState()
        } else {
          this.buildProfileForm(this.user)
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
}
