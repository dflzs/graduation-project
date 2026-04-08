import { SyncPayload } from '../../types/domain';

export type SyncCallback = (payload: SyncPayload) => void;

export class KvSync {
  readonly domain: string = 'campus_market_sync';
  private store: Map<string, SyncPayload> = new Map();
  private listeners: Map<string, Map<string, SyncCallback>> = new Map();

  publish(payload: SyncPayload): void {
    const current: SyncPayload | undefined = this.store.get(payload.key);
    if (current && current.updatedAt > payload.updatedAt) {
      return;
    }
    this.store.set(payload.key, payload);
    this.dispatch(payload);
  }

  subscribe(key: string, callback: SyncCallback): () => void {
    const id: string = `${Date.now()}_${Math.random()}`;
    if (!this.listeners.has(key)) {
      this.listeners.set(key, new Map());
    }
    this.listeners.get(key)?.set(id, callback);

    const current: SyncPayload | undefined = this.store.get(key);
    if (current) {
      callback(current);
    }

    return () => {
      this.listeners.get(key)?.delete(id);
    };
  }

  private dispatch(payload: SyncPayload): void {
    const keyListeners: Map<string, SyncCallback> | undefined = this.listeners.get(payload.key);
    keyListeners?.forEach((fn: SyncCallback) => fn(payload));
  }
}

export const kvSync: KvSync = new KvSync();
