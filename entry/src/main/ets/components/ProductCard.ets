import { Product } from '../types/domain';

@Component
export struct ProductCard {
  @Prop product: Product = {} as Product;
  @Prop onOpen: (productId: string) => void = (_: string) => {};

  build() {
    Column({ space: 6 }) {
      Text(this.product.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
      Text(`分类: ${this.product.category}  地点: ${this.product.locationTag}`)
        .fontSize(13)
        .fontColor('#666666')
      Text(this.product.desc)
        .fontSize(13)
        .fontColor('#444444')
        .maxLines(2)
      Row() {
        Text(`￥${this.product.price.toFixed(2)}`)
          .fontSize(20)
          .fontColor('#E5484D')
        Blank()
        Button('查看详情')
          .height(32)
          .onClick(() => this.onOpen(this.product.id))
      }
      .width('100%')
    }
    .padding(12)
    .margin({ bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}
