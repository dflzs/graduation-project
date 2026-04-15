import { localDb } from '../data/db/local-db';
import { normalizeAppealRecord } from '../data/db/persisted-state';
import { AppealRecord, AppealStatus } from '../types/domain';

export class AppealRepository {
  list(): AppealRecord[] {
    return localDb.getAppealRecords().sort((left: AppealRecord, right: AppealRecord) => right.createdAt - left.createdAt);
  }

  listByAppellant(appellantId: string): AppealRecord[] {
    return this.list().filter((record: AppealRecord) => record.appellantId === appellantId);
  }

  listByModerationRecord(moderationRecordId: string): AppealRecord[] {
    return this.list().filter((record: AppealRecord) => record.moderationRecordId === moderationRecordId);
  }

  listByStatus(status: AppealStatus): AppealRecord[] {
    return this.list().filter((record: AppealRecord) => record.status === status);
  }

  getById(appealId: string): AppealRecord | null {
    const record = localDb.getAppealRecords().find((item: AppealRecord) => item.id === appealId);
    return record ?? null;
  }

  save(record: AppealRecord): AppealRecord {
    const normalized = normalizeAppealRecord(record);
    const items = localDb.getAppealRecords();
    const index = items.findIndex((item: AppealRecord) => item.id === normalized.id);
    if (index >= 0) {
      items[index] = normalized;
    } else {
      items.push(normalized);
    }
    localDb.setAppealRecords(items);
    return normalized;
  }

  replaceAll(records: AppealRecord[]): AppealRecord[] {
    localDb.setAppealRecords(records.map((record: AppealRecord) => normalizeAppealRecord(record)));
    return this.list();
  }
}

export const appealRepository: AppealRepository = new AppealRepository();
