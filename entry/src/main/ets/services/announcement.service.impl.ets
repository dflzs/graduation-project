import { announcementRepository } from '../repositories/announcement.repo';
import { userRepository } from '../repositories/user.repo';
import { Announcement, OperationResult, User } from '../types/domain';
import { newId } from '../utils/id';

export class AnnouncementServiceImpl {
  list(): Announcement[] {
    return announcementRepository.list();
  }

  publish(title: string, content: string, publisherId: string): OperationResult<Announcement> {
    if (title.trim().length === 0 || content.trim().length === 0) {
      return { ok: false, message: 'Title and content are required' };
    }
    const now: number = Date.now();
    const item: Announcement = {
      id: newId('announcement'),
      title,
      content,
      publisherId,
      isDeleted: false,
      createdAt: now,
      updatedAt: now
    };
    announcementRepository.save(item);
    return {
      ok: true,
      message: 'Announcement published',
      data: item
    };
  }

  delete(announcementId: string, operatorId: string): OperationResult<Announcement> {
    const target: Announcement | null = announcementRepository.getById(announcementId);
    const operator: User | null = userRepository.getById(operatorId);
    if (!target || target.isDeleted) {
      return { ok: false, message: 'Announcement not found' };
    }
    if (!operator || operator.role !== 'admin') {
      return { ok: false, message: 'Admin only' };
    }

    const deleted: Announcement | null = announcementRepository.softDelete(announcementId);
    if (!deleted) {
      return { ok: false, message: 'Delete failed' };
    }
    return {
      ok: true,
      message: 'Announcement deleted',
      data: deleted
    };
  }
}

export const announcementService: AnnouncementServiceImpl = new AnnouncementServiceImpl();
