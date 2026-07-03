# RX 9 中文帮助与 UI 字符串安装器

这是一个个人使用的 RX 9 中文帮助与 UI 字符串安装器项目。

本项目不包含 iZotope RX 9 原厂程序、安装包、DLL、模型文件、授权文件或官方帮助文档副本。安装器只包含：

- 中文帮助入口页面
- 原创中文使用教程
- 保守 UI 字符串补丁词表
- 安装/恢复逻辑

## 汉化范围

安装器会处理两类内容：

1. 替换 RX 9 本地帮助入口：
   `HTML Help\en\index.html`
2. 对主程序内可原位替换的 UI 字符串进行汉化：
   `win64\iZotope RX 9 Audio Editor.exe`

由于 RX 9 没有外置语言文件，UI 汉化采用本机二进制字符串补丁方式。安装器只替换中文 UTF-8 字节数不超过原英文长度的文本，不扩展二进制结构，不修改授权逻辑，不包含或分发原厂 EXE。

## 使用方法

1. 关闭 RX 9。
2. 运行 `RX9-CN-Help-Installer.exe`。
3. 如果自动检测到安装目录，确认即可；否则手动选择 RX 9 根目录，例如：
   `D:\tool\Zotope\RX 9 Audio Editor`
4. 安装器会验证目录内是否存在：
   `win64\iZotope RX 9 Audio Editor.exe`
5. 安装器会提示是否应用 UI 汉化；选择[是]会备份并补丁本机 EXE。
6. 安装完成后，打开 RX 9 查看 UI 汉化效果；从帮助入口可进入中文教程。

## 恢复

首次安装时，安装器会在 RX 9 安装目录内创建：

- `.rx9-cn-patch-backup\HTML Help\en\index.html`
- `.rx9-cn-patch-backup\win64\iZotope RX 9 Audio Editor.exe`
- `.rx9-cn-patch-backup\ui-patch-report.txt`

再次运行安装器时，如果检测到备份，会询问：

- 选择[是]：重新安装/更新中文教程和 UI 补丁
- 选择[否]：恢复原帮助入口和原主程序 EXE
- 选择[取消]：退出

## 构建

在 Windows 上运行：

```powershell
.\build-csharp.ps1
```

构建结果会输出到：

`dist\RX9-CN-Help-Installer.exe`

