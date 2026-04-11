import { School } from '../types/domain';
import {
  COMMON_COLLEGE_OPTIONS,
  NATIONAL_MAJOR_SEARCH_ITEMS
} from './national-campus-corpus';

class AcademicOptionConfig {
  value: string;
  majors: string[];

  constructor(value: string, majors: string[]) {
    this.value = value;
    this.majors = majors;
  }
}

export const FALLBACK_ACADEMIC_OPTION: string = '\u5176\u4ed6';

const HNRKU_COLLEGE_CONFIG: AcademicOptionConfig[] = [
  new AcademicOptionConfig('\u4fe1\u606f\u5b66\u9662', [
    '\u8f6f\u4ef6\u5de5\u7a0b',
    '\u6570\u636e\u79d1\u5b66\u4e0e\u5927\u6570\u636e\u6280\u672f',
    '\u8ba1\u7b97\u673a\u79d1\u5b66\u4e0e\u6280\u672f',
    '\u901a\u4fe1\u5de5\u7a0b'
  ]),
  new AcademicOptionConfig('\u6570\u5b66\u4e0e\u91d1\u878d\u5b66\u9662', [
    '\u6570\u5b66\u4e0e\u5e94\u7528\u6570\u5b66',
    '\u4fe1\u606f\u4e0e\u8ba1\u7b97\u79d1\u5b66',
    '\u91d1\u878d\u5de5\u7a0b'
  ]),
  new AcademicOptionConfig('\u6559\u80b2\u5b66\u9662', [
    '\u5c0f\u5b66\u6559\u80b2',
    '\u5b66\u524d\u6559\u80b2',
    '\u5e94\u7528\u5fc3\u7406\u5b66'
  ]),
  new AcademicOptionConfig('\u6587\u5b66\u4e0e\u65b0\u95fb\u4f20\u64ad\u5b66\u9662', [
    '\u6c49\u8bed\u8a00\u6587\u5b66',
    '\u79d8\u4e66\u5b66',
    '\u7f51\u7edc\u4e0e\u65b0\u5a92\u4f53'
  ]),
  new AcademicOptionConfig('\u80fd\u6e90\u4e0e\u673a\u7535\u5de5\u7a0b\u5b66\u9662', [
    '\u673a\u68b0\u8bbe\u8ba1\u5236\u9020\u53ca\u5176\u81ea\u52a8\u5316',
    '\u6750\u6599\u6210\u578b\u53ca\u63a7\u5236\u5de5\u7a0b',
    '\u65b0\u80fd\u6e90\u79d1\u5b66\u4e0e\u5de5\u7a0b'
  ]),
  new AcademicOptionConfig('\u7f8e\u672f\u4e0e\u8bbe\u8ba1\u5b66\u9662', [
    '\u89c6\u89c9\u4f20\u8fbe\u8bbe\u8ba1',
    '\u73af\u5883\u8bbe\u8ba1',
    '\u7f8e\u672f\u5b66'
  ]),
  new AcademicOptionConfig('\u97f3\u4e50\u821e\u8e48\u5b66\u9662', [
    '\u97f3\u4e50\u5b66',
    '\u821e\u8e48\u5b66',
    '\u821e\u8e48\u8868\u6f14'
  ])
];

function usesHnrkuAcademicPreset(schoolId?: string, schoolName?: string): boolean {
  if (schoolId && schoolId.toLowerCase().includes('hnrku')) {
    return true;
  }
  if (!schoolName) {
    return false;
  }
  return schoolName.includes('\u6e56\u5357\u4eba\u6587\u79d1\u6280\u5b66\u9662');
}

function findCollegeConfig(schoolId?: string, schoolName?: string, collegeName?: string): AcademicOptionConfig | null {
  if (!usesHnrkuAcademicPreset(schoolId, schoolName) || !collegeName || collegeName.length === 0) {
    return null;
  }
  const matched = HNRKU_COLLEGE_CONFIG.find((item: AcademicOptionConfig) => item.value === collegeName);
  return matched ?? null;
}

