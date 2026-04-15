import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { GovernanceAction, GovernanceUserSummary, OperationResult } from '../types/domain';
import {
  RemoteGovernanceActionItem,
  RemoteGovernanceActionPayload,
  RemoteGovernanceCancelPayload,
  RemoteGovernanceListResponse,
  RemoteGovernanceResponse,
  RemoteGovernanceUserSummaryItem,
  RemoteGovernanceUserSummaryResponse
} from '../types/governance-remote';

class GovernanceRequestHeaders {
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

export function mapRemoteGovernanceActionItem(item: RemoteGovernanceActionItem): GovernanceAction {
  return {
    id: String(item.id),
    userId: String(item.user_id),
    sourceType: item.source_type,
    sourceId: String(item.source_id),
    actionType: item.action_type,
    reason: item.reason,
    comment: item.comment,
    startAt: parseTimestamp(item.start_at) ?? Date.now(),
    endAt: parseTimestamp(item.end_at),
    active: item.active,
    createdBy: String(item.created_by),
    createdAt: parseTimestamp(item.created_at) ?? Date.now(),
    updatedAt: parseTimestamp(item.updated_at) ?? Date.now(),
    canceledAt: parseTimestamp(item.canceled_at),
    canceledBy: item.canceled_by !== undefined ? String(item.canceled_by) : undefined
  };
}

export function mapRemoteGovernanceUserSummary(item: RemoteGovernanceUserSummaryItem): GovernanceUserSummary {
  return {
    userId: String(item.user_id),
    activeActionTypes: item.active_action_types,
    latestAction: item.latest_action ? mapRemoteGovernanceActionItem(item.latest_action) : undefined,
    totalActionCount: item.total_action_count,
    openCaseCount: item.open_case_count,
    latestActionAt: parseTimestamp(item.latest_action_at)
  };
}

export class RemoteGovernanceClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async createAction(
    token: string,
    payload: RemoteGovernanceActionPayload
  ): Promise<OperationResult<GovernanceAction>> {
    const result = await this.post<RemoteGovernanceResponse>('/api/admin/governance/actions', payload, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回最新治理动作' };
    }
    return {
      ok: true,
      message: result.data.message || '治理动作创建成功',
      data: mapRemoteGovernanceActionItem(result.data.data)
    };
  }

  async listActions(token: string): Promise<OperationResult<GovernanceAction[]>> {
    const result = await this.get<RemoteGovernanceListResponse>('/api/admin/governance/actions', token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回治理动作列表' };
    }
    return {
      ok: true,
      message: result.data.message || '获取治理动作列表成功',
      data: result.data.data.map(mapRemoteGovernanceActionItem)
    };
  }

  async listActionsByUser(token: string, userId: string): Promise<OperationResult<GovernanceAction[]>> {
    const result = await this.get<RemoteGovernanceListResponse>(
      `/api/admin/governance/users/${encodeURIComponent(userId)}/actions`,
      token
    );
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回用户治理动作' };
    }
    return {
      ok: true,
      message: result.data.message || '获取用户治理动作成功',
      data: result.data.data.map(mapRemoteGovernanceActionItem)
    };
  }

  async cancelAction(
    token: string,
    actionId: string,
    payload: RemoteGovernanceCancelPayload
  ): Promise<OperationResult<GovernanceAction>> {
    const result = await this.post<RemoteGovernanceResponse>(
      `/api/admin/governance/actions/${encodeURIComponent(actionId)}/cancel`,
      payload,
      token
    );
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回最新治理动作' };
    }
    return {
      ok: true,
      message: result.data.message || '治理动作已取消',
      data: mapRemoteGovernanceActionItem(result.data.data)
    };
  }

  async getUserSummary(token: string, userId: string): Promise<OperationResult<GovernanceUserSummary>> {
    const result = await this.get<RemoteGovernanceUserSummaryResponse>(
      `/api/governance/users/${encodeURIComponent(userId)}/summary`,
      token
    );
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回治理摘要' };
    }
    return {
      ok: true,
      message: result.data.message || '获取治理摘要成功',
      data: mapRemoteGovernanceUserSummary(result.data.data)
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
    const headers = new GovernanceRequestHeaders();
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
        return { ok: false, message: '治理服务返回了空响应' };
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

export const remoteGovernanceClient: RemoteGovernanceClient = new RemoteGovernanceClient();
