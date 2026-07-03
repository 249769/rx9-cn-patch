# RX 9 中文帮助入口安装器使用指南

## 下载

从 Release 下载：

https://github.com/249769/rx9-cn-patch/releases/tag/v1.0.0

下载文件：

`RX9-CN-Help-Installer.exe`

## 安装

1. 关闭 RX 9。
2. 运行 `RX9-CN-Help-Installer.exe`。
3. 如果自动检测到 RX 9 安装目录，确认即可。
4. 如果没有自动检测到，请手动选择 RX 9 根目录，例如：
   `D:\tool\Zotope\RX 9 Audio Editor`
5. 安装完成后，在 RX 9 中打开帮助入口，即可进入中文使用教程。

## 恢复原帮助入口

首次安装时，安装器会在 RX 9 安装目录内创建备份：

`.rx9-cn-patch-backup\HTML Help\en\index.html`

再次运行安装器时：

- 选择[是]：重新安装或更新中文教程
- 选择[否]：恢复原帮助入口
- 选择[取消]：退出

## 汉化范围

当前安装器只替换本地帮助入口，并安装原创中文教程和使用指南。

它不会修改以下文件：

- RX 9 主程序 EXE
- DLL 文件
- 授权文件
- 模型数据文件
- 原厂安装包

主程序界面菜单、按钮和模块面板文字没有修改，因为当前安装目录中没有发现可编辑的外置语言资源。

## 校验

当前版本：

- Release：`v1.0.0`
- 文件名：`RX9-CN-Help-Installer.exe`
- SHA256：`2D972FA228F5C7E676D630F62D936DF98A860C60B01FED85CD64DDAB16AEBCB0`

