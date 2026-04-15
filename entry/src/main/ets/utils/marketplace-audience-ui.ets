import { User } from '../types/domain';
import { MarketplaceAudienceMode, getMarketplaceAudienceMode } from './trade-guard';

export type MarketplacePrimaryAction = 'none' | 'login' | 'home' | 'admin' | 'profile' | 'publish';

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

export class MyPublishedAudiencePresentation {
  headerDescription: string;
  emptyTitle: string;
  emptyDescription: string;
  emptyPrimaryActionLabel: string;
  primaryAction: MarketplacePrimaryAction;

  constructor(
    headerDescription: string,
    emptyTitle: string,
    emptyDescription: string,
    emptyPrimaryActionLabel: string,
    primaryAction: MarketplacePrimaryAction
  ) {
    this.headerDescription = headerDescription;
    this.emptyTitle = emptyTitle;
    this.emptyDescription = emptyDescription;
    this.emptyPrimaryActionLabel = emptyPrimaryActionLabel;
    this.primaryAction = primaryAction;
  }
}

export class OrderListAudiencePresentation {
  headerDescription: string;
  emptyTitle: string;
  emptyDescription: string;
  emptyPrimaryActionLabel: string;
  primaryAction: MarketplacePrimaryAction;
  readOnlyHint: string;

  constructor(
    headerDescription: string,
    emptyTitle: string,
    emptyDescription: string,
    emptyPrimaryActionLabel: string,
    primaryAction: MarketplacePrimaryAction,
    readOnlyHint: string
  ) {
    this.headerDescription = headerDescription;
    this.emptyTitle = emptyTitle;
    this.emptyDescription = emptyDescription;
    this.emptyPrimaryActionLabel = emptyPrimaryActionLabel;
    this.primaryAction = primaryAction;
    this.readOnlyHint = readOnlyHint;
  }
}

export class AnnouncementAudiencePresentation {
  headerDescription: string;
  showPublishAction: boolean;
  publishActionLabel: string;

  constructor(headerDescription: string, showPublishAction: boolean, publishActionLabel: string) {
    this.headerDescription = headerDescription;
    this.showPublishAction = showPublishAction;
    this.publishActionLabel = publishActionLabel;
  }
}

export class MineTabAudiencePresentation {
  showAdminSection: boolean;
  showTradeSection: boolean;
  showPlatformSection: boolean;
  tradeSectionDescription: string;
  platformSectionDescription: string;

  constructor(
    showAdminSection: boolean,
    showTradeSection: boolean,
    showPlatformSection: boolean,
    tradeSectionDescription: string,
    platformSectionDescription: string
  ) {
    this.showAdminSection = showAdminSection;
    this.showTradeSection = showTradeSection;
    this.showPlatformSection = showPlatformSection;
    this.tradeSectionDescription = tradeSectionDescription;
    this.platformSectionDescription = platformSectionDescription;
  }
}

export class GovernanceCenterAudiencePresentation {
  headerDescription: string;
  emptyTitle: string;
  emptyDescription: string;
  primaryActionLabel: string;
  primaryAction: MarketplacePrimaryAction;
  readOnlyHint: string;
  showAppealSection: boolean;

  constructor(
    headerDescription: string,
    emptyTitle: string,
    emptyDescription: string,
    primaryActionLabel: string,
    primaryAction: MarketplacePrimaryAction,
    readOnlyHint: string,
    showAppealSection: boolean
  ) {
    this.headerDescription = headerDescription;
    this.emptyTitle = emptyTitle;
    this.emptyDescription = emptyDescription;
    this.primaryActionLabel = primaryActionLabel;
    this.primaryAction = primaryAction;
    this.readOnlyHint = readOnlyHint;
    this.showAppealSection = showAppealSection;
  }
}

export function shouldShowMarketplaceUnreadBadge(mode: MarketplaceAudienceMode): boolean {
  return mode !== 'guest';
}

