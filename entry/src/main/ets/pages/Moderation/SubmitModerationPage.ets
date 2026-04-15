import { appContext } from '../../app/app-context';
import { ModerationTargetType } from '../../types/domain';
import {
  buildSubmitModerationButtonLabel,
  buildSubmitModerationDescriptionLabel,
  buildSubmitModerationDescriptionPlaceholder,
  buildSubmitModerationPageTitle,
  buildSubmitModerationReasonLabel,
  buildSubmitModerationReasonPlaceholder,
  buildSubmitModerationReasonSuggestions,
  buildSubmitModerationValidationMessage
} from '../../utils/moderation-submit-copy';
import { backByContext, getParamsByContext, showToastByContext } from '../../utils/ui-context-actions';

const PAGE_BACKGROUND: string = '#F7F3EE';
const CARD_BACKGROUND: string = '#FFFDFC';
const BORDER_COLOR: string = '#E7DED2';
const TITLE_COLOR: string = '#2D2A26';
const SUB_TEXT_COLOR: string = '#7B756E';
const PRIMARY_COLOR: string = '#2F6BFF';

class ModerationPageParams {
  targetType: ModerationTargetType = 'order_complaint';
  targetId: string = '';
  title: string = '';
}

@Entry
@Component
struct SubmitModerationPage {
  @State targetType: ModerationTargetType = 'order_complaint';
  @State targetId: string = '';
  @State title: string = '';
  @State reason: string = '';
  @State description: string = '';
  @State isSubmitting: boolean = false;

  aboutToAppear(): void {
    const params = getParamsByContext<ModerationPageParams>(this);
    this.targetType = params?.targetType ?? 'order_complaint';
    this.targetId = params?.targetId ?? '';
    this.title = params?.title ?? '举报与投诉';
    if (this.reason.length === 0) {
      const suggestions = buildSubmitModerationReasonSuggestions(this.targetType);
      this.reason = suggestions.length > 0 ? suggestions[0] : '';
    }
  }

  private async submit(): Promise<void> {
    const currentUser = appContext.getCurrentUser();
    if (!currentUser) {
      showToastByContext(this, { message: buildSubmitModerationValidationMessage('login'), duration: 1200 });
      return;
    }
    if (this.reason.trim().length === 0) {
      showToastByContext(this, { message: buildSubmitModerationValidationMessage('reason'), duration: 1200 });
      return;
    }
    if (this.description.trim().length < 4) {
      showToastByContext(this, { message: buildSubmitModerationValidationMessage('description'), duration: 1200 });
      return;
    }

    this.isSubmitting = true;
    let result;
    if (this.targetType === 'chat_report') {
      result = await appContext.moderation.submitChatReport(
        this.targetId,
        currentUser.id,
        this.reason.trim(),
        this.description.trim()
      );
    } else if (this.targetType === 'product_report') {
      result = await appContext.moderation.submitProductReport(
        this.targetId,
        currentUser.id,
        this.reason.trim(),
        this.description.trim()
      );
    } else if (this.targetType === 'user_report') {
      result = await appContext.moderation.submitUserReport(
        this.targetId,
        currentUser.id,
        this.reason.trim(),
        this.description.trim()
      );
    } else {
      result = await appContext.moderation.submitOrderComplaint(
        this.targetId,
        currentUser.id,
        this.reason.trim(),
        this.description.trim()
      );
    }
    this.isSubmitting = false;

    showToastByContext(this, { message: result.message, duration: 1500 });
    if (result.ok) {
      backByContext(this);
    }
  }

  @Builder
  private buildReasonChip(item: string): void {
    Text(item)
      .fontSize(13)
      .fontColor(this.reason === item ? '#FFFFFF' : PRIMARY_COLOR)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.reason === item ? PRIMARY_COLOR : '#E8F0FF')
      .borderRadius(16)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => this.reason = item);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 6 }) {
          Text(buildSubmitModerationPageTitle(this.targetType))
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
          Text(buildSubmitModerationReasonLabel())
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(TITLE_COLOR)

          Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
            ForEach(buildSubmitModerationReasonSuggestions(this.targetType), (item: string) => {
              this.buildReasonChip(item);
            }, (item: string) => item)
          }
          .width('100%')

          TextInput({ text: this.reason, placeholder: buildSubmitModerationReasonPlaceholder() })
            .height(46)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .border({ width: 1, color: BORDER_COLOR })
            .onChange((value: string) => this.reason = value)

          Text(buildSubmitModerationDescriptionLabel())
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(TITLE_COLOR)

          TextArea({ text: this.description, placeholder: buildSubmitModerationDescriptionPlaceholder() })
            .height(140)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({ width: 1, color: BORDER_COLOR })
            .onChange((value: string) => this.description = value)

          Button(buildSubmitModerationButtonLabel(this.isSubmitting))
            .width('100%')
            .height(46)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY_COLOR)
            .borderRadius(18)
            .enabled(!this.isSubmitting)
            .opacity(this.isSubmitting ? 0.6 : 1)
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
