# DevEco/Hvigor 环境红线（强制）

本文档用于约束后续开发，避免重复触发：
- `00303217 Invalid value of 'DEVECO_SDK_HOME'`
- `00303168 SDK component missing`

## 一、不可触碰项（除非你明确授权）

1. 不修改 `local.properties`
2. 不修改 `.idea/**`（含 `modules/*.iml`）
3. 不“推断式”切换 SDK 版本（例如看到装了 API19 就强切）
4. 不把“环境故障”和“业务代码改动”混在同一轮处理

## 二、出现 SDK 报错时的唯一流程

1. 先判定为环境问题，暂停业务代码改动
2. 停 daemon：
   - `hvigorw.js --stop-daemon`
3. 仅修正环境变量，不动工程绑定文件
   - `DEVECO_SDK_HOME=D:\develop\DevEco Studio\sdk`
   - `OHOS_BASE_SDK_HOME=D:\develop\DevEco Studio\sdk\default\openharmony`
4. 重启 DevEco Studio 后再编译验证
5. 编译恢复后再继续业务开发

## 三、本项目当前可用基线

- `local.properties` 指向：
  - `sdk.dir=D:/develop/DevEco Studio/sdk/default/openharmony`
  - `hwsdk.dir=D:/develop/DevEco Studio/sdk/default`
- 本地命令行若报 SDK 环境错，优先在当前终端会话补齐环境变量后再编译

## 四、执行承诺

- 默认只改仓库内业务代码
- 环境层操作必须先说明原因，再执行
- 每次异常优先回到“最近一次可编译状态”
