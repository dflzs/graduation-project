import { VerificationMethod, VerificationStatus } from './domain';

export interface RemoteSchoolItem {
  id: string;
  name: string;
  short_name: string;
  city?: string;
  is_enabled: boolean;
  sort_order: number;
  created_at: string | number;
  updated_at: string | number;
}

export interface RemoteCampusItem {
  id: string;
  school_id: string;
  name: string;
  short_name: string;
  is_main_campus: boolean;
  is_enabled: boolean;
  sort_order: number;
  created_at: string | number;
  updated_at: string | number;
}

export interface RemoteLocationGroupItem {
  id: string;
  school_id: string;
  campus_id: string;
  name: string;
  description?: string;
  is_enabled: boolean;
  sort_order: number;
  created_at: string | number;
  updated_at: string | number;
}

export interface RemoteTradeLocationItem {
  id: string;
  school_id: string;
  campus_id: string;
  group_id: string;
  name: string;
  alias?: string;
  description?: string;
  safety_tips?: string;
  recommended_categories: string[];
  is_enabled: boolean;
  is_hot: boolean;
  sort_order: number;
  created_at: string | number;
  updated_at: string | number;
}

export interface RemoteStudentVerificationItem {
  id: string;
  user_id: string;
  school_id: string;
  school_name?: string;
  campus_id: string;
  campus_name?: string;
  student_no: string;
  grade_year?: number;
  college_name?: string;
  major_name?: string;
  verification_method: VerificationMethod;
  material_urls: string[];
  status: VerificationStatus;
  submitted_at: string | number;
  reviewed_at?: string | number;
  reviewed_by?: string;
  review_comment?: string;
  reject_reason?: string;
  updated_at: string | number;
}

export interface RemoteCampusProfileItem {
  id: string;
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
  verified_at?: string | number;
  verification_rejected_reason?: string;
  verification_updated_at?: string | number;
  completed_order_count?: number;
  report_count?: number;
  last_active_at?: string | number;
}

export interface RemoteCampusBaseResponse {
  code: number;
  message: string;
}

export interface RemoteSchoolListResponse extends RemoteCampusBaseResponse {
  data?: RemoteSchoolItem[];
}

export interface RemoteSchoolResponse extends RemoteCampusBaseResponse {
  data?: RemoteSchoolItem;
}

export interface RemoteCampusListResponse extends RemoteCampusBaseResponse {
  data?: RemoteCampusItem[];
}

export interface RemoteCampusResponse extends RemoteCampusBaseResponse {
  data?: RemoteCampusItem;
}

export interface RemoteLocationGroupListResponse extends RemoteCampusBaseResponse {
  data?: RemoteLocationGroupItem[];
}

export interface RemoteLocationGroupResponse extends RemoteCampusBaseResponse {
  data?: RemoteLocationGroupItem;
}

export interface RemoteTradeLocationListResponse extends RemoteCampusBaseResponse {
  data?: RemoteTradeLocationItem[];
}

export interface RemoteTradeLocationResponse extends RemoteCampusBaseResponse {
  data?: RemoteTradeLocationItem;
}

export interface RemoteStudentVerificationResponse extends RemoteCampusBaseResponse {
  data?: RemoteStudentVerificationItem;
}

export interface RemoteStudentVerificationListResponse extends RemoteCampusBaseResponse {
  data?: RemoteStudentVerificationItem[];
}

export interface RemoteCampusProfileResponse extends RemoteCampusBaseResponse {
  data?: RemoteCampusProfileItem;
}

export class RemoteCampusProfilePayload {
  school_id: string = '';
  campus_id?: string;
  campus_name: string = '';
  student_no: string = '';
  grade_year?: number;
  college_name?: string;
  major_name?: string;

