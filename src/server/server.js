/**
 * 量潮商务云共享数据服务（v0.1）
 *
 * 零依赖 Node.js 单文件：业务/报价/合同的增删改查，
 * 数据整体存为一个 JSON 文件（原子写盘），多人通过同一服务端读写实现共享。
 *
 * 环境变量：
 *   PORT             监听端口（默认 8787）
 *   QTBUS_TOKEN      访问令牌；设置后所有接口需带 X-Auth-Token 头（health 除外）
 *   QTBUS_DATA_DIR   数据目录（默认 ./data），状态文件为 state.json
 *   QTBUS_SEED       首次启动的种子数据路径（默认 ../studio/assets/data/seed_business.json）
 *   QTBUS_CORS       允许的跨域来源（默认 *）
 */

'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT || 8787);
const TOKEN = process.env.QTBUS_TOKEN || '';
const DATA_DIR = process.env.QTBUS_DATA_DIR || path.join(__dirname, 'data');
const STATE_FILE = path.join(DATA_DIR, 'state.json');
const SEED_FILE = process.env.QTBUS_SEED || path.join(__dirname, '..', 'studio', 'assets', 'data', 'seed_business.json');
const CORS_ORIGIN = process.env.QTBUS_CORS || '*';
const BODY_LIMIT = 5 * 1024 * 1024;

// ---------- 存储层：内存态 + 串行化原子落盘 ----------

let state = null;
let writeChain = Promise.resolve();

function emptyState() {
  return { businesses: [], quotations: [], contracts: [], templates: [] };
}

function initState() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (fs.existsSync(STATE_FILE)) {
    try {
      state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
      if (!Array.isArray(state.history)) state.history = [];
      console.log(`[store] 已加载 ${STATE_FILE}`);
      return;
    } catch (e) {
      console.error(`[store] 状态文件解析失败，改用 seed 覆盖：${e.message}`);
    }
  }
  state = emptyState();
  if (fs.existsSync(SEED_FILE)) {
    const seed = JSON.parse(fs.readFileSync(SEED_FILE, 'utf8'));
    // 只取集合字段，避免种子里的注释性内容混入
    state = {
      businesses: Array.isArray(seed.businesses) ? seed.businesses : [],
      quotations: Array.isArray(seed.quotations) ? seed.quotations : [],
      contracts: Array.isArray(seed.contracts) ? seed.contracts : [],
      templates: Array.isArray(seed.templates) ? seed.templates : [],
      history: [],
    };
    console.log(`[store] 以 seed 初始化：${SEED_FILE}`);
  } else {
    console.log('[store] 无 seed，以空数据启动');
  }
  persistNow();
}

function persistNow() {
  const tmp = STATE_FILE + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(state));
  fs.renameSync(tmp, STATE_FILE);
}

/// 所有写操作经此串行执行，避免并发交叉写坏 JSON
function enqueueWrite(fn) {
  writeChain = writeChain.then(fn).catch((e) => {
    console.error('[store] 写入失败：', e.message);
  });
  return writeChain;
}

// ---------- 业务规则 ----------

function findIndex(list, id) {
  return list.findIndex((x) => x && x.id === id);
}

function insertFront(list, entity) {
  list.unshift(entity);
}

/// 操作留痕（可审计）：所有增删改记一笔，最多保留 200 条
function recordHistory(collection, action, name, extra) {
  const labels = {
    businesses: '业务',
    quotations: '报价',
    contracts: '合同',
  };
  if (!Array.isArray(state.history)) state.history = [];
  state.history.unshift({
    time: nowStr(),
    action,
    entity: labels[collection] || collection,
    name: name || '',
    ...(extra || {}),
  });
  if (state.history.length > 200) state.history.length = 200;
}

function nowStr() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return (
    `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ` +
    `${p(d.getHours())}:${p(d.getMinutes())}`
  );
}

function deleteBusinessCascade(id) {
  state.businesses = state.businesses.filter((b) => b.id !== id);
  state.quotations = state.quotations.filter((q) => q.businessId !== id);
  state.contracts = state.contracts.filter((c) => c.businessId !== id);
}

// ---------- HTTP 工具 ----------

function sendJson(res, status, body) {
  const data = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': CORS_ORIGIN,
  });
  res.end(data);
}

function corsPreflight(res) {
  res.writeHead(204, {
    'Access-Control-Allow-Origin': CORS_ORIGIN,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Auth-Token',
    'Access-Control-Max-Age': '86400',
  });
  res.end();
}

