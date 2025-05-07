-- CREATE DATABASE IF NOT EXISTS irich CHARACTER 
-- SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- USE irich;

-- CREATE TABLE IF NOT EXISTS provider (
--     id INT UNSIGNED NOT NULL AUTO_INCREMENT,
--     name VARCHAR(20) NOT NULL COMMENT '供应商名称',
--     weight TINYINT DEFAULT 1 COMMENT '权重',
--     cookie TEXT DEFAULT '' comment 'cookie',
--     PRIMARY KEY (id),
--     UNIQUE KEY uk_name (name)  -- 供应商名称应该唯一
-- ) ENGINE = InnoDB COMMENT = '数据供应商列表';

-- CREATE TABLE IF NOT EXISTS api (
--     id INT UNSIGNED NOT NULL AUTO_INCREMENT,
--     name VARCHAR(20) NOT NULL COMMENT 'API 接口名称',
--     PRIMARY KEY (id),
--     UNIQUE KEY uk_name (name)  -- 接口名称应该唯一
-- ) ENGINE = InnoDB COMMENT = '接口列表';

-- CREATE TABLE IF NOT EXISTS provider_api (
--     id INT UNSIGNED NOT NULL AUTO_INCREMENT,  -- 建议添加自增主键
--     provider_id INT UNSIGNED NOT NULL COMMENT '供应商ID',
--     api_id INT UNSIGNED NOT NULL COMMENT '接口ID',
--     weight TINYINT DEFAULT 1 COMMENT '权重',
--     PRIMARY KEY (id),
--     UNIQUE KEY uk_provider_api (provider_id, api_id),  -- 防止重复关联
--     CONSTRAINT fk_provider FOREIGN KEY (provider_id) REFERENCES provider(id) ON DELETE CASCADE,
--     CONSTRAINT fk_api FOREIGN KEY (api_id) REFERENCES api(id) ON DELETE CASCADE
-- ) ENGINE = InnoDB COMMENT = '供应商-接口关联表';

-- CREATE TABLE IF NOT EXISTS request_log (
--     id INT UNSIGNED NOT NULL AUTO_INCREMENT,
--     provider_id INT UNSIGNED NOT NULL COMMENT '供应商ID',
--     api_id INT UNSIGNED NOT NULL COMMENT '接口ID',
--     url VARCHAR(500) NOT NULL COMMENT '请求URL',
--     status TINYINT(1) DEFAULT 0 COMMENT '0=请求失败，1=请求成功',
--     created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
--     PRIMARY KEY (id),
--     INDEX idx_provider (provider_id),  -- 添加索引提高查询性能
--     INDEX idx_api (api_id),
--     INDEX idx_created_at (created_at),
--     CONSTRAINT fk_log_provider FOREIGN KEY (provider_id) REFERENCES provider(id),
--     CONSTRAINT fk_log_api FOREIGN KEY (api_id) REFERENCES api(id)
-- ) ENGINE = InnoDB COMMENT = '接口请求日志表';


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