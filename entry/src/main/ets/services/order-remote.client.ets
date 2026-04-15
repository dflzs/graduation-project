import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { OperationResult, Order, OrderStatus } from '../types/domain';
import {
  RemoteCreateOrderPayload,
  RemoteOrderDetailResponse,
  RemoteOrderItem,
  RemoteOrderListResponse
} from '../types/order-remote';

class OrderRequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

function parseTimestamp(value: string | number): number {
  if (typeof value === 'number') {
    return value;
  }
  const timestamp = Date.parse(value);
  return Number.isNaN(timestamp) ? Date.now() : timestamp;
}

function normalizeOrderStatus(value: string): OrderStatus {
  if (value === 'pending_payment') {
    return OrderStatus.PENDING_PAYMENT;
  }
  if (value === 'paid') {
    return OrderStatus.PAID_SIMULATED;
  }
  if (value === 'ready_handover') {
    return OrderStatus.READY_HANDOVER;
  }
  if (value === 'completed') {
    return OrderStatus.COMPLETED;
  }
  if (value === 'canceled') {
    return OrderStatus.CANCELED;
  }
  return OrderStatus.PENDING_PAYMENT;
}

function normalizeBooleanFlag(value: number | boolean): boolean {
  return typeof value === 'boolean' ? value : value === 1;
}

export function mapRemoteOrderItem(item: RemoteOrderItem): Order {
  return {
    id: String(item.id),
    productId: String(item.product_id),
    buyerId: String(item.buyer_id),
    sellerId: String(item.seller_id),
    amount: Number(item.amount),
    address: item.address,
    locationTag: item.location_tag,
    schoolId: item.school_id,
    schoolName: item.school_name,
    campusId: item.campus_id,
    campusName: item.campus_name,
    locationGroupId: item.location_group_id,
    locationGroupName: item.location_group_name,
    tradeLocationId: item.trade_location_id,
    tradeLocationName: item.trade_location_name,
    locationSafetyTips: item.location_safety_tips,
    payType: 'simulated',
    status: normalizeOrderStatus(item.status),
    buyerArrived: normalizeBooleanFlag(item.buyer_arrived),
    sellerArrived: normalizeBooleanFlag(item.seller_arrived),
    reviewed: false,
    createdAt: parseTimestamp(item.created_at),
    updatedAt: parseTimestamp(item.updated_at)
  };
}

export class RemoteOrderClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async createOrder(token: string, payload: RemoteCreateOrderPayload): Promise<OperationResult<Order>> {
    const result = await this.post<RemoteOrderDetailResponse>('/api/orders', payload, token);
    return this.mapSingleOrderResponse(result, '服务端没有返回新创建的订单数据', '下单成功');
  }

  async listMyOrders(token: string): Promise<OperationResult<Order[]>> {
    const result = await this.get<RemoteOrderListResponse>('/api/orders', token);
    return this.mapOrderListResponse(result, '服务端没有返回订单列表数据', '获取订单列表成功');
  }

  async getOrderDetail(token: string, orderId: string): Promise<OperationResult<Order>> {
    const result = await this.get<RemoteOrderDetailResponse>(`/api/orders/${orderId}`, token);
    return this.mapSingleOrderResponse(result, '服务端没有返回订单详情数据', '获取订单详情成功');
  }

  async simulatePay(token: string, orderId: string): Promise<OperationResult<Order>> {
    const result = await this.put<RemoteOrderDetailResponse>(`/api/orders/${orderId}/pay`, undefined, token);
    return this.mapSingleOrderResponse(result, '服务端没有返回支付后的订单数据', '模拟支付成功');
  }

  async cancelOrder(token: string, orderId: string): Promise<OperationResult<Order>> {
    const result = await this.put<RemoteOrderDetailResponse>(`/api/orders/${orderId}/cancel`, undefined, token);
    return this.mapSingleOrderResponse(result, '服务端没有返回取消后的订单数据', '订单已取消');
  }

  async markArrived(token: string, orderId: string): Promise<OperationResult<Order>> {
    const result = await this.put<RemoteOrderDetailResponse>(`/api/orders/${orderId}/arrive`, undefined, token);
    return this.mapSingleOrderResponse(result, '服务端没有返回到场后的订单数据', '到达状态已更新');
  }

  async completeOrder(token: string, orderId: string): Promise<OperationResult<Order>> {
    const result = await this.put<RemoteOrderDetailResponse>(`/api/orders/${orderId}/complete`, undefined, token);
    return this.mapSingleOrderResponse(result, '服务端没有返回完结后的订单数据', '订单已完成');
  }

  private mapOrderListResponse(
    result: OperationResult<RemoteOrderListResponse>,
    emptyMessage: string,
    successMessage: string
  ): OperationResult<Order[]> {
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    const items = result.data?.data;
    if (!items) {
      return { ok: false, message: emptyMessage };
    }

    return {
      ok: true,
      message: result.data?.message || successMessage,
      data: items.map(mapRemoteOrderItem)
    };
  }

  private mapSingleOrderResponse(
    result: OperationResult<RemoteOrderDetailResponse>,
    emptyMessage: string,
    successMessage: string
  ): OperationResult<Order> {
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    const item = result.data?.data;
    if (!item) {
      return { ok: false, message: emptyMessage };
    }

    return {
      ok: true,
      message: result.data?.message || successMessage,
      data: mapRemoteOrderItem(item)
    };
  }

  private async get<T>(path: string, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.GET, undefined, token);
  }

  private async post<T>(path: string, payload: Object, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.POST, payload, token);
  }

  private async put<T>(path: string, payload?: Object, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.PUT, payload, token);
  }

  private async request<T>(
    path: string,
    method: http.RequestMethod,
    payload?: Object,
    token?: string
  ): Promise<OperationResult<T>> {
    const request = http.createHttp();
    const headers = new OrderRequestHeaders();
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
          message: this.extractErrorMessage(responseText, `请求失败，状态码 ${response.responseCode}`)
        };
      }

      if (!responseText) {
        return {
          ok: false,
          message: '订单服务返回了空响应'
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
      return `网络请求失败，错误码 ${maybeError.code}`;
    }
    return '网络请求失败，请稍后重试';
  }
}

export const remoteOrderClient: RemoteOrderClient = new RemoteOrderClient();
