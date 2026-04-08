import { localDb } from '../data/db/local-db';
import { OrderStatus, Product, ProductStatus } from '../types/domain';
import { orderRepository } from './order.repo';

export interface ProductSearchInput {
  keyword?: string;
  category?: string;
  status?: string;
}

export class ProductRepository {
  private hasSupportingLocalTransactionState(productId: string, status: ProductStatus): boolean {
    if (status === 'locked') {
      return orderRepository.list().some((order) =>
        order.productId === productId
        && (order.status === OrderStatus.PENDING_PAYMENT
          || order.status === OrderStatus.PAID_SIMULATED
          || order.status === OrderStatus.READY_HANDOVER)
      );
    }

    if (status === 'sold') {
      return orderRepository.list().some((order) =>
        order.productId === productId
        && order.status === OrderStatus.COMPLETED
      );
    }

    return false;
  }

  private shouldPreserveLocalTransactionalState(existing: Product | null, incoming: Product): boolean {
    return existing !== null
      && incoming.status === 'on_sale'
      && (existing.status === 'locked' || existing.status === 'sold')
      && this.hasSupportingLocalTransactionState(existing.id, existing.status);
  }

  private persist(product: Product): Product {
    const products: Product[] = localDb.getProducts();
    const index: number = products.findIndex((p: Product) => p.id === product.id);

    if (index >= 0) {
      products[index] = product;
    } else {
      products.push(product);
    }

    localDb.setProducts(products);
    return product;
  }

  list(): Product[] {
    return localDb.getProducts();
  }

  getById(productId: string): Product | null {
    const product: Product | undefined = localDb.getProducts().find((p: Product) => p.id === productId);
    return product ?? null;
  }

  search(input: ProductSearchInput = {}): Product[] {
    const keyword: string = (input.keyword ?? '').trim().toLowerCase();
    const category: string = (input.category ?? '').trim();
    const status: string = (input.status ?? '').trim();

    return localDb.getProducts()
      .filter((p: Product) => !p.isDeleted)
      .filter((p: Product) => status.length === 0 || p.status === status)
      .filter((p: Product) => category.length === 0 || category === '全部' || p.category === category)
      .filter((p: Product) => {
        if (keyword.length === 0) {
          return true;
        }
        return p.title.toLowerCase().includes(keyword) || p.desc.toLowerCase().includes(keyword);
      })
      .sort((a: Product, b: Product) => b.createdAt - a.createdAt);
  }

  save(product: Product): Product {
    return this.persist(product);
  }

  mergeRemote(product: Product): Product {
    const products: Product[] = localDb.getProducts();
    const index: number = products.findIndex((p: Product) => p.id === product.id);
    const existing: Product | null = index >= 0 ? products[index] : null;
    const preservedStatus: ProductStatus = existing ? existing.status : product.status;
    const preservedUpdatedAt: number = existing ? existing.updatedAt : product.updatedAt;
    const nextProduct: Product = this.shouldPreserveLocalTransactionalState(existing, product)
      ? {
          id: product.id,
          sellerId: product.sellerId,
          title: product.title,
          desc: product.desc,
          price: product.price,
          category: product.category,
          images: product.images,
          locationTag: product.locationTag,
          status: preservedStatus,
          isDeleted: product.isDeleted,
          createdAt: product.createdAt,
          updatedAt: Math.max(product.updatedAt, preservedUpdatedAt)
        }
      : product;

    return this.persist(nextProduct);
  }

  updateStatus(productId: string, status: ProductStatus): Product | null {
    const product: Product | null = this.getById(productId);
    if (!product || product.isDeleted) {
      return null;
    }

    product.status = status;
    product.updatedAt = Date.now();
    return this.save(product);
  }
}

export const productRepository: ProductRepository = new ProductRepository();
