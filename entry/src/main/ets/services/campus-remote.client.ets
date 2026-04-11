import http from '@ohos.net.http';
import { CAMPUS_API_BASE_URL, AUTH_HTTP_TIMEOUT_MS } from '../constants/config';
import { OperationResult } from '../types/domain';
import {
  RemoteCampusBaseResponse,
  RemoteCampusItem,
  RemoteCampusListResponse,
  RemoteCampusPayload,
  RemoteCampusProfilePayload,
  RemoteCampusProfileResponse,
  RemoteCampusResponse,
  RemoteLocationGroupItem,
  RemoteLocationGroupListResponse,
  RemoteLocationGroupPayload,
  RemoteLocationGroupResponse,
  RemoteReviewVerificationPayload,
  RemoteSchoolItem,
  RemoteSchoolListResponse,
  RemoteSchoolPayload,
  RemoteSchoolResponse,
  RemoteStudentVerificationListResponse,
  RemoteStudentVerificationResponse,
  RemoteSubmitVerificationPayload,
  RemoteTradeLocationItem,
  RemoteTradeLocationListResponse,
  RemoteTradeLocationPayload,
  RemoteTradeLocationResponse,
  RemoteTradeLocationStatusPayload
} from '../types/campus-remote';
import { CampusLocationQuery } from '../types/service-contracts';

class CampusRequestHeaders {
  ['Content-Type']: string = 'application/json';
  Authorization?: string = undefined;
}

class QueryEntry {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string) {
    this.key = key;
    this.value = value;
  }
}

interface RemoteCampusArrayResponse<T> extends RemoteCampusBaseResponse {
  data?: T[];
}

export interface RemoteCampusClient {
  listSchools(): Promise<OperationResult<RemoteSchoolItem[]>>;
  listCampuses(schoolId: string): Promise<OperationResult<RemoteCampusItem[]>>;
  listLocationGroups(schoolId: string, campusId: string): Promise<OperationResult<RemoteLocationGroupItem[]>>;
  listTradeLocations(query?: CampusLocationQuery): Promise<OperationResult<RemoteTradeLocationItem[]>>;
  getCurrentCampusProfile(token: string): Promise<OperationResult<RemoteCampusProfileResponse>>;
  updateCampusProfile(token: string, payload: RemoteCampusProfilePayload): Promise<OperationResult<RemoteCampusProfileResponse>>;
  getCurrentVerification(token: string): Promise<OperationResult<RemoteStudentVerificationResponse>>;
  submitVerification(token: string, payload: RemoteSubmitVerificationPayload): Promise<OperationResult<RemoteStudentVerificationResponse>>;
  listVerificationApplications(token: string, status?: string): Promise<OperationResult<RemoteStudentVerificationListResponse>>;
  reviewVerification(
    token: string,
    verificationId: string,
    payload: RemoteReviewVerificationPayload
  ): Promise<OperationResult<RemoteStudentVerificationResponse>>;
  upsertSchool(token: string, schoolId: string, payload: RemoteSchoolPayload): Promise<OperationResult<RemoteSchoolResponse>>;
  upsertCampus(token: string, campusId: string, payload: RemoteCampusPayload): Promise<OperationResult<RemoteCampusResponse>>;
  upsertLocationGroup(
    token: string,
    groupId: string,
    payload: RemoteLocationGroupPayload
  ): Promise<OperationResult<RemoteLocationGroupResponse>>;
  upsertTradeLocation(
    token: string,
    locationId: string,
    payload: RemoteTradeLocationPayload
  ): Promise<OperationResult<RemoteTradeLocationResponse>>;
  updateTradeLocationStatus(
    token: string,
    locationId: string,
    isEnabled: boolean
  ): Promise<OperationResult<RemoteTradeLocationResponse>>;
}

