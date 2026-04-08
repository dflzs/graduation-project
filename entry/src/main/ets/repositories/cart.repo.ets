import { localDb } from '../data/db/local-db';
import { CartItem } from '../types/domain';

export class CartRepository {
  listByUser(userId: string): CartItem[] {
    return localDb.getCartItems().filter((item: CartItem) => item.userId === userId);
  }

  getByUserAndProduct(userId: string, productId: string): CartItem | null {
    const item: CartItem | undefined = localDb.getCartItems()
      .find((cart: CartItem) => cart.userId === userId && cart.productId === productId);
    return item ?? null;
  }

  save(item: CartItem): CartItem {
    const cartItems: CartItem[] = localDb.getCartItems();
    const index: number = cartItems.findIndex((c: CartItem) => c.id === item.id);
    if (index >= 0) {
      cartItems[index] = item;
    } else {
      cartItems.push(item);
    }
    localDb.setCartItems(cartItems);
    return item;
  }

  remove(itemId: string): void {
    const cartItems: CartItem[] = localDb.getCartItems().filter((item: CartItem) => item.id !== itemId);
    localDb.setCartItems(cartItems);
  }

  clearByUser(userId: string): void {
    const cartItems: CartItem[] = localDb.getCartItems().filter((item: CartItem) => item.userId !== userId);
    localDb.setCartItems(cartItems);
  }
}

export const cartRepository: CartRepository = new CartRepository();
