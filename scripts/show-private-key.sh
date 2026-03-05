#!/bin/bash
# 显示私钥内容以便复制到 GitHub Secrets

KEY_FILE="$HOME/.tauri/postmock.key"

echo "=========================================="
echo "Tauri Signing Private Key"
echo "=========================================="
echo ""

if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Error: Private key not found at $KEY_FILE"
    echo ""
    echo "Please generate the key first:"
    echo "  ./scripts/generate-signing-key.sh"
    echo ""
    exit 1
fi

echo "✅ Private key found!"
echo ""
echo "📋 Copy the content below (including the first line):"
echo "=========================================="
cat "$KEY_FILE"
echo ""
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Copy the content above"
echo "2. Go to: https://github.com/duwei0227/postmock/settings/secrets/actions"
echo "3. Click 'New repository secret'"
echo "4. Name: TAURI_SIGNING_PRIVATE_KEY"
echo "5. Secret: Paste the copied content"
echo "6. Click 'Add secret'"
echo ""
echo "For detailed instructions, see:"
echo "  .github/GITHUB_SECRETS_SETUP.md"
echo ""
