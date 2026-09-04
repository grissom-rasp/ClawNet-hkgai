-- 008_add_nested_dialog_reason.sql
-- 更新 agent_dialog_sessions 的 termination_reason CHECK 约束， | EN: Update the termination_reason CHECK constraint of agent_dialog_sessions,
-- 新增 'nested_dialog' 枚举值。 | EN: Added 'nested_dialog' enumeration value.
--
-- 背景：002_agent_dialog.sql 使用 CREATE TABLE IF NOT EXISTS， | EN: Background: 002_agent_dialog.sql uses CREATE TABLE IF NOT EXISTS,
-- 修改其中的 CHECK 约束不会在已有数据库上生效，需要 ALTER TABLE。 | EN: Modifying the CHECK constraints will not take effect on the existing database and requires ALTER TABLE.

ALTER TABLE agent_dialog_sessions
  DROP CONSTRAINT IF EXISTS check_valid_termination_reason;

ALTER TABLE agent_dialog_sessions
  ADD CONSTRAINT check_valid_termination_reason CHECK (
    termination_reason IS NULL OR
    termination_reason IN (
      'resolved', 'deadlock', 'rounds_exceeded',
      'owner_terminated', 'owner_rejected',
      'timeout', 'agent_offline', 'nested_dialog'
    )
  );
