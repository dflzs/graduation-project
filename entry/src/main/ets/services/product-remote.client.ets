import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { OperationResult, Product, ProductStatus } from '../types/domain';
import {
  RemoteCreateProductPayload,
  RemoteCreateProductResponse,
  RemoteProductDetailResponse,
  RemoteProductItem,
  RemoteProductListResponse,
  RemoteProductQuery
} from '../types/product-remote';

class ProductRequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

class RequestQueryEntry {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string) {
    this.key = key;
    this.value = value;
  }
}

function parseTimestamp(value: string): number {
  const timestamp = Date.parse(value);
  return Number.isNaN(timestamp) ? Date.now() : timestamp;
}

function normalizeStatus(value: string): ProductStatus {
  if (value === 'pending_review'
    || value === 'on_sale'
    || value === 'locked'
    || value === 'sold'
    || value === 'off_shelf'
    || value === 'rejected') {
    return value;
  }
  return 'on_sale';
}

function mapRemoteProduct(item: RemoteProductItem): Product {
  return {
    id: String(item.id),
    sellerId: String(item.seller_id),
    title: item.title,
    desc: item.description,
    price: Number(item.price),
    category: item.category,
    images: item.cover_image ? [item.cover_image] : [],
    locationTag: item.location_tag,
    status: normalizeStatus(item.status),
    isDeleted: false,
    createdAt: parseTimestamp(item.created_at),
    updatedAt: parseTimestamp(item.updated_at)
  };
}

export class RemoteProductClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async listProducts(query: RemoteProductQuery = {}): Promise<OperationResult<Product[]>> {
    const result = await this.get<RemoteProductListResponse>(
      this.withQuery('/api/products', [
        new RequestQueryEntry('keyword', query.keyword ?? ''),
        new RequestQueryEntry('category', query.category ?? ''),
        new RequestQueryEntry('status', query.status ?? '')
      ])
    );

