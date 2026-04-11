import { VerificationMethod, VerificationStatus } from './domain';

export interface RemoteAuthUser {
  id: number;
  phone: string;
  nickname: string;
  avatar: string;
  role: string;
  status: string;
  credit_score: number;
  school_id?: string;
  school_name?: string;
  campus_id?: string;
  campus_name?: string;
  student_no?: string;
  grade_year?: number;
  college_name?: string;
  major_name?: string;
  verification_status?: VerificationStatus;
  verification_method?: VerificationMethod;
  verified_at?: number;
  verification_rejected_reason?: string;
  verification_updated_at?: number;
  completed_order_count?: number;
  report_count?: number;
  last_active_at?: number;
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
  school_id?: string;
  campus_id?: string;
  student_no?: string;
  grade_year?: number;
  college_name?: string;
  major_name?: string;

  constructor(
    nickname: string,
    avatar: string,
    schoolId?: string,
    campusId?: string,
    studentNo?: string,
    gradeYear?: number,
    collegeName?: string,
    majorName?: string
  ) {
    this.nickname = nickname;
    this.avatar = avatar;
    this.school_id = schoolId;
    this.campus_id = campusId;
    this.student_no = studentNo;
    this.grade_year = gradeYear;
    this.college_name = collegeName;
    this.major_name = majorName;
  }
}
