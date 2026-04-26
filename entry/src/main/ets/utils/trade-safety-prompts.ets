export type CampusTradeSafetyStage = 'product_detail' | 'create_order' | 'chat_coordination' | 'order_detail';

export function buildCampusTradeSafetyHeadline(stage: CampusTradeSafetyStage): string {
  if (stage === 'create_order') {
    return '下单前提醒';
  }
  if (stage === 'chat_coordination') {
    return '沟通提醒';
  }
  if (stage === 'order_detail') {
    return '交接提醒';
  }
  return '校园交易提醒';
}

export function buildCampusTradeSafetyPrompts(category: string, stage: CampusTradeSafetyStage): string[] {
  const prompts: string[] = [...buildBaseStagePrompts(stage), buildCategoryPrompt(category, stage)];
  return prompts;
}

function buildBaseStagePrompts(stage: CampusTradeSafetyStage): string[] {
  if (stage === 'create_order') {
    return [
      '出发前再确认见面时间、地点和到场方式，避免双方空等。',
      '若临时改地点，尽量仍选择校内公开区域，并在聊天中留下确认记录。'
    ];
  }
  if (stage === 'chat_coordination') {
    return [
      '如需改时间或地点，建议直接在当前会话中同步，方便双方回看。',
      '遇到迟到、爽约或异常要求时，优先保留聊天记录并及时调整安排。'
    ];
  }
  if (stage === 'order_detail') {
    return [
      '完成交易前先当面核对商品状态、配件和金额，再确认交接。',
      '如现场情况与约定不符，可先暂停交易，并保留当前订单和聊天记录。'
    ];
  }
  return [
    '优先在校内公开区域当面沟通和验货，避免临时改到过于偏僻的位置。',
    '确认商品关键信息和交易方式后，再继续下单或约面交。'
  ];
}

function buildCategoryPrompt(category: string, stage: CampusTradeSafetyStage): string {
  if (category === '电子数码') {
    return '数码商品建议现场开机、检查外观和主要功能，再确认完成交易。';
  }
  if (category === '教材书籍') {
    return '教材书籍建议核对版次、笔记划线和缺页情况，避免拿错版本。';
  }
  if (category === '运动户外') {
    return '运动户外类商品建议确认尺码、磨损和关键配件是否齐全。';
  }
  if (category === '日用百货') {
    return '日用百货类商品建议确认卫生状况、使用痕迹和主要配件是否齐全。';
  }
  return stage === 'order_detail'
    ? '如现场情况与约定不符，可先暂停交易，并保留当前订单和聊天记录。'
    : '如有不确定的细节，建议继续通过聊天确认后再推进下一步交易。';
}
