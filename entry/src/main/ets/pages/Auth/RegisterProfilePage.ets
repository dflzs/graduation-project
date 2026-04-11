import { backByContext, getParamsByContext, replaceUrlByContext, showToastByContext } from '../../utils/ui-context-actions';
import { appContext } from '../../app/app-context';
import { Campus, School } from '../../types/domain';
import { RegisterProfilePageParams } from '../../types/auth-flow';
import { pickDefaultCampus, pickDefaultSchool, resolveCampusForSchoolSelection } from '../../utils/campus-identity-ui';
import {
  FALLBACK_ACADEMIC_OPTION,
  filterAcademicOptions,
  findSchoolSuggestions,
  listCollegeOptions,
  listMajorOptions,
  normalizeCollegeInput,
  normalizeMajorInput,
  shouldShowAcademicSuggestionPanel,
  shouldShowSchoolSuggestionPanel
} from '../../utils/campus-academics';
import {
  ButtonVisualTone,
  getAuthHeroSurfaceTone,
  getAuthInputSurfaceTone,
  getPolishGhostButtonTone,
  getPolishPrimaryButtonTone
} from '../../utils/ui-polish-tokens';

@Entry
@Component
struct RegisterProfilePage {
  @State phone: string = '';
  @State registerTicket: string = '';
  @State nickname: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isAgree: boolean = false;
  @State isLoading: boolean = false;
  @State schoolOptions: School[] = [];
  @State campusOptions: Campus[] = [];
  @State schoolId: string = '';
  @State schoolName: string = '';
  @State campusId: string = '';
  @State campusName: string = '';
  @State studentNo: string = '';
  @State gradeYear: string = '';
  @State collegeName: string = '';
  @State majorName: string = '';
  @State isCampusLoading: boolean = false;
  @State schoolInputVersion: number = 0;
  @State collegeInputVersion: number = 0;
  @State majorInputVersion: number = 0;
  private schoolInputController: TextInputController = new TextInputController();
  private collegeInputController: TextInputController = new TextInputController();
  private majorInputController: TextInputController = new TextInputController();
  private suppressSchoolDraftChange: boolean = false;
  private suppressCollegeDraftChange: boolean = false;
  private suppressMajorDraftChange: boolean = false;
  private pendingSchoolDraftValue: string = '';
  private pendingCollegeDraftValue: string = '';
  private pendingMajorDraftValue: string = '';

  aboutToAppear(): void {
    const params = getParamsByContext<RegisterProfilePageParams>(this);
    if (params) {
      this.phone = params.phone;
      this.registerTicket = params.registerTicket;
    }

    if (this.phone.trim().length === 0 || this.registerTicket.trim().length === 0) {
      this.showMessage('\u9a8c\u8bc1\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u9a8c\u8bc1\u624b\u673a\u53f7\u3002');
      replaceUrlByContext(this, { url: 'pages/Auth/RegisterVerifyPage' });
      return;
    }

    void this.loadCampusDefaults();
  }

  private showMessage(message: string): void {
    showToastByContext(this, { message, duration: 1800 });
  }

  @Builder
  private buildFieldLabel(text: string): void {
    Text(text)
      .fontSize(13)
      .fontColor('#8B8378')
      .fontWeight(FontWeight.Medium)
  }

  @Builder
  private buildActionButton(label: string, tone: ButtonVisualTone, onClick: () => void, isEnabled: boolean = true): void {
    Button(label)
      .width('100%')
      .height(tone.height)
      .enabled(isEnabled)
      .backgroundColor(tone.backgroundColor)
      .fontColor(tone.textColor)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .borderRadius(tone.radius)
      .border({ width: 1, color: tone.borderColor })
      .opacity(isEnabled ? 1 : 0.55)
      .onClick(onClick)
  }

  @Builder
  private buildSelectionChip(label: string, isSelected: boolean, onClick: () => void): void {
    Button(label)
      .type(ButtonType.Normal)
      .height(38)
      .padding({ left: 14, right: 14 })
      .backgroundColor(isSelected ? '#E8F0FF' : '#FFFFFF')
      .fontColor(isSelected ? '#2F6BFF' : '#5E5851')
      .fontSize(14)
      .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
      .borderRadius(16)
      .border({ width: 1, color: isSelected ? '#C9D8FF' : '#E4D9CC' })
      .margin({ right: 8, bottom: 8 })
      .onClick(onClick)
  }

