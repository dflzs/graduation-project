
import { getParamsByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { PhoneCodePageParams } from '../../types/auth-flow';
import { buildVerificationCodeSlots, normalizeVerificationCode } from '../../utils/verification-code';

@Entry
@Component
struct PhoneLoginStep2Page {
  private readonly codeLength: number = 6;
  @State inputValue: string = '';
  @State codeArray: string[] = buildVerificationCodeSlots('', this.codeLength);
  @State phone: string = '';
  @State maskedPhone: string = '';
  @State debugCode: string = '';
  @State showResendButton: boolean = false;
  @State count: number = 60;
  @State isLoading: boolean = false;
  private timerId: number = -1;

  aboutToAppear(): void {
    const params = getParamsByContext<PhoneCodePageParams>(this);
    if (params) {
      this.phone = params.phone;
      this.maskedPhone = this.maskPhone(params.phone);
      this.debugCode = params.debugCode ?? '';
    }
    this.startCountdown();
  }

  aboutToDisappear(): void {
    this.stopCountdown();
  }

  private maskPhone(phone: string): string {
    return `${phone.substring(0, 3)}****${phone.substring(7)}`;
  }

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 2000 });
  }

  private startCountdown(): void {
    this.stopCountdown();
    this.showResendButton = false;
    this.count = 60;
    this.timerId = setInterval(() => {
      if (this.count > 1) {
        this.count--;
        return;
      }
      this.stopCountdown();
      this.showResendButton = true;
      this.count = 60;
    }, 1000) as number;
  }

  private stopCountdown(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private async resendCode(): Promise<void> {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.sendLoginCode(this.phone);
      console.info(`[Auth] resendLoginCode phone=${this.phone} code=${result.data?.code ?? ''}`);
      if (!result.ok) {
        this.showMessage(result.message);
        return;
      }

      this.debugCode = result.data?.code ?? '';
      this.showMessage(this.debugCode.length > 0 ? `Debug code: ${this.debugCode}` : result.message);
      this.startCountdown();
    } finally {
      this.isLoading = false;
    }
  }

  private async submitLogin(): Promise<void> {
    if (this.isLoading || this.inputValue.length !== this.codeLength) {
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.loginByPhone(this.phone, this.inputValue);
      console.info(`[Auth] loginByPhone phone=${this.phone} ok=${result.ok} message=${result.message}`);
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

  private updateInput(value: string): void {
    this.inputValue = normalizeVerificationCode(value, this.codeLength);
    this.codeArray = buildVerificationCodeSlots(this.inputValue, this.codeLength);

    if (this.inputValue.length >= this.codeLength) {
      void this.submitLogin();
    }
  }

  private isActiveSlot(index: number): boolean {
    return this.inputValue.length === index && this.inputValue.length < this.codeLength;
  }

  private isFilledSlot(index: number): boolean {
    return index < this.inputValue.length;
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Text('Enter Code')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text(`Code sent to ${this.maskedPhone}`)
          .fontSize(14)
          .fontColor('#666666')

        if (this.debugCode.length > 0) {
          Text(`Debug code: ${this.debugCode}`)
            .fontSize(16)
            .fontColor('#C0392B')
            .fontWeight(FontWeight.Medium)
        }

        Stack({ alignContent: Alignment.Center }) {
          Row({ space: 8 }) {
            ForEach(this.codeArray, (item: string, index: number) => {
              Text(item)
                .width(44)
                .height(52)
                .textAlign(TextAlign.Center)
                .fontSize(24)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.isActiveSlot(index) ? '#2563EB' : '#111827')
                .backgroundColor(this.isActiveSlot(index) ? '#EFF6FF' : (this.isFilledSlot(index) ? '#F8FAFC' : '#FFFFFF'))
                .borderRadius(8)
                .border({
                  width: this.isActiveSlot(index) ? 3 : (this.isFilledSlot(index) ? 1.5 : 1),
                  color: this.isActiveSlot(index) ? '#2563EB' : (this.isFilledSlot(index) ? '#CBD5E1' : '#E5E7EB')
                })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          TextInput({ text: this.inputValue })
            .type(InputType.Number)
            .maxLength(this.codeLength)
            .width('100%')
            .height(52)
            .opacity(0)
            .caretColor(Color.Transparent)
            .backgroundColor(Color.Transparent)
            .copyOption(CopyOptions.None)
            .onChange((value: string) => this.updateInput(value))
        }
        .width('100%')
        .height(52)

        if (this.showResendButton) {
          Button(this.isLoading ? 'Sending...' : 'Resend Code')
            .width('100%')
            .height(44)
            .enabled(!this.isLoading)
            .onClick(() => {
              void this.resendCode();
            })
        } else {
          Text(`${this.count}s before resend`)
            .fontSize(14)
            .fontColor('#666666')
        }

        Button(this.isLoading ? 'Submitting...' : 'Login')
          .width('100%')
          .height(44)
          .enabled(!this.isLoading)
          .onClick(() => {
            void this.submitLogin();
          })
      }
      .padding(20)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F6F8')
  }
}
