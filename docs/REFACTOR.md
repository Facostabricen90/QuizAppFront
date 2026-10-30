# Frontend refactoring — IcfesApp (Flutter)

| | |
|---|---|
| **Branch** | `refactor` (created from `app_test`, commit `817ad5b`) |
| **Last update** | 2026-10-30 |
| **Backend** | Must run the `refactor` branch of `quizAppIcfesBack` — see that repo's `docs/REFACTOR.md` |

This document records every change made to the Flutter app during the refactoring: what changed, why, and how it works now.

> **Deploy together:** this frontend only works with the backend from its `refactor` branch, and the old frontend does not work with that backend
> (several endpoints were renamed or removed).

> **Language convention:** code, comments and docs in **English**; texts shown to the user stay in **Spanish**.

---

## 1. Where the API is called

All HTTP calls go through `lib/core/network/api_client.dart` and three repositories:

| Repository | File | Used by |
|---|---|---|
| `AuthRepository` | `lib/core/auth/auth_repository.dart` | `AuthController` (login, sign-up, session, password, email confirmation) |
| `ContentRepository` | `lib/features/content/data/content_repository.dart` | Admin panel, plans and subscription pages |
| `PracticeRepository` | `lib/features/practice/data/practice_repository.dart` | Student dashboard, practice session page |

`ApiClient` adds the access token, and when a request answers 401 it renews the session once with the refresh token and retries.

---

## 2. Change log

### 2.1 Endpoints updated to the new backend contract

| Repository method | Before | Now |
|---|---|---|
| `AuthRepository.register` | `POST /api/auth/register` | `POST /api/auth/register-student` |
| `AuthRepository.session` | `GET /api/auth/session` | **Removed** — the user comes in the refresh-token response |
| `ApiClient` refresh | `POST /api/auth/refresh` | `POST /api/auth/refresh-token` (returns tokens **and user**) |
| `AuthRepository.logout` | `POST /api/auth/revoke` | `POST /api/auth/logout` |
| `AuthRepository.resendConfirmation` | `POST /api/auth/resend-confirmation` | `POST /api/auth/resend-confirmation-email` |
| `PracticeRepository.getMySessions` | `GET /api/practice-sessions` (full sessions) | `getHistory` → `GET /api/practice-sessions/history` (summaries) |
| `ContentRepository.revokeInvitationCode` | `POST /api/invitation-codes/{id}/revoke` | `PUT /api/invitation-codes/{id}` with `isActive: false` |
| `ContentRepository.getMySubscription` | `GET /api/subscriptions/current` | `GET /api/subscriptions/current-user` |
| `ContentRepository.getStudentReports` | `GET /api/reports/students` | `GET /api/reports/student-performance` |

Routes that did not change: `login`, `register-staff`, `forgot-password`, `reset-password`, `change-password`, `confirm-email`,
`/api/subjects`, `/api/institutions`, `/api/questions`, `/api/invitation-codes` (list/create/update/delete), `/api/plans`,
`POST /api/practice-sessions`, `/answers` and `/finish`.

### 2.2 Session restore: 2 requests → 1
- **Before:** on startup `restoreSession` called `/refresh` (tokens) and then `/session` (user).
- **Now:** `/refresh-token` returns the same shape as login (tokens + user), so `ApiClient.tryRefreshSession()` returns the
  `AuthUser` directly (`null` if the session could not be renewed) and `restoreSession` is a single request.
- **Files:** `lib/core/network/api_client.dart`, `lib/core/auth/auth_repository.dart`.

### 2.3 Admin panel: update only what changed (no more full reloads)
- **Before:** after every create / update / delete, `_runMutation` called `_loadData()`, which re-downloaded the 5 lists
  (subjects, questions — with every option —, institutions, invitation codes and the report). Editing one subject name meant 6 requests.
- **Now:** the backend returns the created / updated object, and the panel changes only that item in its list:

| Action | Requests now | What is updated locally |
|---|---|---|
| Create / update / delete question | 1 | The question in `_questions` |
| Create / delete subject | 1 | The subject in `_subjects` (kept sorted by name, like the API) |
| Update subject | 1 (+1 if the name changed) | The subject; questions are reloaded **only if the name changed**, because they show `subjectName` |
| Create / delete institution | 1 | The institution; on delete its invitation codes are removed too (the backend deletes them in cascade) |
| Update institution | 1 (+1 if the name changed) | The institution; codes are reloaded **only if the name changed**, because they show `institutionName` |
| Create / revoke / delete invitation code | 1 | The code in `_invitationCodes` |

- Helpers in `admin_dashboard_page.dart`: `_replaceById`, `_removeById`, `_sortedSubjects`, `_sortedSchools`, `_updateIfMounted`.
- Repository `update*` methods now return the updated model (`SubjectModel`, `SchoolModel`, `QuestionModel`, `InvitationCodeModel`).
- The panel still loads everything once when it opens.

