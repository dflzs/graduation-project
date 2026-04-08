import { CartItem } from '../types/domain';

export function getAllSelectedCartItemIds(cartItems: CartItem[]): string[] {
  return cartItems.map((item: CartItem) => item.id);
}

export function syncSelectedCartItemIds(cartItems: CartItem[], selectedItemIds: string[]): string[] {
  const existingIds: string[] = cartItems.map((item: CartItem) => item.id);
  return selectedItemIds.filter((itemId: string) => existingIds.includes(itemId));
}

export function isCartAllSelected(cartItems: CartItem[], selectedItemIds: string[]): boolean {
  return cartItems.length > 0 && selectedItemIds.length === cartItems.length;
}

export function calculateSelectedCartAmount(cartItems: CartItem[], selectedItemIds: string[]): number {
  return cartItems
    .filter((item: CartItem) => selectedItemIds.includes(item.id))
    .reduce((sum: number, item: CartItem) => sum + item.snapshotPrice * item.qty, 0);
}

export function resolveCartCheckoutState(selectedCount: number): 'none' | 'single' | 'multiple' {
  if (selectedCount <= 0) {
    return 'none';
  }
  if (selectedCount === 1) {
    return 'single';
  }
  return 'multiple';
}
