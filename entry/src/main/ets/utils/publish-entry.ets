import { User } from '../types/domain';
import { pushUrlByContext, showToastByContext, UiContextHost } from './ui-context-actions';

export class PublishEntryTarget {
  url: string;
  requiresLogin: boolean;
  promptMessage: string;

  constructor(url: string, requiresLogin: boolean, promptMessage: string = '') {
    this.url = url;
    this.requiresLogin = requiresLogin;
    this.promptMessage = promptMessage;
  }
}

export function resolvePublishEntryTarget(currentUser: User | null): PublishEntryTarget {
  if (!currentUser) {
    return new PublishEntryTarget('pages/Auth/LoginPage', true, '请先登录后再发布商品');
  }

  if (currentUser.status !== 'active') {
    return new PublishEntryTarget('pages/Profile/ProfilePage', false, '该账号已被停用，无法发布商品');
  }

  if (currentUser.role === 'admin') {
    return new PublishEntryTarget(
      'pages/Admin/AdminDashboardPage',
      false,
      '管理员账号不支持发布商品，已为你切换到后台管理'
    );
  }

  return new PublishEntryTarget('pages/Product/PublishProductPage', false);
}

export function openPublishEntry(host: UiContextHost, currentUser: User | null): void {
  const target = resolvePublishEntryTarget(currentUser);
  if (target.promptMessage.length > 0) {
    showToastByContext(host, {
      message: target.promptMessage,
      duration: 1500
    });
  }
  pushUrlByContext(host, { url: target.url });
}
