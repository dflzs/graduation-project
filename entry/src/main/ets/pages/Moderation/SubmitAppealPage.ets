import { appContext } from '../../app/app-context';
import { AppealEligibility } from '../../types/domain';
import {
  buildSubmitAppealButtonLabel,
  buildSubmitAppealDescriptionLabel,
  buildSubmitAppealDefaultReason,
  buildSubmitAppealDefaultTitle,
  buildSubmitAppealDescriptionPlaceholder,
  buildSubmitAppealPageHeading,
  buildSubmitAppealReasonLabel,
  buildSubmitAppealReasonPlaceholder,
  buildSubmitAppealValidationMessage
} from '../../utils/moderation-submit-copy';
import { backByContext, getParamsByContext, showToastByContext } from '../../utils/ui-context-actions';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const BORDER_COLOR: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const PRIMARY_COLOR: string = '#2F6BFF';

class SubmitAppealPageParams {
  moderationRecordId: string = '';
  title: string = '';
}

@Entry
@Component
struct SubmitAppealPage {
  @State moderationRecordId: string = '';
  @State title: string = '';
  @State reason: string = buildSubmitAppealDefaultReason();
  @State description: string = '';
  @State isSubmitting: boolean = false;
  @State eligibility: AppealEligibility | null = null;

  async aboutToAppear(): Promise<void> {
    const params = getParamsByContext<SubmitAppealPageParams>(this);
    this.moderationRecordId = params?.moderationRecordId ?? '';
    this.title = params?.title ?? buildSubmitAppealDefaultTitle();

    const currentUser = appContext.getCurrentUser();
    if (!currentUser || this.moderationRecordId.length === 0) {
      return;
    }
    const eligibilityResult = await appContext.appeal.checkAppealEligibility(this.moderationRecordId, currentUser.id);
    if (eligibilityResult.ok) {
      this.eligibility = eligibilityResult.data ?? null;
    }
  }

  private canSubmit(): boolean {
    return this.eligibility?.eligible === true;
  }

  private async submit(): Promise<void> {
    const currentUser = appContext.getCurrentUser();
    if (!currentUser) {
      showToastByContext(this, { message: buildSubmitAppealValidationMessage('login'), duration: 1200 });
      return;
    }
    if (!this.canSubmit()) {
      showToastByContext(this, {
        message: this.eligibility?.reason ?? buildSubmitAppealValidationMessage('eligibility'),
        duration: 1500
      });
      return;
    }
    if (this.reason.trim().length === 0) {
      showToastByContext(this, { message: buildSubmitAppealValidationMessage('reason'), duration: 1200 });
      return;
    }
    if (this.description.trim().length < 4) {
      showToastByContext(this, { message: buildSubmitAppealValidationMessage('description'), duration: 1200 });
      return;
    }

    this.isSubmitting = true;
    const result = await appContext.appeal.submitAppeal(
      this.moderationRecordId,
      currentUser.id,
      this.reason.trim(),
      this.description.trim()
    );
    this.isSubmitting = false;

    showToastByContext(this, { message: result.message, duration: 1500 });
    if (result.ok) {
      backByContext(this);
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          Text(buildSubmitAppealPageHeading())
            .width('100%')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TITLE_COLOR)

          Text(this.title)
            .width('100%')
            .fontSize(14)
            .lineHeight(22)
            .fontColor(SUB_TEXT_COLOR)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 14 }) {
          if (this.eligibility && this.eligibility.reason.length > 0) {
            Text(this.eligibility.reason)
              .width('100%')
              .fontSize(13)
              .lineHeight(20)
              .fontColor(this.canSubmit() ? '#237B46' : '#B8643C')
              .padding(14)
              .backgroundColor(this.canSubmit() ? '#E8F5EA' : '#F8ECE4')
              .borderRadius(16)
          }

          Text(buildSubmitAppealReasonLabel())
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(TITLE_COLOR)

          TextInput({ text: this.reason, placeholder: buildSubmitAppealReasonPlaceholder() })
            .height(46)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .border({ width: 1, color: BORDER_COLOR })
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => this.reason = value)

          Text(buildSubmitAppealDescriptionLabel())
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(TITLE_COLOR)

          TextArea({ text: this.description, placeholder: buildSubmitAppealDescriptionPlaceholder() })
            .height(140)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({ width: 1, color: BORDER_COLOR })
            .padding(12)
            .onChange((value: string) => this.description = value)

          Button(buildSubmitAppealButtonLabel(this.isSubmitting))
            .width('100%')
            .height(46)
            .fontColor('#FFFFFF')
            .backgroundColor(this.canSubmit() ? PRIMARY_COLOR : '#BFD0FF')
            .borderRadius(18)
            .enabled(!this.isSubmitting && this.canSubmit())
            .onClick(() => {
              void this.submit();
            })
        }
        .width('100%')
        .padding(18)
        .backgroundColor(CARD_BACKGROUND)
        .borderRadius(24)
        .border({ width: 1, color: BORDER_COLOR })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BACKGROUND)
  }
}
