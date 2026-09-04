-- 007_discovery_task.sql
-- 多用户发现任务表：管理链式/并行 A2A 对话编排 | EN: Multi-user discovery task list: managing chained/parallel A2A conversation orchestration

CREATE TABLE IF NOT EXISTS discovery_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 关联原始会话 | EN: Relate original session
    source_conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,

    -- 发起方 | EN: Initiator
    initiator_agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    initiator_owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 状态 | EN: state
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'running', 'completing', 'completed', 'cancelled', 'failed')),
    original_intent TEXT NOT NULL,

    -- 限制 | EN: limit
    max_hops INTEGER NOT NULL DEFAULT 5 CHECK (max_hops > 0 AND max_hops <= 10),
    current_hop_count INTEGER NOT NULL DEFAULT 0 CHECK (current_hop_count >= 0),
    max_concurrent INTEGER NOT NULL DEFAULT 2 CHECK (max_concurrent > 0 AND max_concurrent <= 5),

    -- JSON 队列 | EN: JSON queue
    pending_queries JSONB NOT NULL DEFAULT '[]'::jsonb,
    completed_results JSONB NOT NULL DEFAULT '[]'::jsonb,
    active_sessions JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- 乐观锁 | EN: optimistic locking
    version INTEGER NOT NULL DEFAULT 0,

    -- 时间戳 | EN: Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 索引 | EN: index
CREATE INDEX IF NOT EXISTS idx_discovery_tasks_source_conv ON discovery_tasks(source_conversation_id);
CREATE INDEX IF NOT EXISTS idx_discovery_tasks_status ON discovery_tasks(status);
CREATE INDEX IF NOT EXISTS idx_discovery_tasks_initiator_agent ON discovery_tasks(initiator_agent_id);
CREATE INDEX IF NOT EXISTS idx_discovery_tasks_initiator_owner ON discovery_tasks(initiator_owner_id);
CREATE INDEX IF NOT EXISTS idx_discovery_tasks_created ON discovery_tasks(created_at DESC);
-- 查找活跃任务（RUNNING 状态） | EN: Find active tasks (RUNNING status)
CREATE INDEX IF NOT EXISTS idx_discovery_tasks_active ON discovery_tasks(status) WHERE status IN ('pending', 'running', 'completing');
