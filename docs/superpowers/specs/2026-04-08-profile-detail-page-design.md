# Personal Profile Page Design

## Goal

Move avatar and profile editing out of the `我的` home tab into a dedicated personal-profile page, and support saving both nickname and avatar in one flow.

## Why

- The current avatar editor on the `我的` tab looks like a debug panel instead of a finished product.
- The natural interaction is: tap the user card, enter a profile-details page, then edit avatar and personal info there.
- We already have the backend path shape for `PUT /api/auth/me`; this is the right place to support profile saves.

## UX

- `我的` keeps a clean summary card plus navigation rows.
- Tapping the avatar area or the whole summary card opens `个人资料`.
- `个人资料` shows:
  - large avatar area with replace action
  - editable nickname
  - readonly phone
  - readonly credit score / role / account status
  - simulator-only image URL fallback
  - one primary `保存资料` button

## Data Flow

1. User opens `个人资料`.
2. Page loads current session user into local editable state.
3. User changes nickname and/or avatar.
4. Save triggers one `PUT /api/auth/me`.
5. Backend returns updated user.
6. Frontend refreshes local repo + session.
7. Returning to `我的` immediately shows updated avatar and nickname.

## API

- Reuse `PUT /api/auth/me`
- Request body supports:
  - `nickname`
  - `avatar`
- Validation:
  - nickname trimmed, minimum 2 chars if provided
  - avatar optional, but if provided must be `http(s)` or `/uploads/...`

## Scope

Included:
- Dedicated profile-details page
- Nickname edit
- Avatar update
- Session refresh after save

Excluded:
- Phone number change
- Password change
- Image cropper
- Multi-image avatar history