function authorized(req) {
  if (!TOKEN) return true;
  return req.headers['x-auth-token'] === TOKEN;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > BODY_LIMIT) {
        reject(new Error('body too large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function validId(id) {
  return typeof id === 'string' && /^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/.test(id);
}

async function parseEntity(req) {
  const raw = await readBody(req);
  let body;
  try {
    body = JSON.parse(raw || '{}');
  } catch (_) {
    throw new HttpError(400, '请求体不是合法 JSON');
  }
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new HttpError(400, '请求体应为对象');
  }
  if (!validId(body.id)) throw new HttpError(400, `id 缺失或不合法：${body.id}`);
  return body;
}

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

// ---------- 路由 ----------

async function route(req, res, pathname) {
  const method = req.method;

  if (pathname === '/api/health') {
    return sendJson(res, 200, { ok: true, version: 'v0.1' });
  }

  if (!authorized(req)) return sendJson(res, 401, { error: '未授权' });

  if (method === 'GET' && pathname === '/api/state') {
    return sendJson(res, 200, state);
  }

  const m = pathname.match(/^\/api\/(businesses|quotations|contracts)(?:\/([^/]+))?$/);
  if (!m) return sendJson(res, 404, { error: 'not found' });
  const collection = m[1];
  const idInPath = m[2];

  if (method === 'POST' && !idInPath) {
    const entity = await parseEntity(req);
    if (findIndex(state[collection], entity.id) !== -1) {
      return sendJson(res, 409, { error: `id 已存在：${entity.id}` });
    }
    return enqueueWrite(() => {
      insertFront(state[collection], entity);
      recordHistory(collection, '新建', entity.name);
      persistNow();
    }).then(() => sendJson(res, 200, entity));
  }

  if (method === 'PUT' && idInPath) {
    const i = findIndex(state[collection], idInPath);
    if (i === -1) return sendJson(res, 404, { error: `不存在：${idInPath}` });
    const entity = await parseEntity(req);
    if (entity.id !== idInPath) {
      return sendJson(res, 400, { error: 'URL id 与请求体 id 不一致' });
    }
    return enqueueWrite(() => {
      const j = findIndex(state[collection], idInPath);
      if (j !== -1) state[collection][j] = entity;
      recordHistory(collection, '修改', entity.name);
      persistNow();
    }).then(() => sendJson(res, 200, entity));
  }

  if (method === 'DELETE' && idInPath) {
    if (collection === 'businesses') {
      const i = findIndex(state.businesses, idInPath);
      if (i === -1) return sendJson(res, 404, { error: `不存在：${idInPath}` });
      return enqueueWrite(() => {
        const j = findIndex(state.businesses, idInPath);
        if (j !== -1) {
          const b = state.businesses[j];
          const qCount = state.quotations.filter((q) => q.businessId === b.id).length;
          const cCount = state.contracts.filter((c) => c.businessId === b.id).length;
          deleteBusinessCascade(idInPath);
          recordHistory('businesses', '删除', b.name, {
            detail: `名下 ${qCount} 个报价、${cCount} 个合同一并删除`,
          });
        }
        persistNow();
      }).then(() => sendJson(res, 200, { ok: true }));
    }
    const i = findIndex(state[collection], idInPath);
    if (i === -1) return sendJson(res, 404, { error: `不存在：${idInPath}` });
    return enqueueWrite(() => {
      const j = findIndex(state[collection], idInPath);
      if (j !== -1) {
        const e = state[collection][j];
        state[collection].splice(j, 1);
        recordHistory(collection, '删除', e.name);
      }
      persistNow();
    }).then(() => sendJson(res, 200, { ok: true }));
  }

  return sendJson(res, 405, { error: 'method not allowed' });
}

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') return corsPreflight(res);
  const pathname = decodeURIComponent((req.url || '/').split('?')[0]);
  route(req, res, pathname).catch((e) => {
    if (e instanceof HttpError) return sendJson(res, e.status, { error: e.message });
    console.error('[server] 未处理错误：', e);
    return sendJson(res, 500, { error: 'internal error' });
  });
});

initState();
server.listen(PORT, () => {
  console.log(`[server] 量潮商务云数据服务 v0.1 监听 :${PORT}（鉴权：${TOKEN ? '开' : '关'}）`);
});

// 优雅退出前落盘兜底（正常路径每次写完即落盘，这里仅防御）
function shutdown(signal) {
  console.log(`[server] 收到 ${signal}，退出`);
  try {
    persistNow();
  } catch (_) {}
  process.exit(0);
}
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
