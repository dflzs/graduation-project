export interface HandoverTimeOption {
  key: string;
  label: string;
  helper: string;
}

const HANDOVER_TIME_OPTIONS: HandoverTimeOption[] = [
  {
    key: 'tonight',
    label: '今晚 18:00-19:00',
    helper: '适合今天内尽快完成面交，减少反复等待。'
  },
  {
    key: 'tomorrow_noon',
    label: '明天中午 12:10-13:00',
    helper: '适合在食堂、教学楼附近快速当面交接。'
  },
  {
    key: 'tomorrow_afternoon',
    label: '明天下午 16:30-17:30',
    helper: '适合下课后在校园公共区域继续验货和交接。'
  },
  {
    key: 'weekend',
    label: '周末白天 10:00-11:00',
    helper: '适合需要更多验货时间的教材或数码商品。'
  }
];

export function buildHandoverTimeOptions(): HandoverTimeOption[] {
  return HANDOVER_TIME_OPTIONS.slice();
}

export function buildRecommendedHandoverNote(locationLabel: string, slotLabel: string): string {
  const location = locationLabel.trim().length > 0 ? locationLabel.trim() : '校园公共区域';
  const slot = slotLabel.trim().length > 0 ? slotLabel.trim() : '尽快';
  return `建议${slot} 在${location}当面交接`;
}

export function buildTradeChatQuickReplySuggestions(locationLabel: string): string[] {
  const location = locationLabel.trim().length > 0 ? locationLabel.trim() : '校园公共区域';
  return buildHandoverTimeOptions()
    .slice(0, 3)
    .map((item: HandoverTimeOption) => `${item.label} 方便在${location}面交吗？`);
}

export function buildHandoverStatusSummary(locationLabel: string, address: string): string {
  const normalizedAddress = address.trim();
  if (normalizedAddress.length > 0) {
    return `当前约定：${normalizedAddress}`;
  }
  const location = locationLabel.trim().length > 0 ? locationLabel.trim() : '校园公共区域';
  return `建议优先在${location}完成当面交接，并提前确认到场时间。`;
}

export function buildCompactHandoverSummary(locationLabel: string, address: string): string {
  const normalizedAddress = address.trim();
  if (normalizedAddress.length > 0) {
    return `面交安排：${normalizedAddress}`;
  }
  const location = locationLabel.trim().length > 0 ? locationLabel.trim() : '待进一步确认';
  return `面交安排：${location}`;
}
