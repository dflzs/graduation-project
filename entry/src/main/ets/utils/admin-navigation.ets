export class AdminNavEntry {
  title: string;
  description: string;
  url: string;
  accent: string;

  constructor(title: string, description: string, url: string, accent: string) {
    this.title = title;
    this.description = description;
    this.url = url;
    this.accent = accent;
  }
}

export function getAdminDashboardEntries(): AdminNavEntry[] {
  return [
    new AdminNavEntry('商品管理', '审核新发布商品，处理在售状态并支持强制下架。', 'pages/Admin/AdminProductsPage', '#2F6BFF'),
    new AdminNavEntry('用户管理', '查看用户身份、认证、信用与账号状态，执行治理动作。', 'pages/Admin/AdminUsersPage', '#B8643C'),
    new AdminNavEntry('认证审核', '处理学生认证申请，核验校园身份并反馈审核结果。', 'pages/Admin/AdminVerificationPage', '#237B46'),
    new AdminNavEntry('举报处理', '集中查看商品、用户、订单、会话治理记录并输出处理结论。', 'pages/Admin/AdminModerationPage', '#A86B00'),
    new AdminNavEntry('公告管理', '维护平台公告，让首页通知与规则信息保持最新。', 'pages/Admin/AdminAnnouncementPage', '#2D2A26')
  ];
}
