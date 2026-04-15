import { ModerationStatus, ModerationTargetType } from './domain';

export interface RemoteModerationItem {
  id: string | number;
  reporter_id: string | number;
  target_type: ModerationTargetType;
  target_id: string | number;
  reported_user_id?: string | number;
  related_order_id?: string | number;
  related_product_id?: string | number;
  related_thread_id?: string | number;
  category?: string;
  reason: string;
  description: string;
  evidence_items?: string[];
  status: ModerationStatus;
  priority?: 'low' | 'medium' | 'high' | 'urgent';
  assigned_admin_id?: string | number;
  admin_comment?: string;
  resolution_code?: string;
  governance_action_id?: string | number;
  reviewed_by?: string | number;
  reviewed_at?: string | number;
  closed_at?: string | number;
  created_at: string | number;
  updated_at: string | number;
}

export interface RemoteModerationResponse {
  code: number;
  message: string;
  data?: RemoteModerationItem;
}

export interface RemoteModerationListResponse {
  code: number;
  message: string;
  data?: RemoteModerationItem[];
}

export class RemoteModerationSubmitPayload {
  target_type: ModerationTargetType;
  target_id: string;
  reason: string;
  description: string;

  constructor(targetType: ModerationTargetType, targetId: string, reason: string, description: string) {
    this.target_type = targetType;
    this.target_id = targetId;
    this.reason = reason;
    this.description = description;
  }
}

export class RemoteModerationReviewPayload {
  status: ModerationStatus;
  admin_comment: string;

  constructor(status: ModerationStatus, adminComment: string) {
    this.status = status;
    this.admin_comment = adminComment;
  }
}
