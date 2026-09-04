#!/usr/bin/env bash
# =============================================================================
#  ClawNet Backend 管理脚本 | EN: ClawNet Backend Management Script
#
#  用法: | EN: usage:
#    ./clawnet.sh setup   [env]   — 首次初始化（构建镜像 + 启动 + 迁移） | EN: ./clawnet.sh setup [env] — First initialization (build image + startup + migration)
#    ./clawnet.sh rebuild [env]   — 重建容器（复用镜像）+ 迁移 | EN: ./clawnet.sh rebuild [env] — Rebuild container (reuse image) + migrate
#    ./clawnet.sh migrate [env]   — 仅执行数据库迁移 | EN: ./clawnet.sh migrate [env] — Perform database migration only
#    ./clawnet.sh shell   [env]   — 进入后端容器 bash | EN: ./clawnet.sh shell [env] — Enter the backend container bash
#    ./clawnet.sh psql    [env]   — 进入 PostgreSQL 交互终端 | EN: ./clawnet.sh psql [env] — Enter the PostgreSQL interactive terminal
#    ./clawnet.sh logs    [env]   — 查看后端日志（follow） | EN: ./clawnet.sh logs [env] — View backend logs (follow)
#    ./clawnet.sh status  [env]   — 查看容器状态 | EN: ./clawnet.sh status [env] — View container status
#    ./clawnet.sh clean   [env]   — 停止并删除容器和数据卷 | EN: ./clawnet.sh clean [env] — Stop and delete containers and volumes
#
#  [env] 可选，指定 .env 文件名（不含 .env 后缀），默认使用 .env。 | EN: [env] Optional, specify the .env file name (without .env suffix), .env is used by default.
#  例如:  ./clawnet.sh setup test   → 使用 .env.test | EN: For example: ./clawnet.sh setup test → use .env.test
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ---- 解析参数 ---- | EN: ---- Parse parameters ----
CMD="${1:-help}"
ENV_NAME="${2:-}"

if [[ -n "$ENV_NAME" ]]; then
    ENV_FILE=".env.${ENV_NAME}"
else
    ENV_FILE=".env"
fi

# ---- 加载 .env ---- | EN: ---- Load .env ----
if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
else
    if [[ "$CMD" != "help" && "$CMD" != "init" ]]; then
        echo "[WARN] $ENV_FILE not found, using defaults. Run: cp .env.example $ENV_FILE"
    fi
fi

# ---- 派生变量（从 .env 读到的值或默认值）---- | EN: ---- Derived variables (values ​​read from .env or default values) ----
# Docker Compose 未设置 COMPOSE_PROJECT_NAME 时默认用目录名，此处保持一致 | EN: Docker Compose defaults to the directory name when COMPOSE_PROJECT_NAME is not set, which remains consistent here.
PROJECT="${COMPOSE_PROJECT_NAME:-$(basename "$SCRIPT_DIR")}"
PG_CONTAINER="${PROJECT}-postgres"
REDIS_CONTAINER="${PROJECT}-redis"
BACKEND_CONTAINER="${PROJECT}-backend"
PG_USER="${POSTGRES_USER:-clawnet}"
PG_DB="${POSTGRES_DB:-clawnet}"
BE_PORT="${BACKEND_PORT:-9000}"

DC="docker compose --env-file $ENV_FILE"
# 如果 env 文件不存在，不传 --env-file | EN: If the env file does not exist, do not pass --env-file
if [[ ! -f "$ENV_FILE" ]]; then
    DC="docker compose"
fi

# ---- 工具函数 ---- | EN: ---- Tool function ----
header() {
    echo ""
    echo "========================================="
    echo "  ClawNet [$PROJECT] — $1"
    echo "========================================="
}

wait_pg() {
    echo "[*] Waiting for PostgreSQL ($PG_CONTAINER) ..."
    for i in $(seq 1 30); do
        if docker exec "$PG_CONTAINER" pg_isready -U "$PG_USER" -q 2>/dev/null; then
            echo "    PostgreSQL is ready."
            return 0
        fi
        if [[ "$i" -eq 30 ]]; then
            echo "    ERROR: PostgreSQL did not become ready in time."
            return 1
        fi
        sleep 1
    done
}

