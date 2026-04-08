import http from '@ohos.net.http';
import { AUTH_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { OperationResult } from '../types/domain';
import { RemoteUploadImageData, RemoteUploadImageResponse } from '../types/upload-remote';

class UploadRequestHeaders {
  Accept: string = 'application/json';
  Authorization?: string = undefined;
}

function toResponseText(result: string | Object | ArrayBuffer): string {
  if (typeof result === 'string') {
    return result;
  }
  if (result instanceof ArrayBuffer) {
    return '';
  }
  return JSON.stringify(result);
}

function extractErrorMessage(responseText: string, fallbackMessage: string): string {
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

export function normalizeUploadedImageUrl(baseUrl: string, uploadedPath: string): string {
  if (uploadedPath.startsWith('http://') || uploadedPath.startsWith('https://')) {
    return uploadedPath;
  }

  const normalizedBase = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  const normalizedPath = uploadedPath.startsWith('/') ? uploadedPath : `/${uploadedPath}`;
  return `${normalizedBase}${normalizedPath}`;
}

export function resolveUploadMimeType(filePath: string): string {
  const lowerPath = filePath.toLowerCase();
  if (lowerPath.endsWith('.png')) {
    return 'image/png';
  }
  if (lowerPath.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lowerPath.endsWith('.gif')) {
    return 'image/gif';
  }
  return 'image/jpeg';
}

function extractUploadFilename(filePath: string): string {
  const normalizedPath = filePath.replace(/\\/g, '/');
  const lastSegment = normalizedPath.substring(normalizedPath.lastIndexOf('/') + 1);
  return lastSegment.length > 0 ? lastSegment : `cover-${Date.now()}.jpg`;
}

function parseUploadResponse(responseText: string): RemoteUploadImageResponse {
  const parsed = JSON.parse(responseText) as Record<string, Object>;
  const data = parsed.data as Record<string, string> | undefined;
  const uploadData = data
    ? new RemoteUploadImageData(String(data.path ?? ''), String(data.url ?? ''))
    : undefined;
  return new RemoteUploadImageResponse(
    Number(parsed.code ?? 1),
    String(parsed.message ?? ''),
    uploadData
  );
}

export class UploadRemoteClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = AUTH_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async uploadProductCover(token: string, filePath: string): Promise<OperationResult<string>> {
    const request = http.createHttp();
    const headers = new UploadRequestHeaders();
    if (token.length > 0) {
      headers.Authorization = `Bearer ${token}`;
    }

    const filePart: http.MultiFormData = {
      name: 'file',
      contentType: resolveUploadMimeType(filePath),
      remoteFileName: extractUploadFilename(filePath),
      filePath: filePath
    };

    try {
      const response = await request.request(`${this.baseUrl}/api/upload/image`, {
        method: http.RequestMethod.POST,
        header: headers,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: AUTH_HTTP_TIMEOUT_MS,
        connectTimeout: AUTH_HTTP_TIMEOUT_MS,
        multiFormDataList: [filePart]
      });

      const responseText = toResponseText(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return {
          ok: false,
          message: extractErrorMessage(
            responseText,
            `Upload failed with status ${response.responseCode}`
          )
        };
      }

      if (!responseText) {
        return {
          ok: false,
          message: 'Upload service returned an empty response'
        };
      }

      const parsed = parseUploadResponse(responseText);
      if (!parsed.data || parsed.data.url.length === 0) {
        return {
          ok: false,
          message: parsed.message.length > 0 ? parsed.message : 'Upload service did not return an image URL'
        };
      }

      return {
        ok: true,
        message: parsed.message,
        data: normalizeUploadedImageUrl(this.baseUrl, parsed.data.url)
      };
    } catch (error) {
      return {
        ok: false,
        message: (error as Error).message ?? 'Upload failed'
      };
    } finally {
      request.destroy();
    }
  }
}

export const uploadRemoteClient = new UploadRemoteClient();
