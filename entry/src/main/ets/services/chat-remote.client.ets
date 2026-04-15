import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { OperationResult } from '../types/domain';
import {
  RemoteChatConversationItem,
  RemoteChatConversationListResponse,
  RemoteChatConversationResponse,
  RemoteChatMessageItem,
  RemoteChatMessageListResponse,
  RemoteChatMessageResponse,
  RemoteCreateConversationPayload,
  RemoteSendMessagePayload
} from '../types/chat-remote';

class ChatRequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

export class RemoteChatClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async listConversations(token: string): Promise<OperationResult<RemoteChatConversationItem[]>> {
    const result = await this.get<RemoteChatConversationListResponse>('/api/conversations', token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回会话列表数据' };
    }
    return {
      ok: true,
      message: result.data.message || '获取会话列表成功',
      data: result.data.data
    };
  }

  async getMessages(token: string, conversationId: string): Promise<OperationResult<RemoteChatMessageItem[]>> {
    const result = await this.get<RemoteChatMessageListResponse>(`/api/conversations/${conversationId}/messages`, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回聊天记录数据' };
    }
    return {
      ok: true,
      message: result.data.message || '获取聊天记录成功',
      data: result.data.data
    };
  }

  async createConversation(
    token: string,
    payload: RemoteCreateConversationPayload
  ): Promise<OperationResult<RemoteChatConversationItem>> {
    const result = await this.post<RemoteChatConversationResponse>('/api/conversations', payload, token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回会话数据' };
    }
    return {
      ok: true,
      message: result.data.message || '会话已创建',
      data: result.data.data
    };
  }

  async sendMessage(
    token: string,
    conversationId: string,
    content: string
  ): Promise<OperationResult<RemoteChatMessageItem>> {
    const result = await this.post<RemoteChatMessageResponse>(
      `/api/conversations/${conversationId}/messages`,
      new RemoteSendMessagePayload(content),
      token
    );
    if (!result.ok) {
      return { ok: false, message: result.message };
    }
    if (!result.data?.data) {
      return { ok: false, message: '服务端没有返回新消息数据' };
    }
    return {
      ok: true,
      message: result.data.message || '消息已发送',
      data: result.data.data
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
    const headers = new ChatRequestHeaders();
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
        return { ok: false, message: '聊天服务返回了空响应' };
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

export const remoteChatClient: RemoteChatClient = new RemoteChatClient();
