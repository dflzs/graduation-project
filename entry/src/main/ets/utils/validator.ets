export function isValidPhone(phone: string): boolean {
  return /^1\d{10}$/.test(phone.trim());
}

export function isNotBlank(input: string): boolean {
  return input.trim().length > 0;
}
