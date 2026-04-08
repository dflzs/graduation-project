
import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { PhoneCodePageParams } from '../../types/auth-flow';

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

  private async getCode(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    if (!this.isAgree) {
      this.showMessage('Please agree to the user agreement first.');
      return;
    }
    if (!this.isValidPhoneNumber(this.phone)) {
      this.showMessage('Please enter a valid phone number.');
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

      this.showMessage(result.data?.code ? `Debug code: ${result.data.code}` : result.message);
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
      Column({ space: 20 }) {
        Text('Phone Code Login')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text('Step 1: call /api/sendLoginCode with the phone number.')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)

        TextInput({ text: this.phone, placeholder: 'Phone number' })
          .type(InputType.PhoneNumber)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.phone = value)

        Row() {
          Checkbox()
            .select(this.isAgree)
            .onChange((value: boolean) => this.isAgree = value)

          Text('I agree to the User Agreement and Privacy Policy')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 8 })
        }
        .width('100%')

        Button(this.isLoading ? 'Sending...' : 'Get Code')
          .width('100%')
          .height(46)
          .enabled(!this.isLoading)
          .onClick(() => {
            void this.getCode();
          })

        Button('Use Password Login')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .onClick(() => replaceUrlByContext(this, { url: 'pages/Auth/PasswordLoginPage' }))

        Button('Go Register')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .onClick(() => replaceUrlByContext(this, { url: 'pages/Auth/RegisterVerifyPage' }))
      }
      .padding(20)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F6F8')
  }
}
