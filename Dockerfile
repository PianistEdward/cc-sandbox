# =============================================
# Claude Code 沙箱镜像
# =============================================
# 基础镜像：Node.js 22 (LTS) - 非 Alpine，使用 glibc
FROM node:22

# node:22 镜像已包含 node 用户，直接使用

# 安装 Bun (claude-mem 插件依赖，如果不安装claude-mem则注释掉)
RUN npm install -g bun

# 通过 npm 全局安装 Claude Code
RUN npm install -g @anthropic-ai/claude-code

# 复制 Claude Code 配置文件
COPY --chown=node:node .claude/ /home/node/.claude/
COPY --chown=node:node .claude.json /home/node/.claude.json

# 工作目录
WORKDIR /workspace

# 数据卷：运行时通过 -v 指定具体挂载点
# 示例：docker run -v /my/project:/workspace claude-sandbox
VOLUME ["/workspace"]

# 切换到非 root 用户
USER node

# 容器启动命令 (npm 安装后 claude 在 PATH 中)
CMD ["claude"]
