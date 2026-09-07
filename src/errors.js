// 面向用户的错误提示与错误分类
// 目的：程序遇到可恢复的常见故障时，不再抛出原始英文报错，
// 而是给出「发生了什么 + 如何修复」的中文指引。

// 连续检测到多少次"页面/浏览器已关闭"类错误后，自动停止轮询
// （默认 3 次 ≈ 3 个轮询周期，约 45 秒），避免无限刷错误日志。
export const CLOSED_ERROR_STOP_THRESHOLD = 3;

// 运行中：闲鱼页面/浏览器被关闭
export const PAGE_CLOSED_HINT = [
  "闲鱼页面或浏览器已被关闭（可能是不小心关掉了 bot 的 Chrome 窗口，或页面崩溃）。",
  "修复方法：",
  "1) 确认没有手动关闭 bot 的 Chrome 窗口（HEADLESS=false 时窗口可见）；",
  "2) 在管理面板点击「启动服务」重新开始；",
  "3) 若提示 Chrome 配置文件被占用，请在项目目录运行 bash restart.sh 一键清理并重启。"
].join("\n");

// 启动时：Chrome 配置文件被另一个实例占用
const PROFILE_LOCK_HINT = [
  "Chrome 配置文件（chrome-profile）被另一个实例占用，通常是上次停止服务时残留的 Chrome 进程没有退出。",
  "修复方法：",
  "1) 在项目目录运行 bash restart.sh（会自动清理残留 Chrome 进程并重启服务）；",
  "2) 或手动关闭所有使用 chrome-profile 的 Chrome 窗口，再重新点击「启动服务」。"
].join("\n");

// 把启动失败的原始错误转成友好的中文提示；无法识别的错误原样返回。
export function describeStartError(message) {
  const msg = String(message || "");
  if (
    /ProcessSingleton/i.test(msg) ||
    /profile directory[\s\S]*already in use/i.test(msg) ||
    /already in use[\s\S]*profile/i.test(msg)
  ) {
    return PROFILE_LOCK_HINT;
  }
  return msg;
}

// 判断错误是否属于"页面/浏览器/上下文已关闭"类
export function isClosedPageError(message) {
  const msg = String(message || "");
  return (
    /\b(?:page|context|browser|target)\b[\s\S]{0,80}\bclosed\b/i.test(msg) ||
    /\bclosed\b[\s\S]{0,80}\b(?:page|context|browser|target)\b/i.test(msg)
  );
}

// 把运行中的可识别错误转成中文提示；无法识别的错误原样返回。
export function describeWorkerError(message) {
  const msg = String(message || "");
  if (/Could not find conversation list/i.test(msg)) {
    return [
      "找不到会话列表。可能原因：闲鱼要求重新登录，或页面结构已变化。",
      "处理方式：",
      "1) 检查 bot 的 Chrome 窗口（HEADLESS=false 时可见），如弹出登录页，请用闲鱼 APP 扫码登录；",
      "2) 确认登录后服务会自动恢复；",
      "3) 若页面已正常登录仍持续报错，可能是闲鱼页面结构变化，需要更新 src/xianyu-page.js 中的选择器。"
    ].join("\n");
  }
  return msg;
}
