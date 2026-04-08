import { appContext } from '../app/app-context';
import { Product } from '../types/domain';

export class HomeViewModel {
  keyword: string = '';
  category: string = '全部';

  loadProducts(): Product[] {
    return appContext.listPublicProducts(this.keyword, this.category);
  }
}
