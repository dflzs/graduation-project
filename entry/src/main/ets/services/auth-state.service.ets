import { AuthSession, User } from '../types/domain';
import { createMemoryPersistenceAdapter, PersistenceAdapter } from '../data/db/persistence-adapter';
import {
  AUTH_STATE_STORAGE_KEY,
  clonePersistedAuthState,
  createEmptyPersistedAuthState,
  normalizePersistedAuthState,
  PersistedAuthState
} from '../data/db/persisted-state';

export class AuthStateSnapshot {
  isLogin: boolean = false;
  currentUser: User | null = null;
  token: string = '';
  expiresAt: number = 0;
  passwordConfigured: boolean = false;
}

export class AuthStateService {
  private persistence: PersistenceAdapter;
  private snapshot: AuthStateSnapshot = new AuthStateSnapshot();

  constructor(persistence: PersistenceAdapter = createMemoryPersistenceAdapter()) {
    this.persistence = persistence;
    this.restoreFromPersistence();
  }

  configurePersistence(persistence: PersistenceAdapter): void {
    this.persistence = persistence;
    this.restoreFromPersistence();
  }

  saveSession(session: AuthSession): void {
    this.snapshot.isLogin = true;
    this.snapshot.currentUser = this.clone(session.currentUser);
    this.snapshot.token = session.token;
    this.snapshot.expiresAt = session.expiresAt;
    this.snapshot.passwordConfigured = session.currentUser.passwordConfigured === true;
    this.flush();
  }

  getCurrentUser(): User | null {
    return this.snapshot.currentUser ? this.clone(this.snapshot.currentUser) : null;
  }

  getToken(): string {
    return this.snapshot.token;
  }

  getExpiresAt(): number {
    return this.snapshot.expiresAt;
  }

  isLoggedIn(): boolean {
    return this.snapshot.isLogin
      && this.snapshot.currentUser !== null
      && this.snapshot.token.length > 0
      && this.snapshot.expiresAt > Date.now();
  }

  isPasswordConfigured(): boolean {
    return this.snapshot.passwordConfigured;
  }

  clear(): void {
    this.snapshot = new AuthStateSnapshot();
    try {
      this.persistence.remove(AUTH_STATE_STORAGE_KEY);
    } catch (_error) {
    }
  }

  private restoreFromPersistence(): void {
    const raw: string | null = this.persistence.load(AUTH_STATE_STORAGE_KEY);
    if (!raw) {
      this.snapshot = new AuthStateSnapshot();
      return;
    }

    try {
      const parsed = normalizePersistedAuthState(JSON.parse(raw) as Partial<PersistedAuthState>);
      this.snapshot = {
        isLogin: parsed.isLogin,
        currentUser: parsed.currentUser ? this.clone(parsed.currentUser) : null,
        token: parsed.token,
        expiresAt: parsed.expiresAt,
        passwordConfigured: parsed.passwordConfigured
      };
    } catch (_error) {
      this.snapshot = new AuthStateSnapshot();
    }
  }

  private flush(): void {
    const state: PersistedAuthState = clonePersistedAuthState({
      version: createEmptyPersistedAuthState().version,
      isLogin: this.snapshot.isLogin,
      currentUser: this.snapshot.currentUser ? this.clone(this.snapshot.currentUser) : null,
      token: this.snapshot.token,
      expiresAt: this.snapshot.expiresAt,
      passwordConfigured: this.snapshot.passwordConfigured
    });

    try {
      this.persistence.save(AUTH_STATE_STORAGE_KEY, JSON.stringify(state));
    } catch (_error) {
    }
  }

  private clone<T>(input: T): T {
    return JSON.parse(JSON.stringify(input)) as T;
  }
}

export const authStateService: AuthStateService = new AuthStateService();
