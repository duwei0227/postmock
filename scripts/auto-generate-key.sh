#!/bin/bash
# 自动生成 Tauri 签名密钥（无密码）

set -e

echo "=========================================="
echo "Auto-generating Tauri Signing Key"
echo "=========================================="
echo ""

# 创建目录
mkdir -p ~/.tauri

# 生成密钥（使用空密码）
echo "Generating key pair..."
echo -e "\n\n" | npm run tauri signer generate -- -w ~/.tauri/postmock.key 2>&1 | tee /tmp/keygen-output.log

# 等待文件生成
sleep 2

# 检查文件是否生成
if [ -f ~/.tauri/postmock.key ]; then
    echo ""
    echo "✅ Key pair generated successfully!"
    echo ""
    echo "=========================================="
    echo "PUBLIC KEY (for tauri.conf.json):"
    echo "=========================================="
    
    # 从输出中提取公钥
    if [ -f ~/.tauri/postmock.key.pub ]; then
        cat ~/.tauri/postmock.key.pub
    else
        # 从日志中提取
        grep "^dW50cnVzdGVk" /tmp/keygen-output.log || grep "Public:" /tmp/keygen-output.log | cut -d: -f2- | xargs
    fi
    
    echo ""
    echo "=========================================="
    echo "PRIVATE KEY (for GitHub Secrets):"
    echo "=========================================="
    cat ~/.tauri/postmock.key
    echo ""
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Copy the PUBLIC KEY above"
    echo "2. Update src-tauri/tauri.conf.json"
    echo "3. Copy the PRIVATE KEY (2 lines)"
    echo "4. Add to GitHub Secrets as TAURI_SIGNING_PRIVATE_KEY"
    echo ""
    echo "Or run: ./scripts/setup-github-secrets.sh"
    echo ""
else
    echo "❌ Failed to generate key"
    echo "Please run manually:"
    echo "  npm run tauri signer generate -- -w ~/.tauri/postmock.key"
    exit 1
fi
