-- 003: 会话软删除支持 | EN: 003: Session soft delete support
-- 在 conversation_participants 上增加 hidden_at 列 | EN: Add hidden_at column on conversation_participants
-- 用户「删除」会话时，只标记当前用户的 hidden_at，不影响其他参与者 | EN: When a user "delete" a session, only the current user's hidden_at is marked and does not affect other participants.

ALTER TABLE conversation_participants
    ADD COLUMN IF NOT EXISTS hidden_at TIMESTAMPTZ DEFAULT NULL;

-- hidden_at IS NOT NULL 表示该用户已「隐藏」此会话 | EN: hidden_at IS NOT NULL means that the user has "hidden" this session
-- 查询时过滤: WHERE hidden_at IS NULL | EN: Query-time filtering: WHERE hidden_at IS NULL
-- 当会话有新消息时，自动重置 hidden_at = NULL（让会话重新出现） | EN: Automatically reset hidden_at = NULL when there are new messages in the session (let the session reappear)

COMMENT ON COLUMN conversation_participants.hidden_at IS '用户隐藏会话的时间，NULL 表示可见';