export class HttpRemoteCampusClient implements RemoteCampusClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = CAMPUS_API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async listSchools(): Promise<OperationResult<RemoteSchoolItem[]>> {
    const result = await this.get<RemoteSchoolListResponse>('/api/campus/schools');
    return this.unwrapListResponse<RemoteSchoolItem>(result, 'School list is empty');
  }

  async listCampuses(schoolId: string): Promise<OperationResult<RemoteCampusItem[]>> {
    const path = this.withQuery('/api/campus/campuses', [new QueryEntry('school_id', schoolId)]);
    const result = await this.get<RemoteCampusListResponse>(path);
    return this.unwrapListResponse<RemoteCampusItem>(result, 'Campus list is empty');
  }

  async listLocationGroups(schoolId: string, campusId: string): Promise<OperationResult<RemoteLocationGroupItem[]>> {
    const path = this.withQuery('/api/campus/location-groups', [
      new QueryEntry('school_id', schoolId),
      new QueryEntry('campus_id', campusId)
    ]);
    const result = await this.get<RemoteLocationGroupListResponse>(path);
    return this.unwrapListResponse<RemoteLocationGroupItem>(result, 'Location group list is empty');
  }

  async listTradeLocations(query?: CampusLocationQuery): Promise<OperationResult<RemoteTradeLocationItem[]>> {
    const path = this.withQuery('/api/campus/trade-locations', [
      new QueryEntry('school_id', query?.schoolId ?? ''),
      new QueryEntry('campus_id', query?.campusId ?? ''),
      new QueryEntry('group_id', query?.groupId ?? ''),
      new QueryEntry('category', query?.category ?? '')
    ]);
    const result = await this.get<RemoteTradeLocationListResponse>(path);
    return this.unwrapListResponse<RemoteTradeLocationItem>(result, 'Trade location list is empty');
  }

  async getCurrentCampusProfile(token: string): Promise<OperationResult<RemoteCampusProfileResponse>> {
    return this.get<RemoteCampusProfileResponse>('/api/campus/profile', token);
  }

  async updateCampusProfile(
    token: string,
    payload: RemoteCampusProfilePayload
  ): Promise<OperationResult<RemoteCampusProfileResponse>> {
    return this.put<RemoteCampusProfileResponse>('/api/campus/profile', payload, token);
  }

  async getCurrentVerification(token: string): Promise<OperationResult<RemoteStudentVerificationResponse>> {
    return this.get<RemoteStudentVerificationResponse>('/api/campus/verification', token);
  }

  async submitVerification(
    token: string,
    payload: RemoteSubmitVerificationPayload
  ): Promise<OperationResult<RemoteStudentVerificationResponse>> {
    return this.post<RemoteStudentVerificationResponse>('/api/campus/verification', payload, token);
  }

  async listVerificationApplications(
    token: string,
    status: string = ''
  ): Promise<OperationResult<RemoteStudentVerificationListResponse>> {
    const path = this.withQuery('/api/campus/admin/verifications', [new QueryEntry('status', status)]);
    return this.get<RemoteStudentVerificationListResponse>(path, token);
  }

  async reviewVerification(
    token: string,
    verificationId: string,
    payload: RemoteReviewVerificationPayload
  ): Promise<OperationResult<RemoteStudentVerificationResponse>> {
    return this.post<RemoteStudentVerificationResponse>(
      `/api/campus/admin/verifications/${verificationId}/review`,
      payload,
      token
    );
  }

  async upsertSchool(
    token: string,
    schoolId: string,
    payload: RemoteSchoolPayload
  ): Promise<OperationResult<RemoteSchoolResponse>> {
    return this.post<RemoteSchoolResponse>(
      `/api/campus/admin/schools${schoolId.length > 0 ? `?id=${encodeURIComponent(schoolId)}` : ''}`,
      payload,
      token
    );
  }

  async upsertCampus(
    token: string,
    campusId: string,
    payload: RemoteCampusPayload
  ): Promise<OperationResult<RemoteCampusResponse>> {
    return this.post<RemoteCampusResponse>(
      `/api/campus/admin/campuses${campusId.length > 0 ? `?id=${encodeURIComponent(campusId)}` : ''}`,
      payload,
      token
    );
  }

  async upsertLocationGroup(
    token: string,
    groupId: string,
    payload: RemoteLocationGroupPayload
  ): Promise<OperationResult<RemoteLocationGroupResponse>> {
    return this.post<RemoteLocationGroupResponse>(
      `/api/campus/admin/location-groups${groupId.length > 0 ? `?id=${encodeURIComponent(groupId)}` : ''}`,
      payload,
      token
    );
  }

  async upsertTradeLocation(
    token: string,
    locationId: string,
    payload: RemoteTradeLocationPayload
  ): Promise<OperationResult<RemoteTradeLocationResponse>> {
    return this.post<RemoteTradeLocationResponse>(
      `/api/campus/admin/trade-locations${locationId.length > 0 ? `?id=${encodeURIComponent(locationId)}` : ''}`,
      payload,
      token
    );
  }

  async updateTradeLocationStatus(
    token: string,
    locationId: string,
    isEnabled: boolean
  ): Promise<OperationResult<RemoteTradeLocationResponse>> {
    return this.put<RemoteTradeLocationResponse>(
      `/api/campus/admin/trade-locations/${locationId}/status`,
      new RemoteTradeLocationStatusPayload(isEnabled),
      token
    );
  }

  private async get<T extends RemoteCampusBaseResponse>(path: string, token: string = ''): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.GET, undefined, token);
  }

  private async post<T extends RemoteCampusBaseResponse>(
    path: string,
    payload: Object,
    token: string
  ): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.POST, payload, token);
  }

  private async put<T extends RemoteCampusBaseResponse>(
    path: string,
    payload: Object,
    token: string
  ): Promise<OperationResult<T>> {
    return this.request<T>(path, http.RequestMethod.PUT, payload, token);
  }

  private async request<T extends RemoteCampusBaseResponse>(
    path: string,
    method: http.RequestMethod,
    payload?: Object,
    token: string = ''
  ): Promise<OperationResult<T>> {
    const request = http.createHttp();
    const headers = new CampusRequestHeaders();
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
          message: this.extractErrorMessage(responseText, `Request failed (${response.responseCode})`)
        };
      }

      if (!responseText) {
        return {
          ok: false,
          message: 'Campus service returned an empty response'
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

  private unwrapListResponse<T>(
    result: OperationResult<RemoteCampusArrayResponse<T>>,
    emptyMessage: string
  ): OperationResult<T[]> {
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    return {
      ok: true,
      message: result.data?.message ?? emptyMessage,
      data: result.data?.data ?? []
    };
  }

  private withQuery(path: string, entries: QueryEntry[]): string {
    const queryParts: string[] = [];
    entries.forEach((entry: QueryEntry) => {
      const value = entry.value.trim();
      if (value.length > 0) {
        queryParts.push(`${entry.key}=${encodeURIComponent(value)}`);
      }
    });
    return queryParts.length > 0 ? `${path}?${queryParts.join('&')}` : path;
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

  private toErrorMessage(error: Object): string {
    const maybeError = error as Record<string, Object>;
    if (typeof maybeError.message === 'string' && maybeError.message.length > 0) {
      return maybeError.message;
    }
    if (typeof maybeError.code === 'number') {
      return `Network request failed (${maybeError.code})`;
    }
    return 'Network request failed, please try again later';
  }
}
