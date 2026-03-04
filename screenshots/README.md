# 应用截图

此目录用于存放应用截图，用于：
- README.md 展示
- Flatpak AppStream 元数据
- GitHub Release 页面

## 截图要求

### 用于 Flatpak/AppStream
- 推荐尺寸：1600x900 或 1920x1080
- 格式：PNG
- 至少一张主界面截图
- 文件名：`main.png`, `collections.png`, `environment.png` 等

### 用于 README
- 格式：PNG 或 JPG
- 建议压缩以减小仓库大小
- 展示主要功能特性

## 当前截图

需要添加以下截图：
- [ ] main.png - 主界面（HTTP 请求测试界面）
- [ ] collections.png - 集合管理界面
- [ ] environment.png - 环境变量配置界面
- [ ] tests.png - 自动化测试界面（可选）
- [ ] history.png - 请求历史界面（可选）

## 临时占位符

在添加实际截图之前，可以使用以下命令创建占位符：

```bash
# 创建占位符图片（需要 ImageMagick）
convert -size 1600x900 xc:lightgray -pointsize 72 -fill black \
  -gravity center -annotate +0+0 "Screenshot Coming Soon" \
  screenshots/main.png
```

或者从 https://placehold.co/ 下载占位符：
```bash
curl -o screenshots/main.png "https://placehold.co/1600x900/png?text=Main+Interface"
curl -o screenshots/collections.png "https://placehold.co/1600x900/png?text=Collections"
curl -o screenshots/environment.png "https://placehold.co/1600x900/png?text=Environment"
```

## 使用方法

在 README.md 中引用：
```markdown
![主界面](screenshots/main.png)
```

在 Flatpak 元数据中引用（已配置）：
```xml
<screenshot type="default">
  <caption>主界面</caption>
  <image>https://raw.githubusercontent.com/duwei0227/postmock/main/screenshots/main.png</image>
</screenshot>
```

## 注意事项

1. 截图应该展示应用的实际功能
2. 避免包含敏感信息（API 密钥、个人数据等）
3. 使用示例数据（如 https://jsonplaceholder.typicode.com）
4. 确保界面整洁、专业
5. 截图文件大小建议控制在 500KB 以内
