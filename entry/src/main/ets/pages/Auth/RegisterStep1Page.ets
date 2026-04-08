
import { replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { PhoneCodePageParams } from '../../types/auth-flow';

@Entry
@Component
struct RegisterStep1Page {
  @State phone: string = '';
  @State isLoading: boolean = false;

  private isValidPhoneNumber(phoneNumber: string): boolean {
    return /^1\d{10}$/.test(phoneNumber.trim());
  }

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 2000 });
  }

  private async nextStep(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    if (!this.isValidPhoneNumber(this.phone)) {
      this.showMessage('Please enter a valid phone number.');
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.sendRegisterCode(this.phone);
      console.info(`[Auth] sendRegisterCode phone=${this.phone} code=${result.data?.code ?? ''}`);
      if (!result.ok) {
        this.showMessage(result.message);
        return;
      }

      this.showMessage(result.data?.code ? `Debug code: ${result.data.code}` : result.message);
      replaceUrlByContext(this, {
        url: 'pages/Auth/RegisterStep2Page',
        params: new PhoneCodePageParams(this.phone, result.data?.code)
      });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Text('Phone Registration')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text('Step 1: call /api/sendCode with the phone number.')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({ text: this.phone, placeholder: 'Phone number' })
          .type(InputType.PhoneNumber)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.phone = value)

        Button(this.isLoading ? 'Sending...' : 'Next Step')
          .width('100%')
          .height(46)
          .enabled(!this.isLoading)
          .onClick(() => {
            void this.nextStep();
          })

        Button('Already have an account? Login')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .onClick(() => replaceUrlByContext(this, { url: 'pages/Auth/LoginPage' }))
      }
      .padding(20)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F6F8')
  }
}
