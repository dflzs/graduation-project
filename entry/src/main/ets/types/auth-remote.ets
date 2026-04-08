export interface RemoteAuthUser {
  id: number;
  phone: string;
  nickname: string;
  avatar: string;
  role: string;
  status: string;
  credit_score: number;
}

export interface RemoteAuthData {
  token: string;
  user: RemoteAuthUser;
}

export interface RemoteBaseResponse {
  code: number;
  message: string;
}

export interface RemotePassResponse extends RemoteBaseResponse {
  data?: RemoteAuthData;
}

export interface RemoteRegisterCodeData {
  phone: string;
  debugCode?: string;
}

export interface RemoteRegisterCodeResponse extends RemoteBaseResponse {
  data?: RemoteRegisterCodeData;
}

export interface RemoteRegisterCodeVerifyData {
  phone: string;
  registerTicket: string;
}

export interface RemoteRegisterCodeVerifyResponse extends RemoteBaseResponse {
  data?: RemoteRegisterCodeVerifyData;
}

export interface RemoteMeResponse extends RemoteBaseResponse {
  data?: RemoteAuthUser;
}

export interface RemoteAuthClient {
  sendLoginCode(phone: string): Promise<RemotePassResponse>;
  validateLoginCode(phone: string, code: string): Promise<RemotePassResponse>;
  loginByPassword(phone: string, password: string): Promise<RemotePassResponse>;
  sendRegisterCode(phone: string): Promise<RemoteRegisterCodeResponse>;
  verifyRegisterCode(phone: string, code: string): Promise<RemoteRegisterCodeVerifyResponse>;
  registerWithTicket(phone: string, registerTicket: string, nickname: string, password: string): Promise<RemotePassResponse>;
  updateMe(token: string, payload: RemoteUpdateMePayload): Promise<RemoteMeResponse>;
}

export class PhonePayload {
  phone: string = '';

  constructor(phone: string) {
    this.phone = phone;
  }
}

export class PhoneCodePayload extends PhonePayload {
  code: string = '';

  constructor(phone: string, code: string) {
    super(phone);
    this.code = code;
  }
}

export class PhoneCodePasswordPayload extends PhoneCodePayload {
  password: string = '';

  constructor(phone: string, code: string, password: string) {
    super(phone, code);
    this.password = password;
  }
}

export class PasswordLoginPayload {
  phone: string = '';
  password: string = '';

  constructor(phone: string, password: string) {
    this.phone = phone;
    this.password = password;
  }
}

export class DirectRegisterPayload {
  phone: string = '';
  nickname: string = '';
  password: string = '';

  constructor(phone: string, nickname: string, password: string) {
    this.phone = phone;
    this.nickname = nickname;
    this.password = password;
  }
}

export class TicketRegisterPayload extends DirectRegisterPayload {
  registerTicket: string = '';

  constructor(phone: string, registerTicket: string, nickname: string, password: string) {
    super(phone, nickname, password);
    this.registerTicket = registerTicket;
  }
}

export class RemoteUpdateMePayload {
  nickname: string = '';
  avatar: string = '';

  constructor(nickname: string, avatar: string) {
    this.nickname = nickname;
    this.avatar = avatar;
  }
}
