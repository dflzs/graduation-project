# Campus Search Corpus Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build production-grade school, college, and major suggestion inputs for profile and registration flows using official nationwide school and major datasets.

**Architecture:** Generate a local front-end search corpus from official Ministry of Education sources, then switch profile/register pages from demo selectors to `TextInput + suggestion list` interactions. Keep campus as free text and normalize unmatched college/major values to `其他` on save.

**Tech Stack:** ArkTS, DevEco Studio, PowerShell/Python data generation, Hypium tests

---

## Chunk 1: Data Corpus

### Task 1: Generate nationwide school corpus from official MOE list

**Files:**
- Create: `tools/generate-campus-corpus.py`
- Create: `entry/src/main/ets/utils/national-campus-corpus.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Assert that searching `湖南` returns Hunan universities and searching `清华` returns Tsinghua.

- [ ] **Step 2: Run test to verify it fails**

Run in DevEco later via local unit tests.

- [ ] **Step 3: Implement the generation script**

Use the official endpoint:

`https://hudong.moe.gov.cn/school/wcmdata/getDataIndex.jsp?listid=10000101&page=N&keyword=`

Scrape all 146 pages and generate a typed ArkTS corpus.

- [ ] **Step 4: Generate the corpus file**

Emit focused search fields:
- `id`
- `name`
- `shortName`
- `provinceName`
- `cityName`
- `schoolType`

- [ ] **Step 5: Commit**

`git commit -m "feat: add nationwide school search corpus"`

## Chunk 2: Major and College Suggestions

### Task 2: Generate major corpus from official 2025 undergraduate catalog

**Files:**
- Modify: `tools/generate-campus-corpus.py`
- Modify: `entry/src/main/ets/utils/national-campus-corpus.ets`
- Modify: `entry/src/main/ets/utils/campus-academics.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Assert that searching `计算机` returns `计算机科学与技术`, and searching `金融` returns `金融学` / `金融工程`.

- [ ] **Step 2: Run test to verify it fails**

Run local unit tests.

- [ ] **Step 3: Parse the official MOE PDF**

Use:

`https://www.moe.gov.cn/srcsite/A08/moe_1034/s4930/202504/W020250422312780837078.pdf`

Extract 6-digit major codes and names into a typed corpus.

- [ ] **Step 4: Expand college helpers**

Convert `campus-academics.ets` from demo-only preset logic to:
- common college vocabulary
- nationwide major corpus search
- unmatched normalization to `其他`

- [ ] **Step 5: Commit**

`git commit -m "feat: add nationwide major and common college suggestions"`

## Chunk 3: Profile Page Interaction

### Task 3: Replace demo selectors with input suggestions in profile

**Files:**
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/utils/campus-academics.ets`
- Modify: `entry/src/main/ets/utils/national-campus-corpus.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add helper-level assertions for:
- school keyword suggestions
- college keyword suggestions
- major keyword suggestions
- unmatched normalization to `其他`

- [ ] **Step 2: Run test to verify it fails**

Run local unit tests.

- [ ] **Step 3: Implement profile input suggestions**

Replace expandable selector remnants with:
- school input + suggestion list
- campus text input
- college input + suggestion list
- major input + suggestion list

- [ ] **Step 4: Preserve save compatibility**

Ensure save still submits:
- `schoolId`
- current `campusId`
- normalized `collegeName`
- normalized `majorName`

- [ ] **Step 5: Commit**

`git commit -m "feat: upgrade profile campus info inputs to suggestion search"`

## Chunk 4: Registration Page Interaction

### Task 4: Mirror the same suggestion UX in registration

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/RegisterProfilePage.ets`
- Modify: `entry/src/main/ets/utils/campus-academics.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Assert helper behavior shared by register page remains consistent with profile page.

- [ ] **Step 2: Run test to verify it fails**

Run local unit tests.

- [ ] **Step 3: Implement registration suggestion UI**

Make register profile page match profile page for:
- school input suggestions
- campus free text
- college input suggestions
- major input suggestions

- [ ] **Step 4: Normalize on submit**

Save unmatched college/major as `其他`.

- [ ] **Step 5: Commit**

`git commit -m "feat: align registration campus info inputs with suggestion search"`

## Chunk 5: Verification

### Task 5: Static verification and IDE validation handoff

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run static checks**

Run:

`git diff --check`

Expected: no patch-format issues other than line-ending warnings.

- [ ] **Step 2: Review changed files**

Ensure no SDK or IDE-local files were changed.

- [ ] **Step 3: Ask user to verify in DevEco**

Validate:
- school suggestions appear for `湖南`, `清华`, `北京`
- college suggestions appear for `信息`, `计算机`
- major suggestions appear for `计算机`, `金融`, `临床`
- campus remains free text

- [ ] **Step 4: Commit**

`git commit -m "test: cover campus search corpus suggestion behavior"`

Plan complete and saved to `docs/superpowers/plans/2026-04-10-campus-search-corpus-plan.md`. Ready to execute?
