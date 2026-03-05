#!/bin/bash
# 生成 Tauri 签名密钥
# 使用空密码（按两次回车）

mkdir -p ~/.tauri

echo "Generating Tauri signing key..."
echo "Press Enter twice for no password, or enter a password when prompted."
echo ""

npm run tauri signer generate -- -w ~/.tauri/postmock.key

echo ""
echo "Key generation complete!"
echo "Private key saved to: ~/.tauri/postmock.key"
echo ""
echo "IMPORTANT: Copy the public key shown above and update it in:"
echo "  src-tauri/tauri.conf.json"
echo ""
echo "Also add the private key to GitHub Secrets:"
echo "  1. Go to: Settings → Secrets and variables → Actions"
echo "  2. Add secret: TAURI_SIGNING_PRIVATE_KEY"
echo "  3. Value: Run 'cat ~/.tauri/postmock.key' and copy the output"
