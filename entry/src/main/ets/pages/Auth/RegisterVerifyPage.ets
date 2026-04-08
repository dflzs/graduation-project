
import { pushUrlByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { RegisterProfilePageParams } from '../../types/auth-flow';
import { buildResendCountdownLabel } from '../../utils/verification-code';

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
        Text('\u624b\u673a\u53f7\u9a8c\u8bc1')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text('\u5148\u9a8c\u8bc1\u624b\u673a\u53f7\u5f52\u5c5e\uff0c\u901a\u8fc7\u540e\u518d\u8bbe\u7f6e\u6635\u79f0\u548c\u5bc6\u7801\u3002')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)

        TextInput({ text: this.phone, placeholder: '\u8bf7\u8f93\u5165\u624b\u673a\u53f7' })
          .type(InputType.PhoneNumber)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.phone = value)

        Row({ space: 10 }) {
          TextInput({ text: this.code, placeholder: '\u8f93\u5165\u9a8c\u8bc1\u7801' })
            .type(InputType.Number)
            .height(52)
            .layoutWeight(2)
            .onChange((value: string) => this.code = value)

          Button(this.isSending ? '\u53d1\u9001\u4e2d...' : buildResendCountdownLabel(this.resendCountdown))
            .height(52)
            .layoutWeight(1)
            .enabled(!this.isSending && this.resendCountdown === 0)
            .onClick(() => {
              void this.sendCode();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Button(this.isVerifying ? '\u9a8c\u8bc1\u4e2d...' : '\u4e0b\u4e00\u6b65')
          .width('100%')
          .height(46)
          .enabled(!this.isVerifying)
          .onClick(() => {
            void this.nextStep();
          })

        Button('\u8fd4\u56de\u767b\u5f55')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .onClick(() => replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' }))
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F6F8')
  }
}
