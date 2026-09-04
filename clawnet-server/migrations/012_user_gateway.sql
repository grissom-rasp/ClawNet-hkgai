-- 012_user_gateway.sql
-- 用户 Gateway 自动化 provision 支持 | EN: User Gateway automation provision support
-- 将 gateway 配置从 gateway_users.json 迁移到数据库 | EN: Migrate gateway configuration from gateway_users.json to database

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS slug             VARCHAR(32),
  ADD COLUMN IF NOT EXISTS role             VARCHAR(16) NOT NULL DEFAULT 'user',
  ADD COLUMN IF NOT EXISTS gateway_port     INTEGER UNIQUE,
  ADD COLUMN IF NOT EXISTS gateway_token    VARCHAR(128),
  ADD COLUMN IF NOT EXISTS gateway_env      VARCHAR(32),
  ADD COLUMN IF NOT EXISTS gateway_status   VARCHAR(16) DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS provisioned_at   TIMESTAMPTZ;

-- 加速按环境查询最大端口 | EN: Accelerate querying the maximum port by environment
CREATE INDEX IF NOT EXISTS idx_users_gateway_env ON users(gateway_env);

-- 加速按 role 过滤 | EN: Accelerate filtering by role
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
