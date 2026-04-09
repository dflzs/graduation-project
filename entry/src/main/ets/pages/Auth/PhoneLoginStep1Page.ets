
import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { PhoneCodePageParams } from '../../types/auth-flow';
import {
  ButtonVisualTone,
  getAuthHeroSurfaceTone,
  getAuthInputSurfaceTone,
  getAuthSymmetricSplitButtonLayout,
  getPolishGhostButtonTone,
  getPolishPrimaryButtonTone,
  getPolishSecondaryButtonTone
} from '../../utils/ui-polish-tokens';

@Entry
@Component
struct PhoneLoginStep1Page {
  @State phone: string = '';
  @State isAgree: boolean = false;
  @State isLoading: boolean = false;

  private isValidPhoneNumber(phoneNumber: string): boolean {
    const cleanedPhone = phoneNumber.replace(/\s+/g, '').trim();
    return /^1\d{10}$/.test(cleanedPhone);
  }

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 2000 });
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

  private async getCode(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    if (!this.isAgree) {
      this.showMessage('\u8bf7\u5148\u52fe\u9009\u5e76\u540c\u610f\u7528\u6237\u534f\u8bae\u3002');
      return;
    }
    if (!this.isValidPhoneNumber(this.phone)) {
      this.showMessage('\u8bf7\u8f93\u5165\u5408\u6cd5\u7684\u624b\u673a\u53f7\u3002');
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.sendLoginCode(this.phone);
      console.info(`[Auth] sendLoginCode phone=${this.phone} code=${result.data?.code ?? ''}`);
      if (!result.ok) {
        this.showMessage(result.message);
        return;
      }

      this.showMessage(result.data?.code ? `\u8c03\u8bd5\u9a8c\u8bc1\u7801\uff1a${result.data.code}` : result.message);
      replaceUrlByContext(this, {
        url: 'pages/Auth/PhoneLoginStep2Page',
        params: new PhoneCodePageParams(this.phone, result.data?.code)
      });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 12 }) {
          Text('\u7b2c\u4e00\u6b65')
            .fontSize(13)
            .fontColor('#9A9083')

          Text('\u624b\u673a\u53f7\u9a8c\u8bc1\u7801\u767b\u5f55')
            .fontSize(33)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E2A26')

          Text('\u8f93\u5165\u624b\u673a\u53f7\u540e\uff0c\u7cfb\u7edf\u4f1a\u5411\u4f60\u53d1\u9001\u767b\u5f55\u9a8c\u8bc1\u7801\u3002\u5f00\u53d1\u73af\u5883\u4e0b\uff0c\u8c03\u8bd5\u9a8c\u8bc1\u7801\u4f1a\u5728\u4e0b\u4e00\u6b65\u4fdd\u7559\u663e\u793a\uff0c\u4fbf\u4e8e\u8054\u8c03\u3002')
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
          this.buildActionButton(this.isLoading ? '\u53d1\u9001\u4e2d...' : '\u83b7\u53d6\u9a8c\u8bc1\u7801', getPolishPrimaryButtonTone(), () => {
            void this.getCode();
          }, !this.isLoading)

          Row({ space: this.getSplitGap() }) {
            Column() {
              this.buildActionButton('\u5bc6\u7801\u767b\u5f55', getPolishSecondaryButtonTone(), () => replaceUrlByContext(this, { url: 'pages/Auth/PasswordLoginPage' }))
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
