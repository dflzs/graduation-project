import { localDb } from '../data/db/local-db';
import { normalizeModerationRecord } from '../data/db/persisted-state';
import { ModerationRecord, ModerationStatus } from '../types/domain';

export class ModerationRepository {
  list(): ModerationRecord[] {
    return localDb.getModerationRecords().sort((a: ModerationRecord, b: ModerationRecord) => b.createdAt - a.createdAt);
  }

  listByStatus(status: ModerationStatus): ModerationRecord[] {
    return this.list().filter((item: ModerationRecord) => item.status === status);
  }

  getById(recordId: string): ModerationRecord | null {
    const item = localDb.getModerationRecords().find((record: ModerationRecord) => record.id === recordId);
    return item ?? null;
  }

  save(record: ModerationRecord): ModerationRecord {
    const normalizedRecord = normalizeModerationRecord(record);
    const items = localDb.getModerationRecords();
    const index = items.findIndex((item: ModerationRecord) => item.id === normalizedRecord.id);
    if (index >= 0) {
      items[index] = normalizedRecord;
    } else {
      items.push(normalizedRecord);
    }
    localDb.setModerationRecords(items);
    return normalizedRecord;
  }

  replaceAll(records: ModerationRecord[]): ModerationRecord[] {
    localDb.setModerationRecords(records.map((record: ModerationRecord) => normalizeModerationRecord(record)));
    return this.list();
  }
}

export const moderationRepository: ModerationRepository = new ModerationRepository();
