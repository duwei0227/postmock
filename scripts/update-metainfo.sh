#!/bin/bash
# 更新 Flatpak metainfo.xml 中的版本信息

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <version> [release-notes]"
    echo "Example: $0 0.2.0 'Added new features'"
    exit 1
fi

VERSION=$1
RELEASE_NOTES=${2:-"See CHANGELOG.md for details"}
DATE=$(date +%Y-%m-%d)

METAINFO_FILE="flatpak/cn.probiecoder.postmock.metainfo.xml"

# 检查文件是否存在
if [ ! -f "$METAINFO_FILE" ]; then
    echo "Error: $METAINFO_FILE not found"
    exit 1
fi

# 创建新的 release 条目
NEW_RELEASE="    <release version=\"$VERSION\" date=\"$DATE\">
      <description>
        <p>$RELEASE_NOTES</p>
      </description>
    </release>"

# 在 <releases> 标签后插入新的 release
sed -i "/<releases>/a\\
$NEW_RELEASE" "$METAINFO_FILE"

echo "✓ Updated $METAINFO_FILE with version $VERSION"
echo "  Date: $DATE"
echo "  Notes: $RELEASE_NOTES"
