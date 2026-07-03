# RX 9 中文帮助入口安装器

这是一个个人使用的 RX 9 中文帮助入口安装器项目。

本项目不包含 iZotope RX 9 原厂程序、安装包、DLL、模型文件、授权文件或官方帮助文档副本。安装器只包含：

- 中文帮助入口页面
- 原创中文使用教程
- 安装/恢复逻辑

## 汉化范围

当前安装器会替换 RX 9 本地帮助入口：

`HTML Help\en\index.html`

替换后，从 RX 9 的帮助入口打开时，会进入中文教程页。主程序界面菜单、按钮、模块面板等文本未修改，因为当前安装目录没有可编辑的外置语言资源；安装器也不会修改 RX 9 主程序 EXE 或授权相关文件。

## 使用方法

1. 关闭 RX 9。
2. 运行 `RX9-CN-Help-Installer.exe`。
3. 如果自动检测到安装目录，确认即可；否则手动选择 RX 9 根目录，例如：
   `D:\tool\Zotope\RX 9 Audio Editor`
4. 安装器会验证目录内是否存在：
   `win64\iZotope RX 9 Audio Editor.exe`
5. 安装完成后，在 RX 9 中打开帮助入口即可看到中文教程。

## 恢复原帮助入口

首次安装时，安装器会在 RX 9 安装目录内创建：

`.rx9-cn-patch-backup\HTML Help\en\index.html`

再次运行安装器时，如果检测到备份，会询问：

- “是”：重新安装/更新中文教程
- “否”：恢复原帮助入口
- “取消”：退出

## 构建

在 Windows 上运行：

```powershell
.\build-csharp.ps1
```

构建结果会输出到：

`dist\RX9-CN-Help-Installer.exe`