  constructor(
    schoolId: string,
    campusId: string,
    campusName: string,
    studentNo: string,
    gradeYear?: number,
    collegeName?: string,
    majorName?: string
  ) {
    this.school_id = schoolId;
    this.campus_id = campusId.length > 0 ? campusId : undefined;
    this.campus_name = campusName;
    this.student_no = studentNo;
    this.grade_year = gradeYear;
    this.college_name = collegeName;
    this.major_name = majorName;
  }
}

export class RemoteSubmitVerificationPayload extends RemoteCampusProfilePayload {
  verification_method: VerificationMethod;
  material_urls: string[];

  constructor(
    schoolId: string,
    campusId: string,
    campusName: string,
    studentNo: string,
    verificationMethod: VerificationMethod,
    materialUrls: string[],
    gradeYear?: number,
    collegeName?: string,
    majorName?: string
  ) {
    super(schoolId, campusId, campusName, studentNo, gradeYear, collegeName, majorName);
    this.verification_method = verificationMethod;
    this.material_urls = materialUrls;
  }
}

export class RemoteReviewVerificationPayload {
  status: VerificationStatus;
  review_comment: string;
  reject_reason: string;

  constructor(status: VerificationStatus, reviewComment: string, rejectReason: string = '') {
    this.status = status;
    this.review_comment = reviewComment;
    this.reject_reason = rejectReason;
  }
}

export class RemoteTradeLocationPayload {
  school_id: string = '';
  campus_id: string = '';
  group_id: string = '';
  name: string = '';
  alias?: string;
  description?: string;
  safety_tips?: string;
  recommended_categories: string[] = [];
  is_hot: boolean = false;
  is_enabled: boolean = true;
  sort_order: number = 0;

  constructor(
    schoolId: string,
    campusId: string,
    groupId: string,
    name: string,
    recommendedCategories: string[],
    sortOrder: number,
    isHot: boolean = false,
    alias?: string,
    description?: string,
    safetyTips?: string,
    isEnabled: boolean = true
  ) {
    this.school_id = schoolId;
    this.campus_id = campusId;
    this.group_id = groupId;
    this.name = name;
    this.recommended_categories = recommendedCategories;
    this.sort_order = sortOrder;
    this.is_hot = isHot;
    this.alias = alias;
    this.description = description;
    this.safety_tips = safetyTips;
    this.is_enabled = isEnabled;
  }
}

export class RemoteSchoolPayload {
  name: string = '';
  short_name?: string;
  province_name?: string;
  city_name?: string;
  display_order: number = 0;
  is_enabled: boolean = true;

  constructor(
    name: string,
    displayOrder: number,
    shortName?: string,
    provinceName?: string,
    cityName?: string,
    isEnabled: boolean = true
  ) {
    this.name = name;
    this.display_order = displayOrder;
    this.short_name = shortName;
    this.province_name = provinceName;
    this.city_name = cityName;
    this.is_enabled = isEnabled;
  }
}

export class RemoteCampusPayload {
  school_id: string = '';
  name: string = '';
  short_name?: string;
  display_order: number = 0;
  is_enabled: boolean = true;

  constructor(
    schoolId: string,
    name: string,
    displayOrder: number,
    shortName?: string,
    isEnabled: boolean = true
  ) {
    this.school_id = schoolId;
    this.name = name;
    this.display_order = displayOrder;
    this.short_name = shortName;
    this.is_enabled = isEnabled;
  }
}

export class RemoteLocationGroupPayload {
  school_id: string = '';
  campus_id: string = '';
  name: string = '';
  description?: string;
  display_order: number = 0;
  is_enabled: boolean = true;

  constructor(
    schoolId: string,
    campusId: string,
    name: string,
    displayOrder: number,
    description?: string,
    isEnabled: boolean = true
  ) {
    this.school_id = schoolId;
    this.campus_id = campusId;
    this.name = name;
    this.display_order = displayOrder;
    this.description = description;
    this.is_enabled = isEnabled;
  }
}

export class RemoteTradeLocationStatusPayload {
  is_enabled: boolean = true;

  constructor(isEnabled: boolean) {
    this.is_enabled = isEnabled;
  }
}
