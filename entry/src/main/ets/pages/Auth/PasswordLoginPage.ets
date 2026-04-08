import { appContext } from '../../app/app-context';
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
      Column({ space: 16 }) {
        Text('\u624b\u673a\u53f7\u5bc6\u7801\u767b\u5f55')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text('\u8be5\u9875\u9762\u5df2\u63a5\u5165\u5f53\u524d\u670d\u52a1\u5668\u7684\u624b\u673a\u53f7\u5bc6\u7801\u767b\u5f55\u63a5\u53e3\u3002')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({ text: this.phone, placeholder: '\u8bf7\u8f93\u5165\u624b\u673a\u53f7' })
          .type(InputType.PhoneNumber)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.phone = value)

        TextInput({ text: this.password, placeholder: '\u8bf7\u8f93\u5165\u5bc6\u7801' })
          .type(InputType.Password)
          .width('100%')
          .height(52)
          .onChange((value: string) => this.password = value)

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

        Button(this.isLoading ? '\u63d0\u4ea4\u4e2d...' : '\u767b\u5f55')
          .width('100%')
          .height(46)
          .enabled(!this.isLoading)
          .onClick(() => {
            void this.submitPasswordLogin();
          })

        Button('\u6539\u7528\u9a8c\u8bc1\u7801\u767b\u5f55')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .onClick(() => replaceUrlByContext(this, { url: 'pages/Auth/PhoneLoginStep1Page' }))

        Button('\u53bb\u6ce8\u518c')
          .width('100%')
          .height(42)
          .type(ButtonType.Normal)
          .onClick(() => replaceUrlByContext(this, { url: 'pages/Auth/RegisterVerifyPage' }))
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F6F8')
  }
}
