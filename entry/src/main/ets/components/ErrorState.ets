const ERROR_CARD_BACKGROUND: string = '#FFFDFC';
const ERROR_TITLE_COLOR: string = '#2D2A26';
const ERROR_TEXT_COLOR: string = '#7B756E';
const ERROR_PRIMARY: string = '#B8643C';

@Component
export struct ErrorState {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop compact: boolean = false;

  build() {
    Column({ space: this.compact ? 8 : 12 }) {
      Text('提示')
        .fontSize(this.compact ? 11 : 12)
        .fontWeight(FontWeight.Medium)
        .fontColor(ERROR_PRIMARY)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#F4E6DE')
        .borderRadius(12)

      Text(this.title)
        .fontSize(this.compact ? 18 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ERROR_TITLE_COLOR)
        .textAlign(TextAlign.Center)

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(this.compact ? 13 : 14)
          .lineHeight(this.compact ? 20 : 22)
          .fontColor(ERROR_TEXT_COLOR)
          .textAlign(TextAlign.Center)
      }

    }
    .width('100%')
    .padding(this.compact ? 18 : 24)
    .backgroundColor(ERROR_CARD_BACKGROUND)
    .borderRadius(this.compact ? 20 : 24)
    .alignItems(HorizontalAlign.Center)
  }
}
