import { User } from '../types/domain';

export class DetailReturnParams {
  tab?: string;

  constructor(tab?: string) {
    this.tab = tab;
  }
}

export class DetailReturnTarget {
  url: string;
  params?: DetailReturnParams;

  constructor(url: string, params?: DetailReturnParams) {
    this.url = url;
    this.params = params;
  }
}

export function buildOrderDetailReturnTarget(source: string): DetailReturnTarget | null {
  if (source === 'create' || source === 'list') {
    return new DetailReturnTarget('pages/Order/OrderListPage');
  }

  if (source === 'message') {
    return new DetailReturnTarget('pages/Index', new DetailReturnParams('message'));
  }

  return null;
}

export function buildChatDetailReturnTarget(user: User | null): DetailReturnTarget {
  if (!user) {
    return new DetailReturnTarget('pages/Auth/LoginPage');
  }
  return new DetailReturnTarget('pages/Index', new DetailReturnParams('message'));
}

export function resolveIndexRouteTab(routeTab: string | undefined, fallbackTab: number): number {
  if (routeTab === 'home') {
    return 0;
  }

  if (routeTab === 'message') {
    return 1;
  }

  if (routeTab === 'mine') {
    return 4;
  }

  return fallbackTab;
}