  private async loadCampusDefaults(): Promise<void> {
    this.isCampusLoading = true;
    const schoolsResult = await appContext.campus.listSchools();
    if (schoolsResult.ok) {
      this.schoolOptions = schoolsResult.data ?? [];
      const defaultSchool = pickDefaultSchool(this.schoolOptions);
      if (defaultSchool) {
        await this.selectSchool(defaultSchool);
      }
    }
    this.isCampusLoading = false;
  }

  private async selectSchool(school: School): Promise<void> {
    const previousSchoolName = this.schoolName;
    this.schoolId = school.id;
    this.schoolName = school.name;
    this.collegeName = '';
    this.majorName = '';
    this.schoolInputVersion += 1;
    this.collegeInputVersion += 1;
    this.majorInputVersion += 1;
    this.replaceInputValue(this.schoolInputController, previousSchoolName, this.schoolName, 'school');
    this.replaceInputValue(this.collegeInputController, '', this.collegeName, 'college');
    this.replaceInputValue(this.majorInputController, '', this.majorName, 'major');
    this.campusOptions = [];
    this.campusId = '';
    this.campusName = '';

    const campusesResult = await appContext.campus.listCampuses(school.id);
    if (!campusesResult.ok) {
      return;
    }

    this.campusOptions = campusesResult.data ?? [];
    const defaultCampus = resolveCampusForSchoolSelection(this.campusOptions, school.id, this.campusId);
    if (defaultCampus) {
      this.campusId = defaultCampus.id;
      this.campusName = defaultCampus.name;
    }
  }

  private getSchoolSuggestions(): School[] {
    return findSchoolSuggestions(this.schoolOptions, this.schoolName);
  }

  private shouldShowSchoolSuggestions(): boolean {
    return shouldShowSchoolSuggestionPanel(this.schoolOptions, this.schoolName);
  }

  private getCollegeOptions(): string[] {
    return listCollegeOptions(this.schoolId, this.schoolName);
  }

  private getCollegeSuggestions(): string[] {
    return filterAcademicOptions(this.getCollegeOptions(), this.collegeName);
  }

  private shouldShowCollegeSuggestions(): boolean {
    return shouldShowAcademicSuggestionPanel(this.getCollegeOptions(), this.collegeName);
  }

  private getMajorOptions(): string[] {
    return listMajorOptions(this.schoolId, this.schoolName, this.collegeName);
  }

  private getMajorSuggestions(): string[] {
    return filterAcademicOptions(this.getMajorOptions(), this.majorName);
  }

  private shouldShowMajorSuggestions(): boolean {
    return shouldShowAcademicSuggestionPanel(this.getMajorOptions(), this.majorName);
  }

  private updateSchoolDraft(value: string): void {
    if (this.suppressSchoolDraftChange) {
      this.schoolName = value;
      if (value === this.pendingSchoolDraftValue) {
        this.suppressSchoolDraftChange = false;
        this.pendingSchoolDraftValue = '';
      }
      return;
    }
    const trimmedValue = value.trim();
    this.schoolName = value;
    const matched = this.schoolOptions.find((item: School) => item.name === trimmedValue || (item.shortName ?? '') === trimmedValue);
    if (matched) {
      void this.selectSchool(matched);
      return;
    }
    this.schoolId = '';
    this.campusOptions = [];
    this.campusId = '';
    this.campusName = '';
    this.collegeName = '';
    this.majorName = '';
  }

  private updateCampusDraft(value: string): void {
    this.campusName = value;
    const trimmedValue = value.trim();
    const matched = this.campusOptions.find((item: Campus) => item.name === trimmedValue || (item.shortName ?? '') === trimmedValue);
    if (matched) {
      this.campusId = matched.id;
      this.campusName = matched.name;
      return;
    }
    this.campusId = '';
  }

  private selectCollegeSuggestion(value: string): void {
    const previousCollegeName = this.collegeName;
    const previousMajorName = this.majorName;
    this.collegeName = value;
    this.collegeInputVersion += 1;
    this.replaceInputValue(this.collegeInputController, previousCollegeName, this.collegeName, 'college');
    const majors = this.getMajorOptions();
    if (!majors.includes(this.majorName)) {
      this.majorName = '';
      this.majorInputVersion += 1;
      this.replaceInputValue(this.majorInputController, previousMajorName, this.majorName, 'major');
    }
  }

  private selectMajorSuggestion(value: string): void {
    const previousMajorName = this.majorName;
    this.majorName = value;
    this.majorInputVersion += 1;
    this.replaceInputValue(this.majorInputController, previousMajorName, this.majorName, 'major');
  }

