#!/bin/bash
# 从 base64 编码的完整公钥中提取第二行（实际的密钥）

BASE64_PUBKEY="dW50cnVzdGVkIGNvbW1lbnQ6IHJzaWduIGVuY3J5cHRlZCBzZWNyZXQga2V5ClJXUlRZMEl5d1RnWXkyL1FycU1PTVZCanpsbGRLV3ZLdmc5NTMzb2tlRWtSaXc3bGxoa0FBQkFBQUFBQUFBQUFBQUlBQUFBQUtJQWNPc0hzcUltWmI0ZmNiVFpYOTZJZFV3WS8vazB0OTZaQWVmTHZlZ29rcFFlblp6dGRSb0EycjV6UFpucDRuaVZCbW5UYzZwNCtMS2pnVGIzanpabDNzS1ArTzhmbHhjVi9ZVTdsMHBDdWJIcHI3UXIySTVSV1lrUGdPTjZFQ2VOZmZkd3liV2s9Cg=="

echo "解码公钥..."
DECODED=$(echo "$BASE64_PUBKEY" | base64 -d)

echo "完整内容（2行）："
echo "$DECODED"
echo ""

echo "提取第二行（实际的密钥）："
PUBKEY_ONLY=$(echo "$DECODED" | tail -n 1)
echo "$PUBKEY_ONLY"
echo ""

echo "这就是应该放在 tauri.conf.json 中 pubkey 字段的内容"
