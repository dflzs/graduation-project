import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { AppealRecord, OperationResult } from '../types/domain';
import {
  RemoteAppealItem,
  RemoteAppealListResponse,
  RemoteAppealResponse,
  RemoteAppealReviewPayload,
  RemoteAppealSubmitPayload
} from '../types/appeal-remote';

class AppealRequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

function parseTimestamp(value: string | number | undefined): number | undefined {
  if (value === undefined) {
    return undefined;
  }
  if (typeof value === 'number') {
    return value;
  }
  const timestamp = Date.parse(value);
  return Number.isNaN(timestamp) ? undefined : timestamp;
}

function mapRemoteAppealItem(item: RemoteAppealItem): AppealRecord {
  return {
    id: String(item.id),
    moderationRecordId: String(item.moderation_record_id),
    appellantId: String(item.appellant_id),
    reason: item.reason,
    description: item.description,
    evidenceItems: Array.isArray(item.evidence_items) ? item.evidence_items : [],
    status: item.status,
    reviewedBy: item.reviewed_by !== undefined ? String(item.reviewed_by) : undefined,
    reviewComment: item.review_comment,
    reviewedAt: parseTimestamp(item.reviewed_at),
    createdAt: parseTimestamp(item.created_at) ?? Date.now(),
    updatedAt: parseTimestamp(item.updated_at) ?? Date.now()
  };
}

export class RemoteAppealClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async submitAppeal(
    token: string,
    payload: RemoteAppealSubmitPayload
  ): Promise<OperationResult<AppealRecord>> {
    const result = await this.post<RemoteAppealResponse>('/api/appeals', payload, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回最新申诉记录' };
    }
    return {
      ok: true,
      message: result.data.message || '申诉提交成功',
      data: mapRemoteAppealItem(result.data.data)
    };
  }

  async listMyAppeals(token: string): Promise<OperationResult<AppealRecord[]>> {
    const result = await this.get<RemoteAppealListResponse>('/api/appeals/my', token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回我的申诉列表' };
    }
    return {
      ok: true,
      message: result.data.message || '获取我的申诉成功',
      data: result.data.data.map(mapRemoteAppealItem)
    };
  }

  async listAppeals(token: string, status?: string): Promise<OperationResult<AppealRecord[]>> {
    const query = status && status.length > 0 ? `?status=${encodeURIComponent(status)}` : '';
    const result = await this.get<RemoteAppealListResponse>(`/api/admin/appeals${query}`, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回后台申诉列表' };
    }
    return {
      ok: true,
      message: result.data.message || '获取后台申诉成功',
      data: result.data.data.map(mapRemoteAppealItem)
    };
  }

  async reviewAppeal(
    token: string,
    appealId: string,
    payload: RemoteAppealReviewPayload
  ): Promise<OperationResult<AppealRecord>> {
    const result = await this.post<RemoteAppealResponse>(`/api/admin/appeals/${appealId}/review`, payload, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回最新申诉审核结果' };
    }
    return {
      ok: true,
      message: result.data.message || '申诉审核成功',
      data: mapRemoteAppealItem(result.data.data)
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
    const headers = new AppealRequestHeaders();
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
        return { ok: false, message: '申诉服务返回了空响应' };
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

export const remoteAppealClient: RemoteAppealClient = new RemoteAppealClient();
