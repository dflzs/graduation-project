import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { ModerationRecord, OperationResult } from '../types/domain';
import {
  RemoteModerationItem,
  RemoteModerationListResponse,
  RemoteModerationResponse,
  RemoteModerationReviewPayload,
  RemoteModerationSubmitPayload
} from '../types/moderation-remote';

class ModerationRequestHeaders {
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

export function mapRemoteModerationItem(item: RemoteModerationItem): ModerationRecord {
  return {
    id: String(item.id),
    reporterId: String(item.reporter_id),
    targetType: item.target_type,
    targetId: String(item.target_id),
    reportedUserId: item.reported_user_id !== undefined ? String(item.reported_user_id) : undefined,
    relatedOrderId: item.related_order_id !== undefined ? String(item.related_order_id) : undefined,
    relatedProductId: item.related_product_id !== undefined ? String(item.related_product_id) : undefined,
    relatedThreadId: item.related_thread_id !== undefined ? String(item.related_thread_id) : undefined,
    category: item.category,
    reason: item.reason,
    description: item.description,
    evidenceItems: item.evidence_items,
    status: item.status,
    priority: item.priority,
    assignedAdminId: item.assigned_admin_id !== undefined ? String(item.assigned_admin_id) : undefined,
    adminComment: item.admin_comment,
    resolutionCode: item.resolution_code,
    governanceActionId: item.governance_action_id !== undefined ? String(item.governance_action_id) : undefined,
    reviewedBy: item.reviewed_by !== undefined ? String(item.reviewed_by) : undefined,
    reviewedAt: parseTimestamp(item.reviewed_at),
    closedAt: parseTimestamp(item.closed_at),
    createdAt: parseTimestamp(item.created_at) ?? Date.now(),
    updatedAt: parseTimestamp(item.updated_at) ?? Date.now()
  };
}

export class RemoteModerationClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async submitRecord(
    token: string,
    payload: RemoteModerationSubmitPayload
  ): Promise<OperationResult<ModerationRecord>> {
    const result = await this.post<RemoteModerationResponse>('/api/moderation/records', payload, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回最新举报记录' };
    }
    return {
      ok: true,
      message: result.data.message || '举报提交成功',
      data: mapRemoteModerationItem(result.data.data)
    };
  }

  async listRecords(token: string, status?: string): Promise<OperationResult<ModerationRecord[]>> {
    const query = status && status.length > 0 ? `?status=${encodeURIComponent(status)}` : '';
    const result = await this.get<RemoteModerationListResponse>(`/api/admin/moderation/records${query}`, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回举报审核列表' };
    }
    return {
      ok: true,
      message: result.data.message || '获取举报审核列表成功',
      data: result.data.data.map(mapRemoteModerationItem)
    };
  }

  async listMyRecords(token: string): Promise<OperationResult<ModerationRecord[]>> {
    const result = await this.get<RemoteModerationListResponse>('/api/moderation/records/my', token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回我的治理记录' };
    }
    return {
      ok: true,
      message: result.data.message || '获取我的治理记录成功',
      data: result.data.data.map(mapRemoteModerationItem)
    };
  }

  async reviewRecord(
    token: string,
    recordId: string,
    payload: RemoteModerationReviewPayload
  ): Promise<OperationResult<ModerationRecord>> {
    const result = await this.post<RemoteModerationResponse>(
      `/api/admin/moderation/records/${recordId}/review`,
      payload,
      token
    );
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回最新审核结果' };
    }
    return {
      ok: true,
      message: result.data.message || '举报审核成功',
      data: mapRemoteModerationItem(result.data.data)
    };
  }

  async triageRecord(token: string, recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>> {
    return this.reviewRecord(token, recordId, new RemoteModerationReviewPayload('triaging', adminComment));
  }

  async requestEvidence(token: string, recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>> {
    return this.reviewRecord(token, recordId, new RemoteModerationReviewPayload('awaiting_evidence', adminComment));
  }

  async closeRecord(token: string, recordId: string, adminComment: string): Promise<OperationResult<ModerationRecord>> {
    return this.reviewRecord(token, recordId, new RemoteModerationReviewPayload('closed', adminComment));
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
    const headers = new ModerationRequestHeaders();
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
        return { ok: false, message: '举报服务返回了空响应' };
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

export const remoteModerationClient: RemoteModerationClient = new RemoteModerationClient();
