export function formatTime(ts: number): string {
  const d: Date = new Date(ts);
  const y: number = d.getFullYear();
  const m: string = `${d.getMonth() + 1}`.padStart(2, '0');
  const day: string = `${d.getDate()}`.padStart(2, '0');
  const hh: string = `${d.getHours()}`.padStart(2, '0');
  const mm: string = `${d.getMinutes()}`.padStart(2, '0');
  return `${y}-${m}-${day} ${hh}:${mm}`;
}
