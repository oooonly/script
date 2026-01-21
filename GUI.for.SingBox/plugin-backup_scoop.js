/**
 * 插件名称：Scoop Gist 备份管理器
 * 功能：通过 Gist 实现 Scoop 配置的安全备份、恢复与管理
 */

// 插件元信息
const onRun = async () => {
  const action = await Plugins.picker.single(
    '请选择操作',
    [
      { label: '立即备份', value: 'backup' },
      { label: '同步至本地', value: 'restore' },
      // { label: '查看备份列表', value: 'list' },
      { label: '管理备份列表', value: 'manage' }
    ],
    []
  )

  const handler = {
    backup: onBackup,
    restore: onRestore,
    list: ()=>{},
    manage: onManage
  }

  await handler[action]()
}

// 依赖路径
const PATH = 'data/third/scoop-gist-backup';
const JS_FILE = PATH + '/crypto-js.js';

// Gist API 地址
const GIST_API = 'https://api.github.com/gists';

// 确保目录存在
async function ensureDir() {
  await window.Plugins.MakeDir(PATH);
  await window.Plugins.MakeDir('/data/backups');
}

// 动态加载 CryptoJS
async function loadCryptoJS() {
  if (window.CryptoJS) return;

  try {
    const scriptText = await window.Plugins.ReadFile(JS_FILE);
    const script = document.createElement('script');
    script.id = 'plugin-scoop-backup-gist-crypto';
    script.textContent = scriptText;
    document.head.appendChild(script);
  } catch (err) {
    throw new Error('加密库加载失败，请重新安装插件');
  }
}

// 加密数据
function encrypt(data) {
  if (!Plugin.Secret) throw '未配置加密密钥';
  return window.CryptoJS.AES.encrypt(data, Plugin.Secret).toString();
}

// 解密数据
function decrypt(data) {
  if (!Plugin.Secret) throw '未配置加密密钥';
  return window.CryptoJS.AES.decrypt(data, Plugin.Secret).toString(window.CryptoJS.enc.Utf8);
}

// HTTP 请求封装
async function httpGet(url, headers = {}) {
  const opts = {
    'User-Agent': 'GUI.for.Cores',
    'X-GitHub-Api-Version': '2022-11-28',
    Accept: 'application/vnd.github+json',
    Authorization: 'Bearer ' + Plugin.Token,
    ...headers
  };
  const { body } = await window.Plugins.HttpGet(url, opts);
  if (body.message) throw new Error(body.message);
  return body;
}

async function httpPost(url, data, headers = {}) {
  const opts = {
    'User-Agent': 'GUI.for.Cores',
    'Content-Type': 'application/json',
    'X-GitHub-Api-Version': '2022-11-28',
    Accept: 'application/vnd.github+json',
    Authorization: 'Bearer ' + Plugin.Token,
    ...headers
  };
  const { body } = await window.Plugins.HttpPost(url, opts, data);
  if (body.message) throw new Error(body.message);
  return body;
}

async function httpDelete(url, headers = {}) {
  const opts = {
    'User-Agent': 'GUI.for.Cores',
    'X-GitHub-Api-Version': '2022-11-28',
    Accept: 'application/vnd.github+json',
    Authorization: 'Bearer ' + Plugin.Token,
    ...headers
  };
  const { body } = await window.Plugins.HttpDelete(url, opts);
  if (body.message) throw new Error(body.message);
  return body;
}

// 生成带时间戳的文件名
function generateFilename() {
  const now = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `scoop_backup_${now.getFullYear()}-${pad(now.getMonth()+1)}-${pad(now.getDate())}-${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}.json`;
}

// 筛选出scoop备份
const filterList = (list) => {
  return list
    .filter(g => g.description.includes('Scoop Backup'))
    .map(g => ({
      label: `${g.description}`,
      value: g.id
    }));
}

// ============ 菜单功能实现 ============

