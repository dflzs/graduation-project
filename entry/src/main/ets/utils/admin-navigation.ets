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
    new AdminNavEntry('商品管理', '审核新发布商品，处理在售状态与强制下架。', 'pages/Admin/AdminProductsPage', '#2F6BFF'),
    new AdminNavEntry('用户管理', '查看用户身份、信用分与账号状态。', 'pages/Admin/AdminUsersPage', '#B8643C'),
    new AdminNavEntry('认证审核', '处理学生认证申请，核验校园身份并反馈驳回原因。', 'pages/Admin/AdminVerificationPage', '#237B46'),
    new AdminNavEntry('公告管理', '维护平台公告，让首页通知和规则保持最新。', 'pages/Admin/AdminAnnouncementPage', '#2D2A26')
  ];
}