### 2.4 Question images are kept when editing 🐞
- **Risk found:** the backend now stores exactly the images it receives on update. `QuestionDraft` did not send any, so editing a question
  from the admin panel would have **deleted its images**.
- **Now:**
  - `QuestionModel` / `QuestionOptionModel` read `imageUrl` and `justificationImageUrl`.
  - `QuestionDraft` / `QuestionOptionDraft` send them back.
  - The question dialog keeps each option's image in `_optionImageUrls`, a list parallel to the option fields, so adding or removing
    options never moves an image to a different option.
- **Files:** `lib/features/content/data/content_models.dart`, `lib/features/admin/presentation/widgets/admin_dialogs.dart`.

### 2.5 Lighter practice history
- **Before:** the student dashboard downloaded every session with all its questions and options, only to show
  "answered / total", status, subject and date.
- **Now:** `PracticeSessionSummaryModel` (`totalQuestions`, `answeredQuestions`, `correctAnswers`, status, dates) from
  `GET /api/practice-sessions/history`. The dashboard and the progress view use those counts.
- `PracticeSessionModel` (with questions) is still used by the practice session page, which gets it from `POST /api/practice-sessions`.
- **Files:** `lib/features/practice/data/practice_models.dart`, `practice_repository.dart`,
  `lib/features/student/presentation/pages/student_dashboard_page.dart`.

### 2.6 `School` → `Institution` (follows backend phase 6)
- **Why:** the backend renamed the concept everywhere and the user JSON field changed from `schoolId` to **`institutionId`**.
  Without this change `AuthUser.institutionId` would always be null.
- **API-visible change:** `AuthUser.schoolId` → `AuthUser.institutionId`, read from `json['institutionId']`.
- **Code renamed for consistency** (same concept, same name in back and front):

| Before | Now |
|---|---|
| `SchoolModel`, `SchoolDraft` | `InstitutionModel`, `InstitutionDraft` |
| `ContentRepository.getSchools / createSchool / updateSchool / deleteSchool` | `getInstitutions / createInstitution / updateInstitution / deleteInstitution` |
| Admin panel: `_schools`, `_openSchool`, `_deleteSchool`, `_sortedSchools`, `_SchoolsPanel`, `_AdminSection.schools` | `_institutions`, `_openInstitution`, `_deleteInstitution`, `_sortedInstitutions`, `_InstitutionsPanel`, `_AdminSection.institutions` |
| `showSchoolDialog`, `_SchoolDialog` | `showInstitutionDialog`, `_InstitutionDialog` |

- The URL did not change (`/api/institutions` already used that name), and the texts shown to the user were already "Instituciones".
- Flutter icon names such as `Icons.school_outlined` were intentionally **not** renamed.

---

## 3. Testing

| Check | Before the changes | After |
|---|---|---|
| `flutter analyze` | No issues | No issues ✅ |
| `flutter test` | 22 / 22 | **28 / 28** ✅ |

The 2 tests that checked the old contract (`/api/auth/register` path, `PUT` answering 204) were updated, and 6 tests were added
(`test/frontend_api_contract_test.dart`):

| New test | Checks |
|---|---|
| Editing a question sends its images back | `imageUrl`, `justificationImageUrl` and `options[].imageUrl` are in the `PUT` body |
| Restoring the session needs a single refresh-token request | 1 request to `/api/auth/refresh-token`, user returned, new tokens saved |
| Logout | Calls `/api/auth/logout` and clears local tokens |
| Revoking an invitation code | `PUT` with `isActive: false` that keeps `maxUses` and the expiration |
| Practice history | Uses `/api/practice-sessions/history` and parses the counts |
| Renamed routes | `/api/subscriptions/current-user` and `/api/reports/student-performance` |

**End-to-end check against the real backend** (temporary test, not kept in the repo): the real repositories were run against the
backend `refactor` branch — once with a fresh database and once with a copy of the developer's database:

- **Admin flow:** login, load the 5 lists, create / edit / delete subject, question (keeping images), institution and invitation code (including revoke), restore session, logout → ✅
- **Student flow:** login, subscription, plans, start practice, answer, history counts, finish, restore session, logout → ✅

A grep confirmed that no old route remains in `lib/` or `test/`.

**After the `School` → `Institution` rename (2.6):** `flutter analyze` no issues, `flutter test` 28 / 28, and the end-to-end check passed again
against the backend with a fresh database and with a copy of the developer's database migrated at startup (the student now receives
`institutionId` and `isInstitutional` is true).

---

## 4. Pending

- The 2FA and Google sign-in endpoints exist in the backend but the app does not use them yet.
- `test/` names are still in Spanish (existing tests); new tests are in English.
