

<div align="center">
<img align="center" src="./assets/images/web_hi_res_512.png" alt="icon" height=200/>
<br/><br/>
<h1 align="center">体温打卡</h1>

<b>电子科大研究生系统一键体温打卡和报平安。</b><br>
<i>提示：请使用系统浏览器进行下载，微信浏览器不会响应下载请求。</i>
<p>下载安装（需梯子）：<a href="https://github.com/Yidadaa/Auto-Check-Temperature/releases/latest/download/app-arm64-v8a-release.apk">arm 64 位版本（推荐）</a> | <a href="https://github.com/Yidadaa/Auto-Check-Temperature/releases/latest/download/app-armeabi-v7a-release.apk">arm 32 位版本</a> | <a href="https://github.com/Yidadaa/Auto-Check-Temperature/releases/latest/download/app-x86_64-release.apk">x86 64 位版本</a> </p>
<p>镜像加速（很稳定）：<a href="https://gitee.com/yidadaa/Auto-Check-Temperature/attach_files/583736/download/app-arm64-v8a-release.apk">arm 64 位版本（推荐）</a> | <a href="https://gitee.com/yidadaa/Auto-Check-Temperature/attach_files/583735/download/app-armeabi-v7a-release.apk">arm 32 位版本</a> | <a href="https://gitee.com/yidadaa/Auto-Check-Temperature/attach_files/583737/download/app-x86_64-release.apk">x86 64 位版本</a> </p>


<img align="center" src="./assets/images/screenshot-1.png" alt="screenshot-1"/>
<img align="center" src="./assets/images/screenshot-2.png" alt="screenshot-2"/>
</div>

<br/>

## 安装提示
对于大多数用户，请优先尝试安装 arm 64 版本；如果安装失败，请尝试 arm 32 位版本。X86 64 位版本一般用不到，可以忽略。

**提示：Github Releases 服务在国内属于被墙状态，所以建议使用<a href="https://gitee.com/yidadaa/Auto-Check-Temperature/releases">国内镜像仓库</a>下载安装包。**

## 常见问题
这里总结了一些使用过程中可能遇到的问题，如果以下解决方案不能满足你的需求，请在 Issue 区附截图提出或者给作者发邮件。
### 为什么明明点击了登录按钮却不会自动跳转到打卡页面？
可以使用右上角的刷新按钮刷新下页面，或者重新登录试试。

### 为什么不做成爬虫的形式？
体温打卡使用了学校的信息门户验证系统，爬虫需要处理“滑动人机验证”，比较繁琐，所以目前是在 Webview 中注入 Javascript 的方式发送打卡请求。

### 账号密码存储在本地安全吗？
本应用使用 [SharedPreferences](https://juejin.cn/search?query=SharedPreferences&type=all) 进行存储，卸载应用后，相应数据会一并清除，在这里可以了解 SharedPreferences 的原理：[SharedPreferences](https://juejin.cn/search?query=SharedPreferences&type=all)。

## 功能
1. 自动填充账号密码（完全本地存储，具体可看源码）；
2. 一键报平安和三次体温打卡，节省宝贵生命，有这时间为啥不去摸鱼呢（呲牙）。

## 开发

这是一个 Flutter 项目，请参照下方文档链接配置 Flutter 开发环境。

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
