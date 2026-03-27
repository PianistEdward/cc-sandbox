# Claude Code 沙箱镜像

将本机 Claude Code（含 skills、agents、rules 配置）封装为 Docker 镜像，实现隔离执行环境。

> 参考资料：https://easyclaude.com/post/claude-code-dangerously-skip-permissions

## 使用场景

- 隔离危险操作（如系统修改、大规模删除）
- 测试自动化脚本对环境的破坏性影响
- 多人共享统一的 Claude Code 配置模板

## 分支说明

| 分支 | 安装方式 | 说明 |
|------|---------|------|
| `master` | node.js 安装包 | 推荐，包含完整配置 |

> `everything-claude-code` 插件需按照官方文档手动创建 rule 文件夹

## 前置条件

- Docker 已安装并运行
- （可选）获取现有配置路径：`~/.claude/` 和 `~/.claude.json`

## 使用方式

本项目支持两种使用方式：

### 方式一：预装插件（推荐）

插件在构建镜像前配置完成并打包进镜像，容器运行时直接使用预装插件，无需重复安装。适用于**一次性容器**，每次新建容器都自带插件，效率更高。

### 方式二：容器内安装

跳过宿主机配置步骤，直接在容器内安装插件。适用于**长期运行的容器**或**挂载卷固定的容器**。

```bash
# 直接运行容器并安装 Claude Code
docker run -it --rm \
  -v $(pwd):/workspace \
  cc-sandbox bash -c "npm install -g @anthropic-ai/claude-code && claude"

# 安装插件
/reload-plugins
/plugin
```

## 完整工作流程（预装插件模式）

### 1. 克隆仓库

```bash
git clone <repo-url>
cd cc-sandbox
```

### 2. 准备配置到宿主机

将仓库中的配置复制到宿主机根目录：

```bash
cp -r .claude  ~
cp  .claude.json ~
```

### 3. 在宿主机上安装 Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

### 4. 在宿主机上配置插件

启动 Claude Code 并配置插件：

```bash
claude
```

在 Claude Code 中执行：

```bash
/reload-plugins   # 重新加载插件
/plugin           # 查看已安装插件
```

进入 marketplace 可执行安装、更新操作。

安装 `everything-claude-code` 插件后，还需要配置 hooks 和 rules：

```bash
mkdir -p ~/.claude/rules
mkdir -p ~/.claude/hooks
cp -r ~/.claude/plugins/marketplaces/everything-claude-code/hooks/* ~/.claude/hooks/
cp -r ~/.claude/plugins/marketplaces/everything-claude-code/rules/* ~/.claude/rules/
```

配置完成后退出 Claude Code。

### 5. 保存配置到仓库

退出 Claude Code 后，将宿主机上的配置复制回仓库：

```bash
cp -r ~/.claude /path/to/cc-sandbox/
cp ~/.claude.json /path/to/cc-sandbox/
```

### 6. 修改插件配置路径

修改插件安装路径配置（适配容器内路径）：

```bash
# 修改已安装插件路径
将 cc-sandbox/.claude/plugins/installed_plugins.json 中 installPath 修改为：
/home/node/.claude/plugins/...

# 修改市场插件路径
将 cc-sandbox/.claude/plugins/known_marketplaces.json 中 installLocation 修改为：
/home/node/.claude/plugins/...
```

### 7. 构建镜像

```bash
cd /path/to/cc-sandbox

sudo docker build -t cc-sandbox:latest .

# 验证镜像
sudo docker images cc-sandbox
```

### 8. 运行容器