  private getNormalizedCollegeName(): string {
    return normalizeCollegeInput(this.schoolId, this.schoolName, this.collegeName);
  }

  private getNormalizedMajorName(): string {
    return normalizeMajorInput(this.schoolId, this.schoolName, this.getNormalizedCollegeName(), this.majorName);
  }

  private parseGradeYear(): number | undefined {
    if (this.gradeYear.trim().length === 0) {
      return undefined;
    }
    const value = Number(this.gradeYear.trim());
    if (Number.isNaN(value) || value <= 0) {
      return undefined;
    }
    return Math.trunc(value);
  }

  private validateInput(): string {
    if (this.phone.trim().length === 0 || this.registerTicket.trim().length === 0) {
      return '\u6ce8\u518c\u51ed\u8bc1\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u9a8c\u8bc1\u624b\u673a\u53f7\u3002';
    }
    if (this.nickname.trim().length < 2) {
      return '\u6635\u79f0\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 2 \u4f4d\u3002';
    }
    if (this.password.trim().length < 6) {
      return '\u5bc6\u7801\u957f\u5ea6\u4e0d\u80fd\u5c11\u4e8e 6 \u4f4d\u3002';
    }
    if (this.password !== this.confirmPassword) {
      return '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4\u3002';
    }
    if (!this.isAgree) {
      return '\u8bf7\u5148\u52fe\u9009\u5e76\u540c\u610f\u7528\u6237\u534f\u8bae\u3002';
    }
    if (this.schoolId.length === 0) {
      return '\u8bf7\u5148\u4ece\u8054\u60f3\u5217\u8868\u4e2d\u786e\u8ba4\u5b66\u6821\u3002';
    }
    if (this.campusName.trim().length === 0) {
      return '\u8bf7\u5148\u586b\u5199\u6821\u533a\u540d\u79f0\u3002';
    }
    if (this.studentNo.trim().length < 6) {
      return '\u8bf7\u586b\u5199\u6b63\u786e\u7684\u5b66\u53f7\u3002';
    }
    return '';
  }

  private replaceInputValue(
    controller: TextInputController,
    previousText: string,
    nextText: string,
    field: 'school' | 'college' | 'major'
  ): void {
    this.setFieldSuppression(field, true);
    this.setPendingFieldValue(field, nextText);
    const clearLength = Math.max(previousText.length, nextText.length) + 64;
    controller.caretPosition(0);
    controller.deleteText({ start: 0, end: clearLength });
    if (nextText.length > 0) {
      controller.addText(nextText);
      controller.caretPosition(nextText.length);
    }
  }

  private setFieldSuppression(field: 'school' | 'college' | 'major', enabled: boolean): void {
    if (field === 'school') {
      this.suppressSchoolDraftChange = enabled;
      return;
    }
    if (field === 'college') {
      this.suppressCollegeDraftChange = enabled;
      return;
    }
    this.suppressMajorDraftChange = enabled;
  }

  private setPendingFieldValue(field: 'school' | 'college' | 'major', value: string): void {
    if (field === 'school') {
      this.pendingSchoolDraftValue = value;
      return;
    }
    if (field === 'college') {
      this.pendingCollegeDraftValue = value;
      return;
    }
    this.pendingMajorDraftValue = value;
  }

  @Builder
  private buildVersionedInput(
    label: string,
    text: string,
    placeholder: string,
    version: number,
    controller: TextInputController,
    onChange: (value: string) => void
  ): void {
    ForEach([version], (item: number) => {
      Column({ space: 8 }) {
        this.buildFieldLabel(label)
        TextInput({ text, placeholder, controller })
          .width('100%')
          .height(54)
          .fontSize(18)
          .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
          .borderRadius(getAuthInputSurfaceTone().radius)
          .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
          .placeholderColor('#9A938A')
          .onChange(onChange)
      }
      .width('100%')
    }, (item: number) => `${label}-${item}`)
  }

