import { kvSync } from '../data/distributed/kv-sync';
import { SyncService } from '../types/service-contracts';
import { SyncPayload } from '../types/domain';

export class SyncServiceImpl implements SyncService {
  publish(payload: SyncPayload): void {
    kvSync.publish(payload);
  }

  subscribe(key: string, callback: (payload: SyncPayload) => void): () => void {
    return kvSync.subscribe(key, callback);
  }
}

export const syncService: SyncServiceImpl = new SyncServiceImpl();