镜像中已预装插件，运行容器时直接使用，无需再次安装：

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  cc-sandbox claude --dangerously-skip-permissions
```

> **注意**：`--dangerously-skip-permissions` 出于安全原因不允许与 sudo/root 一起使用。容器内以非 root 用户（node）运行。

## 文件结构

```
cc-sandbox/
├── .claude/                          # Claude Code 配置
│   ├── agents/                       # Agent 配置
│   ├── skills/                       # Skills 配置
│   ├── rules/                        # Rules 配置
│   ├── hooks/                        # Hooks 配置
│   ├── settings.json                 # 插件配置
│   └── plugins/                      # 插件目录
├── .claude.json                      # CLI 全局配置
├── Dockerfile                        # 镜像构建文件
└── README.md                         # 本文档
```

### 预装插件

`.claude/settings.json` 包含以下插件：

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)
- [everything-claude-code](https://github.com/chchwa/affaan-m-everything-claude-code)
- [claude-mem](https://github.com/thedotmack/claude-mem)
- superpowers

> MCP 会消耗大量 token，ECC 作者建议不要超过 10 个 MCP：[Keep under 10 MCPs enabled to preserve context window](https://github.com/chchwa/affaan-m-everything-claude-code/blob/main/mcp-configs/mcp-servers.json)

## 快速开始

如果已配置好 cc-sandbox 目录，可以跳过上述步骤，直接构建和运行：

```bash
cd /path/to/cc-sandbox

# 构建镜像
sudo docker build -t cc-sandbox:latest .

# 运行容器
docker run -it --rm \
  -v $(pwd):/workspace \
  cc-sandbox claude --dangerously-skip-permissions
```

## 前置条件：授权 Docker socket 访问

如果使用 sudo 运行 docker，需要先授权：

```bash
sudo chmod 666 /var/run/docker.sock
```

## 运行容器

### 交互式运行（推荐）

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  cc-sandbox claude --dangerously-skip-permissions
```

### 挂载特定目录

```bash
# 只挂载需要的代码目录
docker run -it --rm \
  -v /path/to/project:/workspace \
  cc-sandbox claude --dangerously-skip-permissions
```

### 多目录挂载

```bash
docker run -it --rm \
  -v /my/project:/workspace \
  -v /my/tests:/workspace/tests \
  -v /my/data:/workspace/data \
  cc-sandbox claude --dangerously-skip-permissions
```

### 无挂载（使用容器内匿名卷）

```bash
# 数据存储在容器匿名卷中，容器删除后数据丢失
docker run -it --rm cc-sandbox claude --dangerously-skip-permissions
```

### 环境变量注入

`settings.json` 中的 `env` 配置已移除，改为运行时通过 `-e` 参数注入：

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -e ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic \
  -e ANTHROPIC_AUTH_TOKEN=your_token_here \
  -e ANTHROPIC_MODEL=MiniMax-M2 \
  cc-sandbox claude --dangerously-skip-permissions
```

#### 常用环境变量

| 变量 | 说明 |
|------|------|
| `ANTHROPIC_BASE_URL` | API 端点地址 |
| `ANTHROPIC_AUTH_TOKEN` | API 认证令牌 |
| `ANTHROPIC_MODEL` | 默认模型 |
| `API_TIMEOUT_MS` | API 超时（毫秒） |

## 配置来源

| 来源 | 内容 | 容器内位置 |
|------|------|-----------|
| npm (`@anthropic-ai/claude-code`) | Claude Code CLI | 全局安装 |
| `.claude/`（构建上下文） | agents、skills、rules、settings 等 | `/home/node/.claude/` |
| `.claude.json`（构建上下文） | CLI 全局配置（model、verbose 等） | `/home/node/.claude.json` |

## 验证

```bash
# 查看版本
docker run --rm cc-sandbox claude --version

# 确认 hooks 配置存在
docker run --rm cc-sandbox ls -la /home/node/.claude/hooks/

# 确认 rules 配置存在
docker run --rm cc-sandbox ls -la /home/node/.claude/rules/
```

## 安全说明

`--dangerously-skip-permissions` 参数会跳过所有操作确认，行为与宿主机一致。以下操作在沙箱中仍可能造成严重后果：

- 删除系统文件（`rm -rf /` 在容器中等效于删除容器文件系统）
- 格式化磁盘（操作会作用于挂载的 volume）
- 修改 SSH 配置（若 `.ssh` 被挂载）

### 安全建议

- 只挂载必要的目录，避免挂载 `/home`
- 不挂载 `.ssh` 目录，防止密钥泄露
- 生产环境移除 `--dangerously-skip-permissions`，使用确认提示