// 备份：导出 scoop 配置 -> 加密 -> 上传 Gist
const onBackup = async () => {
  try {
    await ensureDir();
    await loadCryptoJS();

    // 1. 执行 scoop export
    const result = await window.Plugins.Exec('scoop', ['export'], { Convert: true });
    const filename = generateFilename();
    const localPath = `/data/.cache/${filename}`;

    // 2. 本地保存原始文件（可选）
    await window.Plugins.WriteFile(localPath, result);

    // 3. 加密内容
    const encrypted = encrypt(result);

    // 4. 上传到 Gist
    const { id } = window.Plugins.message.info('正在上传...', 60000);
    await httpPost(GIST_API, {
      description: `Scoop Backup - ${new Date().toLocaleString()}`,
      public: false,
      files: {
        [filename]: { content: encrypted }
      }
    });

    window.Plugins.message.update(id, '✅ 备份成功', 'success');
    setTimeout(() => window.Plugins.message.destroy(id), 1500);
    await window.Plugins.RemoveFile(localPath)
    
  } catch (err) {
    console.error('备份失败:', err);
    window.Plugins.message.error('备份失败: ' + err.message);
  }
};

// 恢复：列出 Gist -> 选择 -> 下载 -> 解密 -> 执行 scoop import
const onRestore = async () => {
  try {
    await loadCryptoJS();
    
    const res = await httpGet(GIST_API);
    const backups = filterList(res)

    if (backups.length === 0) {
      window.Plugins.message.info('没有找到可用的备份');
      return;
    }

    const selected = await window.Plugins.picker.single('请选择要恢复的备份', backups).catch(err => {
      window.Plugins.message.error(err)
    });
    if (!selected) return
    
    const gist = backups.find(b => b.value === selected);
    const filename = Object.keys(gist.files).find(k => k.endsWith('.json'));
    const rawUrl = gist.files[filename].raw_url;

    const { body: encrypted } = await window.Plugins.HttpGet(rawUrl);
    const decrypted = decrypt(encrypted);

    // 保存临时文件用于导入
    const tempPath = `/data/.cache/scoop_temp_restore.json`;
    await window.Plugins.WriteFile(tempPath, decrypted);

    // 执行恢复
    await window.Plugins.Exec('scoop', ['import', tempPath], { Convert: true });
    window.Plugins.message.success('🎉 恢复完成！');
    await window.Plugins.RemoveFile(tempPath)
    
  } catch (err) {
    console.error('恢复失败:', err);
    window.Plugins.message.error('恢复失败: ' + err.message);
  }
};

// 管理：列出所有备份，支持删除
const onManage = async () => {
  try {
    await loadCryptoJS();
    const res = await httpGet(GIST_API);
    const backups = filterList(res)

    if (backups.length === 0) {
      window.Plugins.message.info('暂无备份');
      return;
    }

    const toDelete = await window.Plugins.picker.multi('选择要删除的备份', backups, []).catch(err => {
      window.Plugins.message.error(err)
    });
    if (!toDelete?.length) return;

    for (const id of toDelete) {
      await httpDelete(`https://api.github.com/gists/${id}`);
      window.Plugins.message.success(`🗑️ 已删除 Gist: ${id}`);
    }
  } catch (err) {
    window.Plugins.message.error('管理失败: ' + err.message);
  }
};

// 插件安装时下载 CryptoJS
const onInstall = async () => {
  await ensureDir();
  await window.Plugins.Download('https://unpkg.com/crypto-js@latest/crypto-js.js', JS_FILE);
  return 0;
};

// 插件卸载时清理文件
const onUninstall = async () => {
  const el = document.getElementById('plugin-scoop-backup-gist-crypto');
  el && el.remove();
  await window.Plugins.RemoveFile(PATH);
  return 0;
};

// 插件准备就绪
const onReady = async () => {
  await loadCryptoJS();
};

// 用于计划任务
const onTask = async () => {
  try {
    // 1. 执行备份操作
    await onBackup();
    // 2. 备份成功后，清理旧备份
    const res = await httpGet(GIST_API);
    const backups = filterList(res);
    // 如果备份数量大于1，说明有旧备份需要删除
    if (backups.length > 1) {
      // 按时间排序（假设 API 返回的列表中，最新的在前面）
      // 为了保险，我们保留列表中的第一个（最新），删除其余所有
      const oldBackups = backups.slice(1); // 从第二个开始截取，都是旧的
      for (const backup of oldBackups) {
        await httpDelete(`https://api.github.com/gists/${backup.value}`);
      }
      
      window.Plugins.message.success(`已清理 ${oldBackups.length} 个旧备份`);
    }
  } catch (err) {
    console.error('计划任务执行失败:', err);
    window.Plugins.message.error('计划任务失败: ' + err.message);
  }
};
