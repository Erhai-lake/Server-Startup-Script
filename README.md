# 一个Minecraft 通用启动脚本

这是一个 Windows 下的 Minecraft 服务器通用启动脚本, 支持 **Vanilla / Paper / Forge / Fabric** 等多种类型服务器的启动.

你可以用他作为整合包服务器的启动脚本, 打包进整合包, 他会很好用的!

---

## 功能特点

- 自动创建默认配置文件 `variables.txt`
- 支持自定义 Java 路径及 JVM 参数
- 自动检查并提示 Java 版本
- 支持 EULA 同意提示
- 支持 Forge 自动安装
- 支持 GUI 或无 GUI 启动模式
- 支持读取 `user_jvm_args.txt`, 方便自定义启动参数

---

## 使用说明

### 第一次使用

1. 将本脚本放在服务器核心文件同目录(如 `forge.jar` / `paper.jar` / `paper-1.20.6-134.jar` 等)
2. 双击 `start.bat`
3. 脚本会检测到 `variables.txt` 不存在, 自动创建默认配置文件
4. 修改配置文件:
   - `JAVA`: 设置正确的 Java 路径
   - `SERVER_JAR`: 设置服务器核心文件名
   - 可选: 修改 `JVM_ARGS`/`SERVER_GUI` 等参数
5. 保存后重新运行脚本

### 配置文件示例 `variables.txt`

```txt
# 配置java版本
#   如果要指定特定版本java, 请用"括起来, 并使用\\分割
JAVA="D:\\FlyEnv\\PhpWebStudy-Data\\app\\openjdk-21.0.9\\bin\\java"

# 配置jvm参数
JVM_ARGS=-Xms4G -Xmx4G

# 推荐JAVA主版本
RECOMMENDED_JAVA_VER=21

# 是否启动 GUI(true/false)
SERVER_GUI=false

# 核心文件名
SERVER_JAR=paper-1.20.6-134.jar
```

## 贡献

欢迎提交 Issues 或 Pull Request, 改善脚本功能.
