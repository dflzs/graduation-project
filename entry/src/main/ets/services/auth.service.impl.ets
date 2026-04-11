import { ADMIN_LOGIN_CODE } from '../constants/config';
import { userRepository } from '../repositories/user.repo';
import {
  AuthSession,
  OperationResult,
  RegisterCodeVerification,
  User,
  VerificationCodeDispatch
} from '../types/domain';
import {
  RemoteAuthClient,
  RemoteAuthUser,
  RemoteMeResponse,
  RemotePassResponse,
  RemoteRegisterCodeResponse,
  RemoteRegisterCodeVerifyResponse,
  RemoteUpdateMePayload
} from '../types/auth-remote';
import { AuthService } from '../types/service-contracts';
import { newId } from '../utils/id';
import { resolveDisplayedVerificationStatus } from '../utils/campus-verification-lifecycle-ui';
import { isValidPhone } from '../utils/validator';
import { HttpRemoteAuthClient } from './auth-remote.client';
import { AuthStateService, authStateService } from './auth-state.service';

const SESSION_TTL_MS: number = 7 * 24 * 3600 * 1000;

export class AuthServiceImpl implements AuthService {
  private session: AuthSession | null = null;
  private readonly remoteClient: RemoteAuthClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteAuthClient = new HttpRemoteAuthClient(),
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  async sendLoginCode(phone: string): Promise<OperationResult<VerificationCodeDispatch>> {
    if (!isValidPhone(phone)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002' };
    }

    return this.toVerificationCodeResult(phone, await this.remoteClient.sendLoginCode(phone));
  }

  async loginByPhone(phone: string, code: string): Promise<OperationResult<AuthSession>> {
    if (!isValidPhone(phone)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002' };
    }
    if (!this.isValidCode(code)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165 6 \u4f4d\u9a8c\u8bc1\u7801\u3002' };
    }

    const response = await this.remoteClient.validateLoginCode(phone, code);
    return this.createSessionFromRemote(response, phone, false);
  }

  async loginByPassword(phone: string, password: string): Promise<OperationResult<AuthSession>> {
    if (!isValidPhone(phone)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002' };
    }
    if (password.trim().length < 6) {
      return { ok: false, message: '\u5bc6\u7801\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 6 \u4f4d\u3002' };
    }

    const response = await this.remoteClient.loginByPassword(phone, password);
    return this.createSessionFromRemote(response, phone, true);
  }

  async sendRegisterCode(phone: string): Promise<OperationResult<VerificationCodeDispatch>> {
    if (!isValidPhone(phone)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002' };
    }

    return this.toRegisterCodeDispatchResult(await this.remoteClient.sendRegisterCode(phone), phone);
  }

  async verifyRegisterCode(phone: string, code: string): Promise<OperationResult<RegisterCodeVerification>> {
    if (!isValidPhone(phone)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002' };
    }
    if (!this.isValidCode(code)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165 6 \u4f4d\u9a8c\u8bc1\u7801\u3002' };
    }

    return this.toRegisterCodeVerificationResult(await this.remoteClient.verifyRegisterCode(phone, code), phone);
  }

  async completeRegister(
    phone: string,
    registerTicket: string,
    nickname: string,
    password: string
  ): Promise<OperationResult<AuthSession>> {
    if (!isValidPhone(phone)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002' };
    }
    if (registerTicket.trim().length === 0) {
      return { ok: false, message: '\u6ce8\u518c\u51ed\u8bc1\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u83b7\u53d6\u9a8c\u8bc1\u7801\u3002' };
    }
    if (nickname.trim().length < 2) {
      return { ok: false, message: '\u6635\u79f0\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 2 \u4f4d\u3002' };
    }
    if (password.trim().length < 6) {
      return { ok: false, message: '\u5bc6\u7801\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 6 \u4f4d\u3002' };
    }

    const response = await this.remoteClient.registerWithTicket(phone, registerTicket, nickname.trim(), password);
    return this.createSessionFromRemote(response, phone, true);
  }

