import { GovernanceActionType, GovernanceSourceType } from './domain';

export interface RemoteGovernanceActionItem {
  id: string | number;
  user_id: string | number;
  source_type: GovernanceSourceType;
  source_id: string | number;
  action_type: GovernanceActionType;
  reason: string;
  comment?: string;
  start_at: string | number;
  end_at?: string | number;
  active: boolean;
  created_by: string | number;
  created_at: string | number;
  updated_at: string | number;
  canceled_at?: string | number;
  canceled_by?: string | number;
}

export interface RemoteGovernanceResponse {
  message?: string;
  data?: RemoteGovernanceActionItem;
}

export interface RemoteGovernanceListResponse {
  message?: string;
  data?: RemoteGovernanceActionItem[];
}

export interface RemoteGovernanceUserSummaryItem {
  user_id: string | number;
  active_action_types: GovernanceActionType[];
  latest_action?: RemoteGovernanceActionItem;
  total_action_count: number;
  open_case_count: number;
  latest_action_at?: string | number;
}

export interface RemoteGovernanceUserSummaryResponse {
  message?: string;
  data?: RemoteGovernanceUserSummaryItem;
}

export class RemoteGovernanceActionPayload {
  user_id: string;
  source_type: GovernanceSourceType;
  source_id: string;
  action_type: GovernanceActionType;
  reason: string;
  comment: string;
  start_at: number;
  end_at?: number;
  created_by: string;

  constructor(
    userId: string,
    sourceType: GovernanceSourceType,
    sourceId: string,
    actionType: GovernanceActionType,
    reason: string,
    comment: string,
    startAt: number,
    endAt: number | undefined,
    createdBy: string
  ) {
    this.user_id = userId;
    this.source_type = sourceType;
    this.source_id = sourceId;
    this.action_type = actionType;
    this.reason = reason;
    this.comment = comment;
    this.start_at = startAt;
    this.end_at = endAt;
    this.created_by = createdBy;
  }
}

export class RemoteGovernanceCancelPayload {
  canceled_by: string;
  comment: string;

  constructor(canceledBy: string, comment: string) {
    this.canceled_by = canceledBy;
    this.comment = comment;
  }
}
