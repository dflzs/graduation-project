
import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { RegisterProfilePageParams } from '../../types/auth-flow';
import { buildResendCountdownLabel } from '../../utils/verification-code';
import {
  ButtonVisualTone,
  getAuthHeroSurfaceTone,
  getAuthInputSurfaceTone,
  getPolishGhostButtonTone,
  getPolishPrimaryButtonTone,
  getPolishSecondaryButtonTone
} from '../../utils/ui-polish-tokens';

@Entry
@Component
struct RegisterVerifyPage {
  private readonly resendSeconds: number = 60;
  @State phone: string = '';
  @State code: string = '';
  @State isSending: boolean = false;
  @State isVerifying: boolean = false;
  @State resendCountdown: number = 0;
  private timerId: number = -1;

  aboutToDisappear(): void {
    this.stopCountdown();
  }

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 1800 });
  }

  private getPageBackground(): string {
    return '#F7F3EE';
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

  private validatePhone(): string {
    if (!/^1\d{10}$/.test(this.phone.trim())) {
      return '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002';
    }
    return '';
  }

  private validateCode(): string {
    if (!/^\d{6}$/.test(this.code.trim())) {
      return '\u8bf7\u8f93\u5165 6 \u4f4d\u9a8c\u8bc1\u7801\u3002';
    }
    return '';
  }

  private startCountdown(): void {
    this.stopCountdown();
    this.resendCountdown = this.resendSeconds;
    this.timerId = setInterval(() => {
      if (this.resendCountdown > 1) {
        this.resendCountdown--;
        return;
      }
      this.stopCountdown();
    }, 1000) as number;
  }

  private stopCountdown(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.resendCountdown = 0;
  }

  private async sendCode(): Promise<void> {
    if (this.isSending || this.resendCountdown > 0) {
      return;
    }

    const validationMessage = this.validatePhone();
    if (validationMessage.length > 0) {
      this.showMessage(validationMessage);
      return;
    }

    this.isSending = true;
    try {
      const result = await appContext.auth.sendRegisterCode(this.phone);
      console.info(`[Auth] sendRegisterCode phone=${this.phone} ok=${result.ok} message=${result.message}`);
      this.showMessage(result.message);
      if (!result.ok) {
        return;
      }

      if (result.data?.code) {
        console.info(`[RegisterCode][DEV] phone=${this.phone} code=${result.data.code}`);
      }
      this.startCountdown();
    } finally {
      this.isSending = false;
    }
  }

  private async nextStep(): Promise<void> {
    if (this.isVerifying) {
      return;
    }

    const phoneMessage = this.validatePhone();
    if (phoneMessage.length > 0) {
      this.showMessage(phoneMessage);
      return;
    }

    const codeMessage = this.validateCode();
    if (codeMessage.length > 0) {
      this.showMessage(codeMessage);
      return;
    }

    this.isVerifying = true;
    try {
      const result = await appContext.auth.verifyRegisterCode(this.phone, this.code);
      console.info(`[Auth] verifyRegisterCode phone=${this.phone} ok=${result.ok} message=${result.message}`);
      this.showMessage(result.message);
      if (!result.ok || !result.data) {
        return;
      }

      pushUrlByContext(this, {
        url: 'pages/Auth/RegisterProfilePage',
        params: new RegisterProfilePageParams(result.data.phone, result.data.registerTicket)
      });
    } finally {
      this.isVerifying = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 12 }) {
          Text('\u6ce8\u518c\u9a8c\u8bc1')
            .fontSize(13)
            .fontColor('#9A9083')

          Text('\u5148\u9a8c\u8bc1\u624b\u673a\u53f7\uff0c\u518d\u521b\u5efa\u6821\u56ed\u8d26\u53f7')
            .fontSize(33)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E2A26')

          Text('\u53ea\u6709\u5b8c\u6210\u624b\u673a\u53f7\u9a8c\u8bc1\u540e\uff0c\u624d\u4f1a\u8fdb\u5165\u540e\u7eed\u7684\u6635\u79f0\u3001\u5bc6\u7801\u548c\u4e2a\u4eba\u8d44\u6599\u8bbe\u7f6e\u6d41\u7a0b\u3002')
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
            this.buildFieldLabel('\u9a8c\u8bc1\u7801')

            Row({ space: 10 }) {
              TextInput({ text: this.code, placeholder: '\u8f93\u5165\u9a8c\u8bc1\u7801' })
                .type(InputType.Number)
                .height(54)
                .fontSize(18)
                .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
                .borderRadius(getAuthInputSurfaceTone().radius)
                .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
                .placeholderColor('#9A938A')
                .layoutWeight(2)
                .onChange((value: string) => this.code = value)

              this.buildActionButton(this.isSending ? '\u53d1\u9001\u4e2d...' : buildResendCountdownLabel(this.resendCountdown), getPolishSecondaryButtonTone(), () => {
                void this.sendCode();
              }, !this.isSending && this.resendCountdown === 0, false)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')

          Text('\u5f00\u53d1\u73af\u5883\u4e0b\uff0c\u8c03\u8bd5\u9a8c\u8bc1\u7801\u4ecd\u4f1a\u5728\u540e\u7eed\u6d41\u7a0b\u4fdd\u7559\u663e\u793a\uff0c\u65b9\u4fbf\u8054\u8c03\u3002')
            .width('100%')
            .fontSize(13)
            .fontColor('#8E857A')
            .lineHeight(20)
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFCF8')
        .borderRadius(24)
        .border({ width: 1, color: '#E4D9CC' })

        Column({ space: 12 }) {
          this.buildActionButton(this.isVerifying ? '\u9a8c\u8bc1\u4e2d...' : '\u4e0b\u4e00\u6b65', getPolishPrimaryButtonTone(), () => {
            void this.nextStep();
          }, !this.isVerifying)

          this.buildActionButton('\u8fd4\u56de\u767b\u5f55', getPolishGhostButtonTone(), () => replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' }))
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
