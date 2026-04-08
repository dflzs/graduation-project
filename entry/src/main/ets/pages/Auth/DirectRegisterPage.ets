import { promptAction, router } from '@kit.ArkUI';
import { appContext } from '../../app/app-context';

@Entry
@Component
struct DirectRegisterPage {
  @State phone: string = '';
  @State nickname: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isAgree: boolean = false;
  @State isLoading: boolean = false;

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 1800 });
  }

  private validateInput(): string {
    if (!/^1\d{10}$/.test(this.phone.trim())) {
      return '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002';
    }
    if (this.nickname.trim().length < 2) {
      return '\u6635\u79f0\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 2 \u4f4d\u3002';
    }
    if (this.password.trim().length < 6) {
      return '\u5bc6\u7801\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 6 \u4f4d\u3002';
    }
    if (this.password !== this.confirmPassword) {
      return '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4\u3002';
    }
    if (!this.isAgree) {
      return '\u8bf7\u5148\u52fe\u9009\u5e76\u540c\u610f\u7528\u6237\u534f\u8bae\u3002';
    }
    return '';
  }

  private async submitRegister(): Promise<void> {
    if (this.isLoading) {
      return;
    }

    const validationMessage = this.validateInput();
    if (validationMessage.length > 0) {
      this.showMessage(validationMessage);
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.registerDirect(this.phone, this.nickname, this.password);
      console.info(`[Auth] registerDirect phone=${this.phone} ok=${result.ok} message=${result.message}`);
      this.showMessage(result.message);
      if (!result.ok) {
        return;
      }

      replaceUrlByContext(this, { url: 'pages/Index' });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('\u624b\u673a\u53f7\u6ce8\u518c')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text('\u76f4\u63a5\u5b8c\u6210\u8d26\u53f7\u6ce8\u518c\uff0c\u6210\u529f\u540e\u4f1a\u81ea\u52a8\u767b\u5f55\u5e76\u8fdb\u5165\u9996\u9875\u3002')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)

        TextInput({ text: this.phone, placeholder: '\u8bf7\u8f93\u5165\u624b\u673a\u53f7' })
          .type(InputType.PhoneNumber)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.phone = value)

        TextInput({ text: this.nickname, placeholder: '\u8bf7\u8f93\u5165\u6635\u79f0' })
          .width('100%')
          .height(52)
          .onChange((value: string) => this.nickname = value)

        TextInput({ text: this.password, placeholder: '\u8bf7\u8bbe\u7f6e\u5bc6\u7801' })
          .type(InputType.Password)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.password = value)

        TextInput({ text: this.confirmPassword, placeholder: '\u8bf7\u518d\u6b21\u8f93\u5165\u5bc6\u7801' })
          .type(InputType.Password)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.confirmPassword = value)

        Row() {
          Checkbox()
            .select(this.isAgree)
            .onChange((value: boolean) => this.isAgree = value)

          Text('\u6211\u5df2\u9605\u8bfb\u5e76\u540c\u610f\u300a\u7528\u6237\u534f\u8bae\u300b\u548c\u300a\u9690\u79c1\u653f\u7b56\u300b')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 8 })
        }
        .width('100%')

        Button(this.isLoading ? '\u63d0\u4ea4\u4e2d...' : '\u6ce8\u518c\u5e76\u767b\u5f55')
          .width('100%')
          .height(46)
          .enabled(!this.isLoading)
          .onClick(() => {
            void this.submitRegister();
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
