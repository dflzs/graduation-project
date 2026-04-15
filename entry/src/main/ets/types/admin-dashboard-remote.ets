export class RemoteAdminDashboardItem {
  user_count: number = 0;
  product_count: number = 0;
  order_count: number = 0;
  completed_order_count: number = 0;
  announcement_count: number = 0;
}

export interface RemoteAdminDashboardResponse {
  code: number;
  message: string;
  data?: RemoteAdminDashboardItem;
}
