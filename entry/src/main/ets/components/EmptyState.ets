const EMPTY_CARD_BACKGROUND: string = '#FFFDFC';
const EMPTY_TITLE_COLOR: string = '#2D2A26';
const EMPTY_TEXT_COLOR: string = '#7B756E';
const EMPTY_ACCENT: string = '#E7DED2';
const EMPTY_PRIMARY: string = '#2F6BFF';

@Component
export struct EmptyState {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop compact: boolean = false;

  build() {
    Column({ space: this.compact ? 8 : 12 }) {
      Row({ space: 6 }) {
        Blank()
          .width(this.compact ? 18 : 22)
          .height(4)
          .backgroundColor(EMPTY_ACCENT)
          .borderRadius(3)

        Blank()
          .width(this.compact ? 32 : 42)
          .height(4)
          .backgroundColor('#F0E8DE')
          .borderRadius(3)
      }

      Text(this.title)
        .fontSize(this.compact ? 18 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor(EMPTY_TITLE_COLOR)
        .textAlign(TextAlign.Center)

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(this.compact ? 13 : 14)
          .lineHeight(this.compact ? 20 : 22)
          .fontColor(EMPTY_TEXT_COLOR)
          .textAlign(TextAlign.Center)
      }

    }
    .width('100%')
    .padding(this.compact ? 18 : 24)
    .backgroundColor(EMPTY_CARD_BACKGROUND)
    .borderRadius(this.compact ? 20 : 24)
    .alignItems(HorizontalAlign.Center)
  }
}