  async updateProfile(nickname: string, avatar: string): Promise<OperationResult<User>> {
    const session = this.restoreSession();
    if (!session) {
      return { ok: false, message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u66f4\u65b0\u8d44\u6599\u3002' };
    }

    const normalizedNickname = nickname.trim();
    const currentAvatar = session.currentUser.avatar ?? '';
    const normalizedAvatar = avatar.trim().length > 0 ? avatar.trim() : currentAvatar;
    if (normalizedNickname.length < 2) {
      return { ok: false, message: '\u6635\u79f0\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 2 \u4e2a\u5b57\u3002' };
    }

    const response = await this.remoteClient.updateMe(
      session.token,
      new RemoteUpdateMePayload(normalizedNickname, normalizedAvatar)
    );

    return this.applyRemoteMeResponse(
      response,
      session.currentUser.phone,
      session.currentUser.passwordConfigured === true
    );
  }

  async updateAvatar(avatar: string): Promise<OperationResult<User>> {
    const session = this.restoreSession();
    if (!session) {
      return { ok: false, message: '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u66f4\u65b0\u5934\u50cf\u3002' };
    }

    return this.updateProfile(session.currentUser.nickname, avatar);
  }

  async registerDirect(_phone: string, _nickname: string, _password: string): Promise<OperationResult<AuthSession>> {
    return {
      ok: false,
      message: '\u8bf7\u5148\u5b8c\u6210\u624b\u673a\u53f7\u9a8c\u8bc1\u540e\u518d\u6ce8\u518c\u3002'
    };
  }

  async registerByPhone(_phone: string, _code: string, _password: string): Promise<OperationResult<AuthSession>> {
    return {
      ok: false,
      message: '\u65e7\u6ce8\u518c\u6d41\u7a0b\u5df2\u505c\u7528\uff0c\u8bf7\u4f7f\u7528\u9a8c\u8bc1\u7801\u524d\u7f6e\u7684\u65b0\u6ce8\u518c\u6d41\u7a0b\u3002'
    };
  }

  loginByAdminCode(phone: string, adminCode: string): OperationResult<AuthSession> {
    if (adminCode !== ADMIN_LOGIN_CODE) {
      return { ok: false, message: '\u7ba1\u7406\u5458\u53e3\u4ee4\u4e0d\u6b63\u786e\u3002' };
    }
    if (!isValidPhone(phone)) {
      return { ok: false, message: '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7\u3002' };
    }

    let admin: User | null = userRepository.getByPhone(phone);
    if (!admin) {
      const now = Date.now();
      admin = {
        id: newId('admin'),
        phone,
        nickname: '\u7ba1\u7406\u5458',
        role: 'admin',
        status: 'active',
        creditScore: 100,
        passwordConfigured: true,
        createdAt: now,
        updatedAt: now
      };
    } else {
      admin.role = 'admin';
      admin.passwordConfigured = true;
      admin.updatedAt = Date.now();
    }

    userRepository.save(admin);
    this.session = {
      currentUser: admin,
      token: newId('token'),
      expiresAt: Date.now() + 24 * 3600 * 1000
    };
    this.stateService.saveSession(this.session);

    return {
      ok: true,
      message: '\u7ba1\u7406\u5458\u767b\u5f55\u6210\u529f\u3002',
      data: this.session
    };
  }

  logout(): void {
    this.session = null;
    this.stateService.clear();
  }

  restoreSession(): AuthSession | null {
    if (!this.session && this.stateService.isLoggedIn()) {
      const persistedUser = this.stateService.getCurrentUser();
      const token = this.stateService.getToken();
      const expiresAt = this.stateService.getExpiresAt();
      if (persistedUser && token.length > 0) {
        const latestUser = userRepository.getById(persistedUser.id) ?? userRepository.getByPhone(persistedUser.phone);
        const sessionUser = this.normalizeVerificationState(latestUser ?? persistedUser);

        if (!latestUser) {
          userRepository.save(sessionUser);
        }

        this.session = {
          currentUser: sessionUser,
          token,
          expiresAt
        };
      }
    }

    if (!this.session) {
      return null;
    }
    if (this.session.expiresAt < Date.now()) {
      this.session = null;
      this.stateService.clear();
      return null;
    }

    const latestUser = userRepository.getById(this.session.currentUser.id);
    if (!latestUser || latestUser.status !== 'active') {
      this.session = null;
      this.stateService.clear();
      return null;
    }

    this.session.currentUser = this.normalizeVerificationState(latestUser);
    userRepository.save(this.session.currentUser);
    this.stateService.saveSession(this.session);
    return this.session;
  }

  private toVerificationCodeResult(phone: string, response: RemotePassResponse): OperationResult<VerificationCodeDispatch> {
    return {
      ok: response.code === 0,
      message: response.message,
      data: response.code === 0 ? {
        phone,
        code: undefined
      } : undefined
    };
  }

  private toRegisterCodeDispatchResult(
    response: RemoteRegisterCodeResponse,
    fallbackPhone: string
  ): OperationResult<VerificationCodeDispatch> {
    return {
      ok: response.code === 0,
      message: response.message,
      data: response.code === 0 ? {
        phone: response.data?.phone ?? fallbackPhone,
        code: response.data?.debugCode
      } : undefined
    };
  }

  private toRegisterCodeVerificationResult(
    response: RemoteRegisterCodeVerifyResponse,
    fallbackPhone: string
  ): OperationResult<RegisterCodeVerification> {
    return {
      ok: response.code === 0,
      message: response.message,
      data: response.code === 0 ? {
        phone: response.data?.phone ?? fallbackPhone,
        registerTicket: response.data?.registerTicket ?? '',
        code: undefined
      } : undefined
    };
  }

  private createSessionFromRemote(
    response: RemotePassResponse,
    fallbackPhone: string,
    passwordConfigured: boolean
  ): OperationResult<AuthSession> {
    if (response.code !== 0) {
      return {
        ok: false,
        message: response.message || '\u8ba4\u8bc1\u5931\u8d25\u3002'
      };
    }

    const remoteUser = response.data?.user;
    const token = response.data?.token;
    if (!remoteUser || !token) {
      return { ok: false, message: '\u767b\u5f55\u6210\u529f\uff0c\u4f46\u670d\u52a1\u5668\u672a\u8fd4\u56de\u5b8c\u6574\u7528\u6237\u4fe1\u606f\u3002' };
    }

    const currentUser = userRepository.getByPhone(remoteUser.phone || fallbackPhone);
    if (currentUser && currentUser.status !== 'active') {
      return { ok: false, message: '\u8be5\u8d26\u53f7\u5df2\u88ab\u505c\u7528\u3002' };
    }

    const mergedUser = this.mergeRemoteUser(currentUser, remoteUser, fallbackPhone, passwordConfigured);
    userRepository.save(mergedUser);
    this.session = this.buildSession(mergedUser, token);
    this.stateService.saveSession(this.session);

    return {
      ok: true,
      message: response.message || (passwordConfigured ? '\u6ce8\u518c\u6210\u529f\u3002' : '\u767b\u5f55\u6210\u529f\u3002'),
      data: this.session
    };
  }

  private applyRemoteMeResponse(
    response: RemoteMeResponse,
    fallbackPhone: string,
    passwordConfigured: boolean
  ): OperationResult<User> {
    if (response.code !== 0) {
      return {
        ok: false,
        message: response.message || '\u66f4\u65b0\u5934\u50cf\u5931\u8d25\u3002'
      };
    }

    const currentSession = this.restoreSession();
    const remoteUser = response.data;
    if (!currentSession || !remoteUser) {
      return { ok: false, message: '\u670d\u52a1\u5668\u672a\u8fd4\u56de\u5b8c\u6574\u7684\u7528\u6237\u4fe1\u606f\u3002' };
    }

    const existingUser = userRepository.getById(currentSession.currentUser.id)
      ?? userRepository.getByPhone(remoteUser.phone || fallbackPhone);
    const mergedUser = this.mergeRemoteUser(existingUser, remoteUser, fallbackPhone, passwordConfigured);

    userRepository.save(mergedUser);
    currentSession.currentUser = mergedUser;
    this.session = currentSession;
    this.stateService.saveSession(currentSession);

    return {
      ok: true,
      message: response.message || '\u5934\u50cf\u66f4\u65b0\u6210\u529f\u3002',
      data: mergedUser
    };
  }

  private buildSession(user: User, token?: string): AuthSession {
    return {
      currentUser: this.normalizeVerificationState(user),
      token: token || newId('token'),
      expiresAt: Date.now() + SESSION_TTL_MS
    };
  }

  private mergeRemoteUser(
    existingUser: User | null,
    remoteUser: RemoteAuthUser,
    fallbackPhone: string,
    passwordConfigured: boolean
  ): User {
    const now = Date.now();
    const phone = remoteUser.phone || fallbackPhone;

    if (!existingUser) {
      const createdUser: User = {
        id: String(remoteUser.id),
        phone,
        nickname: remoteUser.nickname || `\u7528\u6237${phone.slice(-4)}`,
        avatar: remoteUser.avatar || '',
        role: remoteUser.role === 'admin' ? 'admin' : 'user',
        status: remoteUser.status === 'banned' ? 'banned' : 'active',
        creditScore: remoteUser.credit_score,
        schoolId: remoteUser.school_id,
        schoolName: remoteUser.school_name,
        campusId: remoteUser.campus_id,
        campusName: remoteUser.campus_name,
        studentNo: remoteUser.student_no,
        gradeYear: remoteUser.grade_year,
        collegeName: remoteUser.college_name,
        majorName: remoteUser.major_name,
        verificationStatus: remoteUser.verification_status,
        verificationMethod: remoteUser.verification_method,
        verifiedAt: remoteUser.verified_at,
        verificationRejectedReason: remoteUser.verification_rejected_reason,
        verificationUpdatedAt: remoteUser.verification_updated_at,
        completedOrderCount: remoteUser.completed_order_count,
        reportCount: remoteUser.report_count,
        lastActiveAt: remoteUser.last_active_at,
        remoteUserId: String(remoteUser.id),
        passwordConfigured,
        createdAt: now,
        updatedAt: now
      };
      return this.normalizeVerificationState(createdUser);
    }

    const mergedUser: User = {
      id: String(remoteUser.id || existingUser.id),
      phone,
      nickname: remoteUser.nickname || existingUser.nickname || `\u7528\u6237${phone.slice(-4)}`,
      avatar: remoteUser.avatar || existingUser.avatar || '',
      role: remoteUser.role === 'admin' ? 'admin' : existingUser.role,
      status: remoteUser.status === 'banned' ? 'banned' : 'active',
      creditScore: remoteUser.credit_score || existingUser.creditScore,
      schoolId: remoteUser.school_id ?? existingUser.schoolId,
      schoolName: remoteUser.school_name ?? existingUser.schoolName,
      campusId: remoteUser.campus_id ?? existingUser.campusId,
      campusName: remoteUser.campus_name ?? existingUser.campusName,
      studentNo: remoteUser.student_no ?? existingUser.studentNo,
      gradeYear: remoteUser.grade_year ?? existingUser.gradeYear,
      collegeName: remoteUser.college_name ?? existingUser.collegeName,
      majorName: remoteUser.major_name ?? existingUser.majorName,
      verificationStatus: remoteUser.verification_status ?? existingUser.verificationStatus,
      verificationMethod: remoteUser.verification_method ?? existingUser.verificationMethod,
      verifiedAt: remoteUser.verified_at ?? existingUser.verifiedAt,
      verificationRejectedReason: remoteUser.verification_rejected_reason ?? existingUser.verificationRejectedReason,
      verificationUpdatedAt: remoteUser.verification_updated_at ?? existingUser.verificationUpdatedAt,
      completedOrderCount: remoteUser.completed_order_count ?? existingUser.completedOrderCount,
      reportCount: remoteUser.report_count ?? existingUser.reportCount,
      lastActiveAt: remoteUser.last_active_at ?? existingUser.lastActiveAt,
      remoteUserId: String(remoteUser.id),
      passwordConfigured: passwordConfigured || existingUser.passwordConfigured || false,
      createdAt: existingUser.createdAt,
      updatedAt: now
    };
    return this.normalizeVerificationState(mergedUser);
  }

  private normalizeVerificationState(user: User): User {
    const normalizedUser: User = {
      id: user.id,
      phone: user.phone,
      nickname: user.nickname,
      avatar: user.avatar,
      role: user.role,
      status: user.status,
      creditScore: user.creditScore,
      remoteUserId: user.remoteUserId,
      remoteSalt: user.remoteSalt,
      passwordConfigured: user.passwordConfigured,
      schoolId: user.schoolId,
      schoolName: user.schoolName,
      campusId: user.campusId,
      campusName: user.campusName,
      studentNo: user.studentNo,
      gradeYear: user.gradeYear,
      collegeName: user.collegeName,
      majorName: user.majorName,
      verificationStatus: resolveDisplayedVerificationStatus(user),
      verificationMethod: user.verificationMethod,
      verifiedAt: user.verifiedAt,
      verificationRejectedReason: user.verificationRejectedReason,
      verificationUpdatedAt: user.verificationUpdatedAt,
      completedOrderCount: user.completedOrderCount,
      reportCount: user.reportCount,
      lastActiveAt: user.lastActiveAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };
    return normalizedUser;
  }

  private isValidCode(code: string): boolean {
    return /^\d{6}$/.test(code.trim());
  }
}

export const authService: AuthServiceImpl = new AuthServiceImpl();
