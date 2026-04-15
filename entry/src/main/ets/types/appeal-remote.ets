import { AppealStatus } from './domain';

export interface RemoteAppealItem {
  id: string | number;
  moderation_record_id: string | number;
  appellant_id: string | number;
  reason: string;
  description: string;
  evidence_items: string[];
  status: AppealStatus;
  reviewed_by?: string | number;
  review_comment?: string;
  reviewed_at?: string | number;
  created_at: string | number;
  updated_at: string | number;
}

export interface RemoteAppealResponse {
  message?: string;
  data?: RemoteAppealItem;
}

export interface RemoteAppealListResponse {
  message?: string;
  data?: RemoteAppealItem[];
}

export class RemoteAppealSubmitPayload {
  moderation_record_id: string;
  reason: string;
  description: string;
  evidence_items: string[];

  constructor(moderationRecordId: string, reason: string, description: string, evidenceItems: string[] = []) {
    this.moderation_record_id = moderationRecordId;
    this.reason = reason;
    this.description = description;
    this.evidence_items = evidenceItems;
  }
}

export class RemoteAppealReviewPayload {
  status: AppealStatus;
  review_comment: string;

  constructor(status: AppealStatus, reviewComment: string) {
    this.status = status;
    this.review_comment = reviewComment;
  }
}
