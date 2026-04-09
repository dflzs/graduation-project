import {
  ButtonVisualTone,
  getAuthHeroSurfaceTone,
  getAuthSymmetricSplitButtonLayout,
  getPolishGhostButtonTone,
  getPolishPrimaryButtonTone,
  getPolishSecondaryButtonTone
} from '../../utils/ui-polish-tokens';
import { pushUrlByContext } from '../../utils/ui-context-actions';

@Entry
@Component
struct LoginPage {
  private getPageBackground(): string {
    return '#F7F3EE';
  }

  private getSplitGap(): number {
    return getAuthSymmetricSplitButtonLayout().gap;
  }

  private getSplitLeftWeight(): number {
    return getAuthSymmetricSplitButtonLayout().leftWeight;
  }

  private getSplitRightWeight(): number {
    return getAuthSymmetricSplitButtonLayout().rightWeight;
  }

  @Builder
  private buildEntryButton(label: string, url: string, tone: ButtonVisualTone) {
    Button(label)
      .width('100%')
      .height(tone.height)
      .backgroundColor(tone.backgroundColor)
      .fontColor(tone.textColor)
      .fontSize(17)
      .fontWeight(FontWeight.Medium)
      .borderRadius(tone.radius)
      .border({ width: 1, color: tone.borderColor })
      .onClick(() => pushUrlByContext(this, { url }))
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 10 }) {
          Text('\u6821\u56ed\u95f2\u7f6e\u4ea4\u6613')
            .fontSize(12)
            .fontColor('#9A8F82')
            .fontWeight(FontWeight.Medium)

          Text('\u9009\u62e9\u4f60\u7684\u767b\u5f55\u65b9\u5f0f')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2723')

          Text('\u5e38\u7528\u8d26\u53f7\u53ef\u76f4\u63a5\u7528\u5bc6\u7801\u767b\u5f55\uff0c\u4e34\u65f6\u8fd4\u56de\u53ef\u4f7f\u7528\u9a8c\u8bc1\u7801\u767b\u5f55\uff0c\u65b0\u7528\u6237\u5219\u4ece\u6ce8\u518c\u9a8c\u8bc1\u5f00\u59cb\u3002')
            .fontSize(16)
            .fontColor('#655D55')
            .lineHeight(25)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 24, left: 22, right: 22, bottom: 22 })
        .backgroundColor(getAuthHeroSurfaceTone().backgroundColor)
        .borderRadius(getAuthHeroSurfaceTone().radius)
        .border({ width: 1, color: getAuthHeroSurfaceTone().borderColor })

        Column({ space: 14 }) {
          this.buildEntryButton('\u624b\u673a\u53f7\u5bc6\u7801\u767b\u5f55', 'pages/Auth/PasswordLoginPage', getPolishPrimaryButtonTone())

          Row({ space: this.getSplitGap() }) {
            Column() {
              this.buildEntryButton('\u9a8c\u8bc1\u7801\u767b\u5f55', 'pages/Auth/PhoneLoginStep1Page', getPolishSecondaryButtonTone())
            }
            .layoutWeight(this.getSplitLeftWeight())

            Column() {
              this.buildEntryButton('\u624b\u673a\u53f7\u6ce8\u518c', 'pages/Auth/RegisterVerifyPage', getPolishGhostButtonTone())
            }
            .layoutWeight(this.getSplitRightWeight())
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFCF8')
        .borderRadius(24)
        .border({ width: 1, color: '#E4D9CC' })

        Column({ space: 6 }) {
          Text('\u767b\u5f55\u540e\u53ef\u7ee7\u7eed\u67e5\u770b\u53d1\u5e03\uff0c\u7ef4\u62a4\u804a\u5929\u4f1a\u8bdd\uff0c\u5b8c\u6210\u4ea4\u6613\u63d0\u9192\u548c\u8ba2\u5355\u8ddf\u8fdb\u3002')
            .width('100%')
            .fontSize(14)
            .fontColor('#7A7268')
            .lineHeight(22)
            .textAlign(TextAlign.Start)

          Text('\u4e3b\u5165\u53e3\u7a81\u51fa\uff0c\u8f85\u52a9\u5165\u53e3\u5bf9\u79f0\u6392\u5217\uff0c\u6574\u4e2a\u767b\u5f55\u9996\u5c4f\u4f1a\u66f4\u50cf\u6b63\u5f0f\u4ea7\u54c1\u95e8\u6237\u3002')
            .width('100%')
            .fontSize(13)
            .fontColor('#958C81')
            .lineHeight(20)
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding({ left: 4, right: 4 })
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
