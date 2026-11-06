# 打过补丁的 MoltenVK

[English](README.md) | [Chinese](README.zh-CN.md) | [Japanese](README.ja.md)

> 英文文档是权威版本。中文和日文文档是为方便阅读提供的完整翻译。

这是一个打过补丁的 [MoltenVK](https://github.com/KhronosGroup/MoltenVK)：固定的上游提交、取自公开 fork 的有序补丁系列，以及重新构建它的脚本。它不作任何兼容性或一致性承诺。仓库不含 MoltenVK 源码树，也不含构建好的 dylib。

## 基线与当前补丁集

- 上游基线：MoltenVK `main` 的 `5189f8de`（`v1.4.2-58-g5189f8de`），固定在 [`base/moltenvk-main-5189f8de.json`](base/moltenvk-main-5189f8de.json)。依赖遵循其 `ExternalRevisions`
- 当前补丁集：[`1.4.2-patched.1`](patchsets/1.4.2-patched.1/manifest.json)，共 8 个补丁。其 Git tag 是下游所用构建的源码依据；不提供二进制 Release。ID 保留上游最后一个发布版本；源码自身的版本常量为 1.4.3，上游尚未发布该版本
- 审查记录：见 [MAINTENANCE.md](MAINTENANCE.md#review-records)

## 仓库结构

| 路径 | 内容 |
|---|---|
| `base/` | 固定的上游仓库和提交 |
| `patchsets/<id>/` | 一个补丁集的 `series` 和 `manifest.json`；脚本默认使用最新的，可用 `MOLTENVK_PATCHSET_DEFINITION=patchsets/<id>` 选择其他补丁集 |
| `patches/community/` | 取自公开 fork 的修复，每个文件一个提交 |
| `scripts/` | 获取、检查和构建脚本 |
| `docs/` | 审查记录 |

## 补丁的作用

所有改动都是通用的、默认开启的，绝不匹配具体游戏。每个非平凡的改动都有一个环境变量开关；见 [MAINTENANCE.md](MAINTENANCE.md#environment-switches)。

- 在 present 等待信号量发出信号后才呈现交换链图像
- 按着色器实际写入的大小确定细分暂存缓冲区，并把间接细分绘制限制在其范围内
- 让源为 compute 的屏障留在 compute 编码器内，并在屏障得到遵守时让 `vkCmdDispatch` 编码器并发运行
- 让 Metal 优化片段和 compute 阶段中的精确数学辅助函数
- 对声明最大值很大的 indirect-count 命令限制编码的 Metal 绘制数，发生截断时提高上限；超过阈值的一次性命令可能丢失绘制
- 在动态渲染开始前转换 indirect-count 参数

## 验证与构建

```bash
scripts/static-check.sh
scripts/integration-check.sh "$(scripts/fetch-source.sh)"
scripts/build.sh
```

`integration-check.sh` 用 `git am` 把每个补丁应用到固定基线的临时 worktree，并检查结果是否为 manifest 记录的树。`build.sh` 的说明见 [BUILDING.md](BUILDING.md)。

## 文档

- [BUILDING.md](BUILDING.md)：构建 dylib
- [MAINTENANCE.md](MAINTENANCE.md)：审查记录、准入门槛和环境变量开关
- [SECURITY.md](SECURITY.md)：报告安全问题
- [docs/upstream-reviews.md](docs/upstream-reviews.md)：审查记录

## 许可证

Apache-2.0，与 MoltenVK 相同；见 [`LICENSE`](LICENSE)。采用的提交保留原作者，被修改的文件带有修改声明。
