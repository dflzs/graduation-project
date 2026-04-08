const LOADING_CARD_BACKGROUND: string = '#FFFDFC';
const LOADING_TITLE_COLOR: string = '#2D2A26';
const LOADING_TEXT_COLOR: string = '#7B756E';
const LOADING_PRIMARY: string = '#2F6BFF';

@Component
export struct LoadingState {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop compact: boolean = false;

  build() {
    Column({ space: this.compact ? 8 : 12 }) {
      Row({ space: 8 }) {
        Circle()
          .width(this.compact ? 8 : 10)
          .height(this.compact ? 8 : 10)
          .fill(LOADING_PRIMARY)

        Circle()
          .width(this.compact ? 8 : 10)
          .height(this.compact ? 8 : 10)
          .fill('#9EBBFF')

        Circle()
          .width(this.compact ? 8 : 10)
          .height(this.compact ? 8 : 10)
          .fill('#DCE7FF')
      }

      Text(this.title)
        .fontSize(this.compact ? 17 : 20)
        .fontWeight(FontWeight.Bold)
        .fontColor(LOADING_TITLE_COLOR)
        .textAlign(TextAlign.Center)

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(this.compact ? 13 : 14)
          .lineHeight(this.compact ? 20 : 22)
          .fontColor(LOADING_TEXT_COLOR)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(this.compact ? 18 : 24)
    .backgroundColor(LOADING_CARD_BACKGROUND)
    .borderRadius(this.compact ? 20 : 24)
    .alignItems(HorizontalAlign.Center)
  }
}
