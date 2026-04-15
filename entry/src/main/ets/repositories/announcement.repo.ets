import { localDb } from '../data/db/local-db';
import { Announcement } from '../types/domain';

export class AnnouncementRepository {
  list(): Announcement[] {
    return localDb.getAnnouncements()
      .filter((item: Announcement) => !item.isDeleted)
      .sort((a: Announcement, b: Announcement) => b.createdAt - a.createdAt);
  }

  save(announcement: Announcement): Announcement {
    const items: Announcement[] = localDb.getAnnouncements();
    const index: number = items.findIndex((a: Announcement) => a.id === announcement.id);
    if (index >= 0) {
      items[index] = announcement;
    } else {
      items.push(announcement);
    }
    localDb.setAnnouncements(items);
    return announcement;
  }

  replaceAll(announcements: Announcement[]): Announcement[] {
    localDb.setAnnouncements(announcements);
    return this.list();
  }

  getById(announcementId: string): Announcement | null {
    const item: Announcement | undefined = localDb.getAnnouncements()
      .find((announcement: Announcement) => announcement.id === announcementId);
    return item ?? null;
  }

  softDelete(announcementId: string): Announcement | null {
    const items: Announcement[] = localDb.getAnnouncements();
    const index: number = items.findIndex((item: Announcement) => item.id === announcementId);
    if (index < 0) {
      return null;
    }
    items[index].isDeleted = true;
    items[index].updatedAt = Date.now();
    localDb.setAnnouncements(items);
    return items[index];
  }
}

export const announcementRepository: AnnouncementRepository = new AnnouncementRepository();
