import {
  Campus,
  LocationGroup,
  OperationResult,
  School,
  StudentVerification,
  TradeLocation,
  User,
  VerificationStatus
} from '../types/domain';
import {
  CampusLocationQuery,
  CampusService
} from '../types/service-contracts';
import {
  RemoteCampusItem,
  RemoteCampusProfileItem,
  RemoteLocationGroupItem,
  RemoteReviewVerificationPayload,
  RemoteSchoolItem,
  RemoteStudentVerificationItem,
  RemoteSubmitVerificationPayload,
  RemoteTradeLocationItem,
  RemoteCampusProfilePayload,
  RemoteSchoolPayload,
  RemoteCampusPayload,
  RemoteLocationGroupPayload,
  RemoteTradeLocationPayload
} from '../types/campus-remote';
import { userRepository } from '../repositories/user.repo';
import { authStateService, AuthStateService } from './auth-state.service';
import { HttpRemoteCampusClient, RemoteCampusClient } from './campus-remote.client';
import { resolveDisplayedVerificationStatus } from '../utils/campus-verification-lifecycle-ui';

class CampusSessionData {
  token: string;
  user: User;

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}

function canManageCampusIdentity(user: User): boolean {
  return user.role === 'user';
}

function parseTimestamp(value: string | number | undefined): number | undefined {
  if (value === undefined) {
    return undefined;
  }
  if (typeof value === 'number') {
    return value;
  }

  const timestamp = Date.parse(value);
  return Number.isNaN(timestamp) ? undefined : timestamp;
}

function parseRequiredTimestamp(value: string | number): number {
  return parseTimestamp(value) ?? Date.now();
}

