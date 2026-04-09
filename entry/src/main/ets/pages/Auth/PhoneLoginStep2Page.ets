
import { getParamsByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { PhoneCodePageParams } from '../../types/auth-flow';
import { buildVerificationCodeSlots, normalizeVerificationCode } from '../../utils/verification-code';
import { getAuthHeroSurfaceTone, getPolishGhostButtonTone, getPolishPrimaryButtonTone, getPolishSecondaryButtonTone } from '../../utils/ui-polish-tokens';

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

  private getPageBackground(): string {
    return '#F7F3EE';
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
      this.showMessage(this.debugCode.length > 0 ? `\u8c03\u8bd5\u9a8c\u8bc1\u7801\uff1a${this.debugCode}` : result.message);
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
      Column({ space: 18 }) {
        Column({ space: 12 }) {
          Text('\u7b2c\u4e8c\u6b65')
            .fontSize(13)
            .fontColor('#9A9083')

          Text('\u8f93\u5165\u767b\u5f55\u9a8c\u8bc1\u7801')
            .fontSize(33)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E2A26')

          Text(`\u9a8c\u8bc1\u7801\u5df2\u53d1\u9001\u81f3 ${this.maskedPhone}\uff0c\u8f93\u51656 \u4f4d\u9a8c\u8bc1\u7801\u5373\u53ef\u5b8c\u6210\u767b\u5f55\u3002`)
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
          if (this.debugCode.length > 0) {
            Text(`\u8c03\u8bd5\u9a8c\u8bc1\u7801\uff1a${this.debugCode}`)
              .fontSize(14)
              .fontColor('#B8643C')
              .fontWeight(FontWeight.Medium)
              .padding({ left: 2, right: 2 })
          }

          Stack({ alignContent: Alignment.Center }) {
            Row({ space: 8 }) {
              ForEach(this.codeArray, (item: string, index: number) => {
                Text(item)
                  .width(46)
                  .height(56)
                  .textAlign(TextAlign.Center)
                  .fontSize(24)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isActiveSlot(index) ? '#2364F5' : '#282420')
                  .backgroundColor(this.isActiveSlot(index) ? '#EEF4FF' : (this.isFilledSlot(index) ? '#FAF7F2' : '#FFFFFF'))
                  .borderRadius(16)
                  .border({
                    width: this.isActiveSlot(index) ? 2 : 1,
                    color: this.isActiveSlot(index) ? '#2364F5' : (this.isFilledSlot(index) ? '#D7D0C8' : '#E5DDD1')
                  })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)

            TextInput({ text: this.inputValue })
              .type(InputType.Number)
              .maxLength(this.codeLength)
              .width('100%')
              .height(56)
              .opacity(0)
              .caretColor(Color.Transparent)
              .backgroundColor(Color.Transparent)
              .copyOption(CopyOptions.None)
              .onChange((value: string) => this.updateInput(value))
          }
          .width('100%')
          .height(56)

          if (this.showResendButton) {
            Button(this.isLoading ? '\u53d1\u9001\u4e2d...' : '\u91cd\u65b0\u83b7\u53d6\u9a8c\u8bc1\u7801')
              .width('100%')
              .height(getPolishSecondaryButtonTone().height)
              .enabled(!this.isLoading)
              .backgroundColor(getPolishSecondaryButtonTone().backgroundColor)
              .fontColor(getPolishSecondaryButtonTone().textColor)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .borderRadius(getPolishSecondaryButtonTone().radius)
              .border({ width: 1, color: getPolishSecondaryButtonTone().borderColor })
              .onClick(() => {
                void this.resendCode();
              })
          } else {
            Text(`${this.count}s \u540e\u53ef\u91cd\u65b0\u83b7\u53d6`)
              .width('100%')
              .fontSize(14)
              .fontColor('#857C72')
              .textAlign(TextAlign.Center)
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFCF8')
        .borderRadius(24)
        .border({ width: 1, color: '#E4D9CC' })

        Column({ space: 12 }) {
          Button(this.isLoading ? '\u767b\u5f55\u4e2d...' : '\u5b8c\u6210\u767b\u5f55')
            .width('100%')
            .height(getPolishPrimaryButtonTone().height)
            .enabled(!this.isLoading)
            .backgroundColor(getPolishPrimaryButtonTone().backgroundColor)
            .fontColor(getPolishPrimaryButtonTone().textColor)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(getPolishPrimaryButtonTone().radius)
            .border({ width: 1, color: getPolishPrimaryButtonTone().borderColor })
            .opacity(this.isLoading ? 0.55 : 1)
            .onClick(() => {
              void this.submitLogin();
            })

          Button('\u8fd4\u56de\u767b\u5f55\u65b9\u5f0f')
            .width('100%')
            .height(getPolishGhostButtonTone().height)
            .backgroundColor(getPolishGhostButtonTone().backgroundColor)
            .fontColor(getPolishGhostButtonTone().textColor)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(getPolishGhostButtonTone().radius)
            .border({ width: 1, color: getPolishGhostButtonTone().borderColor })
            .onClick(() => replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' }))
        }
        .width('100%')
      }
      .padding(20)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getPageBackground())
  }
}
