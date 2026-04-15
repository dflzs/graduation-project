export function buildAdminGuardSyncKeys(): string[] {
  return [
    'admin:user-status-changed',
    'users:changed'
  ];
}

export function buildAdminDashboardSyncKeys(): string[] {
  return [
    'admin:verification-changed',
    'admin:user-status-changed',
    'users:changed',
    'products:changed',
    'orders:changed',
    'announcements:changed'
  ];
}
