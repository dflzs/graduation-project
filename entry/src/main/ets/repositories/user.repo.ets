import { localDb } from '../data/db/local-db';
import { User, UserStatus } from '../types/domain';
import { syncService } from '../services/sync.service.impl';

export class UserRepository {
  private hasMeaningfulUserChange(previous: User | null, next: User): boolean {
    if (!previous) {
      return true;
    }
    return JSON.stringify(previous) !== JSON.stringify(next);
  }

  list(): User[] {
    return localDb.getUsers();
  }

  getById(userId: string): User | null {
    const user: User | undefined = localDb.getUsers().find((u: User) => u.id === userId);
    return user ?? null;
  }

  getByPhone(phone: string): User | null {
    const user: User | undefined = localDb.getUsers().find((u: User) => u.phone === phone);
    return user ?? null;
  }

  save(user: User): User {
    const users: User[] = localDb.getUsers();
    const index: number = users.findIndex((u: User) => u.id === user.id);
    const previousUser: User | null = index >= 0 ? users[index] : null;
    if (index >= 0) {
      users[index] = user;
    } else {
      users.push(user);
    }
    localDb.setUsers(users);
    if (this.hasMeaningfulUserChange(previousUser, user)) {
      syncService.publish({
        key: 'users:changed',
        value: user.id,
        updatedAt: user.updatedAt
      });
    }
    return user;
  }

  updateStatus(userId: string, status: UserStatus): User | null {
    const users: User[] = localDb.getUsers();
    const index: number = users.findIndex((u: User) => u.id === userId);
    if (index < 0) {
      return null;
    }
    users[index].status = status;
    users[index].updatedAt = Date.now();
    localDb.setUsers(users);
    syncService.publish({
      key: 'admin:user-status-changed',
      value: users[index].id,
      updatedAt: users[index].updatedAt
    });
    syncService.publish({
      key: 'users:changed',
      value: users[index].id,
      updatedAt: users[index].updatedAt
    });
    return users[index];
  }

  updateAvatar(userId: string, avatar: string): User | null {
    const users: User[] = localDb.getUsers();
    const index: number = users.findIndex((u: User) => u.id === userId);
    if (index < 0) {
      return null;
    }
    users[index].avatar = avatar;
    users[index].updatedAt = Date.now();
    localDb.setUsers(users);
    return users[index];
  }
}

export const userRepository: UserRepository = new UserRepository();
