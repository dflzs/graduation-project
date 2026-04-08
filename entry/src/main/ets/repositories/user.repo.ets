import { localDb } from '../data/db/local-db';
import { User } from '../types/domain';

export class UserRepository {
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
    if (index >= 0) {
      users[index] = user;
    } else {
      users.push(user);
    }
    localDb.setUsers(users);
    return user;
  }

  updateStatus(userId: string, status: 'active' | 'banned'): User | null {
    const users: User[] = localDb.getUsers();
    const index: number = users.findIndex((u: User) => u.id === userId);
    if (index < 0) {
      return null;
    }
    users[index].status = status;
    users[index].updatedAt = Date.now();
    localDb.setUsers(users);
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
