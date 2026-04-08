# Client Password Login And Chinese Auth UI Design

> Approved scope: connect the local HarmonyOS client to the deployed backend for password login, and translate the login entry and password-login UI into Chinese first.

## Goal

Make the local HarmonyOS client log in against the deployed backend at `http://49.232.30.147` using the existing `/api/auth/login/password` endpoint, while converting the login entry flow and password-login page text to Chinese.

## Why This Slice First

The backend now already supports a stable password-login flow, while SMS login and registration still need extra client/backend alignment. Shipping the password-login path first gives us the smallest reliable end-to-end loop:

- open the app
- see Chinese login UI
- enter phone + password
- authenticate against the real server
- land in the app with a stored authenticated session

This avoids blocking on unfinished SMS-code behavior and keeps the client changes narrowly scoped.

## In Scope

- Update the client auth base URL from the old demo service to the deployed server
- Replace the old remote auth response model with the current backend response shape for password login
- Adapt the password-login network client to call `/api/auth/login/password`
- Adapt the auth service to build a local session from backend `token + user`
- Translate the login entry page and password-login page copy to Chinese
- Keep unsupported auth paths explicit instead of pretending they work

## Out Of Scope

- Product, order, announcement, chat, or admin client integration
- Full SMS-code login
- Full registration flow integration
- Broad Chinese localization outside the login entry and password-login pages

## Architecture

The client continues to use the existing auth service boundary, but the transport and response mapping change. `HttpRemoteAuthClient` becomes responsible for talking to the new backend shape, `AuthServiceImpl` becomes responsible for converting backend user data into the local `User` and `AuthSession` domain model, and the login UI stays thin by only calling the auth service and rendering localized copy.

Unsupported SMS-code and registration methods will remain available in code only if required by existing interfaces, but they should fail fast with clear Chinese messages rather than silently relying on the old demo backend.

## File-Level Design

### `entry/src/main/ets/constants/config.ets`

- Change `AUTH_API_BASE_URL` to `http://49.232.30.147`
- Leave unrelated config untouched

### `entry/src/main/ets/types/auth-remote.ets`

- Replace the old XiaomiMall-style response interfaces with backend-aligned types
- Model success response as:
  - `code`
  - `message`
  - optional `data`
- Model auth payload data as:
  - `token`
  - `user`
- Model remote user fields around the current backend shape:
  - `id`
  - `phone`
  - `nickname`
  - `avatar`
  - `role`
  - `status`
  - `credit_score`

### `entry/src/main/ets/services/auth-remote.client.ets`

- Point password login to `/api/auth/login/password`
- Send payload `{ phone, password }`
- Parse backend JSON safely
- Preserve interface shape for now, but return explicit “暂未接通服务器” style failures for unimplemented SMS/register calls

### `entry/src/main/ets/services/auth.service.impl.ets`

- Stop expecting `userinfo[0]`
- Build session from backend `data.user`
- Store backend token in the session instead of generating a fake local token for password login
- Map backend fields into the local `User`
- Prefer backend-provided Chinese `message` for success/failure text
- Leave admin local-code login path in place unless it conflicts with the backend path

### `entry/src/main/ets/pages/Auth/LoginPage.ets`

- Translate the page title, description, and button labels into Chinese
- Keep navigation structure unchanged

### `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`

- Translate labels, placeholders, button text, and validation to Chinese
- Update the helper text so it no longer references the obsolete `/api/doLogin`
- Keep page interactions unchanged except for localized copy

## Data Mapping

Backend login success currently returns a shape equivalent to:

```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "token": "...",
    "user": {
      "id": 2,
      "phone": "13800138000",
      "nickname": "测试用户",
      "avatar": "",
      "role": "user",
      "status": "active",
      "credit_score": 60
    }
  }
}
```

Client mapping rules:

- `code === 0` means success
- `message` is surfaced directly to the UI where reasonable
- `data.token` becomes the session token
- `data.user` maps into the local `User`
- `credit_score` maps to `creditScore`

## Error Handling

- Network failures should surface a Chinese network error message
- Empty or malformed backend payloads should surface a Chinese parsing/auth failure message
- Unsupported SMS-code and registration transport calls should return a clear Chinese message that those server paths are not connected yet
- Banned users should still be blocked based on backend `status`

## Validation Strategy

This slice is complete when all of the following are true:

1. The login entry page is Chinese
2. The password-login page is Chinese
3. The client targets `http://49.232.30.147`
4. A valid backend account can log in through the local client password-login flow
5. Auth failures surface understandable Chinese messages

## Follow-Up Work

After this slice, the next recommended client work is:

1. Chinese localization for the rest of auth pages
2. Registration flow alignment with the real backend
3. Product/order/chat page integration against the deployed backend
