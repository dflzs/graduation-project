import { UserStatus } from './domain';

export interface RemoteAdminUserItem {
  id: number | string;
  phone: string;
  nickname: string;
  avatar?: string;
  role: string;
  status: string;
  credit_score: number;
  created_at: string | number;
  updated_at: string | number;
}

export interface RemoteAdminUserListResponse {
  code: number;
  message: string;
  data?: RemoteAdminUserItem[];
}

export interface RemoteAdminUserResponse {
  code: number;
  message: string;
  data?: RemoteAdminUserItem;
}

export class RemoteAdminUserStatusPayload {
  status: string = '';

  constructor(status: UserStatus) {
    this.status = status;
  }
}
