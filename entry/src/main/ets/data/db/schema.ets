export const TABLES: string[] = [
  'users',
  'products',
  'cart_items',
  'orders',
  'reviews',
  'announcements',
  'chats'
];

export const INDEXES: string[] = [
  'products(status,category,createdAt)',
  'orders(buyerId,status)',
  'orders(sellerId,status)',
  'reviews(toUserId)'
];

export const DB_VERSION: number = 1;