  private async submitRegister(): Promise<void> {
    if (this.isLoading) {
      return;
    }

    const validationMessage = this.validateInput();
    if (validationMessage.length > 0) {
      this.showMessage(validationMessage);
      return;
    }

    this.isLoading = true;
    try {
      const result = await appContext.auth.completeRegister(this.phone, this.registerTicket, this.nickname, this.password);
      console.info(`[Auth] completeRegister phone=${this.phone} ok=${result.ok} message=${result.message}`);
      this.showMessage(result.message);
      if (!result.ok) {
        return;
      }

      const campusResult = await appContext.campus.updateCampusProfile(
        this.schoolId,
        this.campusId,
        this.campusName.trim(),
        this.studentNo.trim(),
        this.parseGradeYear(),
        this.getNormalizedCollegeName(),
        this.getNormalizedMajorName()
      );
      if (!campusResult.ok) {
        this.showMessage('\u8d26\u53f7\u5df2\u521b\u5efa\uff0c\u6821\u56ed\u8d44\u6599\u53ef\u7a0d\u540e\u5728\u4e2a\u4eba\u8d44\u6599\u9875\u7ee7\u7eed\u5b8c\u5584\u3002');
      }

      replaceUrlByContext(this, { url: 'pages/Index' });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 12 }) {
          Text('\u5b8c\u5584\u8d26\u53f7\u4fe1\u606f')
            .fontSize(13)
            .fontColor('#9A9083')

          Text('\u8bbe\u7f6e\u6635\u79f0\u5bc6\u7801\uff0c\u5e76\u540c\u6b65\u6821\u56ed\u8eab\u4efd\u8d44\u6599')
            .fontSize(33)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E2A26')

          Text('\u5b8c\u6210\u8fd9\u4e00\u6b65\u540e\uff0c\u5e73\u53f0\u4f1a\u4e3a\u4f60\u4fdd\u5b58\u5b66\u6821\u3001\u6821\u533a\u548c\u5b66\u53f7\u4fe1\u606f\uff0c\u540e\u7eed\u518d\u63d0\u4ea4\u5b66\u751f\u8ba4\u8bc1\u6750\u6599\u3002')
            .fontSize(16)
            .fontColor('#6D655D')
            .lineHeight(25)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 24, left: 22, right: 22, bottom: 22 })
        .backgroundColor(getAuthHeroSurfaceTone().backgroundColor)
        .borderRadius(getAuthHeroSurfaceTone().radius)
        .border({ width: 1, color: getAuthHeroSurfaceTone().borderColor })

        Column({ space: 16 }) {
          Column({ space: 8 }) {
            this.buildFieldLabel('\u624b\u673a\u53f7')
            Text(this.phone)
              .width('100%')
              .fontSize(16)
              .fontColor('#2E2A26')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            this.buildFieldLabel('\u6635\u79f0')
            TextInput({ text: this.nickname, placeholder: '\u8bf7\u8f93\u5165\u6635\u79f0' })
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.nickname = value)
          }
          .width('100%')

          Column({ space: 8 }) {
            this.buildFieldLabel('\u5bc6\u7801')
            TextInput({ text: this.password, placeholder: '\u8bf7\u8bbe\u7f6e\u5bc6\u7801' })
              .type(InputType.Password)
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.password = value)
          }
          .width('100%')

          Column({ space: 8 }) {
            this.buildFieldLabel('\u786e\u8ba4\u5bc6\u7801')
            TextInput({ text: this.confirmPassword, placeholder: '\u8bf7\u518d\u6b21\u8f93\u5165\u5bc6\u7801' })
              .type(InputType.Password)
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.confirmPassword = value)
          }
          .width('100%')
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFCF8')
        .borderRadius(24)
        .border({ width: 1, color: '#E4D9CC' })

        Column({ space: 16 }) {
          Row() {
            Text('\u6821\u56ed\u8d44\u6599')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2E2A26')
            Blank()
            if (this.isCampusLoading) {
              Text('\u52a0\u8f7d\u4e2d')
                .fontSize(12)
                .fontColor('#8B8378')
            }
          }
          .width('100%')

          this.buildVersionedInput('\u5b66\u6821', this.schoolName, '\u8f93\u5165\u5b66\u6821\u5173\u952e\u5b57', this.schoolInputVersion, this.schoolInputController, (value: string) => this.updateSchoolDraft(value))

          if (this.shouldShowSchoolSuggestions()) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.getSchoolSuggestions(), (school: School) => {
                this.buildSelectionChip(school.name, this.schoolId === school.id, () => {
                  void this.selectSchool(school);
                })
              }, (school: School) => school.id)
            }
            .width('100%')
          }

          Column({ space: 8 }) {
            this.buildFieldLabel('\u6821\u533a')
            TextInput({ text: this.campusName, placeholder: '\u4f8b\u5982 \u4e3b\u6821\u533a / \u4e1c\u6821\u533a / \u5357\u533a' })
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.updateCampusDraft(value))
          }
          .width('100%')

          Column({ space: 8 }) {
            this.buildFieldLabel('\u5b66\u53f7')
            TextInput({ text: this.studentNo, placeholder: '\u8bf7\u8f93\u5165\u5b66\u53f7' })
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.studentNo = value)
          }
          .width('100%')

          Column({ space: 8 }) {
            this.buildFieldLabel('\u5e74\u7ea7')
            TextInput({ text: this.gradeYear, placeholder: '\u4f8b\u5982 2024' })
              .type(InputType.Number)
              .width('100%')
              .height(54)
              .fontSize(18)
              .backgroundColor(getAuthInputSurfaceTone().backgroundColor)
              .borderRadius(getAuthInputSurfaceTone().radius)
              .border({ width: 1, color: getAuthInputSurfaceTone().borderColor })
              .placeholderColor('#9A938A')
              .onChange((value: string) => this.gradeYear = value)
          }
          .width('100%')

          this.buildVersionedInput('\u9662\u7cfb', this.collegeName, '\u8f93\u5165\u9662\u7cfb\u5173\u952e\u5b57', this.collegeInputVersion, this.collegeInputController, (value: string) => {
            if (this.suppressCollegeDraftChange) {
              this.collegeName = value;
              if (value === this.pendingCollegeDraftValue) {
                this.suppressCollegeDraftChange = false;
                this.pendingCollegeDraftValue = '';
              }
              return;
            }
            this.collegeName = value;
            this.majorName = '';
          })

          if (this.shouldShowCollegeSuggestions()) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.getCollegeSuggestions(), (college: string) => {
                this.buildSelectionChip(college, this.collegeName === college, () => this.selectCollegeSuggestion(college))
              }, (college: string) => college)
            }
            .width('100%')
          }

          if (this.collegeName.trim().length > 0 && this.getNormalizedCollegeName() === FALLBACK_ACADEMIC_OPTION) {
            Text('\u5f53\u524d\u9662\u7cfb\u672a\u5339\u914d\u5230\u9884\u7f6e\u9879\uff0c\u6ce8\u518c\u540e\u5c06\u6309\u201c\u5176\u4ed6\u201d\u5f52\u6863\u3002')
              .width('100%')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#8B8378')
          }

          this.buildVersionedInput('\u4e13\u4e1a', this.majorName, '\u8f93\u5165\u4e13\u4e1a\u5173\u952e\u5b57', this.majorInputVersion, this.majorInputController, (value: string) => {
            if (this.suppressMajorDraftChange) {
              this.majorName = value;
              if (value === this.pendingMajorDraftValue) {
                this.suppressMajorDraftChange = false;
                this.pendingMajorDraftValue = '';
              }
              return;
            }
            this.majorName = value;
          })

          if (this.shouldShowMajorSuggestions()) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.getMajorSuggestions(), (major: string) => {
                this.buildSelectionChip(major, this.majorName === major, () => this.selectMajorSuggestion(major))
              }, (major: string) => major)
            }
            .width('100%')
          }

          if (this.majorName.trim().length > 0 && this.getNormalizedMajorName() === FALLBACK_ACADEMIC_OPTION) {
            Text('\u5f53\u524d\u4e13\u4e1a\u672a\u5339\u914d\u5230\u9884\u7f6e\u9879\uff0c\u6ce8\u518c\u540e\u5c06\u6309\u201c\u5176\u4ed6\u201d\u5f52\u6863\u3002')
              .width('100%')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#8B8378')
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFCF8')
        .borderRadius(24)
        .border({ width: 1, color: '#E4D9CC' })

        Row() {
          Checkbox()
            .select(this.isAgree)
            .onChange((value: boolean) => this.isAgree = value)

          Text('\u6211\u5df2\u9605\u8bfb\u5e76\u540c\u610f\u300a\u7528\u6237\u534f\u8bae\u300b\u548c\u300a\u9690\u79c1\u653f\u7b56\u300b')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 8 })
        }
        .width('100%')

        Column({ space: 12 }) {
          this.buildActionButton(this.isLoading ? '\u63d0\u4ea4\u4e2d...' : '\u6ce8\u518c\u5e76\u8fdb\u5165\u6821\u56ed', getPolishPrimaryButtonTone(), () => {
            void this.submitRegister();
          }, !this.isLoading)

          this.buildActionButton('\u8fd4\u56de\u4e0a\u4e00\u6b65', getPolishGhostButtonTone(), () => backByContext(this))
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F3EE')
  }
}
