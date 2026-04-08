@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop actionText: string = '';
  @Prop onAction: () => void = () => {};

  build() {
    Row() {
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Blank()
      if (this.actionText.length > 0) {
        Text(this.actionText)
          .fontSize(14)
          .fontColor('#0A84FF')
          .onClick(() => this.onAction())
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
  }
}
