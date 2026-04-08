import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import {
  PhoneCodePayload,
  PhonePayload,
  PasswordLoginPayload,
  RemoteAuthClient,
  RemoteBaseResponse,
  RemoteMeResponse,
  RemotePassResponse,
  RemoteRegisterCodeResponse,
  RemoteRegisterCodeVerifyResponse,
  RemoteUpdateMePayload,
  TicketRegisterPayload
} from '../types/auth-remote';

class RequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

class RemoteErrorResponse implements RemoteBaseResponse {
  code: number = 1;
  message: string = '';

  constructor(message: string) {
    this.message = message;
  }
}

export class HttpRemoteAuthClient implements RemoteAuthClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  sendLoginCode(phone: string): Promise<RemotePassResponse> {
    return Promise.resolve(this.unsupportedResponse());
  }

  validateLoginCode(phone: string, code: string): Promise<RemotePassResponse> {
    return Promise.resolve(this.unsupportedResponse());
  }

  loginByPassword(phone: string, password: string): Promise<RemotePassResponse> {
    return this.post('/api/auth/login/password', new PasswordLoginPayload(phone, password));
  }

  sendRegisterCode(phone: string): Promise<RemoteRegisterCodeResponse> {
    return this.post<RemoteRegisterCodeResponse>('/api/auth/register/code', new PhonePayload(phone));
  }

  verifyRegisterCode(phone: string, code: string): Promise<RemoteRegisterCodeVerifyResponse> {
    return this.post<RemoteRegisterCodeVerifyResponse>('/api/auth/register/code/verify', new PhoneCodePayload(phone, code));
  }

  registerWithTicket(phone: string, registerTicket: string, nickname: string, password: string): Promise<RemotePassResponse> {
    return this.post('/api/auth/register', new TicketRegisterPayload(phone, registerTicket, nickname, password));
  }

  updateMe(token: string, payload: RemoteUpdateMePayload): Promise<RemoteMeResponse> {
    return this.put<RemoteMeResponse>('/api/auth/me', payload, token);
  }

  private async post<T extends RemoteBaseResponse>(path: string, payload: Object): Promise<T> {
    return this.send<T>(http.RequestMethod.POST, path, payload);
  }

  private async put<T extends RemoteBaseResponse>(path: string, payload: Object, token: string): Promise<T> {
    return this.send<T>(http.RequestMethod.PUT, path, payload, token);
  }

  private async send<T extends RemoteBaseResponse>(
    method: http.RequestMethod,
    path: string,
    payload: Object,
    token: string = ''
  ): Promise<T> {
    const request = http.createHttp();
    const headers = new RequestHeaders();
    if (token.length > 0) {
      headers.Authorization = `Bearer ${token}`;
    }

    try {
      const response = await request.request(`${this.baseUrl}${path}`, {
        method,
        header: headers,
        extraData: JSON.stringify(payload),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: AUTH_HTTP_TIMEOUT_MS,
        connectTimeout: AUTH_HTTP_TIMEOUT_MS
      });

      const responseText = this.toResponseText(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return this.errorResponse<T>(this.extractErrorMessage(
          responseText,
          `\u8bf7\u6c42\u5931\u8d25\uff08${response.responseCode}\uff09`
        ));
      }

      if (!responseText) {
        return this.errorResponse<T>('\u8ba4\u8bc1\u670d\u52a1\u8fd4\u56de\u4e86\u7a7a\u54cd\u5e94\u3002');
      }

      return JSON.parse(responseText) as T;
    } catch (error) {
      return this.errorResponse<T>(this.toErrorMessage(error as Object));
    } finally {
      request.destroy();
    }
  }

  private unsupportedResponse(): RemotePassResponse {
    return {
      code: 1,
      message: '\u8be5\u529f\u80fd\u6682\u672a\u63a5\u901a\u670d\u52a1\u5668\uff0c\u8bf7\u5148\u4f7f\u7528\u624b\u673a\u53f7\u5bc6\u7801\u767b\u5f55\u3002'
    };
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
    } catch (error) {
      // Non-JSON error body: return the raw text below.
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
      return `\u7f51\u7edc\u8bf7\u6c42\u5931\u8d25\uff08${maybeError.code}\uff09`;
    }
    return '\u7f51\u7edc\u8bf7\u6c42\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5\u3002';
  }

  private errorResponse<T extends RemoteBaseResponse>(message: string): T {
    return new RemoteErrorResponse(message) as T;
  }
}
