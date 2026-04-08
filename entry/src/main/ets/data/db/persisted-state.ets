import { SEED_ANNOUNCEMENTS, SEED_PRODUCTS, SEED_USERS } from '../../constants/seed-data';
import { Announcement, CartItem, ChatMessage, ChatThreadRecord, MessageNotification, Order, Review, User, Product } from '../../types/domain';

export const LOCAL_DB_STORAGE_KEY: string = 'campus_market_local_db';
export const AUTH_STATE_STORAGE_KEY: string = 'campus_market_auth_state';
const PERSISTED_STATE_VERSION: number = 1;

export interface PersistedLocalState {
  version: number;
  users: User[];
  products: Product[];
  cartItems: CartItem[];
  orders: Order[];
  reviews: Review[];
  announcements: Announcement[];
  chatThreads: ChatThreadRecord[];
  chats: ChatMessage[];
  notifications: MessageNotification[];
}

export interface PersistedAuthState {
  version: number;
  isLogin: boolean;
  currentUser: User | null;
  token: string;
  expiresAt: number;
  passwordConfigured: boolean;
}

function clone<T>(input: T): T {
  return JSON.parse(JSON.stringify(input)) as T;
}

export function createSeedLocalState(): PersistedLocalState {
  return {
    version: PERSISTED_STATE_VERSION,
    users: clone(SEED_USERS),
    products: clone(SEED_PRODUCTS),
    cartItems: [],
    orders: [],
    reviews: [],
    announcements: clone(SEED_ANNOUNCEMENTS),
    chatThreads: [],
    chats: [],
    notifications: []
  };
}

export function createEmptyPersistedAuthState(): PersistedAuthState {
  return {
    version: PERSISTED_STATE_VERSION,
    isLogin: false,
    currentUser: null,
    token: '',
    expiresAt: 0,
    passwordConfigured: false
  };
}

export function normalizePersistedLocalState(raw: Partial<PersistedLocalState> | null | undefined): PersistedLocalState {
  const seed: PersistedLocalState = createSeedLocalState();
  if (!raw || raw.version !== PERSISTED_STATE_VERSION) {
    return seed;
  }

  return {
    version: PERSISTED_STATE_VERSION,
    users: Array.isArray(raw.users) ? clone(raw.users) : seed.users,
    products: Array.isArray(raw.products) ? clone(raw.products) : seed.products,
    cartItems: Array.isArray(raw.cartItems) ? clone(raw.cartItems) : [],
    orders: Array.isArray(raw.orders) ? clone(raw.orders) : [],
    reviews: Array.isArray(raw.reviews) ? clone(raw.reviews) : [],
    announcements: Array.isArray(raw.announcements) ? clone(raw.announcements) : seed.announcements,
    chatThreads: Array.isArray(raw.chatThreads) ? clone(raw.chatThreads) : [],
    chats: Array.isArray(raw.chats) ? clone(raw.chats) : [],
    notifications: Array.isArray(raw.notifications) ? clone(raw.notifications) : []
  };
}

export function normalizePersistedAuthState(raw: Partial<PersistedAuthState> | null | undefined): PersistedAuthState {
  const emptyState: PersistedAuthState = createEmptyPersistedAuthState();
  if (!raw || raw.version !== PERSISTED_STATE_VERSION) {
    return emptyState;
  }

  return {
    version: PERSISTED_STATE_VERSION,
    isLogin: raw.isLogin === true,
    currentUser: raw.currentUser ? clone(raw.currentUser) : null,
    token: typeof raw.token === 'string' ? raw.token : '',
    expiresAt: typeof raw.expiresAt === 'number' ? raw.expiresAt : 0,
    passwordConfigured: raw.passwordConfigured === true
  };
}

export function clonePersistedLocalState(state: PersistedLocalState): PersistedLocalState {
  return clone(state);
}

export function clonePersistedAuthState(state: PersistedAuthState): PersistedAuthState {
  return clone(state);
}
