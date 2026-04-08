import { User } from '../types/domain';

export function canAccessAdmin(user: User | null): boolean {
  return user !== null && user.role === 'admin' && user.status === 'active';
}
