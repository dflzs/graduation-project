export function normalizeManualCoverUrl(value: string): string {
  const trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  const matched = trimmed.match(/https?:\/\/[^\s"'<>]+/);
  if (matched && matched.length > 0) {
    return matched[0];
  }
  return '';
}
