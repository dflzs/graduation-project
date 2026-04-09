export function canRequestRemoteProductDetail(productId: string): boolean {
  return /^\d+$/.test(productId.trim());
}
