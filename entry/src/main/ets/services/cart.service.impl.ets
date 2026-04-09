import { cartRepository } from '../repositories/cart.repo';
import { productRepository } from '../repositories/product.repo';
import { CartItem, OperationResult, Product } from '../types/domain';
import { newId } from '../utils/id';
import { isProductOwnedByUser } from '../utils/trade-guard';
import { syncService } from './sync.service.impl';

export class CartServiceImpl {
  listByUser(userId: string): CartItem[] {
    return cartRepository.listByUser(userId)
      .sort((a: CartItem, b: CartItem) => b.updatedAt - a.updatedAt);
  }

  addToCart(userId: string, productId: string, qty: number = 1): OperationResult<CartItem> {
    const product: Product | null = productRepository.getById(productId);
    if (!product || product.isDeleted || product.status !== 'on_sale') {
      return { ok: false, message: '商品不可加入购物车' };
    }
    if (isProductOwnedByUser(product, userId)) {
      return { ok: false, message: '不能购买自己发布的商品' };
    }

    const existed: CartItem | null = cartRepository.getByUserAndProduct(userId, productId);
    if (existed) {
      existed.qty += qty;
      existed.snapshotPrice = product.price;
      existed.updatedAt = Date.now();
      cartRepository.save(existed);
      this.publishCart(userId);
      return { ok: true, message: '购物车数量已更新', data: existed };
    }

    const item: CartItem = {
      id: newId('cart'),
      userId,
      productId,
      qty,
      snapshotPrice: product.price,
      updatedAt: Date.now()
    };

    cartRepository.save(item);
    this.publishCart(userId);
    return { ok: true, message: '已加入购物车', data: item };
  }

  removeItem(userId: string, itemId: string): void {
    cartRepository.remove(itemId);
    this.publishCart(userId);
  }

  clearByUser(userId: string): void {
    cartRepository.clearByUser(userId);
    this.publishCart(userId);
  }

  private publishCart(userId: string): void {
    const payload = JSON.stringify(this.listByUser(userId));
    syncService.publish({
      key: `cart:${userId}`,
      value: payload,
      updatedAt: Date.now()
    });
  }
}

export const cartService: CartServiceImpl = new CartServiceImpl();
