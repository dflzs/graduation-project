import { preferences } from '@kit.ArkData';

export interface PersistenceAdapter {
  load(key: string): string | null;
  save(key: string, value: string): void;
  remove(key: string): void;
}

interface ChunkMeta {
  count?: number;
}

export class MemoryPersistenceAdapter implements PersistenceAdapter {
  private readonly store: Map<string, string>;

  constructor(store: Map<string, string> = new Map()) {
    this.store = store;
  }

  load(key: string): string | null {
    return this.store.get(key) ?? null;
  }

  save(key: string, value: string): void {
    this.store.set(key, value);
  }

  remove(key: string): void {
    this.store.delete(key);
  }

  keys(): string[] {
    return Array.from(this.store.keys());
  }
}

export class PreferencesPersistenceAdapter implements PersistenceAdapter {
  private static readonly VALUE_CHUNK_SIZE: number = 7000;
  private static readonly META_SUFFIX: string = '__meta';
  private static readonly CHUNK_PREFIX: string = '__chunk_';
  private context: Context | null = null;
  private readonly fallback: MemoryPersistenceAdapter = new MemoryPersistenceAdapter();
  private readonly storeName: string;

  constructor(storeName: string = 'campus_market_store') {
    this.storeName = storeName;
  }

  setContext(context: Context): void {
    this.context = context;
    this.flushFallbackToPreferences();
  }

  load(key: string): string | null {
    const store = this.getPreferenceStore();
    if (!store) {
      return this.fallback.load(key);
    }

    try {
      const chunkMeta = store.getSync(this.getMetaKey(key), '') as string;
      if (typeof chunkMeta === 'string' && chunkMeta.length > 0) {
        const parsedMeta = JSON.parse(chunkMeta) as ChunkMeta;
        const chunkCount = typeof parsedMeta.count === 'number' ? parsedMeta.count : 0;
        if (chunkCount > 0) {
          let combinedValue = '';
          for (let index = 0; index < chunkCount; index++) {
            const chunkValue = store.getSync(this.getChunkKey(key, index), '') as string;
            combinedValue += typeof chunkValue === 'string' ? chunkValue : '';
          }
          return combinedValue.length > 0 ? combinedValue : null;
        }
      }

      const value = store.getSync(key, '') as string;
      return typeof value === 'string' && value.length > 0 ? value : null;
    } catch (_error) {
      return this.fallback.load(key);
    }
  }

  save(key: string, value: string): void {
    const store = this.getPreferenceStore();
    if (!store) {
      this.fallback.save(key, value);
      return;
    }

    try {
      this.persistValue(store, key, value);
      store.flushSync();
    } catch (_error) {
      this.fallback.save(key, value);
    }
  }

  remove(key: string): void {
    this.fallback.remove(key);
    const store = this.getPreferenceStore();
    if (!store) {
      return;
    }

    try {
      this.clearStoredValue(store, key);
      store.flushSync();
    } catch (_error) {
    }
  }

  private getPreferenceStore(): preferences.Preferences | null {
    if (!this.context) {
      return null;
    }

    try {
      return preferences.getPreferencesSync(this.context, { name: this.storeName });
    } catch (_error) {
      return null;
    }
  }

  private flushFallbackToPreferences(): void {
    const store = this.getPreferenceStore();
    if (!store) {
      return;
    }

    const pendingKeys = this.fallback.keys();
    pendingKeys.forEach((key) => {
      const value = this.fallback.load(key);
      if (value !== null) {
        this.persistValue(store, key, value);
      }
    });

    if (pendingKeys.length > 0) {
      try {
        store.flushSync();
      } catch (_error) {
      }
    }
  }

  private clearStoredValue(store: preferences.Preferences, key: string): void {
    const chunkMeta = store.getSync(this.getMetaKey(key), '') as string;
    if (typeof chunkMeta === 'string' && chunkMeta.length > 0) {
      try {
        const parsedMeta = JSON.parse(chunkMeta) as ChunkMeta;
        const chunkCount = typeof parsedMeta.count === 'number' ? parsedMeta.count : 0;
        for (let index = 0; index < chunkCount; index++) {
          store.deleteSync(this.getChunkKey(key, index));
        }
      } catch (_error) {
      }
      store.deleteSync(this.getMetaKey(key));
    }
    store.deleteSync(key);
  }

  private persistValue(store: preferences.Preferences, key: string, value: string): void {
    this.clearStoredValue(store, key);
    if (value.length <= PreferencesPersistenceAdapter.VALUE_CHUNK_SIZE) {
      store.putSync(key, value);
      return;
    }

    const chunks = this.splitValue(value);
    store.putSync(this.getMetaKey(key), JSON.stringify({ count: chunks.length }));
    chunks.forEach((chunk, index) => {
      store.putSync(this.getChunkKey(key, index), chunk);
    });
  }

  private splitValue(value: string): string[] {
    const chunks: string[] = [];
    for (let offset = 0; offset < value.length; offset += PreferencesPersistenceAdapter.VALUE_CHUNK_SIZE) {
      chunks.push(value.slice(offset, offset + PreferencesPersistenceAdapter.VALUE_CHUNK_SIZE));
    }
    return chunks;
  }

  private getMetaKey(key: string): string {
    return `${key}${PreferencesPersistenceAdapter.META_SUFFIX}`;
  }

  private getChunkKey(key: string, index: number): string {
    return `${key}${PreferencesPersistenceAdapter.CHUNK_PREFIX}${index}`;
  }
}

export function createMemoryPersistenceAdapter(): PersistenceAdapter {
  return new MemoryPersistenceAdapter();
}