    return this.mapProductListResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u5546\u54c1\u5217\u8868',
      '\u83b7\u53d6\u5546\u54c1\u5217\u8868\u6210\u529f'
    );
  }

  async listMyProducts(token: string): Promise<OperationResult<Product[]>> {
    const result = await this.get<RemoteProductListResponse>('/api/products/mine', token);
    return this.mapProductListResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u6211\u53d1\u5e03\u7684\u5546\u54c1',
      '\u83b7\u53d6\u6211\u53d1\u5e03\u7684\u5546\u54c1\u6210\u529f'
    );
  }

  async listAdminProducts(token: string): Promise<OperationResult<Product[]>> {
    const result = await this.get<RemoteProductListResponse>('/api/admin/products', token);
    return this.mapProductListResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u540e\u53f0\u5546\u54c1\u5217\u8868',
      '\u83b7\u53d6\u540e\u53f0\u5546\u54c1\u5217\u8868\u6210\u529f'
    );
  }

  async createProduct(
    token: string,
    payload: RemoteCreateProductPayload
  ): Promise<OperationResult<Product>> {
    const result = await this.post<RemoteCreateProductResponse>('/api/products', payload, token);
    return this.mapSingleProductResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u65b0\u521b\u5efa\u7684\u5546\u54c1\u6570\u636e',
      '\u5546\u54c1\u5df2\u63d0\u4ea4\u5ba1\u6838'
    );
  }

  async approveProduct(token: string, productId: string): Promise<OperationResult<Product>> {
    const result = await this.request<RemoteProductDetailResponse>(
      `/api/admin/products/${productId}/approve`,
      http.RequestMethod.PUT,
      undefined,
      token
    );
    return this.mapSingleProductResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u5ba1\u6838\u540e\u7684\u5546\u54c1\u6570\u636e',
      '\u5546\u54c1\u5ba1\u6838\u901a\u8fc7'
    );
  }

  async rejectProduct(token: string, productId: string): Promise<OperationResult<Product>> {
    const result = await this.request<RemoteProductDetailResponse>(
      `/api/admin/products/${productId}/reject`,
      http.RequestMethod.PUT,
      undefined,
      token
    );
    return this.mapSingleProductResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u9a73\u56de\u540e\u7684\u5546\u54c1\u6570\u636e',
      '\u5546\u54c1\u5df2\u9a73\u56de'
    );
  }

  async forceOffShelfProduct(token: string, productId: string): Promise<OperationResult<Product>> {
    const result = await this.request<RemoteProductDetailResponse>(
      `/api/admin/products/${productId}/off-shelf`,
      http.RequestMethod.PUT,
      undefined,
      token
    );
    return this.mapSingleProductResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u4e0b\u67b6\u540e\u7684\u5546\u54c1\u6570\u636e',
      '\u5546\u54c1\u5df2\u4e0b\u67b6'
    );
  }

  async getProductDetail(productId: string): Promise<OperationResult<Product>> {
    const result = await this.get<RemoteProductDetailResponse>(`/api/products/${productId}`);
    return this.mapSingleProductResponse(
      result,
      '\u670d\u52a1\u5668\u6ca1\u6709\u8fd4\u56de\u5546\u54c1\u8be6\u60c5',
      '\u83b7\u53d6\u5546\u54c1\u8be6\u60c5\u6210\u529f'
    );
  }

  private mapProductListResponse(
    result: OperationResult<RemoteProductListResponse>,
    emptyMessage: string,
    successMessage: string
  ): OperationResult<Product[]> {
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    const items = result.data?.data;
    if (!items) {
      return {
        ok: false,
        message: emptyMessage
      };
    }

    return {
      ok: true,
      message: result.data?.message || successMessage,
      data: items.map(mapRemoteProduct)
    };
  }

  private mapSingleProductResponse(
    result: OperationResult<RemoteProductDetailResponse | RemoteCreateProductResponse>,
    emptyMessage: string,
    successMessage: string
  ): OperationResult<Product> {
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    const item = result.data?.data;
    if (!item) {
      return {
        ok: false,
        message: emptyMessage
      };
    }

    return {
      ok: true,
      message: result.data?.message || successMessage,
      data: mapRemoteProduct(item)
    };
  }

  private async get<T>(path: string, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.GET, undefined, token);
  }

  private async post<T>(path: string, payload: Object, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.POST, payload, token);
  }

  private async request<T>(
    path: string,
    method: http.RequestMethod,
    payload?: Object,
    token?: string
  ): Promise<OperationResult<T>> {
    const request = http.createHttp();
    const headers = new ProductRequestHeaders();
    if (token && token.length > 0) {
      headers.Authorization = `Bearer ${token}`;
    }

    try {
      const response = await request.request(`${this.baseUrl}${path}`, {
        method,
        header: headers,
        extraData: payload ? JSON.stringify(payload) : undefined,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: AUTH_HTTP_TIMEOUT_MS,
        connectTimeout: AUTH_HTTP_TIMEOUT_MS
      });

      const responseText = this.toResponseText(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return {
          ok: false,
          message: this.extractErrorMessage(
            responseText,
            `\u8bf7\u6c42\u5931\u8d25\uff0c\u72b6\u6001\u7801 ${response.responseCode}`
          )
        };
      }

      if (!responseText) {
        return {
          ok: false,
          message: '\u5546\u54c1\u670d\u52a1\u8fd4\u56de\u4e86\u7a7a\u54cd\u5e94'
        };
      }

      return {
        ok: true,
        message: '',
        data: JSON.parse(responseText) as T
      };
    } catch (error) {
      return {
        ok: false,
        message: this.toErrorMessage(error as Object)
      };
    } finally {
      request.destroy();
    }
  }

  private withQuery(path: string, entries: RequestQueryEntry[]): string {
    const queryParts: string[] = [];
    entries.forEach((entry: RequestQueryEntry) => {
      const value = entry.value.trim();
      if (value.length > 0) {
        queryParts.push(`${entry.key}=${encodeURIComponent(value)}`);
      }
    });
    return queryParts.length > 0 ? `${path}?${queryParts.join('&')}` : path;
  }

  private extractErrorMessage(responseText: string, fallbackMessage: string): string {
    if (!responseText) {
      return fallbackMessage;
    }

    try {
      const parsed = JSON.parse(responseText) as Record<string, Object>;
      if (typeof parsed.message === 'string' && parsed.message.length > 0) {
        return parsed.message;
      }
    } catch (_error) {
    }

    return responseText;
  }

  private toResponseText(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result;
    }
    if (result instanceof ArrayBuffer) {
      return '';
    }
    return JSON.stringify(result);
  }

  private toErrorMessage(error: Object): string {
    const maybeError = error as Record<string, Object>;
    if (typeof maybeError.message === 'string' && maybeError.message.length > 0) {
      return maybeError.message;
    }
    if (typeof maybeError.code === 'number') {
      return `\u7f51\u7edc\u8bf7\u6c42\u5931\u8d25\uff0c\u9519\u8bef\u7801 ${maybeError.code}`;
    }
    return '\u7f51\u7edc\u8bf7\u6c42\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
  }
}

export const remoteProductClient: RemoteProductClient = new RemoteProductClient();
