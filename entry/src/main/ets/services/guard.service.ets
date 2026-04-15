import { User } from '../types/domain';

export function canAccessAdmin(user: User | null): boolean {
  return user !== null && user.role === 'admin' && user.status === 'active';
}

export function getAdminActionDeniedMessage(user: User | null): string {
  if (canAccessAdmin(user)) {
    return '';
  }
  if (user && user.role === 'admin' && user.status !== 'active') {
    return '当前管理员账号已被停用，无法继续执行该操作';
  }
  return '仅管理员可执行该操作';
}

export function getAdminAccessDeniedMessage(user: User | null): string {
  if (canAccessAdmin(user)) {
    return '';
  }
  if (user && user.role === 'admin' && user.status !== 'active') {
    return '当前管理员账号已被停用，已停止后台访问';
  }
  return '仅管理员可访问';
}
