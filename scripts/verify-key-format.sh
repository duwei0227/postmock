#!/bin/bash
# 验证 Tauri 签名密钥格式

KEY_FILE="$HOME/.tauri/postmock.key"

echo "=========================================="
echo "Tauri Signing Key Format Validator"
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

echo "Checking private key format..."
echo ""

# 读取文件内容
CONTENT=$(cat "$KEY_FILE")
LINE_COUNT=$(wc -l < "$KEY_FILE")
FIRST_LINE=$(head -n 1 "$KEY_FILE")
SECOND_LINE=$(tail -n 1 "$KEY_FILE")

# 检查行数
echo "1. Line count check:"
if [ "$LINE_COUNT" -eq 2 ]; then
    echo "   ✅ Correct: 2 lines"
else
    echo "   ❌ Error: Found $LINE_COUNT lines (should be exactly 2)"
    echo ""
    echo "   The key file should contain exactly 2 lines:"
    echo "   - Line 1: untrusted comment: ..."
    echo "   - Line 2: RW... (base64 encoded key)"
    exit 1
fi

# 检查第一行
echo ""
echo "2. First line check:"
if [[ "$FIRST_LINE" == "untrusted comment:"* ]]; then
    echo "   ✅ Correct: Starts with 'untrusted comment:'"
else
    echo "   ❌ Error: First line should start with 'untrusted comment:'"
    echo "   Found: $FIRST_LINE"
    exit 1
fi

# 检查第二行
echo ""
echo "3. Second line check:"
if [[ "$SECOND_LINE" == RW* ]]; then
    echo "   ✅ Correct: Starts with 'RW' (base64 encoded)"
    
    # 检查是否只包含 base64 字符
    if [[ "$SECOND_LINE" =~ ^[A-Za-z0-9+/=]+$ ]]; then
        echo "   ✅ Correct: Contains only valid base64 characters"
    else
        echo "   ⚠️  Warning: May contain invalid base64 characters"
    fi
else
    echo "   ❌ Error: Second line should start with 'RW'"
    echo "   Found: ${SECOND_LINE:0:50}..."
    exit 1
fi

# 检查文件大小
echo ""
echo "4. File size check:"
FILE_SIZE=$(wc -c < "$KEY_FILE")
if [ "$FILE_SIZE" -gt 100 ] && [ "$FILE_SIZE" -lt 500 ]; then
    echo "   ✅ Correct: $FILE_SIZE bytes (reasonable size)"
else
    echo "   ⚠️  Warning: $FILE_SIZE bytes (unusual size)"
fi

echo ""
echo "=========================================="
echo "✅ Private key format is valid!"
echo "=========================================="
echo ""
echo "Key content (safe to copy to GitHub Secrets):"
echo "---"
cat "$KEY_FILE"
echo "---"
echo ""
echo "Next steps:"
echo "1. Copy the content above (between the --- markers)"
echo "2. Go to GitHub Secrets settings"
echo "3. Add/Update TAURI_SIGNING_PRIVATE_KEY"
echo "4. Paste the content (2 lines only)"
echo ""
echo "Or use the interactive setup:"
echo "  ./scripts/setup-github-secrets.sh"
echo ""
