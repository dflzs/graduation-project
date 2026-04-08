const CODE_TTL_MS = 5 * 60 * 1000;
const TICKET_TTL_MS = 10 * 60 * 1000;

const codeStore = new Map();
const ticketStore = new Map();

function now() {
  return Date.now();
}

function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function generateTicket(phone) {
  return `ticket_${phone}_${now()}_${Math.random().toString(36).slice(2, 10)}`;
}

function issueRegisterCode(phone) {
  const code = generateCode();
  codeStore.set(phone, {
    phone,
    code,
    purpose: 'register',
    consumed: false,
    expiresAt: now() + CODE_TTL_MS
  });
  return code;
}

function verifyRegisterCode(phone, code) {
  const record = codeStore.get(phone);
  if (!record) {
    return { ok: false, message: '验证码不存在，请先获取验证码。' };
  }
  if (record.consumed) {
    return { ok: false, message: '验证码已使用，请重新获取。' };
  }
  if (record.expiresAt <= now()) {
    codeStore.delete(phone);
    return { ok: false, message: '验证码已过期，请重新获取。' };
  }
  if (record.code !== code) {
    return { ok: false, message: '验证码错误。' };
  }

  record.consumed = true;
  const registerTicket = generateTicket(phone);
  ticketStore.set(registerTicket, {
    phone,
    registerTicket,
    expiresAt: now() + TICKET_TTL_MS,
    consumed: false
  });

  return {
    ok: true,
    data: {
      phone,
      registerTicket
    }
  };
}

function consumeRegisterTicket(phone, registerTicket) {
  const record = ticketStore.get(registerTicket);
  if (!record) {
    return { ok: false, message: '注册凭证无效，请重新验证手机号。' };
  }
  if (record.consumed) {
    return { ok: false, message: '注册凭证已失效，请重新验证手机号。' };
  }
  if (record.phone !== phone) {
    return { ok: false, message: '注册凭证与手机号不匹配。' };
  }
  if (record.expiresAt <= now()) {
    ticketStore.delete(registerTicket);
    return { ok: false, message: '注册凭证已过期，请重新验证手机号。' };
  }

  record.consumed = true;
  return { ok: true };
}

module.exports = {
  issueRegisterCode,
  verifyRegisterCode,
  consumeRegisterTicket
};
