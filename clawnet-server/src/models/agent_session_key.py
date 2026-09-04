"""
Agent Session Key 持久化模型 / EN: Agent Session Key persistence model

记录每个「用户 ↔ Agent」的 OpenClaw session key 及 Gateway 连接信息， / EN: Record the OpenClaw session key and Gateway connection information of each "User ↔ Agent",
供外挂程序直接从数据库读取。 / EN: For plug-in programs to read directly from the database.
"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, Text, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from src.database import Base


class AgentSessionKey(Base):
    __tablename__ = "agent_session_keys"
    __table_args__ = (
        UniqueConstraint("user_id", "agent_id", name="uq_user_agent"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )
    agent_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("agents.id", ondelete="CASCADE"),
        nullable=False,
    )
    session_key: Mapped[str] = mapped_column(
        String(255), nullable=False,
    )
    gateway_ws_url: Mapped[str] = mapped_column(
        Text, nullable=False,
    )
    gateway_token: Mapped[str] = mapped_column(
        String(255), nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
