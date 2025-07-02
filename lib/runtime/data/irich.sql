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

 CREATE TABLE IF NOT EXISTS share_finance (
  -- 主键ID
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- 基础信息（必须）
  code TEXT NOT NULL COMMENT '股票代码',
  year INTEGER NOT NULL COMMENT '年份',
  quarter INTEGER NOT NULL COMMENT '季度 (1-4)',

  -- 财务指标（必须）
  main_business_income REAL NOT NULL COMMENT '主营收入(万元)',
  main_business_profit REAL NOT NULL COMMENT '主营利润(万元)',
  total_assets REAL NOT NULL COMMENT '总资产(万元)',
  current_assets REAL NOT NULL COMMENT '流动资产(万元)',
  fixed_assets REAL NOT NULL COMMENT '固定资产(万元)',
  intangible_assets REAL NOT NULL COMMENT '无形资产(万元)',
  long_term_investment REAL NOT NULL COMMENT '长期投资(万元)',
  current_liabilities REAL NOT NULL COMMENT '流动负债(万元)',
  long_term_liabilities REAL NOT NULL COMMENT '长期负债(万元)',
  capital_reserve REAL NOT NULL COMMENT '资本公积金(万元)',
  per_share_reserve REAL NOT NULL COMMENT '每股公积金(元)',
  shareholder_equity REAL NOT NULL COMMENT '股东权益(万元)',
  per_share_net_assets REAL NOT NULL COMMENT '每股净资产(元)',
  operating_income REAL NOT NULL COMMENT '营业收入(万元)',
  net_profit REAL NOT NULL COMMENT '净利润(万元)',
  undistributed_profit REAL NOT NULL COMMENT '未分配利润(万元)',
  per_share_undistributed_profit REAL NOT NULL COMMENT '每股未分配利润(元)',
  per_share_earnings REAL NOT NULL COMMENT '每股收益(元)',
  per_share_cash_flow REAL NOT NULL COMMENT '每股现金流(元)',
  per_share_operating_cash_flow REAL NOT NULL COMMENT '每股经营现金流(元)',

  -- 成长能力指标（可选）
  net_profit_growth_rate REAL DEFAULT 0 COMMENT '净利润增长率(%)',
  operating_income_growth_rate REAL DEFAULT 0 COMMENT '营业收入增长率(%)',
  total_assets_growth_rate REAL DEFAULT 0 COMMENT '总资产增长率(%)',
  shareholder_equity_growth_rate REAL DEFAULT 0 COMMENT '股东权益增长率(%)',

  -- 现金流指标（可选）
  operating_cash_flow REAL DEFAULT 0 COMMENT '经营活动产生的现金流量净额(万元)',
  investment_cash_flow REAL DEFAULT 0 COMMENT '投资活动产生的现金流量净额(万元)',
  financing_cash_flow REAL DEFAULT 0 COMMENT '筹资活动产生的现金流量净额(万元)',
  cash_increase REAL DEFAULT 0 COMMENT '现金及现金等价物净增加额(万元)',
  per_share_operating_cash_flow_net REAL DEFAULT 0 COMMENT '每股经营活动产生的现金流量净额(元)',
  per_share_cash_increase REAL DEFAULT 0 COMMENT '每股现金及现金等价物净增加额(元)',
  per_share_earnings_after_non_recurring REAL DEFAULT 0 COMMENT '扣除非经常性损益后的每股收益(元)',

  -- 盈利能力指标（自动计算）
  net_profit_rate REAL COMMENT '净利润率(%) = 净利润/营业收入*100',
  gross_profit_rate REAL COMMENT '毛利率(%) = (营业收入-主营收入)/营业收入*100',
  roe REAL COMMENT '净资产收益率(%) = 净利润/股东权益*100',

  -- 偿债能力指标（自动计算）
  debt_ratio REAL COMMENT '资产负债率(%) = (流动负债+长期负债)/总资产*100',
  current_ratio REAL COMMENT '流动比率 = 流动资产/流动负债',
  quick_ratio REAL COMMENT '速动比率 = (流动资产-固定资产)/流动负债',

  -- 唯一约束：防止同一股票同一季度的数据重复
  UNIQUE(code, year, quarter)
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_share_finance_code ON share_finance(code);
CREATE INDEX IF NOT EXISTS idx_share_finance_year ON share_finance(year);
CREATE INDEX IF NOT EXISTS idx_share_finance_quarter ON share_finance(quarter);
CREATE INDEX IF NOT EXISTS idx_share_finance_code_year_quarter ON share_finance(code, year, quarter);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_provider_name ON provider(name);
CREATE INDEX IF NOT EXISTS idx_api_name ON api(name);
CREATE INDEX IF NOT EXISTS idx_provider_api ON provider_api(provider_id, api_id);
CREATE INDEX IF NOT EXISTS idx_log_provider ON request_log(provider_id);
CREATE INDEX IF NOT EXISTS idx_log_api ON request_log(api_id);
CREATE INDEX IF NOT EXISTS idx_log_created ON request_log(created_at);