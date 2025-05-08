-- 修改后的 irich.sql (SQLite 兼容语法)

CREATE TABLE IF NOT EXISTS provider (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL, -- 供应商名称
    weight INTEGER DEFAULT 1, -- 权重
    cookie TEXT DEFAULT '' -- cookie
);

CREATE TABLE IF NOT EXISTS api (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL -- API 接口名称
);

CREATE TABLE IF NOT EXISTS provider_api (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider_id INTEGER NOT NULL, -- 供应商ID
    api_id INTEGER NOT NULL, -- 接口ID
    weight INTEGER DEFAULT 1, -- 权重
    FOREIGN KEY (provider_id) REFERENCES provider(id) ON DELETE CASCADE,
    FOREIGN KEY (api_id) REFERENCES api(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS request_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider_id INTEGER NOT NULL, -- 供应商ID
    api_id INTEGER NOT NULL, -- 接口ID
    url TEXT NOT NULL, -- 请求URL
    status INTEGER DEFAULT 0, -- 0=请求失败，1=请求成功
    created_at TEXT DEFAULT CURRENT_TIMESTAMP, -- 创建时间
    FOREIGN KEY (provider_id) REFERENCES provider(id),
    FOREIGN KEY (api_id) REFERENCES api(id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_provider_name ON provider(name);
CREATE INDEX IF NOT EXISTS idx_api_name ON api(name);
CREATE INDEX IF NOT EXISTS idx_provider_api ON provider_api(provider_id, api_id);
CREATE INDEX IF NOT EXISTS idx_log_provider ON request_log(provider_id);
CREATE INDEX IF NOT EXISTS idx_log_api ON request_log(api_id);
CREATE INDEX IF NOT EXISTS idx_log_created ON request_log(created_at);