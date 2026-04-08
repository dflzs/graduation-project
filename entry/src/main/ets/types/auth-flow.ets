export class PhoneCodePageParams {
  phone: string = '';
  debugCode: string = '';

  constructor(phone: string, debugCode?: string) {
    this.phone = phone;
    this.debugCode = debugCode ?? '';
  }
}

export class RegisterProfilePageParams {
  phone: string = '';
  registerTicket: string = '';
  debugCode: string = '';

  constructor(phone: string, registerTicket: string, debugCode?: string) {
    this.phone = phone;
    this.registerTicket = registerTicket;
    this.debugCode = debugCode ?? '';
  }
}

export class RegisterPasswordPageParams extends RegisterProfilePageParams {
  code: string = '';

  constructor(phone: string, code: string, debugCode?: string) {
    super(phone, code, debugCode);
    this.code = code;
  }
}