export function buildMarketplaceUserSyncKeys(): string[] {
  return ['users:changed', 'governance:changed', 'moderation:changed'];
}

export function buildAnnouncementAudiencePresentation(mode: MarketplaceAudienceMode): AnnouncementAudiencePresentation {
  if (mode === 'admin') {
    return new AnnouncementAudiencePresentation(
      '平台规则、交易提醒和重要通知都会集中显示在这里。管理员可直接从这里进入公告发布与维护。',
      true,
      '发布'
    );
  }

  if (mode === 'restricted') {
    return new AnnouncementAudiencePresentation(
      '平台规则、交易提醒和重要通知都会集中显示在这里。当前账号仅可查看公告，不能继续发布或维护平台通知。',
      false,
      ''
    );
  }

  return new AnnouncementAudiencePresentation(
    '平台规则、交易提醒和重要通知都会集中显示在这里。',
    false,
    ''
  );
}

export function buildMineTabAudiencePresentation(user: User | null): MineTabAudiencePresentation {
  if (!user) {
    return new MineTabAudiencePresentation(
      false,
      false,
      false,
      '',
      ''
    );
  }

  const mode = getMarketplaceAudienceMode(user);
  if (mode === 'admin') {
    return new MineTabAudiencePresentation(
      true,
      false,
      false,
      '',
      ''
    );
  }

  if (user.role === 'admin') {
    return new MineTabAudiencePresentation(
      false,
      false,
      true,
      '',
      '账号当前受限，后台入口已暂停，仅保留公告查看和账号状态说明。'
    );
  }

  if (mode === 'restricted') {
    return new MineTabAudiencePresentation(
      false,
      true,
      true,
      '账号当前受限，但历史订单和已发布记录仍可查看，待恢复后可继续处理。',
      '平台公告和账号操作统一放在这个区域，方便查看当前限制状态。'
    );
  }

  return new MineTabAudiencePresentation(
    false,
    true,
    true,
    '常用交易入口会集中在这里，方便快速继续处理。',
    '平台公告和账号操作统一放在这个区域。'
  );
}