export function listCollegeOptions(schoolId?: string, schoolName?: string): string[] {
  const options: string[] = [];
  if (usesHnrkuAcademicPreset(schoolId, schoolName)) {
    HNRKU_COLLEGE_CONFIG.forEach((item: AcademicOptionConfig) => options.push(item.value));
  }
  COMMON_COLLEGE_OPTIONS.forEach((item: string) => {
    if (!options.includes(item)) {
      options.push(item);
    }
  });
  return options;
}

export function listMajorOptions(schoolId?: string, schoolName?: string, collegeName?: string): string[] {
  const options: string[] = [];
  const config = findCollegeConfig(schoolId, schoolName, collegeName);
  if (config) {
    config.majors.forEach((item: string) => options.push(item));
  }
  NATIONAL_MAJOR_SEARCH_ITEMS.forEach((item) => {
    if (!options.includes(item.name)) {
      options.push(item.name);
    }
  });
  return options;
}

function normalizeKeyword(value?: string): string {
  return (value ?? '').trim().toLowerCase();
}

function hasExactSchoolMatch(schools: School[], keyword?: string): boolean {
  return findExactSchoolSelection(schools, keyword) !== null;
}

export function findExactSchoolSelection(schools: School[], keyword?: string): School | null {
  const normalizedKeyword = normalizeKeyword(keyword);
  if (normalizedKeyword.length === 0) {
    return null;
  }
  const matched = schools.find((item: School) => {
    const name = item.name.toLowerCase();
    const shortName = (item.shortName ?? '').toLowerCase();
    return name === normalizedKeyword || shortName === normalizedKeyword;
  });
  return matched ?? null;
}

function hasExactAcademicMatch(options: string[], keyword?: string): boolean {
  const normalizedKeyword = normalizeKeyword(keyword);
  if (normalizedKeyword.length === 0) {
    return false;
  }
  return options.some((item: string) => item.toLowerCase() === normalizedKeyword);
}

function normalizeOptionValue(options: string[], value?: string): string {
  const trimmedValue = (value ?? '').trim();
  if (trimmedValue.length === 0) {
    return '';
  }
  const matched = options.find((item: string) => item === trimmedValue);
  if (matched) {
    return matched;
  }
  return FALLBACK_ACADEMIC_OPTION;
}

export function findSchoolSuggestions(schools: School[], keyword?: string): School[] {
  const normalizedKeyword = normalizeKeyword(keyword);
  if (normalizedKeyword.length === 0) {
    return schools.slice(0, 8);
  }
  const filtered = schools.filter((item: School) => {
    const name = item.name.toLowerCase();
    const shortName = (item.shortName ?? '').toLowerCase();
    const city = (item.city ?? '').toLowerCase();
    return name.includes(normalizedKeyword) || shortName.includes(normalizedKeyword) || city.includes(normalizedKeyword);
  });
  return filtered.slice(0, 12);
}

export function shouldShowSchoolSuggestionPanel(schools: School[], keyword?: string): boolean {
  const normalizedKeyword = normalizeKeyword(keyword);
  if (normalizedKeyword.length === 0) {
    return false;
  }
  if (hasExactSchoolMatch(schools, keyword)) {
    return false;
  }
  return findSchoolSuggestions(schools, keyword).length > 0;
}

export function filterAcademicOptions(options: string[], keyword?: string): string[] {
  const normalizedKeyword = normalizeKeyword(keyword);
  if (normalizedKeyword.length === 0) {
    return options.slice(0, 10);
  }
  return options.filter((item: string) => item.toLowerCase().includes(normalizedKeyword)).slice(0, 12);
}

export function shouldShowAcademicSuggestionPanel(options: string[], keyword?: string): boolean {
  const normalizedKeyword = normalizeKeyword(keyword);
  if (normalizedKeyword.length === 0) {
    return false;
  }
  if (hasExactAcademicMatch(options, keyword)) {
    return false;
  }
  return filterAcademicOptions(options, keyword).length > 0;
}

export function normalizeCollegeInput(
  schoolId?: string,
  schoolName?: string,
  collegeName?: string
): string {
  return normalizeOptionValue(listCollegeOptions(schoolId, schoolName), collegeName);
}

export function normalizeMajorInput(
  schoolId?: string,
  schoolName?: string,
  collegeName?: string,
  majorName?: string
): string {
  return normalizeOptionValue(listMajorOptions(schoolId, schoolName, collegeName), majorName);
}
