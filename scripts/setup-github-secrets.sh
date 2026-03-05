#!/bin/bash
# 交互式 GitHub Secrets 配置助手

set -e

REPO_URL="https://github.com/duwei0227/postmock"
KEY_FILE="$HOME/.tauri/postmock.key"
PUB_KEY_FILE="$HOME/.tauri/postmock.key.pub"

echo "=========================================="
echo "GitHub Secrets 配置助手"
echo "=========================================="
echo ""

# 检查密钥是否存在
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ 私钥文件不存在: $KEY_FILE"
    echo ""
    echo "请先生成签名密钥："
    echo "  ./scripts/generate-signing-key.sh"
    echo ""
    exit 1
fi

echo "✅ 找到私钥文件"
echo ""

# 显示私钥内容
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "步骤 1: 复制私钥内容"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "请复制下面的完整内容（包括第一行注释）："
echo ""
echo "--- 开始复制 ---"
cat "$KEY_FILE"
echo ""
echo "--- 结束复制 ---"
echo ""

read -p "已复制私钥内容？(y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "请复制上面的内容后重新运行此脚本"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "步骤 2: 添加到 GitHub Secrets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 打开浏览器访问："
echo "   $REPO_URL/settings/secrets/actions"
echo ""
echo "2. 点击 'New repository secret' 按钮"
echo ""
echo "3. 填写表单："
echo "   Name: TAURI_SIGNING_PRIVATE_KEY"
echo "   Secret: 粘贴刚才复制的内容"
echo ""
echo "4. 点击 'Add secret' 保存"
echo ""

read -p "已添加 TAURI_SIGNING_PRIVATE_KEY？(y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "请完成添加后重新运行此脚本"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "步骤 3: 密码配置（可选）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "生成密钥时是否设置了密码？(y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "请添加密码 Secret："
    echo ""
    echo "1. 再次点击 'New repository secret'"
    echo ""
    echo "2. 填写表单："
    echo "   Name: TAURI_SIGNING_PRIVATE_KEY_PASSWORD"
    echo "   Secret: 输入你设置的密码"
    echo ""
    echo "3. 点击 'Add secret' 保存"
    echo ""
    
    read -p "已添加 TAURI_SIGNING_PRIVATE_KEY_PASSWORD？(y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "请完成添加后重新运行此脚本"
        exit 1
    fi
else
    echo ""
    echo "✅ 跳过密码配置（未设置密码）"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "步骤 4: 验证配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "配置完成！你应该在 Secrets 列表中看到："
echo ""
echo "  ✅ TAURI_SIGNING_PRIVATE_KEY"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  ✅ TAURI_SIGNING_PRIVATE_KEY_PASSWORD"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "下一步"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 确保公钥已配置到 src-tauri/tauri.conf.json"
echo "2. 提交并推送代码"
echo "3. 创建版本标签测试自动构建："
echo "   git tag v0.1.1"
echo "   git push origin v0.1.1"
echo ""
echo "4. 查看 GitHub Actions 工作流日志验证签名"
echo ""
echo "详细文档："
echo "  .github/GITHUB_SECRETS_SETUP.md"
echo ""
echo "✨ 配置完成！"
echo ""
