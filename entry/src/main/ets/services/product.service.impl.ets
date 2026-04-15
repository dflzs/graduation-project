import { PRODUCT_CATEGORIES } from '../constants/config';
import { productRepository } from '../repositories/product.repo';
import { userRepository } from '../repositories/user.repo';
import { OperationResult, Product } from '../types/domain';
import { ProductQuery, ProductService } from '../types/service-contracts';
import { newId } from '../utils/id';
import { isNotBlank } from '../utils/validator';
import { syncService } from './sync.service.impl';

export class ProductServiceImpl implements ProductService {
  private canManageProduct(userId: string): OperationResult<null> {
    const user = userRepository.getById(userId);
    if (!user) {
      return { ok: false, message: '用户不存在' };
    }
    if (user.status !== 'active') {
      return { ok: false, message: '该账号已被停用，无法发布或编辑商品' };
    }
    if (user.role === 'admin') {
      return { ok: false, message: '管理员账号不支持发布或编辑商品' };
    }
    return { ok: true, message: '', data: null };
  }

  listProducts(query: ProductQuery = {}): Product[] {
    return productRepository.search({
      keyword: query.keyword,
      category: query.category,
      status: query.status
    });
  }

  getProductById(productId: string): Product | null {
    return productRepository.getById(productId);
  }

  createProduct(input: Partial<Product>, sellerId: string): OperationResult<Product> {
    const permission = this.canManageProduct(sellerId);
    if (!permission.ok) {
      return { ok: false, message: permission.message };
    }
    if (!isNotBlank(input.title ?? '')) {
      return { ok: false, message: '标题不能为空' };
    }
    if ((input.price ?? 0) <= 0) {
      return { ok: false, message: '价格必须大于0' };
    }

    const now: number = Date.now();
    const category: string = PRODUCT_CATEGORIES.includes(input.category ?? '') ? (input.category ?? '') : PRODUCT_CATEGORIES[0];
    const product: Product = {
      id: newId('product'),
      sellerId,
      title: input.title ?? '',
      desc: input.desc ?? '',
      price: input.price ?? 0,
      category,
      images: input.images ?? [],
      locationTag: input.locationTag ?? '图书馆大厅',
      schoolId: input.schoolId,
      schoolName: input.schoolName,
      campusId: input.campusId,
      campusName: input.campusName,
      locationGroupId: input.locationGroupId,
      locationGroupName: input.locationGroupName,
      tradeLocationId: input.tradeLocationId,
      tradeLocationName: input.tradeLocationName,
      locationSafetyTips: input.locationSafetyTips,
      status: 'pending_review',
      isDeleted: false,
      createdAt: now,
      updatedAt: now
    };

    productRepository.save(product);
    syncService.publish({
      key: 'products:changed',
      value: product.id,
      updatedAt: product.updatedAt
    });
    return {
      ok: true,
      message: '商品已提交审核',
      data: product
    };
  }

  updateProduct(productId: string, input: Partial<Product>, operatorId: string): OperationResult<Product> {
    const permission = this.canManageProduct(operatorId);
    if (!permission.ok) {
      return { ok: false, message: permission.message };
    }

    const product: Product | null = productRepository.getById(productId);
    if (!product || product.isDeleted) {
      return { ok: false, message: '商品不存在' };
    }
    if (product.sellerId !== operatorId) {
      return { ok: false, message: '只有发布者可编辑' };
    }

    product.title = input.title ?? product.title;
    product.desc = input.desc ?? product.desc;
    product.price = input.price ?? product.price;
    product.category = input.category ?? product.category;
    product.locationTag = input.locationTag ?? product.locationTag;
    product.schoolId = input.schoolId ?? product.schoolId;
    product.schoolName = input.schoolName ?? product.schoolName;
    product.campusId = input.campusId ?? product.campusId;
    product.campusName = input.campusName ?? product.campusName;
    product.locationGroupId = input.locationGroupId ?? product.locationGroupId;
    product.locationGroupName = input.locationGroupName ?? product.locationGroupName;
    product.tradeLocationId = input.tradeLocationId ?? product.tradeLocationId;
    product.tradeLocationName = input.tradeLocationName ?? product.tradeLocationName;
    product.locationSafetyTips = input.locationSafetyTips ?? product.locationSafetyTips;
    product.updatedAt = Date.now();

    productRepository.save(product);
    syncService.publish({
      key: 'products:changed',
      value: product.id,
      updatedAt: product.updatedAt
    });
    return {
      ok: true,
      message: '更新成功',
      data: product
    };
  }
}

export const productService: ProductServiceImpl = new ProductServiceImpl();
