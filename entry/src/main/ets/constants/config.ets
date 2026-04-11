import { OrderStatus } from '../types/domain';

export const ADMIN_LOGIN_CODE: string = 'ADMIN2026';
export const AUTH_API_BASE_URL: string = 'http://49.232.30.147';
export const CAMPUS_API_BASE_URL: string = AUTH_API_BASE_URL;
export const AUTH_HTTP_TIMEOUT_MS: number = 15000;

export const DEFAULT_AVATAR: string = '';

export const ORDER_STATUS_TEXT: Record<OrderStatus, string> = {
  [OrderStatus.PENDING_PAYMENT]: '待付款',
  [OrderStatus.PAID_SIMULATED]: '已模拟支付',
  [OrderStatus.READY_HANDOVER]: '待当面交接',
  [OrderStatus.COMPLETED]: '已完成',
  [OrderStatus.CANCELED]: '已取消'
};

export const PRODUCT_CATEGORIES: string[] = [
  '教材书籍',
  '电子数码',
  '日用百货',
  '运动户外',
  '其他'
];

// Legacy fallback only. New publish/order flows should migrate to campus-configured trade locations.
export const CAMPUS_LOCATIONS: string[] = [
  '一食堂门口',
  '图书馆大厅',
  '北门快递点',
  '教学楼A栋',
  '宿舍区南门'
];
