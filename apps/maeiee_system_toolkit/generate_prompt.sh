#!/bin/bash

# 输出文件
OUTPUT_FILE="PROJECT_CONTEXT_PROMPT.md"

# 清空旧文件
> "$OUTPUT_FILE"

# --- 1. 写入 Prompt 头部 ---
echo "正在生成 Prompt 头部..."
cat <<EOF >> "$OUTPUT_FILE"
# Role: Flutter Senior Architect & 系统工具软件开发专家

## 角色与目标
你是一位拥有极高审美的高级 Flutter 架构师和 UI/UX 设计师。
你的任务是开发 "maeiee_system_toolkit"（代号）。
**核心定义**：maeiee_system_toolkit 是 Maeiee 开发的系统工具箱，包含各种实用工具。

注意：

1. 请将每次的改动，控制在一个 Commit 能够解决的范围内。并且在给出代码修改建议时，请给出明确的代码修改位置和内容。
2. 对于程序中所有文案使用中文
3. 遵循  K.I.S.S (Keep It Simple, Stupid) 原则

---

EOF

# --- 2. 写入 README.md ---
echo "正在读取 README.md..."
if [ -f "README.md" ]; then
    echo "## 文件: README.md" >> "$OUTPUT_FILE"
    echo '```markdown' >> "$OUTPUT_FILE"
    cat "README.md" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
else
    echo "警告: 未找到 README.md"
fi

# --- 3. 写入 Flutter 代码 (lib 目录) ---
# 排除生成的文件 (.g.dart, .freezed.dart) 和测试文件
echo "正在扫描 lib/ 目录..."

find lib -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" ! -name "*_test.dart" | sort | while read -r file; do
    echo "正在处理: $file"
    
    echo "## 文件: $file" >> "$OUTPUT_FILE"
    echo '```dart' >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

# --- 4. 写入 Prompt 尾部指令 ---
cat <<EOF >> "$OUTPUT_FILE"

---

# 指令

现在你已经拥有了项目的完整快照。请等待我的下一个指令。
EOF

echo "✅ 生成完毕！文件已保存为: $OUTPUT_FILE"
echo "你可以直接复制该文件内容作为下一次对话的开头。"