run_migrations() {
    echo "[*] Running database migrations ..."
    for sql_file in migrations/*.sql; do
        [[ -f "$sql_file" ]] || continue
        filename=$(basename "$sql_file")
        if [[ "$filename" == "001_initial.sql" ]]; then
            continue
        fi
        echo "    Applying $filename ..."
        docker exec -i "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_DB" < "$sql_file" 2>&1 | \
            grep -v "^$" | sed 's/^/      /' || true
    done
    echo "    Migrations done."
}

show_info() {
    echo ""
    echo "  Backend : http://localhost:${BE_PORT}"
    echo "  Logs    : ./clawnet.sh logs${ENV_NAME:+ $ENV_NAME}"
    echo "  Shell   : ./clawnet.sh shell${ENV_NAME:+ $ENV_NAME}"
    echo "  Stop    : ./clawnet.sh down${ENV_NAME:+ $ENV_NAME}"
    echo ""
}

# ---- 命令实现 ---- | EN: ---- Command implementation ----
case "$CMD" in

setup)
    header "Setup (first time)"
    echo "[1/4] Building & starting containers ..."
    $DC up -d --build
    echo "[2/4] Waiting for services ..."
    wait_pg
    echo "[3/4] Running migrations ..."
    run_migrations
    echo "[4/4] Done!"
    show_info
    ;;

rebuild)
    header "Rebuild (reuse existing image)"
    echo "[1/4] Stopping containers ..."
    $DC down
    echo "[2/4] Starting containers ..."
    $DC up -d
    echo "[3/4] Waiting for services ..."
    wait_pg
    echo "[4/4] Running migrations ..."
    run_migrations
    echo "  Rebuild done!"
    show_info
    ;;

shell)
    header "Shell → $BACKEND_CONTAINER"
    docker exec -it "$BACKEND_CONTAINER" bash
    ;;

psql)
    header "PostgreSQL → $PG_CONTAINER"
    docker exec -it "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_DB"
    ;;

logs)
    docker logs -f "$BACKEND_CONTAINER"
    ;;

status)
    header "Status"
    echo ""
    echo "  Containers:"
    for c in "$PG_CONTAINER" "$REDIS_CONTAINER" "$BACKEND_CONTAINER"; do
        state=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo "not found")
        printf "    %-30s %s\n" "$c" "$state"
    done
    echo ""
    echo "  Ports:"
    echo "    Backend   : ${BE_PORT}"
    echo "    PostgreSQL: ${POSTGRES_PORT:-5432}"
    echo "    Redis     : ${REDIS_PORT:-6379}"
    echo ""
    echo "  Env file: $ENV_FILE"
    echo "  Project : $PROJECT"
    echo ""
    ;;

clean)
    header "Clean (remove containers + volumes)"
    read -rp "  This will DELETE all data. Continue? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        $DC down -v
        echo "  Cleaned."
    else
        echo "  Cancelled."
    fi
    ;;

init)
    if [[ -f "$ENV_FILE" ]]; then
        echo "[SKIP] $ENV_FILE already exists."
    else
        cp .env.example "$ENV_FILE"
        echo "[OK] Created $ENV_FILE from .env.example"
        echo "     Edit it: vim $ENV_FILE"
    fi
    ;;

help|*)
    cat <<'USAGE'
ClawNet Backend 管理脚本

用法: ./clawnet.sh <command> [env]

命令:
  init    [env]   创建 .env 文件（从 .env.example 复制）
  setup   [env]   首次初始化（构建镜像 + 启动 + 迁移）
  rebuild [env]   重建容器（复用镜像）+ 迁移
  shell   [env]   进入后端容器 bash
  psql    [env]   进入 PostgreSQL 交互终端
  logs    [env]   查看后端日志（follow）
  status  [env]   查看容器状态
  clean   [env]   停止并删除容器和数据卷（危险）
  help            显示此帮助

环境参数:
  [env] 可选，指定使用 .env.<env> 配置文件，默认使用 .env
  例如: ./clawnet.sh setup test  →  使用 .env.test 配置

示例:
  ./clawnet.sh init                # 创建 .env
  ./clawnet.sh init test           # 创建 .env.test
  ./clawnet.sh setup               # 首次部署（默认环境）
  ./clawnet.sh setup test          # 首次部署（test 环境）
  ./clawnet.sh rebuild             # 重建容器（默认环境）
  ./clawnet.sh rebuild test        # 重建 test 环境容器
  ./clawnet.sh shell               # 进入后端容器
  ./clawnet.sh psql test           # 连接 test 环境数据库
USAGE
    ;;

esac
