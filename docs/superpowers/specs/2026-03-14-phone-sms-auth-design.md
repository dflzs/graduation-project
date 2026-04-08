# 手机号短信登录注册设计

**背景**

当前项目的普通用户认证是本地模拟实现：[`entry/src/main/ets/services/auth.service.impl.ets`](/c:/Users/23947/Desktop/DFL_code/entry/src/main/ets/services/auth.service.impl.ets) 直接校验固定验证码 `123456`，首次登录时本地造用户。这与 `D:/codespace/XiaoMiMall/docs/phone-sms-login-api.md` 描述的真实短信登录/注册链路不一致。

**目标**

将普通用户认证替换为文档定义的远程接口流程：
- 登录发码：`/api/sendLoginCode`
- 登录校验并登录：`/api/validateLoginCode`
- 注册发码：`/api/sendCode`
- 注册校验：`/api/validateCode`
- 注册完成：`/api/register`

保留现有本地业务域模型、仓储和管理员登录能力，不改动订单、商品、公告等业务模块的本地实现。

## 架构

认证改造分为三层：

1. 远程认证客户端
负责封装 HTTP 请求、JSON 序列化和响应解析，只暴露登录/注册相关方法，不直接操作本地仓库。

2. 认证服务
负责参数校验、调用远程认证客户端、把远程 `userinfo[0]` 映射到项目本地 `User`，并创建 `AuthSession`。

3. 登录注册页面
普通用户模式拆分为“短信登录”和“短信注册”两个流程；管理员模式继续走本地管理员码登录。

## 数据设计

现有 `User` 结构不足以保存远程用户关键字段，增加如下扩展字段：
- `remoteUserId?: string`
- `remoteSalt?: string`
- `passwordConfigured?: boolean`

映射规则：
- `id`：优先使用现有本地用户 `id`，首次远程登录/注册时新建本地 `id`
- `phone`：映射远程 `tel`
- `nickname`：优先使用远程 `username`，为空时回退 `用户${phone 后四位}`
- `remoteUserId`：映射远程 `_id`
- `remoteSalt`：映射远程 `salt`
- `passwordConfigured`：注册成功后为 `true`，纯登录场景保持现有值或 `false`

这样可以保持本地订单、商品等模块继续依赖 `User.id`，同时保留后续对接更多远程接口所需的 `_id/salt`。

## 接口边界

新增认证客户端方法：
- `sendLoginCode(phone: string)`
- `validateLoginCode(phone: string, code: string)`
- `sendRegisterCode(phone: string)`
- `validateRegisterCode(phone: string, code: string)`
- `registerByPhone(phone: string, code: string, password: string)`

认证服务新增普通用户方法：
- `sendLoginCode(phone: string)`
- `loginByPhone(phone: string, code: string)` 改为远程校验
- `sendRegisterCode(phone: string)`
- `verifyRegisterCode(phone: string, code: string)`
- `registerByPhone(phone: string, code: string, password: string)`

管理员方法 `loginByAdminCode` 保持本地实现，不与远程接口耦合。

## 页面流程

登录页调整为三个模式：

1. 用户登录
- 输入手机号
- 点击“发送验证码”
- 输入验证码
- 点击“登录”

2. 用户注册
- 输入手机号
- 点击“发送验证码”
- 输入验证码并校验
- 输入密码、确认密码
- 点击“注册并登录”

3. 管理员登录
- 继续保留手机号 + 管理员码模式

页面状态只保存本次认证所需表单数据，不缓存验证码。普通用户提示文案改为真实短信接口说明，不再出现固定验证码提示。

## 错误处理

- 手机号、验证码、密码等基础校验先在本地完成，避免无效请求
- 远程接口 `success === false` 时，优先展示服务端 `message`
- 网络异常、JSON 解析异常统一转成用户可读错误，例如“网络请求失败，请稍后重试”
- 注册时必须校验两次密码一致、密码非空
- 如果远程登录返回的用户在本地已存在且状态为 `banned`，本地仍阻止登录

## 测试策略

先写失败测试，再实现：

1. 认证服务测试
- `loginByPhone` 不再接受固定验证码模拟，而是依赖远程客户端结果
- 远程登录成功时能写入或更新本地用户扩展字段
- 注册校验/注册成功时能正确创建会话
- 远程失败时返回服务端消息

2. 页面逻辑测试
- 不新增 UI 自动化；以服务层测试覆盖核心行为
- 页面通过编译验证保证接口调用和状态字段一致

3. 回归
- 现有管理员登录测试继续通过
- 交易闭环测试改为先通过一个可控的认证测试桩拿到普通用户会话

## 风险与约束

- 当前仓库没有初始提交，无法按 `using-git-worktrees` 流程创建隔离工作区；本次在当前目录实施
- ArkTS 的 HTTP 能力和 Node 不同，需要按项目现有依赖选择可用请求方式
- 远程接口返回 `userinfo` 为数组，必须做健壮性校验，不能假设一定有 `userinfo[0]`
