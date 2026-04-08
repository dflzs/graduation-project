import { Announcement, Product, User } from '../types/domain';

const now: number = Date.now();

export const SEED_USERS: User[] = [
  {
    id: 'u_admin',
    phone: '18800000000',
    nickname: '系统管理员',
    role: 'admin',
    status: 'active',
    creditScore: 100,
    createdAt: now,
    updatedAt: now
  },
  {
    id: 'u_demo_1',
    phone: '18812345678',
    nickname: '校园卖家A',
    role: 'user',
    status: 'active',
    creditScore: 88,
    createdAt: now,
    updatedAt: now
  }
];

export const SEED_PRODUCTS: Product[] = [
  {
    id: 'p_1',
    sellerId: 'u_demo_1',
    title: '高数教材（同济版）',
    desc: '九成新，带笔记，适合大一新生。',
    price: 28,
    category: '教材书籍',
    images: [],
    locationTag: '图书馆大厅',
    status: 'on_sale',
    isDeleted: false,
    createdAt: now,
    updatedAt: now
  },
  {
    id: 'p_2',
    sellerId: 'u_demo_1',
    title: '二手机械键盘',
    desc: '蓝牙双模，使用一年，功能正常。',
    price: 120,
    category: '电子数码',
    images: [],
    locationTag: '北门快递点',
    status: 'on_sale',
    isDeleted: false,
    createdAt: now,
    updatedAt: now
  }
];

export const SEED_ANNOUNCEMENTS: Announcement[] = [
  {
    id: 'a_1',
    title: '欢迎使用校园电商',
    content: '请遵守平台规则，严禁发布违规商品。',
    publisherId: 'u_admin',
    isDeleted: false,
    createdAt: now,
    updatedAt: now
  }
];
