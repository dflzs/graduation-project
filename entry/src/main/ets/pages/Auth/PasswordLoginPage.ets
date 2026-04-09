import { appContext } from '../../app/app-context';
import {
  ButtonVisualTone,
  getAuthHeroSurfaceTone,
  getAuthInputSurfaceTone,
  getAuthSymmetricSplitButtonLayout,
  getPolishGhostButtonTone,
  getPolishPrimaryButtonTone,
  getPolishSecondaryButtonTone
} from '../../utils/ui-polish-tokens';
import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';

@Entry
@Component
struct PasswordLoginPage {
  @State phone: string = '';
  @State password: string = '';
  @State isAgree: boolean = false;
  @State isLoading: boolean = false;

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 1800 });
  }

  private getPageBackground(): string {
    return '#F7F3EE';
  }

  private getSplitGap(): number {
    return getAuthSymmetricSplitButtonLayout().gap;
  }

  private getSplitLeftWeight(): number {
    return getAuthSymmetricSplitButtonLayout().leftWeight;
  }

  private getSplitRightWeight(): number {
    return getAuthSymmetricSplitButtonLayout().rightWeight;
  }

  @Builder
  private buildFieldLabel(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor('#8B8378')
      .fontWeight(FontWeight.Medium)
  }

  @Builder
  private buildActionButton(label: string, tone: ButtonVisualTone, onClick: () => void, isEnabled: boolean = true, isWide: boolean = true) {
    Button(label)
      .width(isWide ? '100%' : undefined)
      .height(tone.height)
      .enabled(isEnabled)
      .backgroundColor(tone.backgroundColor)
      .fontColor(tone.textColor)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .borderRadius(tone.radius)
      .border({ width: 1, color: tone.borderColor })
      .opacity(isEnabled ? 1 : 0.55)
      .onClick(onClick)
  }

  private async submitPasswordLogin(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    if (!this.isAgree) {
      this.showMessage('\u8bf7\u5148\u52fe\u9009\u5e76\u540c\u610f\u7528\u6237\u534f\u8bae\u3002');
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.loginByPassword(this.phone, this.password);
      console.info(`[Auth] loginByPassword phone=${this.phone} ok=${result.ok} message=${result.message}`);
      if (!result.ok) {
        this.showMessage(result.message);
        return;
      }

      this.showMessage(result.message);
      replaceUrlByContext(this, { url: 'pages/Index' });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 12 }) {
          Text('\u5b89\u5168\u767b\u5f55')
            .fontSize(13)
            .fontColor('#9A9083')

          Text('\u624b\u673a\u53f7\u5bc6\u7801\u767b\u5f55')
            .fontSize(33)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E2A26')

          Text('\u4f7f\u7528\u5e38\u7528\u8d26\u53f7\u5feb\u901f\u56de\u5230\u6821\u56ed\u95f2\u7f6e\u4ea4\u6613\uff0c\u7ee7\u7eed\u5904\u7406\u6d88\u606f\uff0c\u53d1\u5e03\uff0c\u8ba2\u5355\u548c\u8d2d\u7269\u8f66\u3002')
            .fontSize(16)
            .fontColor('#6D655D')
            .lineHeight(25)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 24, left: 22, right: 22, bottom: 22 })
        .backgroundColor(getAuthHeroSurfaceTone().backgroundColor)
        .borderRadius(getAuthHeroSurfaceTone().radius)
        .border({ width: 1, color: getAuthHeroSurfaceTone().borderColor })

        Column({ space: 16 }) {
          Column({ space: 8 }) {
            this.buildFieldLabel('\u624b\u673a\u53f7')

            TextInput({ text: this.phone, placeholder: '\u8bf7\u8f93\u5165\u624b\u673a\u53f7' })
              .type(InputType.PhoneNumber)
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.phone = value)
          }
          .width('100%')

          Column({ space: 8 }) {
            this.buildFieldLabel('\u5bc6\u7801')

            TextInput({ text: this.password, placeholder: '\u8bf7\u8f93\u5165\u5bc6\u7801' })
              .type(InputType.Password)
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.password = value)
          }
          .width('100%')

          Row() {
            Checkbox()
              .select(this.isAgree)
              .onChange((value: boolean) => this.isAgree = value)

            Text('\u6211\u5df2\u9605\u8bfb\u5e76\u540c\u610f\u300a\u7528\u6237\u534f\u8bae\u300b\u548c\u300a\u9690\u79c1\u653f\u7b56\u300b')
              .fontSize(13)
              .fontColor('#696158')
              .lineHeight(20)
              .margin({ left: 10 })
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFCF8')
        .borderRadius(24)
        .border({ width: 1, color: '#E4D9CC' })

        Column({ space: 12 }) {
          this.buildActionButton(this.isLoading ? '\u767b\u5f55\u4e2d...' : '\u767b\u5f55', getPolishPrimaryButtonTone(), () => {
            void this.submitPasswordLogin();
          }, !this.isLoading)

          Row({ space: this.getSplitGap() }) {
            Column() {
              this.buildActionButton('\u6539\u7528\u9a8c\u8bc1\u7801\u767b\u5f55', getPolishSecondaryButtonTone(), () => replaceUrlByContext(this, { url: 'pages/Auth/PhoneLoginStep1Page' }))
            }
            .layoutWeight(this.getSplitLeftWeight())

            Column() {
              this.buildActionButton('\u53bb\u6ce8\u518c', getPolishGhostButtonTone(), () => replaceUrlByContext(this, { url: 'pages/Auth/RegisterVerifyPage' }))
            }
            .layoutWeight(this.getSplitRightWeight())
          }
          .width('100%')
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20, top: 18, bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getPageBackground())
  }
}
