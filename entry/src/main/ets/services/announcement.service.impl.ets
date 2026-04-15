import { announcementRepository } from '../repositories/announcement.repo';
import { userRepository } from '../repositories/user.repo';
import { Announcement, OperationResult, User } from '../types/domain';
import { newId } from '../utils/id';
import { canAccessAdmin, getAdminActionDeniedMessage } from './guard.service';
import { syncService } from './sync.service.impl';
import { AuthStateService, authStateService } from './auth-state.service';
import { RemoteAnnouncementClient, remoteAnnouncementClient } from './announcement-remote.client';
import { RemoteAnnouncementItem } from '../types/announcement-remote';

function parseTimestamp(value: string | number): number {
  if (typeof value === 'number') {
    return value;
  }
  const timestamp = Date.parse(value);
  return Number.isNaN(timestamp) ? Date.now() : timestamp;
}

function normalizeDeletedFlag(value: number | boolean): boolean {
  return typeof value === 'boolean' ? value : value === 1;
}

export class AnnouncementServiceImpl {
  private readonly remoteClient: RemoteAnnouncementClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteAnnouncementClient = remoteAnnouncementClient,
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  private resolveAdminToken(operatorId: string): string {
    if (!this.stateService.isLoggedIn()) {
      return '';
    }
    const currentUser = this.stateService.getCurrentUser();
    if (!currentUser || currentUser.id !== operatorId || !canAccessAdmin(currentUser)) {
      return '';
    }
    return this.stateService.getToken();
  }

  private canRequestRemoteAdminAction(operatorId: string): boolean {
    return /^\d+$/.test(operatorId.trim());
  }

  private mapRemoteAnnouncementItem(item: RemoteAnnouncementItem): Announcement {
    return {
      id: String(item.id),
      title: item.title,
      content: item.content,
      publisherId: String(item.publisher_id),
      isDeleted: normalizeDeletedFlag(item.is_deleted),
      createdAt: parseTimestamp(item.created_at),
      updatedAt: parseTimestamp(item.updated_at)
    };
  }

  private publishAnnouncementChanged(id: string, updatedAt: number): void {
    syncService.publish({
      key: 'announcements:changed',
      value: id,
      updatedAt
    });
  }

  async list(): Promise<Announcement[]> {
    const remoteResult = await this.remoteClient.listAnnouncements();
    if (remoteResult.ok && remoteResult.data) {
      const announcements = remoteResult.data
        .map((item: RemoteAnnouncementItem) => this.mapRemoteAnnouncementItem(item))
        .filter((item: Announcement) => !item.isDeleted)
        .sort((a: Announcement, b: Announcement) => b.createdAt - a.createdAt);
      announcementRepository.replaceAll(announcements);
      return announcements;
    }

    return announcementRepository.list();
  }

  async publish(title: string, content: string, publisherId: string): Promise<OperationResult<Announcement>> {
    const trimmedTitle = title.trim();
    const trimmedContent = content.trim();
    if (trimmedTitle.length === 0 || trimmedContent.length === 0) {
      return { ok: false, message: '公告标题和内容不能为空' };
    }

    const publisher: User | null = userRepository.getById(publisherId);
    if (!canAccessAdmin(publisher)) {
      return { ok: false, message: getAdminActionDeniedMessage(publisher) };
    }

    const token = this.resolveAdminToken(publisherId);
    if (token.length > 0 && this.canRequestRemoteAdminAction(publisherId)) {
      const remoteResult = await this.remoteClient.publishAnnouncement(token, trimmedTitle, trimmedContent);
      if (remoteResult.ok && remoteResult.data) {
        const announcement = announcementRepository.save(this.mapRemoteAnnouncementItem(remoteResult.data));
        this.publishAnnouncementChanged(announcement.id, announcement.updatedAt);
        return {
          ok: true,
          message: remoteResult.message || '公告发布成功',
          data: announcement
        };
      }
    }

    const now: number = Date.now();
    const item: Announcement = {
      id: newId('announcement'),
      title: trimmedTitle,
      content: trimmedContent,
      publisherId,
      isDeleted: false,
      createdAt: now,
      updatedAt: now
    };
    announcementRepository.save(item);
    this.publishAnnouncementChanged(item.id, item.updatedAt);
    return {
      ok: true,
      message: '公告发布成功',
      data: item
    };
  }

  async delete(announcementId: string, operatorId: string): Promise<OperationResult<Announcement>> {
    const operator: User | null = userRepository.getById(operatorId);
    if (!canAccessAdmin(operator)) {
      return { ok: false, message: getAdminActionDeniedMessage(operator) };
    }

    const token = this.resolveAdminToken(operatorId);
    if (token.length > 0
      && this.canRequestRemoteAdminAction(operatorId)
      && /^\d+$/.test(announcementId.trim())) {
      const remoteResult = await this.remoteClient.deleteAnnouncement(token, announcementId);
      if (remoteResult.ok) {
        const deleted = announcementRepository.softDelete(announcementId)
          ?? announcementRepository.save({
            id: announcementId,
            title: '',
            content: '',
            publisherId: operatorId,
            isDeleted: true,
            createdAt: Date.now(),
            updatedAt: Date.now()
          });
        this.publishAnnouncementChanged(announcementId, deleted.updatedAt);
        return {
          ok: true,
          message: remoteResult.message || '公告删除成功',
          data: deleted
        };
      }
    }

    const target: Announcement | null = announcementRepository.getById(announcementId);
    if (!target || target.isDeleted) {
      return { ok: false, message: '公告不存在' };
    }

    const deleted: Announcement | null = announcementRepository.softDelete(announcementId);
    if (!deleted) {
      return { ok: false, message: '删除公告失败' };
    }
    this.publishAnnouncementChanged(deleted.id, deleted.updatedAt);
    return {
      ok: true,
      message: '公告删除成功',
      data: deleted
    };
  }
}

export const announcementService: AnnouncementServiceImpl = new AnnouncementServiceImpl();
