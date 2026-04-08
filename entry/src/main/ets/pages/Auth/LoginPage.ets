import { pushUrlByContext } from '../../utils/ui-context-actions';

@Entry
@Component
struct LoginPage {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('\u767b\u5f55\u4e2d\u5fc3')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        Text('\u5f53\u524d\u5df2\u63a5\u901a\u624b\u673a\u53f7\u5bc6\u7801\u767b\u5f55\u548c\u9a8c\u8bc1\u7801\u524d\u7f6e\u6ce8\u518c\u3002\u5f00\u53d1\u6001\u4f1a\u5728\u6ce8\u518c\u9875\u663e\u793a\u8c03\u8bd5\u9a8c\u8bc1\u7801\u3002')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)

        Button('\u624b\u673a\u53f7\u5bc6\u7801\u767b\u5f55')
          .width('100%')
          .height(48)
          .onClick(() => pushUrlByContext(this, { url: 'pages/Auth/PasswordLoginPage' }))

        Button('\u624b\u673a\u53f7\u9a8c\u8bc1\u7801\u767b\u5f55')
          .width('100%')
          .height(48)
          .onClick(() => pushUrlByContext(this, { url: 'pages/Auth/PhoneLoginStep1Page' }))

        Button('\u624b\u673a\u53f7\u6ce8\u518c')
          .width('100%')
          .height(48)
          .onClick(() => pushUrlByContext(this, { url: 'pages/Auth/RegisterVerifyPage' }))
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F6F8')
  }
}
