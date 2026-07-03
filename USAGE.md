# RX 9 中文帮助与 UI 字符串安装器使用指南

## 下载

从 Release 下载：

https://github.com/249769/rx9-cn-patch/releases/tag/v1.1.0

下载文件：

`RX9-CN-Help-Installer.exe`

## 安装

1. 关闭 RX 9。
2. 运行 `RX9-CN-Help-Installer.exe`。
3. 如果自动检测到 RX 9 安装目录，确认即可。
4. 如果没有自动检测到，请手动选择 RX 9 根目录，例如：
   `D:\tool\Zotope\RX 9 Audio Editor`
5. 当安装器询问是否应用 UI 汉化时，选择[是]。
6. 安装完成后，打开 RX 9 查看界面汉化效果；打开帮助入口可进入中文教程。

## 恢复原版

首次安装时，安装器会在 RX 9 安装目录内创建备份：

- `.rx9-cn-patch-backup\HTML Help\en\index.html`
- `.rx9-cn-patch-backup\win64\iZotope RX 9 Audio Editor.exe`

再次运行安装器时：

- 选择[是]：重新安装或更新中文教程和 UI 补丁
- 选择[否]：恢复原帮助入口和原主程序 EXE
- 选择[取消]：退出

## 汉化范围

当前安装器包含：

- 本地帮助入口替换
- 原创中文使用教程
- RX 9 主程序中可原位替换的 UI 字符串补丁

它不会包含或分发以下内容：

- RX 9 原厂程序
- 原厂 DLL
- 授权文件
- 模型数据文件
- 原厂安装包

## 注意事项

UI 汉化采用本机二进制字符串补丁方式，只替换中文 UTF-8 字节数不超过原英文长度的文本。此操作可能使本机 EXE 的数字签名状态发生变化；如遇异常，重新运行安装器并选择[否]即可恢复备份。

## 校验

当前版本：

- Release：`v1.1.0`
- 文件名：`RX9-CN-Help-Installer.exe`
- SHA256：`ACFCA349CC5575E6C034BD9209780298EF1BD5B84EC7C038F09D4CB8D8E8FAFA`
