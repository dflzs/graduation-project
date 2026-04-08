import { CartContent } from '../../components/CartContent';

@Entry
@Component
struct CartPage {
  build() {
    Column() {
      CartContent({ shellMode: false })
    }
    .width('100%')
    .height('100%')
  }
}
