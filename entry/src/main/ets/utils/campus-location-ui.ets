import { TradeLocation } from '../types/domain';

function compareTradeLocationPriority(left: TradeLocation, right: TradeLocation, category: string): number {
  const leftCategoryMatched = left.recommendedCategories.includes(category) ? 1 : 0;
  const rightCategoryMatched = right.recommendedCategories.includes(category) ? 1 : 0;
  if (leftCategoryMatched !== rightCategoryMatched) {
    return rightCategoryMatched - leftCategoryMatched;
  }
  if (left.isHot !== right.isHot) {
    return right.isHot ? 1 : -1;
  }
  if (left.sortOrder !== right.sortOrder) {
    return left.sortOrder - right.sortOrder;
  }
  return left.name.localeCompare(right.name);
}

export function filterTradeLocationsForCategory(
  locations: TradeLocation[],
  category: string,
  groupId?: string
): TradeLocation[] {
  let items = locations.filter((item: TradeLocation) => item.isEnabled);
  if (groupId && groupId.length > 0) {
    items = items.filter((item: TradeLocation) => item.groupId === groupId);
  }
  items.sort((left: TradeLocation, right: TradeLocation) => compareTradeLocationPriority(left, right, category));
  return items;
}

export function pickPreferredTradeLocation(
  locations: TradeLocation[],
  category: string,
  groupId?: string
): TradeLocation | null {
  const items = filterTradeLocationsForCategory(locations, category, groupId);
  return items.length > 0 ? items[0] : null;
}

export function buildTradeLocationLabel(location: TradeLocation, groupName?: string): string {
  const baseName = location.alias && location.alias.length > 0 ? location.alias : location.name;
  if (!groupName || groupName.length === 0) {
    return baseName;
  }
  return `${groupName} · ${baseName}`;
}

export function buildTradeLocationHint(location: TradeLocation | null): string {
  if (!location) {
    return '当前校区暂未配置可用交易点，请联系管理员完善校园地点。';
  }
  if (location.safetyTips && location.safetyTips.length > 0) {
    return location.safetyTips;
  }
  if (location.description && location.description.length > 0) {
    return location.description;
  }
  return '建议优先选择人流较稳定、光线较好的校内公共区域完成交易。';
}
