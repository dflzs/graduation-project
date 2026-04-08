export function normalizeVerificationCode(value: string, length: number): string {
  return value.replace(/\D/g, '').slice(0, length);
}

export function buildVerificationCodeSlots(value: string, length: number): string[] {
  const normalized: string = normalizeVerificationCode(value, length);
  const slots: string[] = new Array(length).fill('');
  const pieces: string[] = normalized.split('');

  for (let index = 0; index < slots.length; index++) {
    slots[index] = pieces[index] || '';
  }

  return slots;
}

export function buildResendCountdownLabel(secondsRemaining: number): string {
  return secondsRemaining > 0 ? `${secondsRemaining}s` : '获取验证码';
}
