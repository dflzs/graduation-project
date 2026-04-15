export interface RemoteAnnouncementItem {
  id: number | string;
  title: string;
  content: string;
  publisher_id: number | string;
  is_deleted: number | boolean;
  created_at: string | number;
  updated_at: string | number;
  publisher_nickname?: string;
}

export interface RemoteAnnouncementListResponse {
  code: number;
  message: string;
  data?: RemoteAnnouncementItem[];
}

export interface RemoteAnnouncementResponse {
  code: number;
  message: string;
  data?: RemoteAnnouncementItem;
}

export interface RemoteAnnouncementDeleteResponse {
  code: number;
  message: string;
  data?: null;
}

export class RemotePublishAnnouncementPayload {
  title: string = '';
  content: string = '';

  constructor(title: string, content: string) {
    this.title = title;
    this.content = content;
  }
}
