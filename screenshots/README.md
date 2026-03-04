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
- 文件名：`main.png`, `request.png`, `collections.png` 等

### 用于 README
- 格式：PNG 或 JPG
- 建议压缩以减小仓库大小
- 展示主要功能特性

## 当前截图

请添加以下截图：
- [ ] main.png - 主界面
- [ ] request.png - 请求界面
- [ ] collections.png - 集合管理
- [ ] environment.png - 环境变量
- [ ] tests.png - 自动化测试

## 使用方法

在 README.md 中引用：
```markdown
![主界面](screenshots/main.png)
```

在 Flatpak 元数据中引用：
```xml
<screenshot type="default">
  <caption>主界面</caption>
  <image>https://raw.githubusercontent.com/duwei0227/postmock/main/screenshots/main.png</image>
</screenshot>
```
