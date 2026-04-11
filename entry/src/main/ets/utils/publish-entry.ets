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
  if (currentUser?.role === 'admin') {
    return new PublishEntryTarget(
      'pages/Admin/AdminDashboardPage',
      false,
      '管理员账号不支持发布商品，已为你切换到后台管理'
    );
  }

  if (currentUser) {
    return new PublishEntryTarget('pages/Product/PublishProductPage', false);
  }

  return new PublishEntryTarget('pages/Auth/LoginPage', true, '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u53d1\u5e03\u5546\u54c1');
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
