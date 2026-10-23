# Electron + Vue2 桌面应用骨架（统信 UOS / deepin ARM64 版）—— 完整使用文档

> 本文档面向**新手**，从零开始带你完成统信 UOS（含银河麒麟等国产化 Linux）环境下本骨架的环境搭建、离线依赖安装、开发、deb 打包与常见问题排查。
>
> 统信 UOS 是国产 Linux 发行版，通常在**内网（离线）环境**部署，因此本文档重点覆盖「离线安装」的完整流程。
>
> 项目通用概念（主进程/渲染进程、IPC、环境变量、更新机制等）与 Windows 版完全一致，建议先阅读同目录下 `electron-vue-skeleton-win/README.md` 的前十节理解整体结构，本文档对相同内容只做简要复述，重点讲 UOS 特有的部分。

---

## 目录

1. [骨架与 UOS 环境总览](#一骨架与-uos-环境总览)
2. [环境要求](#二环境要求)
3. [第一阶段：离线安装基础环境（nvm / Node / Git）](#三第一阶段离线安装基础环境)
4. [第二阶段：安装打包依赖（gcc / ruby / gem / fpm / zlib）](#四第二阶段安装打包依赖)
5. [第三阶段：配置 Electron 镜像](#五第三阶段配置-electron-镜像)
6. [第四阶段：复制项目并修改配置](#六第四阶段复制项目并修改配置)
7. [开发与启动](#七开发与启动)
8. [打包（deb 安装包）](#八打包deb-安装包)
9. [deb 安装/卸载行为与桌面文件](#九deb-安装卸载行为与桌面文件)
10. [更新机制](#十更新机制)
11. [七大机制完整链路代码地图（重点章节）](#十一七大机制完整链路代码地图)
12. [配置项说明（含 IPC 沙箱 / 深链 / iframe / 首屏优化 / 打包优化）](#十二配置项说明)
13. [系统调优与常见报错处理](#十三系统调优与常见报错处理)
14. [常见问题速查表](#十四常见问题速查表)
15. [附录：Windows 代码移植到 UOS 的适配要点](#十五附录windows-代码移植到-uos-的适配要点)

---

## 一、骨架与 UOS 环境总览

本骨架是开箱即用的 Electron 桌面应用脚手架（Electron 21 + Vue2 + webpack 5 + electron-builder 22），已内置打包 / 全量更新 / 增量热更新链路，**不含任何业务代码**。UOS 版与 Windows 版的差异：

1. **离线/内网部署**：多数生产环境无法访问外网，依赖需提前在有网环境下载好再拷贝进去。
2. **打包产物不同**：UOS 上打包生成 **`.deb` 安装包**（而非 Windows 的 `.exe`）。
3. **打包依赖更复杂**：Linux 打 deb 需要 `fpm`（基于 ruby）等额外工具链。
4. **目标架构**：骨架默认打包目标为 **arm64**（鲲鹏/飞腾等国产芯片），见 `package.json` → `build.linux.target`。

整体流程分四个阶段：

```
第一阶段：装基础环境（nvm / node / git）
   ↓
第二阶段：装打包依赖（gcc / ruby / gem / fpm / zlib）
   ↓
第三阶段：配置 Electron 镜像（或拷贝缓存）
   ↓
第四阶段：复制项目 → 改配置 → 开发 / 打包
```

---

## 二、环境要求

| 项 | 要求 |
|----|------|
| 操作系统 | 统信 UOS / 银河麒麟（Linux） |
| Node.js | 16.x（推荐 v16.20.2） |
| Git | 2.36.x |
| ruby | 3.0.2 |
| fpm | 1.15.x |
| zlib | 1.3.x |
| 目标架构 | arm64（打包机必须与目标机同架构） |

> ⚠️ **打包机必须是 ARM64**：x86 机器交叉打 arm64 deb 会因 Electron 二进制和原生模块架构不符而失败。请在实际的 ARM64 UOS 机器上执行打包。

---

## 三、第一阶段：离线安装基础环境

### 3.1 安装 nvm

nvm（Node Version Manager）用于管理多个 Node 版本。**有网时**直接：

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
sudo apt-get update && apt-get upgrade
```

安装完成后刷新环境变量：

```bash
source ~/.bashrc
```

> 内网无法联网时：在有网机器下载 nvm 安装脚本（或整个 `~/.nvm` 目录），拷贝到内网机器执行/放置。

### 3.2 安装 Node.js（离线）

原理：nvm 管理的 Node 版本都放在 `~/.nvm/versions/node/` 目录下，手动把离线下载的 Node 解压进去即可。

```bash
# 1. 创建 node 版本目录（若不存在）
mkdir -p ~/.nvm/versions/node

# 2. 解压离线下载的 node 安装包到该目录
#    注意：arm64 机器必须下载 linux-arm64 版本！
tar -zxvf node-v16.20.2-linux-arm64.tar.gz -C ~/.nvm/versions/node

# 3. 重命名为 nvm 可识别的版本号格式
mv ~/.nvm/versions/node/node-v16.20.2-linux-arm64 ~/.nvm/versions/node/v16.20.2

# 4. 查看已安装版本
nvm ls

# 5. 使用该版本
nvm use 16.20.2
```

验证：

```bash
node -v   # v16.20.2
```

> 离线包需提前在有网环境从 Node 官网（或团队共享）下载，**架构必须与目标机器一致**（arm64 机器用 `linux-arm64` 包）。

### 3.3 安装 Git（离线）

源码编译安装：

```bash
# 1. 解压离线下载的 git 源码包
tar xvf git-2.36.1.tar.gz
cd git-2.36.1

# 2. 配置安装路径并编译安装
./configure --prefix=/usr/local/git
make && sudo make install

# 3. 配置环境变量（写入 /etc/profile 或 ~/.bashrc 末尾，永久生效）
export GIT_PATH=/usr/local/git/bin
export PATH=$PATH:$GIT_PATH

# 4. 刷新并验证
source ~/.bashrc
git --version   # git version 2.36.1
```

> ⚠️ `export` 必须**永久写入** `/etc/profile` 或 `~/.bashrc` 再 `source`，否则新开终端会失效。

---

## 四、第二阶段：安装打包依赖

Linux 下 electron-builder 打 deb 底层依赖 `fpm`（Effing Package Management），而 fpm 是 ruby 写的，所以需要先装 ruby 工具链。

### 4.1 安装 gcc 编译环境

ruby 源码需要 gcc 编译。内网环境通过「离线 deb 包」安装：

1. **在有网环境**下载所需的编译包：

```bash
sudo apt reinstall -d gcc g++   # -d 表示只下载不安装
# 或用：sudo apt download gcc g++
```

2. 下载的 deb 包存放在 `/var/cache/apt/archives` 目录。

3. 把该目录下**所有 deb 包**复制到内网机器任意目录。

4. 在内网机器对应目录批量安装：

```bash
sudo dpkg -i ./*.deb
```

5. 若报缺少依赖或版本不对，根据报错回到有网机器补下载，**可能需要反复 5–10 次**，直到装完。

6. 验证：

```bash
gcc -v
g++ -v
```

### 4.2 安装 ruby

```bash
# 1. 解压 ruby 源码
tar -zxvf ruby-3.0.2.tar.gz
cd ruby-3.0.2

# 2. 配置并安装（prefix 可自定义）
./configure --prefix=/usr/local/ruby
make && sudo make install

# 3. 验证
ruby -v
```

**配置环境变量**（写入 `~/.bashrc` 末尾，需 source 生效）：

```bash
export PATH=/usr/local/ruby/bin:$PATH
```

> 若安装后 gems 目录内容缺失，需从有网机器把 `/usr/local/lib/ruby/gems` 整个目录拷贝过来。

### 4.3 安装 gem

**在线安装（有网环境）：**

```bash
sudo apt install ruby ruby-dev
```

**离线安装（内网环境）：**

```bash
tar -zxvf rubygems-3.2.22.tgz
cd rubygems-3.2.22
sudo ruby setup.rb
# 输出 "rubygems-3.2.22 installed" 表示成功
```

### 4.4 安装 fpm

**在线安装：**

```bash
sudo gem install fpm
```

**离线安装：**

```bash
# 1. 在有网环境把 gems 包打包，复制到内网机器的 ruby gems 目录
#    目标路径：/usr/local/lib/ruby/gems

# 2. 本地安装
sudo gem install --local /usr/share/gems/cache/*.gem

# 3. 配置环境变量（写入 ~/.bashrc 永久生效）
export USE_SYSTEM_FPM=true
```

> `USE_SYSTEM_FPM=true` 告诉 electron-builder 使用系统已安装的 fpm，而非自行下载——内网无法下载时**必须设置**。

### 4.5 安装 zlib

某些环境打包时缺少 zlib 会报错，需源码安装：

```bash
tar -zxvf zlib-1.3.1.tar.gz
cd zlib-1.3.1
./configure --prefix=/usr/local/zlib
make && sudo make install
```

> 也可以直接 `sudo apt install zlib1g-dev`（有网时）。fpm 编译报 zlib 相关错误时优先检查此项。

### 4.6 检查 ar 命令（打 deb 必需）

fpm 把目录转换为 deb 时需要 `ar` 命令，缺失会报 `Need executable 'ar' to convert dir to deb`：

```bash
which ar || sudo apt install binutils
```

---

## 五、第三阶段：配置 Electron 镜像

内网无法从 GitHub 下载 Electron 和 electron-builder 依赖，需配置国内镜像：

```bash
npm config edit
```

添加：

```
registry=https://registry.npmmirror.com
electron_mirror=https://cdn.npmmirror.com/binaries/electron/
electron_builder_binaries_mirror=https://npmmirror.com/mirrors/electron-builder-binaries/
```

> **更快的离线方案**：如果已有外网机器装过本项目，直接把它的 `~/.cache/electron` 和 `~/.cache/electron-builder` 两个目录整个复制到内网机器的 `~/.cache/` 下，即可完全跳过下载。

---

## 六、第四阶段：复制项目并修改配置

### 6.1 复制项目到目标机器

将完整项目目录（**含 node_modules**）复制到 UOS 机器。

> 骨架未包含 node_modules，请在有网的同架构（ARM64）UOS 机器上先执行 `npm install`，再整体拷贝。

### 6.2 修改 package.json 关键字段

骨架的 UOS 打包配置已就位（`build.linux.target = deb + arm64`），复制后只需检查/修改：

```jsonc
{
  "build": {
    "productName": "myapp",              // 应用名（请改成你的产品名）
    "appId": "com.example.myapp",        // 应用唯一标识（请改）
    "publish": [
      {
        "provider": "generic",
        "url": "http://your-update-server:8888/packageUpload"  // 更新服务器地址（内网改为实际地址）
      }
    ],
    "linux": {
      "target": [{ "target": "deb", "arch": ["arm64"] }],
      "icon": "build/icons/hicolor",     // 图标（npm run build-icon 生成）
      "desktop": { "Name": "myapp", "X-UOS-AppID": "myapp" /* ... */ }
    },
    "deb": {
      "afterInstall": "./build/shell/postinst.sh",  // 安装后脚本
      "afterRemove": "./build/shell/prerm.sh"       // 卸载前脚本
    }
  }
}
```

> 改名时注意三处同步：`productName`、`desktop.Name/Icon/X-UOS-AppID`、`build/shell/myapp.desktop` 中的 `Exec=/opt/myapp/myapp`。

### 6.3 处理权限问题

复制到 Linux 后 `node_modules` 可能权限异常，导致打包报 `EACCES: permission denied`：

```bash
chmod -R 777 node_modules/
chmod -R 777 electron-vue-skeleton-uos/   # 项目目录（按实际目录名）
```

### 6.4 补充平台相关的编译依赖

`esbuild` 等是平台相关二进制。若 node_modules 是从 Windows/x86 机器拷来的，必须在 UOS（ARM64）机器上重新执行 `npm i`，或从有网的同架构 UOS 机器拷贝以下目录：

```
node_modules/@esbuild/
node_modules/esbuild/
node_modules/esbuild-loader/
```

### 6.5 增加文件监听数量（必做）

UOS 默认 inotify 上限较低，`npm run dev` 会报 `ENOSPC: System limit for number of file watchers reached`：

```bash
sudo vim /etc/sysctl.conf
# 添加一行：
fs.inotify.max_user_watches=524288

# 使配置生效
sudo sysctl -p
```

---

## 七、开发与启动

```bash
npm run dev
```

- dev-server 默认监听 **9080 端口**（被占用自动顺延），同时自动拉起 Electron 窗口。
- 修改 Vue 代码热重载；修改 `src/main/` 自动重启 Electron。
- 启动成功看到示例页显示版本号，即说明骨架运行正常。

---

## 八、打包（deb 安装包）

```bash
npm run build          # 等同 build:linux
```

对应脚本：

```jsonc
"build": "cross-env BUILD_TARGET=clean TERGET_ENV=production node .electron-vue/build.js && electron-builder --linux --arm64"
```

产物输出到 `build/` 目录：

- `myapp_x.x.x_arm64.deb` —— UOS/麒麟 deb 安装包
- `latest-linux.yml` —— 更新描述文件（自动更新用）

其他命令：

| 命令 | 说明 |
|------|------|
| `npm run build:test` | 测试环境包（加载 `env/test.env`） |
| `npm run build:dir` | 只解包不压 deb（快速验证文件是否齐全） |
| `npm run build:clean` | 只清理编译产物 |

> **打包前检查清单**：① `ar` 命令存在；② `USE_SYSTEM_FPM=true` 已设置（离线时）；③ node_modules 权限正常；④ `build/icons/` 图标存在。

---

## 九、deb 安装/卸载行为与桌面文件

### 9.1 安装行为（postinst.sh）

deb 安装后应用位于 `/opt/myapp/`。骨架的 `build/shell/postinst.sh` 会：

1. 把 `myapp.desktop` 复制到 `/root/Desktop`（若存在）；
2. 遍历在线用户，复制到每个用户的 `~/Desktop` 并赋权限；
3. 刷新桌面图标缓存。

### 9.2 卸载行为（prerm.sh）

`build/shell/prerm.sh` 在卸载前清理上述桌面快捷方式。

### 9.3 桌面文件（Desktop Entry）

`build/shell/myapp.desktop`（随包分发到 `/opt/myapp/build/shell/`）：

```ini
[Desktop Entry]
Name=myapp
Exec=/opt/myapp/myapp %U
Terminal=false
Type=Application
Icon=/opt/myapp/build/shell/512x512.png
Categories=Utility;
MimeType=application/myapp;
```

同时 `package.json` 的 `build.linux.desktop` 字段控制安装到系统应用列表的桌面项，关键字段含义：

| 字段 | 说明 |
|------|------|
| `Name` | 应用显示名称 |
| `Exec` | 启动命令（指向 `/opt/` 下的可执行文件） |
| `Icon` | 图标名/路径 |
| `Categories` | 应用分类（开始菜单分组） |
| `MimeType` | `x-scheme-handler/myapp` 表示支持 `myapp://` 协议唤起 |
| `X-Deepin-*` / `X-UOS-*` | 统信/深度的应用标识（上架商店需要） |

---

## 十、更新机制

### 10.1 全量更新（electron-updater）

1. 改 `package.json` 的 `version`，执行 `npm run build`；
2. 把 `build/` 下的 **deb 包** 和 **`latest-linux.yml`** 压缩成 zip（文件直接在 zip 根目录）上传到更新服务器（`build.publish[0].url`）；
3. 客户端启动自动检查（`src/main/services/checkupdate.js`，仅生产环境），事件与 Windows 版一致：`update-available` / `update-download-progress` / `update-downloaded` / `update-error`。

### 10.2 增量热更新

```bash
npm run build
npm run pack:resources   # 产出 build/update/（json 描述 + tar 包）
```

把 `build/update/` 内容打成 zip 发给后端上传（**tar 包本身不解压**）。服务器目录约定与 HotUpdater 使用方式同 Windows 版，见 `src/main/services/HotUpdater.js` 注释。

### 10.3 本地更新模拟服务器

```bash
npm run update:serve    # 25565 端口，静态服务 server/client/
```

调试时把 publish.url 临时改为 `http://127.0.0.1:25565`。

---

## 十一、七大机制完整链路代码地图（重点章节）

> 这是本骨架最核心的一章。骨架从真实项目剥离了**七大机制的完整链路代码**（不含任何云空间业务代码），每个机制都能在 Demo 页（`Home.vue`）点按验证。下面用「机制说明 + 完整链路代码文件 + 关键代码」三部分，带你把每一条链路从头到尾走一遍。
>
> **学习方法**：先看「链路」知道有哪些文件、谁调用谁，再对照「关键代码」打开对应文件阅读注释。所有文件都有中文注释，专为新手准备。
>
> ⚠️ UOS 版骨架与 Windows 版的 `src/` 代码**完全一致**，七大机制的实现一模一样；差异只在打包配置（deb vs exe）与协议注册方式（desktop 文件 vs 注册表）。因此本章链路图直接复用 Windows 版，仅在「深链唤起」小节补充 UOS 特有说明。

### 11.1 机制①：主进程 ↔ 渲染进程信息交互（IPC）

**是什么**：Electron 应用分主进程（Node 环境）和渲染进程（Vue 页面），两者之间靠 IPC 通信。渲染进程想「拿版本号、控制系统、触发更新」，都得通过 IPC 请主进程代办。

**沙箱方案（本骨架采用）**：`contextIsolation: false + nodeIntegration: true`。即关闭上下文隔离、开启 Node 集成，让渲染进程可以直接 `require('electron')` 拿到 `ipcRenderer`，无需 contextBridge 白名单桥接。

**完整链路**：

```
渲染进程组件 (Home.vue)
   └─ this.$ipcRenderer.invoke('xxx') / send('xxx') / sendSync('xxx')
        │  ← 挂载点：src/renderer/main.js 的 Vue.prototype.$ipcRenderer = ipcRenderer
        ▼
主进程 ipcMain.js 的 Mainfunc() 里注册的对应 handler
   └─ ipcMain.handle('xxx')  / ipcMain.on('xxx')
        │
        ▼
处理完成 → 通过 event.returnValue（同步）/ return（异步）/ webContents.send（推送）
        │
        ▼
渲染进程 this.$ipcRenderer.on('xxx') 接收
```

**涉及文件**：

| 文件 | 角色 |
|------|------|
| `src/renderer/main.js` | 把 `ipcRenderer` 挂到 `Vue.prototype.$ipcRenderer` |
| `src/main/services/ipcMain.js` | 主进程侧所有 IPC 通道的注册中心（`Mainfunc()`） |
| `src/main/services/windowManager.js` | 额外注册 `file:select` / `file:readChunk`（断点续传分片读取） |
| `src/renderer/utils/ipc/ipcFun.js` | 主进程侧右键菜单/兄弟窗口传值/electron-store 的 IPC |
| `src/renderer/utils/ipc/index.js` | re-export 统一出口，被 windowManager.js 引用 |
| `src/renderer/views/Home.vue` | 渲染进程侧调用示例 |

**三种通信模式**：

| 模式 | 渲染进程 | 主进程 | 适用场景 |
|------|---------|--------|---------|
| 请求/响应 | `invoke(channel, data)` → Promise | `ipcMain.handle(channel, fn)` | 取数据（版本号、系统信息） |
| 单向发送 | `send(channel, data)` | `ipcMain.on(channel, fn)` | 触发动作（写 store、窗口控制） |
| 同步取值 | `sendSync(channel, data)` | `ipcMain.on(channel, (e)=>{e.returnValue=...})` | 同步拿返回值（版本号、store 读） |
| 主进程推送 | `on(channel, cb)` 注册监听 | `win.webContents.send(channel, data)` | 进度上报、深链参数下发 |

> ⚠️ 安全提示：`contextIsolation:false + nodeIntegration:true` 开发最省事，但安全边界弱，**只适合加载可信内容**（内部工具、企业应用）。若你的应用要加载不可信外部网页，请切换到 `contextIsolation:true + contextBridge` 白名单方案（`preload.js` 头部有完整对比说明）。

**常用通道速查**（完整列表见 `ipcMain.js`）：

| 通道 | 模式 | 作用 |
|------|------|------|
| `get-version` | sendSync | 获取版本号（同步） |
| `get-system-info` | invoke | 获取系统信息（异步，含国产化检测） |
| `get-system-summary` | sendSync | 获取系统信息摘要 |
| `get-install-version` | invoke | 获取安装包版本详情 |
| `get-app-path` | invoke | 获取应用路径 |
| `windows-mini` / `window-max` / `window-hide` / `window-refresh` | invoke | 窗口控制 |
| `window-close` | invoke | 关闭窗口（白名单 `/iframe` 直接 close，其余 hide） |
| `check-update` / `start-update` / `confirm-update` | invoke | 全量更新三步 |
| `hot-update` / `start-hot-update` / `confirm-hot-update` | invoke | 热更新三步 |
| `files-download` / `start-download` | invoke | 全量/简单文件下载 |
| `open-messagebox` / `open-errorbox` / `open-directory` | invoke | 对话框 |
| `open-win` | invoke | 打开子窗口 |
| `get-log-path` / `open-log-folder` / `get-log-files` | invoke | 日志 |
| `file:select` / `file:readChunk` | invoke | 断点续传分片读取（windowManager.js 注册） |
| `setStore` / `getStore` / `deleteOne` / `deleteAll` / `getAllStore` | send/sendSync | electron-store 持久化（ipcFun.js 注册） |

### 11.2 机制②：窗口控制

**是什么**：无边框窗口（`IsUseSysTitle:false`）下，最小化/最大化/关闭/隐藏/刷新这些操作都通过 IPC 交给主进程执行。

**完整链路**：

```
Home.vue 按钮点击 → this.$ipcRenderer.invoke('windows-mini')
   → ipcMain.js: ipcMain.handle('windows-mini', e => BrowserWindow.fromWebContents(e.sender)?.minimize())
```

**涉及文件**：`src/renderer/views/Home.vue`（触发）→ `src/main/services/ipcMain.js`（处理）。

**关键代码**（ipcMain.js 摘录）：

```js
ipcMain.handle('windows-mini', (event) => {
  BrowserWindow.fromWebContents(event.sender)?.minimize()
})
ipcMain.handle('window-close', (event) => {
  const currentWindowURL = event.sender.getURL()
  const pathname = currentWindowURL.split('?')[0].split('#')[1]
  if (!whiteList.includes(pathname)) {   // whiteList = ['/iframe']
    BrowserWindow.fromWebContents(event.sender)?.hide()
    event.preventDefault()
  } else {
    BrowserWindow.fromWebContents(event.sender)?.hide()
    BrowserWindow.fromWebContents(event.sender)?.close()
  }
})
```

> 注意 `window-close` 的白名单逻辑：`/iframe` 路由的窗口关闭时真正 `close`，其余窗口只 `hide`（隐藏不销毁），这是为「关闭主窗口实际是隐藏到托盘」这类体验服务的。

### 11.3 机制③：全量更新（electron-updater）

**是什么**：下载完整 deb 安装包替换整个应用，适合大版本发布。基于 `electron-updater` 的 `autoUpdater`，带 6 状态机（-1/0/1/2/3/4）。

**完整链路**：

```
Home.vue 点击「检查全量更新」
   → this.$ipcRenderer.invoke('check-update')
   → ipcMain.js: allUpdater.checkUpdate(win)
   → checkupdate.js: autoUpdater.setFeedURL(nowIpUrl) + checkForUpdates()
        ├─ 'checking-for-update'   → Message(win, 0)   state=0 检查中
        ├─ 'update-available'      → Message(win, 1)   state=1 有更新
        ├─ 'update-not-available'  → Message(win, 2)   state=2 无更新
        ├─ 'download-progress'     → Message(win, 3)   state=3 下载中
        ├─ 'update-downloaded'     → Message(win, 4)   state=4 完成
        └─ 'error'                 → Message(win, -1)  state=-1 出错
   → webContents.send('update-msg', {state, msg})
   → Home.vue 监听 'update-msg'，按 state 更新 UI
下载：Home.vue invoke('start-update') → checkupdate.js handleDownload() → downloadUpdate()
安装：Home.vue invoke('confirm-update') → checkupdate.js quitInstall() → quitAndInstall()
```

**涉及文件**：`src/renderer/views/Home.vue`（触发+监听）→ `src/main/services/ipcMain.js`（转发）→ `src/main/services/checkupdate.js`（Update 类，核心实现）。

**关键代码**（checkupdate.js 状态机摘录）：

```js
autoUpdater.on('update-available', (arg) => {
  this.Message(this.mainWindow, 1, arg)   // 有更新
})
// ...
Message(mainWindow, type, data) {
  const senddata = { state: type, msg: data || '' }
  mainWindow.webContents.send('update-msg', senddata)
}
```

> 更新服务器地址通过 `electron-store` 的 `nowIpStr` 动态切换（`checkUpdate` 内读取），默认 `http://127.0.0.1:8888/packageUpload`。生产环境才生效。**UOS 上全量更新产物是 `.deb` + `latest-linux.yml`**（非 exe + latest.yml），服务器目录里放这两者即可。

### 11.4 机制④：增量热更新（HotUpdater）

**是什么**：只更新前端的 `dist` 资源（不重装应用），省流量、快，适合高频小改动。自研实现，链路完整：**版本比对 → 流式下载 → sha256 校验 → 解压 → 覆盖 → 重启**。

**完整链路**：

```
Home.vue 点击「检查热更新」→ invoke('hot-update')
   → ipcMain.js: updater(win)
   → HotUpdater.js:
        1. 读取 electron-store 的 nowIpStr 拼服务器地址
        2. 请求 <configName>.json 描述文件（带时间戳防缓存）
        3. semver gt(服务器版本, 本地版本) 判断是否需更新
        4. 需更新 → 推送 'hot-update-status' status=update-available
           + 注册 ipcMain.handle('start-hot-update') 下载逻辑
Home.vue 点击「下载热更新包」→ invoke('start-hot-update')
   → emptyDir(updatePath) → 流式下载 zip
   → createHmac('sha256','Sky') 校验 hash
   → extract-zip 解压 → remove 旧 dist/package.json → copy 覆盖
   → 推送 status: downloading → moving → finished
Home.vue 点击「重启生效」→ invoke('confirm-hot-update')
   → ipcMain.js: app.relaunch() + app.exit(0)
```

**涉及文件**：`src/renderer/views/Home.vue` → `src/main/services/ipcMain.js` → `src/main/services/HotUpdater.js` → `src/main/config/hotPublish.js`（`configName`）→ `src/main/config/StaticPath.js`（`resolveProdURL` 热更优先加载）。

**关键代码**（HotUpdater.js 摘录）：

```js
// 版本比较：服务器版本 > 本地版本才更新
if (gt(res.data.version, version)) {
  updateInfo.status = 'update-available'
  // ...
  ipcMain.handle('start-hot-update', async () => {
    await emptyDir(updatePath)
    const filePath = join(updatePath, res.data.name)
    updateInfo.status = 'downloading'
    await download(`${nowIpUrl}/${res.data.name}`, filePath)
    // sha256 完整性校验（key='Sky'）
    const buffer = await readFile(filePath)
    const sha256 = hash(buffer)
    if (sha256 !== res.data.hash) throw new Error('sha256 error')
    // 解压 + 覆盖
    await extract(filePath, { dir: join(updatePath, 'temp') })
    await remove(join(appPath, 'dist'))
    await copy(join(updatePath, 'temp'), appPath)
    updateInfo.status = 'finished'
  })
}
```

**热更新生效原理**（StaticPath.js 的 `resolveProdURL`）：

```js
function resolveProdURL() {
  const hotEntry = path.join(app.getPath('userData'), 'hot-update', 'index.html')
  if (fs.existsSync(hotEntry)) return `file://${hotEntry}`  // 热更优先
  return `file://${__dirname}/index.html`
}
```

> 状态机：`init → update-available → downloading → moving → finished / failed`。服务器目录约定：`<publishUrl>/<configName>.json`（版本描述）+ `<publishUrl>/<name>`（zip 包）。热更新在 UOS 上特别实用：内网环境改个小功能无需重新走 deb 安装。

### 11.5 机制⑤：深链唤起应用（myapp:// 短链）

**是什么**：浏览器/命令行输入 `myapp://openapp?token=abc123`，操作系统唤起应用并把参数传进去。常用于邮件一键唤起、扫码登录回跳、外部分享落地页。

**UOS 与 Windows 的差异（重要）**：协议注册方式不同。Windows 靠安装脚本写注册表 `HKCR\myapp`；**UOS/Linux 靠 desktop 文件的 `MimeType=x-scheme-handler/myapp` 声明**，由系统在安装时把协议关联到应用。骨架已配好两处：

1. `package.json` → `build.linux.desktop.MimeType = "x-scheme-handler/myapp"`
2. `build/shell/myapp.desktop` → `MimeType=x-scheme-handler/myapp;` 且 `Exec=/opt/myapp/myapp %U`（`%U` 把 URL 作为参数传入）

**完整链路**：

```
用户点击 myapp://openapp?token=abc123
   ├─ 应用未运行（冷启动）→ 进程启动，URL 在 process.argv
   │     → index.js 底部遍历 argv 找到 myapp:// 开头参数 → handleDeepLink()
   └─ 应用已运行（热启动）→ 单实例锁触发 'second-instance' 事件
         → index.js 从 commandLine 找深链 → handleDeepLink()
   ↓
handleDeepLink(url):
   1. Windows 下先 decodeURIComponent 解码（Linux 无需）
   2. new URL() 解析 protocol='myapp:' hostname='openapp'
   3. 把 ?a=1&b=2 解析成 params 对象
   4. 窗口已加载 → webContents.send('deep-link-params', params)
      窗口未加载 → 等 did-finish-load 再发
   5. 聚焦窗口确保弹到最前
   ↓
Home.vue 监听 'deep-link-params' → 展示收到的参数
```

**涉及文件**：`src/main/index.js`（`handleDeepLink` + 单实例锁 + 协议注册，全链路核心）→ `src/renderer/views/Home.vue`（监听 `deep-link-params`）→ `build/shell/myapp.desktop`（UOS 协议声明）。

**关键代码**（index.js 摘录）：

```js
const PROTOCOL = 'myapp'

function handleDeepLink (url) {
  let decodedUrl = url
  if (process.platform === 'win32') {
    decodedUrl = decodeURIComponent(url)   // Windows 命令行传参需解码
  }
  const urlObj = new URL(decodedUrl)
  if (urlObj.protocol === 'myapp:' && urlObj.hostname === 'openapp') {
    const params = {}
    urlObj.searchParams.forEach((value, key) => { params[key] = value })
    deepLinkParams = params
    // ...聚焦窗口 + webContents.send('deep-link-params', params)
    return true
  }
  return false
}

// 单实例锁
const gotTheLock = app.requestSingleInstanceLock()
if (!gotTheLock) {
  app.quit()
} else {
  app.on('second-instance', (event, commandLine) => {
    const deepLinkArg = commandLine.find(arg => arg.startsWith('myapp://'))
    if (deepLinkArg) handleDeepLink(deepLinkArg)
    // ...聚焦主窗口
  })
}

// 协议注册（开发环境 + 生产环境双路径）
if (process.defaultApp) {
  app.setAsDefaultProtocolClient(PROTOCOL, process.execPath, [path.resolve(process.argv[1])])
} else {
  app.setAsDefaultProtocolClient(PROTOCOL)
}
```

> 注意：`second-instance` 依赖**单实例锁**（`requestSingleInstanceLock`），删掉它，深链热启动就会变成「又开了一个应用」。UOS 上安装后若点击协议链接无反应，执行 `update-desktop-database` 刷新桌面数据库，或注销重登一次桌面会话。

### 11.6 机制⑥：iframe 内嵌网页

**是什么**：在应用内用 iframe 嵌入第三方网页（在线文档、外部系统等）。本骨架通过 `webviewTag:true` + 独立 `/iframe` 路由实现，并支持 postMessage 兄弟窗口传值。

**完整链路**：

```
Home.vue 输入地址 → 点击「跳转到 iframe 视图」
   → this.$router.push({ path: '/iframe', query: { src: url } })
   → 路由 views/iframe/index.vue 的 created 读 this.$route.query.src
   → 渲染 components/iFrame/index.vue 的 <iframe :src="src">
        （依赖 windowManager.js 里 webPreferences.webviewTag:true）
   → iframe 子页面 postMessage → views/iframe/index.vue 的 handleMessage
        → this.$ipcRenderer.send('siblingConnect', data) 兄弟窗口传值
        → 若 data.type === 'finishTask' → invoke('window-close') 关闭
```

**涉及文件**：`src/renderer/views/Home.vue`（入口）→ `src/renderer/router/index.js`（`/iframe` 路由）→ `src/renderer/views/iframe/index.vue`（视图 + postMessage 处理）→ `src/renderer/components/iFrame/index.vue`（iframe 组件 + 高度自适应）→ `src/main/services/windowManager.js`（`webviewTag:true` 开关）→ `src/main/services/ipcMain.js`（`window-close` 白名单）→ `src/renderer/utils/ipc/ipcFun.js`（`siblingConnect` 兄弟窗口传值）。

**关键代码**（windowManager.js 的 webPreferences）：

```js
webPreferences: {
  contextIsolation: false,
  nodeIntegration: true,
  webSecurity: false,
  webviewTag: true,   // 允许 <webview>/iframe 内嵌
  preload: join(__dirname, 'preload.js'),
  devTools: process.env.NODE_ENV === 'development' || openDevTools,
  scrollBounce: process.platform === 'darwin'
}
```

**兄弟窗口传值**（ipcFun.js 的 `refreshPage`）：

```js
ipcMain.on('siblingConnect', (e, arg) => {
  if (!mainWindow.isDestroyed()) {
    mainWindow.webContents.send('siblingConnect', arg)  // 转发给主窗口
  }
})
```

> 若目标站点有 `X-Frame-Options: DENY` / CSP 防嵌入头，iframe 会被浏览器拒绝渲染。这类第三方站点建议用系统浏览器打开，或自行在主进程用 `session.webRequest.onHeadersReceived` 剥离响应头（骨架未内置，需按需加）。

### 11.7 机制⑦：本地持久化（electron-store）

**是什么**：类似 localStorage，但由主进程管理、重启不丢，适合存用户配置、token、服务器 IP 等。本骨架已内置 `electron-store@8.0.1`。

**完整链路**：

```
Home.vue 输入 key/value → 点击「写入」
   → this.$ipcRenderer.send('setStore', key, value)
   → ipcFun.js initStore() 里 ipcMain.on('setStore', (_,k,v)=>store.set(k,v))
读取：Home.vue sendSync('getStore', key)
   → ipcMain.on('getStore', (_,k)=>{ _.returnValue = store.get(k) })
```

**涉及文件**：`src/renderer/views/Home.vue`（触发）→ `src/renderer/utils/ipc/ipcFun.js`（`initStore` 注册通道）→ `src/renderer/utils/ipc/index.js`（`toInitStore`）→ `src/main/services/windowManager.js`（`toInitStore()` 调用）。

**关键代码**（ipcFun.js 摘录）：

```js
const Store = require('electron-store')
const store = new Store()

export function initStore() {
  ipcMain.on('setStore', (_, key, value) => { store.set(key, value) })
  ipcMain.on('getStore', (_, key) => {
    let value = store.get(key)
    _.returnValue = value || ''
  })
  ipcMain.on('getAllStore', (_, key) => { _.returnValue = store.store || {} })
  ipcMain.on('deleteOne', (_, key) => { store.delete(key) })
  ipcMain.on('deleteAll', (_) => { store.clear() })
}
```

> `initStore()` 在主进程 `windowManager.js` 的 `createMainWindow()` 里被 `toInitStore()` 调用一次，之后所有渲染进程都能用这 5 个通道读写本地数据。

### 11.8 补充机制：国产化系统检测 + 版本识别

这是 UOS 版骨架的重点。**链路**：`src/renderer/utils/ipc/systemDetect.js`（检测核心，主+渲染共用）→ 主进程 `ipcMain.js` 的 `get-system-info` / `get-system-summary` 通道 → 渲染进程 `systemInfo.js` 封装 → `Home.vue` 展示。

- 可识别：UOS（统信）、麒麟、CPU 架构（鲲鹏/飞腾/海光/兆芯/龙芯/x86/arm64 等）。
- 版本识别走 `src/main/utils/installVersion.js`（四层优先级：热更新元数据 → 安装目录 package.json → app.getVersion() → 0.0.0）。

---

## 十二、配置项说明

### 12.1 环境变量

| 文件 | 何时加载 |
|------|----------|
| `env/.env` | `npm run dev` |
| `env/production.env` | `npm run build` |
| `env/test.env` | `npm run build:test` |
| `.env.development` | 前端开发辅助变量（`VUE_APP_*`） |

内容挂载到 **`process.env.userConfig`**（主/渲染进程都能访问）。骨架默认值为占位地址，请改成实际地址。

### 12.2 IPC 通信与沙箱安全（重点）

Electron 应用 = 1 个**主进程**（能访问操作系统全部能力）+ N 个**渲染进程**（跑 Vue 页面，默认什么系统能力都没有）。两者间唯一通信方式是 IPC。

骨架安全配置（`windowManager.js`）：`contextIsolation: false` + `nodeIntegration: true`，
渲染进程可直接 `require('electron')` 拿到 `ipcRenderer`，无需 contextBridge 桥接。
挂载点：`src/renderer/main.js` 里 `Vue.prototype.$ipcRenderer = ipcRenderer`，页面用 `this.$ipcRenderer` 调用。

**新增一条 IPC 的步骤**：
1. `src/main/services/ipcMain.js` 注册 `ipcMain.handle('my:thing', ...)`（或 `ipcMain.on`）
2. 页面 `this.$ipcRenderer.invoke('my:thing')`（或 `send` / `sendSync`）

**三种通信模式**（详见第七节「机制①」的完整链路）：

| 模式 | 渲染进程 | 主进程 | 场景 |
|------|---------|--------|------|
| 请求/响应 | `invoke` → Promise | `ipcMain.handle` | 取数据 |
| 单向发送 | `send` | `ipcMain.on` | 触发动作 |
| 主进程推送 | `on`（组件销毁时移除监听） | `webContents.send` | 进度上报、深链下发 |

> ⚠️ 安全提示：`contextIsolation:false + nodeIntegration:true` 只适合加载**可信内容**（内部工具、企业应用）。若需加载不可信外部网页，请切换 `contextIsolation:true + contextBridge` 白名单方案（`preload.js` 头部有完整对比说明）。

内置通道速查（完整列表见 `ipcMain.js`）：`get-version`、`get-system-info`、`get-system-summary`、
`get-install-version`、`get-app-path`、`windows-mini`/`window-max`/`window-hide`/`window-refresh`、
`window-close`、`check-update`/`start-update`/`confirm-update`、`hot-update`/`start-hot-update`/`confirm-hot-update`、
`files-download`/`start-download`、`open-messagebox`/`open-errorbox`/`open-directory`、`open-win`、
`get-log-path`/`open-log-folder`/`get-log-files`、`file:select`/`file:readChunk`、
`setStore`/`getStore`/`deleteOne`/`deleteAll`/`getAllStore`。Demo 页 `Home.vue` 逐卡片演示全部通道。

### 12.3 深链唤起（myapp://）

Linux/UOS 通过 desktop 文件声明协议，骨架已配好两处（详见第七节「机制⑤」，含完整链路代码）：

1. `package.json` → `build.linux.desktop.MimeType = "x-scheme-handler/myapp;"`
2. `build/shell/myapp.desktop` → `MimeType=x-scheme-handler/myapp;` 且 `Exec=/opt/myapp/myapp %U`（`%U` 表示把 URL 作为参数传入）

链路：浏览器点击 `myapp://xxx` → 系统按 desktop 声明启动应用，URL 进入 `process.argv`
→ `index.js` 的 `handleDeepLink` 解析 → `webContents.send('deep-link-params', params)`
→ 页面监听 `deep-link-params` 事件接收（Home.vue 第⑤卡片演示）。

已运行时再次点击：单实例锁触发 `second-instance`，URL 在其 `argv` 参数里，由 `index.js` 的 `second-instance` 处理器调用 `handleDeepLink`。

> UOS 上安装后若点击协议链接无反应，执行 `update-desktop-database` 刷新桌面数据库，或注销重登一次桌面会话。

### 12.4 iframe 内嵌网页

骨架通过 `webviewTag:true` + 独立 `/iframe` 路由实现 iframe 内嵌（详见第七节「机制⑥」，含完整链路代码）。目标站点带 `X-Frame-Options` / CSP `frame-ancestors` 头时 iframe 打不开，处理方案：

| 方案 | 位置 | 适用 |
|------|------|------|
| 系统浏览器打开 | 在 `Home.vue` 用 `shell.openExternal` 或系统默认方式 | 不可控第三方站点 |
| 应用内子窗口 | `windowManager.js` 的 `open-win` IPC | 要应用内体验但对方有防护头 |
| 剥离响应头嵌 iframe | 主进程 `session.webRequest.onHeadersReceived` | 你有权嵌入的站点（骨架未内置，需按需加） |

页面正常写 `<iframe>` 或走 `/iframe` 路由即可（Home.vue 第⑥卡片演示）。

### 12.5 首屏加载优化（启动屏）

骨架已实现"秒开"体验：启动时先弹启动屏（毫秒级），主窗口 `show:false` 后台加载，`dom-ready` 后显示主窗口并关闭启动屏。

- 代码：`src/main/services/windowManager.js` 的 `loadingWindow()` / `loadingOtherWindow()` / `initWindow()`
- 开关：`src/main/config/const.js` 的 `UseStartupChart: true`
- 路径：`src/main/config/StaticPath.js` 的 `loadingURL` 区分开发（dev-server）/生产（resources/static/）
- 配套：`backgroundColor` 防闪帧、路由懒加载 `() => import(...)` 减小首屏 chunk

### 12.6 打包体积与速度优化

| 配置 | 当前值 | 说明 |
|------|--------|------|
| `asar: false` | 不打 asar | 配合热更新直接覆盖文件；不需要热更可改 true |
| `compression: store` | 不压缩 | 打包快体积大；要小体积改 maximum |
| `linux.asarUnpack` | `*.node`/`*.so` | 原生模块必须解包才能 dlopen |
| `deb.compression: xz` | xz 压缩 | deb 包体压缩格式 |
| `files` 排除 | map/日志/文档 | 安装包更干净 |

### 12.7 版本号机制

版本识别有四层优先级（`src/main/utils/installVersion.js`）：热更新元数据 → 安装目录 package.json → `app.getVersion()` → 默认 `0.0.0`。发版只需改 `package.json` 的 `version` 再打包。渲染进程走 `get-version`（sendSync）或 `get-install-version`（invoke）IPC 读取。

---

## 十三、系统调优与常见报错处理

### 13.1 文件监听数量不足（ENOSPC）

见 6.5 节，`fs.inotify.max_user_watches=524288`。

### 13.2 缺少 deepin 脚本

若系统缺少 `deepin-security-dpkg-post-hook.sh`，需复制一份到 `/usr/bin/` 并赋权：

```bash
chmod 777 /usr/bin/deepin-security-dpkg-post-hook.sh
```

### 13.3 cross-env 软链接失效

报错类似：

```
node_modules/.bin/cross-env: ../cross-env/src/bin/cross-env.js: not found
```

**处理**：进入 `node_modules/.bin` 目录执行 `npm rebuild` 重建软链接。根因多是 node_modules 从其他系统拷贝导致软链接失效，最稳妥的做法是在目标机器上重新 `npm install`。

### 13.4 静态资源 404（打包后路径变化）

报错类似：

```
GET /home/xxx/resources/app/dist/electron/static/xxx/yyy.js net::ERR_ABORTED 404
```

**原因**：打包后静态资源位于安装目录，与开发环境的相对路径不同。

**处理**：不要写死相对路径，通过 IPC 动态获取应用路径再拼接（见附录 15.2）。

### 13.5 fpm 下载失败 / 报 zlib 错

- 设置 `export USE_SYSTEM_FPM=true`（写入 ~/.bashrc）使用系统 fpm；
- 缺 zlib 时 `sudo apt install zlib1g-dev` 或按 4.5 节源码安装后重装 fpm。

---

## 十四、常见问题速查表

| 问题 | 解决方案 |
|------|----------|
| Node 装不上 / `nvm ls` 为空 | 确认按 3.2 节手动解压并重命名为 `v16.20.2`，且架构是 arm64 |
| `git` 命令找不到 | 确认 `/etc/profile` 或 `~/.bashrc` 已写入 export 并 source |
| 打包报 `Need executable 'ar'` | `sudo apt install binutils` |
| 打包报 `EACCES permission denied` | `chmod -R 777` 项目目录和 node_modules |
| 启动报 `ENOSPC file watchers` | `fs.inotify.max_user_watches=524288` + `sysctl -p` |
| fpm 下载失败 | `export USE_SYSTEM_FPM=true` 使用系统 fpm |
| fpm 报 zlib 错误 | 安装 `zlib1g-dev` 后重装 fpm |
| `cross-env.js not found` | 进 `node_modules/.bin` 执行 `npm rebuild`，或重装依赖 |
| electron 下载超时 | 配镜像，或拷贝有网机器的 `~/.cache/electron` 与 `~/.cache/electron-builder` |
| 静态资源 404 | 通过 IPC 获取 app path 动态拼接（见附录） |
| deb 装完桌面无图标 | 检查 `extraFiles` 是否包含 build/shell（骨架已配置），确认 postinst.sh 有执行权限 |
| x86 机器打 arm64 包失败 | 不支持，必须在 ARM64 机器上打包 |

---

## 十五、附录：Windows 代码移植到 UOS 的适配要点

从 Windows 移植到 UOS 时，最大的坑是「路径」：Windows 用反斜杠，UOS 用正斜杠；且打包后静态资源路径与开发环境不同。**原则：所有路径都不要写死，通过 IPC 向主进程要应用路径再拼接。**

### 15.1 主进程提供路径查询 IPC（骨架已内置）

骨架的 `src/main/services/ipcMain.js` **已经内置了 `get-app-path` 通道**（返回 `app.getAppPath()`），无需自行添加：

```js
// src/main/services/ipcMain.js 中已有
ipcMain.handle('get-app-path', () => app.getAppPath())
```

### 15.2 渲染进程动态拼路径（以加载 static 下的文件为例）

```js
data() {
  return {
    resultPath: ''
  }
},

async mounted() {
  await this.fetchAppPath()
  // 生产环境拼接安装目录下的 static 资源
  let proUrl = this.resultPath + '/static/vditor'
},

methods: {
  async fetchAppPath() {
    let result = await this.$ipcRenderer.invoke('get-app-path')
    let char = '/'
    let lastIndex = result.lastIndexOf(char)
    this.resultPath = lastIndex !== -1 ? result.slice(0, lastIndex) : result
  }
}
```

### 15.3 下载本地静态文件（区分开发/生产路径）

```js
async handleDownloadItem(item) {
  // 开发环境相对路径
  let urlTest = `../../../../static/file/${item.value}`
  await this.fetchAppPath()
  // 生产环境安装目录路径
  let urlPro = this.resultPath + `/static/file/${item.value}`
  let url = process.env.userConfig.NODE_ENV === 'development' ? urlTest : urlPro

  let link = document.createElement('a')
  link.style.display = 'none'
  link.href = url
  link.setAttribute('download', `${item.name}`)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}
```

---

## 附：项目脚本速查表

| 命令 | 作用 |
|------|------|
| `npm run dev` | 启动开发环境（热重载） |
| `npm run build` / `build:linux` | 打包 ARM64 deb |
| `npm run build:test` | 测试环境打包 |
| `npm run build:dir` | 只解包不压 deb（调试） |
| `npm run build:clean` | 清理编译产物 |
| `npm run pack:resources` | 打包热更新增量资源 |
| `npm run update:serve` | 启动本地更新模拟服务器（25565 端口） |
| `npm run build-icon` | 由 icon.png 生成 hicolor 图标目录 |

---

*Windows 环境的搭建与 NSIS 打包请参阅同目录下 `electron-vue-skeleton-win/README.md`。*
