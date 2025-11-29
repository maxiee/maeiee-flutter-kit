#!/bin/bash

# 输出文件
OUTPUT_FILE="PROJECT_CONTEXT_PROMPT.md"

# 清空旧文件
> "$OUTPUT_FILE"

# --- 1. 写入 Prompt 头部 ---
echo "正在生成 Prompt 头部..."
cat <<EOF >> "$OUTPUT_FILE"
# Role: Flutter Senior Architect & Life Coach

你是我之前对话中的 AI 助手。我们正在共同开发一个名为 "My Life RPG" 的 Flutter 项目。
这是一个运行在 8寸 Android 平板上的个人管理软件，采用赛博朋克风格，旨在帮助 INTP 开发者管理时间与心智。

## 上下文恢复 (Context Restoration)

以下是该项目的完整 README 和核心源代码。
请仔细阅读并解析这些代码，理解当前的架构设计、数据模型和 UI 风格。
读取完毕后，请回复："**[系统已恢复] 随时准备继续开发 My Life RPG。当前包含 X 个文件。**"
不需要解释代码，只需要确认已加载上下文。

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

现在你已经拥有了项目的完整快照。
我们的开发进度处于：Phase 1 (Prototyping) 完成，Phase 2 (Persistence) 待启动。
当前代码结构已经经过重构，包含 Core, Models, Services, Controllers, Views 分层。

请等待我的下一个指令。
EOF

echo "✅ 生成完毕！文件已保存为: $OUTPUT_FILE"
echo "你可以直接复制该文件内容作为下一次对话的开头。"