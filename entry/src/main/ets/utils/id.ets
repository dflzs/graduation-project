export function newId(prefix: string): string {
  const randomPart: number = Math.floor(Math.random() * 100000);
  return `${prefix}_${Date.now()}_${randomPart}`;
}
