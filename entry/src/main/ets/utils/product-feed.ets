import { Product } from '../types/domain';
import { canRequestRemoteProductDetail } from './product-detail-source';

export function mergeKnownRemoteProductIds(existingIds: string[], remoteProducts: Product[]): string[] {
  const mergedIds: string[] = [];

  existingIds.forEach((productId: string) => {
    if (!mergedIds.includes(productId)) {
      mergedIds.push(productId);
    }
  });

  remoteProducts.forEach((product: Product) => {
    if (!mergedIds.includes(product.id)) {
      mergedIds.push(product.id);
    }
  });

  return mergedIds;
}

export function resolveVisibleRemoteHomeProducts(products: Product[], remoteProductIds: string[]): Product[] {
  if (remoteProductIds.length === 0) {
    return [];
  }

  const visibleProducts: Product[] = [];
  remoteProductIds.forEach((productId: string) => {
    if (!canRequestRemoteProductDetail(productId)) {
      return;
    }

    const product: Product | undefined = products.find((item: Product) => item.id === productId);
    if (product && !product.isDeleted) {
      visibleProducts.push(product);
    }
  });

  return visibleProducts.sort((a: Product, b: Product) => b.createdAt - a.createdAt);
}