export function buildGovernanceCenterAudiencePresentation(
  mode: MarketplaceAudienceMode
): GovernanceCenterAudiencePresentation {
  if (mode === 'guest') {
    return new GovernanceCenterAudiencePresentation(
      '登录后可以集中查看你提交过的举报、投诉、申诉记录和平台处理进度。',
      '登录后查看治理记录',
      '治理中心会保存你的举报、投诉、申诉和平台处理结果，方便持续追踪。',
      '去登录',
      'login',
      '',
      false
    );
  }

  if (mode === 'admin') {
    return new GovernanceCenterAudiencePresentation(
      '管理员账号应通过后台治理工作台处理平台事件，不在前台治理中心查看个人案件。',
      '管理员请前往后台治理台',
      '如需处理举报、投诉或申诉，请前往后台举报处理页面统一操作。',
      '进入后台管理',
      'admin',
      '',
      false
    );
  }

  if (mode === 'restricted') {
    return new GovernanceCenterAudiencePresentation(
      '账号当前受限，但你仍可查看已提交的举报、投诉、申诉与平台处理结果。',
      '当前没有新的治理记录',
      '当平台处理结论、补证要求或申诉结果更新时，会优先同步到这里。',
      '',
      'none',
      '账号当前受限，治理中心仅保留只读追踪与申诉查看能力。',
      true
    );
  }

  return new GovernanceCenterAudiencePresentation(
    '集中查看你提交过的举报、投诉、申诉记录，以及平台最新处理进度。',
    '当前还没有治理记录',
    '当你发起举报、订单投诉或申诉后，平台处理进度会持续同步到这里。',
    '',
    'none',
    '',
    true
  );
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

  if (mode === 'restricted') {
    return new MessageHubAudiencePresentation(
      '账号当前已被限制，普通交易提醒和商品沟通已暂停。你仍可以在个人页查看账号状态和处理结果。',
      '账号提醒',
      '当账号状态、申诉结果或平台处理结论更新时，会优先展示在这里。',
      '当前没有新的账号提醒',
      '若账号恢复正常，交易提醒和商品沟通入口会自动恢复。',
      false,
      '',
      '',
      '',
      '',
      '查看账号状态',
      'profile'
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

  if (mode === 'restricted') {
    return new CartAudiencePresentation(
      '账号当前已被限制，购物车和结算流程暂不可用。请先前往个人页查看账号状态或等待恢复。',
      '当前账号暂不可使用购物车',
      '账号恢复正常后，你之前的交易操作会重新开放，届时可以继续添加商品和结算。',
      '查看账号状态',
      'profile',
      true,
      '账号受限期间，购物车与结算入口已暂停'
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

export function buildMyPublishedAudiencePresentation(mode: MarketplaceAudienceMode): MyPublishedAudiencePresentation {
  if (mode === 'guest') {
    return new MyPublishedAudiencePresentation(
      '登录后即可查看你发布过的商品、审核状态和交易进展。',
      '登录后查看你的发布记录',
      '发布后的审核结果、在售状态和交易进度都会集中显示在这里。',
      '去登录',
      'login'
    );
  }

  if (mode === 'restricted') {
    return new MyPublishedAudiencePresentation(
      '当前账号已被限制，你仍可查看历史发布记录，但暂时不能继续发布新的商品。',
      '当前账号暂不能继续发布商品',
      '账号恢复正常后，发布入口会自动重新开放，历史商品状态也会继续保留。',
      '查看账号状态',
      'profile'
    );
  }

  if (mode === 'admin') {
    return new MyPublishedAudiencePresentation(
      '管理员账号不参与普通商品发布，相关治理入口请前往后台管理。',
      '管理员不使用普通发布入口',
      '如需处理商品审核或平台治理，请直接进入后台管理页面。',
      '进入后台管理',
      'admin'
    );
  }

  return new MyPublishedAudiencePresentation(
    '这里会显示你的商品审核状态、交易状态和最近发布时间。',
    '你还没有发布过商品',
    '发布后会先进入审核，审核通过后才会显示在首页。',
    '去发布商品',
    'publish'
  );
}

export function buildOrderListAudiencePresentation(mode: MarketplaceAudienceMode): OrderListAudiencePresentation {
  if (mode === 'guest') {
    return new OrderListAudiencePresentation(
      '登录后可集中查看每一笔交易的状态、金额和后续操作。',
      '登录后查看订单记录',
      '完成下单后，交易进度、面交信息和后续操作都会在这里集中展示。',
      '去登录',
      'login',
      ''
    );
  }

  if (mode === 'restricted') {
    return new OrderListAudiencePresentation(
      '当前账号已被限制，你仍可查看历史订单，但暂时不能继续推进交易流程。',
      '当前没有可继续处理的订单',
      '账号受限期间，历史订单仍会保留在这里，恢复后可继续跟进后续进度。',
      '查看账号状态',
      'profile',
      '账号当前受限，仅可查看历史订单，不能继续支付、取消、确认到场、完结或评价。'
    );
  }

  if (mode === 'admin') {
    return new OrderListAudiencePresentation(
      '管理员账号不参与普通订单流转，这里不会产生常规交易订单。',
      '管理员没有普通订单记录',
      '如需处理交易治理，请前往后台查看平台数据与审核结果。',
      '进入后台管理',
      'admin',
      ''
    );
  }

  return new OrderListAudiencePresentation(
    '这里会集中展示每一笔交易的状态、金额和后续操作。',
    '还没有订单记录',
    '完成下单后，交易进度、面交信息和后续操作都会在这里集中展示。',
    '去逛逛商品',
    'home',
    ''
  );
}
