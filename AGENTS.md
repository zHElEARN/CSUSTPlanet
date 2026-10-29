# AGENTS.md

本仓库：CSUSTPlanet（Swift/iOS 应用，含 CSUSTPlanetWidget widget target）。

## 敏感文件

- 不得读取 `.env` 与 `Configs/User.xcconfig`，只应读取 `.env.template` 与 `Configs/User.xcconfig.template`。
- `Configs/User.xcconfig` 与 `.env` 同等重要，直接读取会泄露用户敏感信息。
- 若需要真实值，应向用户询问，不得自行读取真实文件。

## 编译验证

- 只有用户明确要求时才进行编译验证，默认不跑编译验证。
- 需要编译验证时，必须使用 `csustplanet-build` skill，按其中的固定命令执行，不要自行编写 xcodebuild 命令。

## 代码格式化

- 修改完代码后必须执行 `Scripts/format-swift.sh`，使用仓库 `.swift-format` 配置递归格式化 CSUSTPlanet 与 CSUSTPlanetWidget 目录。