function cloneUser(user: User): User {
  return {
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
    verificationStatus: user.verificationStatus,
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
}

function mapRemoteSchool(item: RemoteSchoolItem): School {
  return {
    id: item.id,
    name: item.name,
    shortName: item.short_name,
    city: item.city,
    isEnabled: item.is_enabled,
    sortOrder: item.sort_order,
    createdAt: parseRequiredTimestamp(item.created_at),
    updatedAt: parseRequiredTimestamp(item.updated_at)
  };
}

function mapRemoteCampus(item: RemoteCampusItem): Campus {
  return {
    id: item.id,
    schoolId: item.school_id,
    name: item.name,
    shortName: item.short_name,
    isMainCampus: item.is_main_campus,
    isEnabled: item.is_enabled,
    sortOrder: item.sort_order,
    createdAt: parseRequiredTimestamp(item.created_at),
    updatedAt: parseRequiredTimestamp(item.updated_at)
  };
}

function mapRemoteLocationGroup(item: RemoteLocationGroupItem): LocationGroup {
  return {
    id: item.id,
    schoolId: item.school_id,
    campusId: item.campus_id,
    name: item.name,
    description: item.description,
    isEnabled: item.is_enabled,
    sortOrder: item.sort_order,
    createdAt: parseRequiredTimestamp(item.created_at),
    updatedAt: parseRequiredTimestamp(item.updated_at)
  };
}

function mapRemoteTradeLocation(item: RemoteTradeLocationItem): TradeLocation {
  return {
    id: item.id,
    schoolId: item.school_id,
    campusId: item.campus_id,
    groupId: item.group_id,
    name: item.name,
    alias: item.alias,
    description: item.description,
    safetyTips: item.safety_tips,
    recommendedCategories: item.recommended_categories,
    isEnabled: item.is_enabled,
    isHot: item.is_hot,
    sortOrder: item.sort_order,
    createdAt: parseRequiredTimestamp(item.created_at),
    updatedAt: parseRequiredTimestamp(item.updated_at)
  };
}

function mapRemoteVerification(item: RemoteStudentVerificationItem): StudentVerification {
  return {
    id: item.id,
    userId: item.user_id,
    schoolId: item.school_id,
    schoolName: item.school_name,
    campusId: item.campus_id,
    campusName: item.campus_name,
    studentNo: item.student_no,
    gradeYear: item.grade_year,
    collegeName: item.college_name,
    majorName: item.major_name,
    verificationMethod: item.verification_method,
    materialUrls: item.material_urls,
    status: item.status,
    submittedAt: parseRequiredTimestamp(item.submitted_at),
    reviewedAt: parseTimestamp(item.reviewed_at),
    reviewedBy: item.reviewed_by,
    reviewComment: item.review_comment,
    rejectReason: item.reject_reason,
    updatedAt: parseRequiredTimestamp(item.updated_at)
  };
}

function normalizeIdentityText(value?: string): string {
  if (value === undefined) {
    return '';
  }
  return value.trim();
}

function hasCampusIdentityChanged(existingUser: User, mergedUser: User): boolean {
  return normalizeIdentityText(existingUser.schoolId) !== normalizeIdentityText(mergedUser.schoolId)
    || normalizeIdentityText(existingUser.schoolName) !== normalizeIdentityText(mergedUser.schoolName)
    || normalizeIdentityText(existingUser.campusId) !== normalizeIdentityText(mergedUser.campusId)
    || normalizeIdentityText(existingUser.campusName) !== normalizeIdentityText(mergedUser.campusName)
    || normalizeIdentityText(existingUser.studentNo) !== normalizeIdentityText(mergedUser.studentNo)
    || (existingUser.gradeYear ?? 0) !== (mergedUser.gradeYear ?? 0)
    || normalizeIdentityText(existingUser.collegeName) !== normalizeIdentityText(mergedUser.collegeName)
    || normalizeIdentityText(existingUser.majorName) !== normalizeIdentityText(mergedUser.majorName);
}

function hasExistingCampusIdentity(user: User): boolean {
  return normalizeIdentityText(user.schoolId).length > 0
    || normalizeIdentityText(user.schoolName).length > 0
    || normalizeIdentityText(user.campusId).length > 0
    || normalizeIdentityText(user.campusName).length > 0
    || normalizeIdentityText(user.studentNo).length > 0
    || (user.gradeYear ?? 0) > 0
    || normalizeIdentityText(user.collegeName).length > 0
    || normalizeIdentityText(user.majorName).length > 0;
}

function mergeUserVerificationFromRecord(existingUser: User, verification: StudentVerification): User {
  const mergedUser = cloneUser(existingUser);
  mergedUser.schoolId = verification.schoolId || existingUser.schoolId;
  mergedUser.campusId = verification.campusId || existingUser.campusId;
  mergedUser.campusName = verification.campusName || existingUser.campusName;
  mergedUser.studentNo = verification.studentNo || existingUser.studentNo;
  mergedUser.gradeYear = verification.gradeYear ?? existingUser.gradeYear;
  mergedUser.collegeName = verification.collegeName ?? existingUser.collegeName;
  mergedUser.majorName = verification.majorName ?? existingUser.majorName;
  mergedUser.verificationStatus = verification.status;
  mergedUser.verificationMethod = verification.verificationMethod;
  mergedUser.verificationRejectedReason = verification.rejectReason ?? '';
  if (verification.status === VerificationStatus.VERIFIED && verification.reviewedAt !== undefined) {
    mergedUser.verifiedAt = verification.reviewedAt;
    mergedUser.verificationUpdatedAt = verification.reviewedAt;
  } else {
    mergedUser.verificationUpdatedAt = verification.updatedAt;
  }
  mergedUser.verificationStatus = resolveDisplayedVerificationStatus(mergedUser);
  mergedUser.updatedAt = Date.now();
  return mergedUser;
}

export function mergeRemoteCampusProfile(existingUser: User, profile: RemoteCampusProfileItem): User {
  const mergedUser = cloneUser(existingUser);
  mergedUser.schoolId = profile.school_id ?? existingUser.schoolId;
  mergedUser.schoolName = profile.school_name ?? existingUser.schoolName;
  mergedUser.campusId = profile.campus_id ?? existingUser.campusId;
  mergedUser.campusName = profile.campus_name ?? existingUser.campusName;
  mergedUser.studentNo = profile.student_no ?? existingUser.studentNo;
  mergedUser.gradeYear = profile.grade_year ?? existingUser.gradeYear;
  mergedUser.collegeName = profile.college_name ?? existingUser.collegeName;
  mergedUser.majorName = profile.major_name ?? existingUser.majorName;
  mergedUser.verificationStatus = profile.verification_status ?? existingUser.verificationStatus;
  mergedUser.verificationMethod = profile.verification_method ?? existingUser.verificationMethod;
  mergedUser.verifiedAt = parseTimestamp(profile.verified_at) ?? existingUser.verifiedAt;
  mergedUser.verificationRejectedReason =
    profile.verification_rejected_reason ?? existingUser.verificationRejectedReason;
  mergedUser.verificationUpdatedAt =
    parseTimestamp(profile.verification_updated_at) ?? existingUser.verificationUpdatedAt;
  mergedUser.completedOrderCount = profile.completed_order_count ?? existingUser.completedOrderCount;
  mergedUser.reportCount = profile.report_count ?? existingUser.reportCount;
  mergedUser.lastActiveAt = parseTimestamp(profile.last_active_at) ?? existingUser.lastActiveAt;
  if (
    resolveDisplayedVerificationStatus(existingUser) === VerificationStatus.VERIFIED
    && hasExistingCampusIdentity(existingUser)
    && mergedUser.verificationStatus === VerificationStatus.VERIFIED
    && hasCampusIdentityChanged(existingUser, mergedUser)
  ) {
    const verifiedAt = mergedUser.verifiedAt ?? 0;
    const currentVerificationUpdatedAt = mergedUser.verificationUpdatedAt ?? 0;
    if (currentVerificationUpdatedAt <= verifiedAt) {
      mergedUser.verificationUpdatedAt = Math.max(verifiedAt + 1, currentVerificationUpdatedAt);
    }
  }
  mergedUser.verificationStatus = resolveDisplayedVerificationStatus(mergedUser);
  mergedUser.updatedAt = Date.now();
  return mergedUser;
}

export class CampusServiceImpl implements CampusService {
  private readonly remoteClient: RemoteCampusClient;
  private readonly stateService: AuthStateService;

  constructor(
    remoteClient: RemoteCampusClient = new HttpRemoteCampusClient(),
    stateService: AuthStateService = authStateService
  ) {
    this.remoteClient = remoteClient;
    this.stateService = stateService;
  }

  async listSchools(): Promise<OperationResult<School[]>> {
    const result = await this.remoteClient.listSchools();
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    return {
      ok: true,
      message: result.message,
      data: (result.data ?? []).map(mapRemoteSchool)
    };
  }

  async listCampuses(schoolId: string): Promise<OperationResult<Campus[]>> {
    const result = await this.remoteClient.listCampuses(schoolId);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    return {
      ok: true,
      message: result.message,
      data: (result.data ?? []).map(mapRemoteCampus)
    };
  }

  async listLocationGroups(schoolId: string, campusId: string): Promise<OperationResult<LocationGroup[]>> {
    const result = await this.remoteClient.listLocationGroups(schoolId, campusId);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    return {
      ok: true,
      message: result.message,
      data: (result.data ?? []).map(mapRemoteLocationGroup)
    };
  }

  async listTradeLocations(query: CampusLocationQuery = {}): Promise<OperationResult<TradeLocation[]>> {
    const result = await this.remoteClient.listTradeLocations(query);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    let items: TradeLocation[] = (result.data ?? []).map(mapRemoteTradeLocation);
    if (query.enabledOnly === true) {
      items = items.filter((item) => item.isEnabled);
    }

    return {
      ok: true,
      message: result.message,
      data: items
    };
  }

  async getCurrentCampusProfile(): Promise<OperationResult<User | null>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }

    const current = sessionUser.data!;
    if (!canManageCampusIdentity(current.user)) {
      return { ok: false, message: '\u5f53\u524d\u8d26\u53f7\u7c7b\u578b\u4e0d\u652f\u6301\u67e5\u770b\u6821\u56ed\u8eab\u4efd\u8d44\u6599' };
    }
    const result = await this.remoteClient.getCurrentCampusProfile(current.token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    const profile = result.data?.data;
    if (!profile) {
      return { ok: true, message: result.data?.message ?? '', data: null };
    }

    const merged = mergeRemoteCampusProfile(current.user, profile);
    this.persistCurrentUser(current.token, merged);
    return {
      ok: true,
      message: result.data?.message ?? '',
      data: merged
    };
  }

  async updateCampusProfile(
    schoolId: string,
    campusId: string,
    campusName: string,
    studentNo: string,
    gradeYear?: number,
    collegeName?: string,
    majorName?: string
  ): Promise<OperationResult<User>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok || !sessionUser.data) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data;
    if (!canManageCampusIdentity(current.user)) {
      return { ok: false, message: '当前账号类型不支持维护校园身份资料' };
    }

    const result = await this.remoteClient.updateCampusProfile(
      current.token,
      new RemoteCampusProfilePayload(
        schoolId,
        campusId,
        campusName,
        studentNo,
        gradeYear,
        collegeName,
        majorName
      )
    );

    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '更新校园资料失败' };
    }

    const merged = mergeRemoteCampusProfile(current.user, result.data.data);
    this.persistCurrentUser(current.token, merged);
    return {
      ok: true,
      message: result.data.message,
      data: merged
    };
  }

  async getCurrentVerification(): Promise<OperationResult<StudentVerification | null>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }

    const current = sessionUser.data!;
    if (!canManageCampusIdentity(current.user)) {
      return { ok: false, message: '\u5f53\u524d\u8d26\u53f7\u7c7b\u578b\u4e0d\u652f\u6301\u67e5\u770b\u5b66\u751f\u8eab\u4efd\u8ba4\u8bc1' };
    }
    const result = await this.remoteClient.getCurrentVerification(current.token);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    if (!result.data?.data) {
      return {
        ok: true,
        message: result.data?.message ?? '',
        data: null
      };
    }

    const verification = mapRemoteVerification(result.data.data);
    const mergedUser = mergeUserVerificationFromRecord(current.user, verification);
    this.persistCurrentUser(current.token, mergedUser);

    return {
      ok: true,
      message: result.data.message,
      data: verification
    };
  }

  async submitVerification(input: StudentVerification): Promise<OperationResult<StudentVerification>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;
    if (!canManageCampusIdentity(current.user)) {
      return { ok: false, message: '当前账号类型不支持提交学生身份认证' };
    }

    const result = await this.remoteClient.submitVerification(
      current.token,
      new RemoteSubmitVerificationPayload(
        input.schoolId,
        input.campusId,
        input.campusName ?? '',
        input.studentNo,
        input.verificationMethod,
        input.materialUrls,
        input.gradeYear,
        input.collegeName,
        input.majorName
      )
    );

    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '提交认证失败' };
    }

    const verification = mapRemoteVerification(result.data.data);
    const mergedUser: User = cloneUser(current.user);
    mergedUser.schoolId = input.schoolId;
    mergedUser.campusId = input.campusId.length > 0 ? input.campusId : current.user.campusId;
    mergedUser.campusName = (input.campusName ?? '').length > 0 ? input.campusName : current.user.campusName;
    mergedUser.studentNo = input.studentNo;
    mergedUser.gradeYear = input.gradeYear;
    mergedUser.collegeName = input.collegeName;
    mergedUser.majorName = input.majorName;
    mergedUser.verificationStatus = verification.status;
    mergedUser.verificationMethod = verification.verificationMethod;
    mergedUser.verificationRejectedReason = verification.rejectReason ?? '';
    mergedUser.verificationUpdatedAt = verification.updatedAt;
    mergedUser.updatedAt = Date.now();
    this.persistCurrentUser(current.token, mergedUser);

    return {
      ok: true,
      message: result.data.message,
      data: verification
    };
  }

  async listVerificationApplications(status?: VerificationStatus): Promise<OperationResult<StudentVerification[]>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;

    const result = await this.remoteClient.listVerificationApplications(current.token, status);
    if (!result.ok) {
      return { ok: false, message: result.message };
    }

    return {
      ok: true,
      message: result.data?.message ?? '',
      data: (result.data?.data ?? []).map(mapRemoteVerification)
    };
  }

  async reviewVerification(
    verificationId: string,
    status: VerificationStatus,
    reviewComment: string,
    rejectReason: string
  ): Promise<OperationResult<StudentVerification>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;

    const result = await this.remoteClient.reviewVerification(
      current.token,
      verificationId,
      new RemoteReviewVerificationPayload(status, reviewComment, rejectReason)
    );

    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '审核认证失败' };
    }

    return {
      ok: true,
      message: result.data.message,
      data: mapRemoteVerification(result.data.data)
    };
  }

  async upsertSchool(school: School): Promise<OperationResult<School>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;

    const result = await this.remoteClient.upsertSchool(
      current.token,
      school.id,
      new RemoteSchoolPayload(
        school.name,
        school.sortOrder,
        school.shortName,
        undefined,
        school.city,
        school.isEnabled
      )
    );

    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '保存学校失败' };
    }

    return {
      ok: true,
      message: result.data.message,
      data: mapRemoteSchool(result.data.data)
    };
  }

  async upsertCampus(campus: Campus): Promise<OperationResult<Campus>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;

    const result = await this.remoteClient.upsertCampus(
      current.token,
      campus.id,
      new RemoteCampusPayload(
        campus.schoolId,
        campus.name,
        campus.sortOrder,
        campus.shortName,
        campus.isEnabled
      )
    );

    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '保存校区失败' };
    }

    return {
      ok: true,
      message: result.data.message,
      data: mapRemoteCampus(result.data.data)
    };
  }

  async upsertLocationGroup(group: LocationGroup): Promise<OperationResult<LocationGroup>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;

    const result = await this.remoteClient.upsertLocationGroup(
      current.token,
      group.id,
      new RemoteLocationGroupPayload(
        group.schoolId,
        group.campusId,
        group.name,
        group.sortOrder,
        group.description,
        group.isEnabled
      )
    );

    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '保存地点分组失败' };
    }

    return {
      ok: true,
      message: result.data.message,
      data: mapRemoteLocationGroup(result.data.data)
    };
  }

  async upsertTradeLocation(location: TradeLocation): Promise<OperationResult<TradeLocation>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;

    const result = await this.remoteClient.upsertTradeLocation(
      current.token,
      location.id,
      new RemoteTradeLocationPayload(
        location.schoolId,
        location.campusId,
        location.groupId,
        location.name,
        location.recommendedCategories,
        location.sortOrder,
        location.isHot,
        location.alias,
        location.description,
        location.safetyTips,
        location.isEnabled
      )
    );

    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '保存交易地点失败' };
    }

    return {
      ok: true,
      message: result.data.message,
      data: mapRemoteTradeLocation(result.data.data)
    };
  }

  async updateTradeLocationStatus(locationId: string, isEnabled: boolean): Promise<OperationResult<TradeLocation>> {
    const sessionUser = this.requireCurrentUser();
    if (!sessionUser.ok) {
      return { ok: false, message: sessionUser.message };
    }
    const current = sessionUser.data!;

    const result = await this.remoteClient.updateTradeLocationStatus(current.token, locationId, isEnabled);
    if (!result.ok || !result.data?.data) {
      return { ok: false, message: result.message || result.data?.message || '更新交易地点状态失败' };
    }

    return {
      ok: true,
      message: result.data.message,
      data: mapRemoteTradeLocation(result.data.data)
    };
  }

  private requireCurrentUser(): OperationResult<CampusSessionData> {
    const currentUser = this.stateService.getCurrentUser();
    const token = this.stateService.getToken();
    if (!currentUser || token.length === 0) {
      return { ok: false, message: '请先登录后再继续。' };
    }

    const sessionData = new CampusSessionData(token, currentUser);
    return {
      ok: true,
      message: '',
      data: sessionData
    };
  }

  private persistCurrentUser(token: string, user: User): void {
    userRepository.save(user);
    this.stateService.saveSession({
      currentUser: user,
      token,
      expiresAt: this.stateService.getExpiresAt()
    });
  }
}

export const campusService: CampusServiceImpl = new CampusServiceImpl();
