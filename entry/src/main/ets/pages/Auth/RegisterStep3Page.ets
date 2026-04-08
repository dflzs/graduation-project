import { appContext } from '../../app/app-context';
import { RegisterPasswordPageParams } from '../../types/auth-flow';
import { getParamsByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';

@Entry
@Component
struct RegisterStep3Page {
  @State phone: string = '';
  @State code: string = '';
  @State debugCode: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;

  aboutToAppear(): void {
    const params = getParamsByContext<RegisterPasswordPageParams>(this);
    if (params) {
      this.phone = params.phone;
      this.code = params.code;
      this.debugCode = params.debugCode ?? '';
    }
  }

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 2000 });
  }

  private async submitRegister(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.showMessage('Passwords do not match.');
      return;
    }
    if (this.password.trim().length < 6) {
      this.showMessage('Password must be at least 6 characters.');
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.registerByPhone(this.phone, this.code, this.password);
      console.info(`[Auth] registerByPhone phone=${this.phone} ok=${result.ok} message=${result.message}`);
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
      Column({ space: 20 }) {
        Text('Set Password')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text(`Phone: ${this.phone}`)
          .fontSize(14)
          .fontColor('#666666')

        if (this.debugCode.length > 0) {
          Text(`Verified debug code: ${this.debugCode}`)
            .fontSize(14)
            .fontColor('#666666')
        }

        TextInput({ text: this.password, placeholder: 'Password' })
          .type(InputType.Password)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.password = value)

        TextInput({ text: this.confirmPassword, placeholder: 'Confirm password' })
          .type(InputType.Password)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.confirmPassword = value)

        Button(this.isLoading ? 'Submitting...' : 'Complete Registration')
          .width('100%')
          .height(46)
          .enabled(!this.isLoading)
          .onClick(() => {
            void this.submitRegister();
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
