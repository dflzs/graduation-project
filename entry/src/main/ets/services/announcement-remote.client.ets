import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { OperationResult } from '../types/domain';
import {
  RemoteAnnouncementDeleteResponse,
  RemoteAnnouncementItem,
  RemoteAnnouncementListResponse,
  RemoteAnnouncementResponse,
  RemotePublishAnnouncementPayload
} from '../types/announcement-remote';

class AnnouncementRequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

export class RemoteAnnouncementClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async listAnnouncements(): Promise<OperationResult<RemoteAnnouncementItem[]>> {
    const result = await this.get<RemoteAnnouncementListResponse>('/api/announcements');
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回公告列表数据' };
    }
    return {
      ok: true,
      message: result.data.message || '获取公告列表成功',
      data: result.data.data
    };
  }

  async publishAnnouncement(token: string, title: string, content: string): Promise<OperationResult<RemoteAnnouncementItem>> {
    const result = await this.post<RemoteAnnouncementResponse>(
      '/api/announcements',
      new RemotePublishAnnouncementPayload(title, content),
      token
    );
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回新公告数据' };
    }
    return {
      ok: true,
      message: result.data.message || '公告发布成功',
      data: result.data.data
    };
  }

  async deleteAnnouncement(token: string, announcementId: string): Promise<OperationResult<string>> {
    const result = await this.delete<RemoteAnnouncementDeleteResponse>(`/api/announcements/${announcementId}`, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    return {
      ok: true,
      message: result.data?.message || '公告删除成功',
      data: announcementId
    };
  }

  private async get<T>(path: string, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.GET, undefined, token);
  }

  private async post<T>(path: string, payload: Object, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.POST, payload, token);
  }

  private async delete<T>(path: string, token?: string): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.DELETE, undefined, token);
  }

  private async request<T>(
    path: string,
    method: http.RequestMethod,
    payload?: Object,
    token?: string
  ): Promise<OperationResult<T>> {
    const request = http.createHttp();
    const headers = new AnnouncementRequestHeaders();
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
        return { ok: false, message: '公告服务返回了空响应' };
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

export const remoteAnnouncementClient: RemoteAnnouncementClient = new RemoteAnnouncementClient();
