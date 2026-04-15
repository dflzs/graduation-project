import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { OperationResult } from '../types/domain';
import {
  RemoteAdminUserItem,
  RemoteAdminUserListResponse,
  RemoteAdminUserResponse,
  RemoteAdminUserStatusPayload
} from '../types/admin-user-remote';

class AdminUserRequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

export class RemoteAdminUserClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async listUsers(token: string): Promise<OperationResult<RemoteAdminUserItem[]>> {
    const result = await this.get<RemoteAdminUserListResponse>('/api/admin/users', token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '\u670d\u52a1\u7aef\u6ca1\u6709\u8fd4\u56de\u7528\u6237\u5217\u8868\u6570\u636e' };
    }
    return {
      ok: true,
      message: result.data.message || '\u83b7\u53d6\u7528\u6237\u5217\u8868\u6210\u529f',
      data: result.data.data
    };
  }

  async updateUserStatus(
    token: string,
    userId: string,
    payload: RemoteAdminUserStatusPayload
  ): Promise<OperationResult<RemoteAdminUserItem>> {
    const result = await this.put<RemoteAdminUserResponse>(`/api/admin/users/${userId}/status`, payload, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '\u670d\u52a1\u7aef\u6ca1\u6709\u8fd4\u56de\u6700\u65b0\u7528\u6237\u72b6\u6001\u6570\u636e' };
    }
    return {
      ok: true,
      message: result.data.message || '\u7528\u6237\u72b6\u6001\u66f4\u65b0\u6210\u529f',
      data: result.data.data
    };
  }

  private async get<T>(path: string, token: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.GET, undefined, token);
  }

  private async put<T>(path: string, payload: Object, token: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.PUT, payload, token);
  }

  private async request<T>(
    path: string,
    method: http.RequestMethod,
    payload?: Object,
    token: string = ''
  ): Promise<OperationResult<T>> {
    const request = http.createHttp();
    const headers = new AdminUserRequestHeaders();
    if (token.length > 0) {
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
        return { ok: false, message: '\u540e\u53f0\u7528\u6237\u670d\u52a1\u8fd4\u56de\u4e86\u7a7a\u54cd\u5e94' };
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
      return `\u7f51\u7edc\u8bf7\u6c42\u5931\u8d25\uff0c\u9519\u8bef\u7801 ${maybeError.code}`;
    }
    return '\u7f51\u7edc\u8bf7\u6c42\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
  }
}

export const remoteAdminUserClient: RemoteAdminUserClient = new RemoteAdminUserClient();
