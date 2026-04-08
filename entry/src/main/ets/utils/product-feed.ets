import { Product } from '../types/domain';

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
