import { MarketplaceAudienceMode } from './trade-guard';

export type MarketplacePrimaryAction = 'none' | 'login' | 'home' | 'admin';

export class MessageHubAudiencePresentation {
  headerDescription: string;
  reminderSectionTitle: string;
  reminderSectionDescription: string;
  emptyReminderTitle: string;
  emptyReminderDescription: string;
  showThreads: boolean;
  threadSectionTitle: string;
  threadSectionDescription: string;
  emptyThreadTitle: string;
  emptyThreadDescription: string;
  emptyPrimaryActionLabel: string;
  primaryAction: MarketplacePrimaryAction;

  constructor(
    headerDescription: string,
    reminderSectionTitle: string,
    reminderSectionDescription: string,
    emptyReminderTitle: string,
    emptyReminderDescription: string,
    showThreads: boolean,
    threadSectionTitle: string,
    threadSectionDescription: string,
    emptyThreadTitle: string,
    emptyThreadDescription: string,
    emptyPrimaryActionLabel: string,
    primaryAction: MarketplacePrimaryAction
  ) {
    this.headerDescription = headerDescription;
    this.reminderSectionTitle = reminderSectionTitle;
    this.reminderSectionDescription = reminderSectionDescription;
    this.emptyReminderTitle = emptyReminderTitle;
    this.emptyReminderDescription = emptyReminderDescription;
    this.showThreads = showThreads;
    this.threadSectionTitle = threadSectionTitle;
    this.threadSectionDescription = threadSectionDescription;
    this.emptyThreadTitle = emptyThreadTitle;
    this.emptyThreadDescription = emptyThreadDescription;
    this.emptyPrimaryActionLabel = emptyPrimaryActionLabel;
    this.primaryAction = primaryAction;
  }
}

export class CartAudiencePresentation {
  headerDescription: string;
  emptyTitle: string;
  emptyDescription: string;
  emptyPrimaryActionLabel: string;
  primaryAction: MarketplacePrimaryAction;
  isLocked: boolean;
  bottomHint: string;

  constructor(
    headerDescription: string,
    emptyTitle: string,
    emptyDescription: string,
    emptyPrimaryActionLabel: string,
    primaryAction: MarketplacePrimaryAction,
    isLocked: boolean,
    bottomHint: string
  ) {
    this.headerDescription = headerDescription;
    this.emptyTitle = emptyTitle;
    this.emptyDescription = emptyDescription;
    this.emptyPrimaryActionLabel = emptyPrimaryActionLabel;
    this.primaryAction = primaryAction;
    this.isLocked = isLocked;
    this.bottomHint = bottomHint;
  }
}

export function shouldShowMarketplaceUnreadBadge(mode: MarketplaceAudienceMode): boolean {
  return mode === 'trader';
}

export function buildMessageHubAudiencePresentation(mode: MarketplaceAudienceMode): MessageHubAudiencePresentation {
  if (mode === 'guest') {
    return new MessageHubAudiencePresentation(
      '把交易提醒和商品沟通集中在一起，重要信息会优先出现在上面。',
      '交易提醒',
      '订单状态、审核结果和系统提醒会优先显示在这里。',
      '登录后查看消息',
      '审核结果、订单变化和与卖家的沟通记录都会集中保存在这里。',
      false,
      '',
      '',
      '',
      '',
      '去登录',
      'login'
    );
  }

  if (mode === 'admin') {
    return new MessageHubAudiencePresentation(
      '管理员账号不参与普通交易沟通，这里只保留平台审核和治理过程中需要关注的后台提醒。',
      '后台提醒',
      '审核处理、平台治理和系统状态更新会集中显示在这里。',
      '当前没有新的后台提醒',
      '当出现新的审核处理结果、系统状态变化或治理事项时，会优先展示在这里。',
      false,
      '',
      '',
      '',
      '',
      '进入后台管理',
      'admin'
    );
  }

  return new MessageHubAudiencePresentation(
    '把交易提醒和商品沟通集中在一起，重要信息会优先出现在上面。',
    '交易提醒',
    '订单状态、审核结果和系统提醒会优先显示在这里。',
    '暂时没有新的交易提醒',
    '商品审核、下单、取消和完成交易后，提醒会第一时间出现在这里。',
    true,
    '会话',
    '联系卖家之后，这里会保留每件商品对应的沟通记录。',
    '还没有开始新的商品沟通',
    '去商品详情联系卖家后，会话会自动出现在这里，方便继续确认时间、地点和交易细节。',
    '',
    'none'
  );
}

export function buildCartAudiencePresentation(mode: MarketplaceAudienceMode): CartAudiencePresentation {
  if (mode === 'guest') {
    return new CartAudiencePresentation(
      '登录后可同步你想买的商品，并集中管理待结算内容',
      '登录后同步你的购物车',
      '把想买的商品先加入购物车，再统一勾选、删除和去结算，流程会更顺。',
      '去登录',
      'login',
      false,
      '登录后可同步购物车并继续结算'
    );
  }

  if (mode === 'admin') {
    return new CartAudiencePresentation(
      '管理员账号不参与普通交易，购物车仅对校园用户开放。',
      '管理员不使用购物车',
      '后台账号不参与普通商品购买、结算和交易沟通。需要处理平台事务时，请直接进入后台管理。',
      '进入后台管理',
      'admin',
      true,
      '管理员账号不参与普通交易'
    );
  }

  return new CartAudiencePresentation(
    '已加入待选商品，勾选后可统一管理和结算',
    '购物车还是空的',
    '把想买的商品先加入购物车，之后就能在这里统一勾选、管理和去结算。',
    '去首页继续挑选',
    'home',
    false,
    '已选商品可统一结算'
  );
}
