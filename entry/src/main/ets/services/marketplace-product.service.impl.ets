import { productRepository } from '../repositories/product.repo';
import { OperationResult, Product, User } from '../types/domain';
import { MarketplaceProductService } from '../types/service-contracts';
import { productService } from './product.service.impl';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteProductClient, remoteProductClient } from './product-remote.client';
import { notificationService } from './notification.service.impl';
import { RemoteCreateProductPayload } from '../types/product-remote';

class MarketplaceProductSession {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

function sortProducts(products: Product[]): Product[] {
  return products.sort((a: Product, b: Product) => b.createdAt - a.createdAt);
}

export class MarketplaceProductServiceImpl implements MarketplaceProductService {
  private readonly remoteClient: RemoteProductClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteProductClient = remoteProductClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  private resolveSessionForUser(userId: string): MarketplaceProductSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.id !== userId) {
      return null;
    }
    return new MarketplaceProductSession(this.stateService.getToken(), currentUser);
  }

  private canRequestRemoteById(id: string): boolean {
    return /^\d+$/.test(id.trim());
  }

  private listLocalPublicProducts(): Product[] {
    return productService.listProducts({ status: 'on_sale' });
  }

  private listLocalPublishedProducts(userId: string): Product[] {
    return sortProducts(
      productRepository.list().filter((item: Product) => item.sellerId === userId && !item.isDeleted)
    );
  }

  async listMarketplaceProducts(): Promise<OperationResult<Product[]>> {
    const remoteResult = await this.remoteClient.listProducts({ status: 'on_sale' });
    if (remoteResult.ok && remoteResult.data) {
      const products = sortProducts(remoteResult.data);
      products.forEach((item: Product) => productRepository.mergeRemote(item));
      return {
        ok: true,
        message: remoteResult.message,
        data: products
      };
    }

    return {
      ok: true,
      message: '\u5df2\u4f7f\u7528\u672c\u5730\u5546\u54c1\u7f13\u5b58',
      data: this.listLocalPublicProducts()
    };
  }

  async listMyPublishedProducts(userId: string): Promise<OperationResult<Product[]>> {
    const session = this.resolveSessionForUser(userId);
    if (session && this.canRequestRemoteById(userId)) {
      const remoteResult = await this.remoteClient.listMyProducts(session.token);
      if (remoteResult.ok && remoteResult.data) {
        const products = sortProducts(remoteResult.data);
        products.forEach((item: Product) => productRepository.mergeRemote(item));
        return {
          ok: true,
          message: remoteResult.message,
          data: products
        };
      }
    }

    return {
      ok: true,
      message: '\u5df2\u4f7f\u7528\u672c\u5730\u6211\u7684\u53d1\u5e03\u7f13\u5b58',
      data: this.listLocalPublishedProducts(userId)
    };
  }

  async getProductDetail(productId: string): Promise<OperationResult<Product>> {
    const localProduct = productRepository.getById(productId);
    if (!this.canRequestRemoteById(productId)) {
      if (localProduct) {
        return {
          ok: true,
          message: '\u83b7\u53d6\u5546\u54c1\u8be6\u60c5\u6210\u529f',
          data: localProduct
        };
      }
      return { ok: false, message: '\u5546\u54c1\u4e0d\u5b58\u5728\u6216\u52a0\u8f7d\u5931\u8d25' };
    }

    const remoteResult = await this.remoteClient.getProductDetail(productId);
    if (remoteResult.ok && remoteResult.data) {
      const product = productRepository.mergeRemote(remoteResult.data);
      return {
        ok: true,
        message: remoteResult.message,
        data: product
      };
    }

    if (localProduct) {
      return {
        ok: true,
        message: '\u5df2\u4f7f\u7528\u672c\u5730\u5546\u54c1\u7f13\u5b58',
        data: localProduct
      };
    }

    return {
      ok: false,
      message: remoteResult.message
    };
  }

  async createMarketplaceProduct(input: RemoteCreateProductPayload, sellerId: string): Promise<OperationResult<Product>> {
    const session = this.resolveSessionForUser(sellerId);
    if (session && this.canRequestRemoteById(sellerId)) {
      const remoteResult = await this.remoteClient.createProduct(
        session.token,
        new RemoteCreateProductPayload(
          input.title,
          input.description,
          input.price,
          input.category,
          input.location_tag,
          input.cover_image,
          input.school_id,
          input.campus_id,
          input.location_group_id,
          input.trade_location_id
        )
      );
      if (remoteResult.ok && remoteResult.data) {
        const product = productRepository.mergeRemote(remoteResult.data);
        notificationService.notifyProductSubmitted(sellerId, product.title, product.id);
        return {
          ok: true,
          message: remoteResult.message,
          data: product
        };
      }
    }

    const localResult = productService.createProduct({
      title: input.title,
      desc: input.description,
      price: input.price,
      category: input.category,
      locationTag: input.location_tag,
      images: input.cover_image && input.cover_image.length > 0 ? [input.cover_image] : [],
      schoolId: input.school_id,
      campusId: input.campus_id,
      locationGroupId: input.location_group_id,
      tradeLocationId: input.trade_location_id
    }, sellerId);
    if (localResult.ok && localResult.data) {
      notificationService.notifyProductSubmitted(sellerId, localResult.data.title, localResult.data.id);
    }
    return localResult;
  }
}

export const marketplaceProductService: MarketplaceProductServiceImpl = new MarketplaceProductServiceImpl();
