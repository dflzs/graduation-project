import {
  AppealRecord,
  Announcement,
  CartItem,
  ChatMessage,
  ChatThreadRecord,
  GovernanceAction,
  MessageNotification,
  ModerationRecord,
  Order,
  Product,
  Review,
  User
} from '../../types/domain';
import { createMemoryPersistenceAdapter, PersistenceAdapter } from './persistence-adapter';
import {
  clonePersistedLocalState,
  createSeedLocalState,
  LOCAL_DB_STORAGE_KEY,
  normalizeAppealRecord,
  normalizeGovernanceAction,
  normalizeModerationRecord,
  normalizePersistedLocalState,
  PersistedLocalState
} from './persisted-state';

export class LocalDb {
  private persistence: PersistenceAdapter;
  private users: User[] = [];
  private products: Product[] = [];
  private cartItems: CartItem[] = [];
  private orders: Order[] = [];
  private reviews: Review[] = [];
  private announcements: Announcement[] = [];
  private chatThreads: ChatThreadRecord[] = [];
  private chats: ChatMessage[] = [];
  private notifications: MessageNotification[] = [];
  private moderationRecords: ModerationRecord[] = [];
  private appealRecords: AppealRecord[] = [];
  private governanceActions: GovernanceAction[] = [];

  constructor(persistence: PersistenceAdapter = createMemoryPersistenceAdapter()) {
    this.persistence = persistence;
    this.restore();
  }

  configurePersistence(persistence: PersistenceAdapter): void {
    this.persistence = persistence;
    this.restore();
  }

  reload(): void {
    this.restore();
  }

  private clone<T>(input: T): T {
    return JSON.parse(JSON.stringify(input)) as T;
  }

  private restore(): void {
    const raw: string | null = this.persistence.load(LOCAL_DB_STORAGE_KEY);
    if (!raw) {
      this.applyState(createSeedLocalState());
      return;
    }

    try {
      this.applyState(normalizePersistedLocalState(JSON.parse(raw) as Partial<PersistedLocalState>));
    } catch (_error) {
      this.applyState(createSeedLocalState());
    }
  }

  private applyState(state: PersistedLocalState): void {
    const normalizedState: PersistedLocalState = clonePersistedLocalState(state);
    this.users = normalizedState.users;
    this.products = normalizedState.products;
    this.cartItems = normalizedState.cartItems;
    this.orders = normalizedState.orders;
    this.reviews = normalizedState.reviews;
    this.announcements = normalizedState.announcements;
    this.chatThreads = normalizedState.chatThreads;
    this.chats = normalizedState.chats;
    this.notifications = normalizedState.notifications;
    this.moderationRecords = normalizedState.moderationRecords;
    this.appealRecords = normalizedState.appealRecords;
    this.governanceActions = normalizedState.governanceActions;
  }

  private flush(): void {
    const state: PersistedLocalState = {
      version: 1,
      users: this.clone(this.users),
      products: this.clone(this.products),
      cartItems: this.clone(this.cartItems),
      orders: this.clone(this.orders),
      reviews: this.clone(this.reviews),
      announcements: this.clone(this.announcements),
      chatThreads: this.clone(this.chatThreads),
      chats: this.clone(this.chats),
      notifications: this.clone(this.notifications),
      moderationRecords: this.clone(this.moderationRecords),
      appealRecords: this.clone(this.appealRecords),
      governanceActions: this.clone(this.governanceActions)
    };

    try {
      this.persistence.save(LOCAL_DB_STORAGE_KEY, JSON.stringify(state));
    } catch (_error) {
      // Keep in-memory state even if persistence is temporarily unavailable.
    }
  }

  getUsers(): User[] {
    return this.clone(this.users);
  }

  setUsers(users: User[]): void {
    this.users = this.clone(users);
    this.flush();
  }

  getProducts(): Product[] {
    return this.clone(this.products);
  }

  setProducts(products: Product[]): void {
    this.products = this.clone(products);
    this.flush();
  }

  getCartItems(): CartItem[] {
    return this.clone(this.cartItems);
  }

  setCartItems(cartItems: CartItem[]): void {
    this.cartItems = this.clone(cartItems);
    this.flush();
  }

  getOrders(): Order[] {
    return this.clone(this.orders);
  }

  setOrders(orders: Order[]): void {
    this.orders = this.clone(orders);
    this.flush();
  }

  getReviews(): Review[] {
    return this.clone(this.reviews);
  }

  setReviews(reviews: Review[]): void {
    this.reviews = this.clone(reviews);
    this.flush();
  }

  getAnnouncements(): Announcement[] {
    return this.clone(this.announcements);
  }

  setAnnouncements(announcements: Announcement[]): void {
    this.announcements = this.clone(announcements);
    this.flush();
  }

  getChats(): ChatMessage[] {
    return this.clone(this.chats);
  }

  getChatThreads(): ChatThreadRecord[] {
    return this.clone(this.chatThreads);
  }

  setChatThreads(chatThreads: ChatThreadRecord[]): void {
    this.chatThreads = this.clone(chatThreads);
    this.flush();
  }

  setChats(chats: ChatMessage[]): void {
    this.chats = this.clone(chats);
    this.flush();
  }

  getNotifications(): MessageNotification[] {
    return this.clone(this.notifications);
  }

  setNotifications(notifications: MessageNotification[]): void {
    this.notifications = this.clone(notifications);
    this.flush();
  }

  getModerationRecords(): ModerationRecord[] {
    return this.clone(this.moderationRecords);
  }

  setModerationRecords(records: ModerationRecord[]): void {
    this.moderationRecords = records.map((record: ModerationRecord) => normalizeModerationRecord(record));
    this.flush();
  }

  getAppealRecords(): AppealRecord[] {
    return this.clone(this.appealRecords);
  }

  setAppealRecords(records: AppealRecord[]): void {
    this.appealRecords = records.map((record: AppealRecord) => normalizeAppealRecord(record));
    this.flush();
  }

  getGovernanceActions(): GovernanceAction[] {
    return this.clone(this.governanceActions);
  }

  setGovernanceActions(records: GovernanceAction[]): void {
    this.governanceActions = records.map((record: GovernanceAction) => normalizeGovernanceAction(record));
    this.flush();
  }
}

export const localDb: LocalDb = new LocalDb();
