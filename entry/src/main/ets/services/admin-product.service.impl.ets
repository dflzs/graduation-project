import { productRepository } from '../repositories/product.repo';
import { OperationResult, Product, ProductStatus, User } from '../types/domain';
import { AdminProductService } from '../types/service-contracts';
import { getAdminAccessDeniedMessage, getAdminActionDeniedMessage } from './guard.service';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteProductClient, remoteProductClient } from './product-remote.client';
import { notificationService } from './notification.service.impl';
import { syncService } from './sync.service.impl';

class AdminProductSession {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

export class AdminProductServiceImpl implements AdminProductService {
  private readonly remoteClient: RemoteProductClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteProductClient = remoteProductClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  private resolveAdminSession(): AdminProductSession | null {
    if (!this.stateService.isLoggedIn()) {
      return null;
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.role !== 'admin' || currentUser.status !== 'active') {
      return null;
    }
    return new AdminProductSession(this.stateService.getToken(), currentUser);
  }

  private canRequestRemoteAdmin(currentUser: User): boolean {
    return /^\d+$/.test(currentUser.id.trim());
  }

  private canRequestRemoteProduct(productId: string): boolean {
    return /^\d+$/.test(productId.trim());
  }

  private listLocalProducts(): Product[] {
    return productRepository.list()
      .filter((item: Product) => !item.isDeleted)
      .sort((a: Product, b: Product) => b.createdAt - a.createdAt);
  }

  private publishProductChanged(product: Product): void {
    syncService.publish({
      key: 'products:changed',
      value: product.id,
      updatedAt: product.updatedAt
    });
  }

  private getActionSuccessMessage(status: ProductStatus): string {
    if (status === 'on_sale') {
      return '\u5546\u54c1\u5ba1\u6838\u901a\u8fc7';
    }
    if (status === 'rejected') {
      return '\u5546\u54c1\u5df2\u9a73\u56de';
    }
    return '\u5546\u54c1\u5df2\u4e0b\u67b6';
  }

  private persistLocalStatus(productId: string, status: ProductStatus): OperationResult<Product> {
    const updated = productRepository.updateStatus(productId, status);
    if (!updated) {
      return { ok: false, message: '\u5546\u54c1\u4e0d\u5b58\u5728' };
    }
    this.publishProductChanged(updated);
    return {
      ok: true,
      message: this.getActionSuccessMessage(status),
      data: updated
    };
  }

  private notifyIfNeeded(status: ProductStatus, product: Product): void {
    if (status === 'on_sale') {
      notificationService.notifyProductApproved(product.sellerId, product.title, product.id);
      return;
    }
    if (status === 'rejected') {
      notificationService.notifyProductRejected(product.sellerId, product.title, product.id);
    }
  }

  async listProducts(): Promise<OperationResult<Product[]>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminAccessDeniedMessage(this.stateService.getCurrentUser()) };
    }

    if (!this.canRequestRemoteAdmin(session.user)) {
      return {
        ok: true,
        message: '\u83b7\u53d6\u540e\u53f0\u5546\u54c1\u5217\u8868\u6210\u529f',
        data: this.listLocalProducts()
      };
    }

    const remoteResult = await this.remoteClient.listAdminProducts(session.token);
    if (remoteResult.ok && remoteResult.data) {
      const products = remoteResult.data.sort((a: Product, b: Product) => b.createdAt - a.createdAt);
      products.forEach((item: Product) => {
        productRepository.mergeRemote(item);
      });
      return {
        ok: true,
        message: remoteResult.message,
        data: products
      };
    }

    return {
      ok: true,
      message: '\u5df2\u4f7f\u7528\u672c\u5730\u5546\u54c1\u7f13\u5b58',
      data: this.listLocalProducts()
    };
  }

  async approveProduct(productId: string): Promise<OperationResult<Product>> {
    return this.runRemoteFirstAction(productId, 'on_sale');
  }

  async rejectProduct(productId: string): Promise<OperationResult<Product>> {
    return this.runRemoteFirstAction(productId, 'rejected');
  }

  async forceOffShelfProduct(productId: string): Promise<OperationResult<Product>> {
    return this.runRemoteFirstAction(productId, 'off_shelf');
  }

  private async runRemoteFirstAction(productId: string, fallbackStatus: ProductStatus): Promise<OperationResult<Product>> {
    const session = this.resolveAdminSession();
    if (!session) {
      return { ok: false, message: getAdminActionDeniedMessage(this.stateService.getCurrentUser()) };
    }

    if (this.canRequestRemoteAdmin(session.user) && this.canRequestRemoteProduct(productId)) {
      const remoteResult = await this.runRemoteAction(session.token, productId, fallbackStatus);
      if (remoteResult.ok && remoteResult.data) {
        const persisted = productRepository.mergeRemote(remoteResult.data);
        this.notifyIfNeeded(fallbackStatus, persisted);
        return {
          ok: true,
          message: remoteResult.message,
          data: persisted
        };
      }
    }

    const localResult = this.persistLocalStatus(productId, fallbackStatus);
    if (localResult.ok && localResult.data) {
      this.notifyIfNeeded(fallbackStatus, localResult.data);
    }
    return localResult;
  }

  private async runRemoteAction(
    token: string,
    productId: string,
    status: ProductStatus
  ): Promise<OperationResult<Product>> {
    if (status === 'on_sale') {
      return this.remoteClient.approveProduct(token, productId);
    }
    if (status === 'rejected') {
      return this.remoteClient.rejectProduct(token, productId);
    }
    return this.remoteClient.forceOffShelfProduct(token, productId);
  }
}

export const adminProductService: AdminProductServiceImpl = new AdminProductServiceImpl();
