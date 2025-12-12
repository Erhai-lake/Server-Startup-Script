@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ===============================
echo Minecraft 通用启动脚本
echo 版本: 1.0.0
echo 作者: 洱海之畔
echo ===============================
echo.

set "CONFIG_FILE=variables.txt"
set "TEMP_FILE=%CONFIG_FILE%.tmp"

:: -------------------------------------------------
:: 检查配置文件是否存在, 不存在则创建并打开编辑
:: -------------------------------------------------
if not exist "%CONFIG_FILE%" (
    echo 配置文件不存在, 正在创建默认 %CONFIG_FILE%...

    (
        echo # 配置java版本
        echo #   如果要指定特定版本java, 请用"括起来, 并使用\\分割
        echo JAVA="D:\\FlyEnv\\PhpWebStudy-Data\\app\\openjdk-17.0.17\\bin\\java"
        echo.
        echo # 配置jvm参数
        echo JVM_ARGS=-Xms4G -Xmx4G
        echo.
        echo # 推荐JAVA主版本
        echo RECOMMENDED_JAVA_VER=17
        echo.
        echo # 是否启动 GUI^(true/false^)
        echo SERVER_GUI=false
        echo.
        echo # 核心文件名
        echo SERVER_JAR=forge.jar
    ) > "%TEMP_FILE%"

    move /Y "%TEMP_FILE%" "%CONFIG_FILE%" >nul

    echo 默认配置文件已创建: %CONFIG_FILE%
    echo.
    echo 请修改配置文件中的以下项目:
    echo 1. JAVA - 设置正确的Java路径
    echo 2. SERVER_JAR - 设置服务器核心文件名
    echo 3. 其他可选配置 ^(如内存大小/GUI设置等^)
    echo.
    echo 请按任意键编辑配置...
    pause >nul
    notepad "%CONFIG_FILE%"
    echo 编辑完成后请重新运行本脚本.
    pause
    exit /b 1
)

:: -------------------------------------------------
:: 读取配置文件
:: -------------------------------------------------
echo 正在读取配置文件...

for /f "usebackq delims=" %%L in ("%CONFIG_FILE%") do (
    set "line=%%L"

    :: 跳过空行和注释
    if not "!line!"=="" if not "!line:~0,1!"=="#" (
        :: 解析 key=value
        for /f "tokens=1,* delims==" %%A in ("!line!") do (
            set "KEY=%%A"
            set "VAL=%%B"

            :: 去掉 key 前后空格
            for /f "tokens=* delims= " %%X in ("!KEY!") do set "KEY=%%X"
            for /f "tokens=* delims= " %%Y in ("!VAL!") do set "VAL=%%Y"

            set "!KEY!=!VAL!"
            echo 读取: !KEY!=!VAL!
        )
    )
)

echo.
echo 配置读取完成
echo.

:: -------------------------------------------------
:: 检查 Java 是否存在
:: -------------------------------------------------
echo 检查 Java 路径...
%JAVA% -version >nul 2>&1
if errorlevel 1 (
    echo [错误] Java 不存在或路径错误: !JAVA!
    pause
    exit /b 1
)
echo Java 路径有效.
echo.

:: -------------------------------------------------
:: 检查 Java 主版本
:: -------------------------------------------------
for /f "tokens=3 delims= " %%i in ('powershell -Command "& '%JAVA%' -version 2>&1 | Select-String version"') do (
    set "RAW_JAVA_VER=%%i"
)
set "RAW_JAVA_VER=!RAW_JAVA_VER:"=!"
for /f "tokens=1 delims=." %%a in ("!RAW_JAVA_VER!") do set "JAVA_MAJOR=%%a"

echo 检测到 Java 版本: !RAW_JAVA_VER!(主版本: !JAVA_MAJOR!)
echo 推荐版本: !RECOMMENDED_JAVA_VER!
echo.

if not "!JAVA_MAJOR!"=="!RECOMMENDED_JAVA_VER!" (
    echo [警告] Java 版本不是 !RECOMMENDED_JAVA_VER!, 可能会导致兼容性问题.
    echo.

    set /p CH="是否继续? (y/n, 默认 n): "
    if /i "!CH!"=="y" (
        echo 用户选择跳过 Java 检查.
    ) else (
        echo 用户取消.
        exit /b 1
    )
)

:: -------------------------------------------------
:: 检查核心文件是否存在
:: -------------------------------------------------
if not exist "!SERVER_JAR!" (
    echo [错误] 未找到服务器核心文件: !SERVER_JAR!
    echo 当前目录 jar 列表:
    dir *.jar /b
    echo 请将核心文件的文件名写入配置文件 SERVER_JAR 中.
    pause
    exit /b 1
)
echo 找到核心文件: !SERVER_JAR!
echo.

:: -------------------------------------------------
:: 处理 eula.txt
:: -------------------------------------------------
set "EULA_FILE=eula.txt"
set "EULA_AGREED=false"

if exist "%EULA_FILE%" (
    for /f "usebackq tokens=1,2 delims== " %%A in ("%EULA_FILE%") do (
        if /i "%%A"=="eula" (
            set "EULA_VALUE=%%B"
        )
    )

    :: 去掉可能的空格
    set "EULA_VALUE=!EULA_VALUE: =!"

    if /i "!EULA_VALUE!"=="true" (
        echo EULA 已同意
        set "EULA_AGREED=true"
    ) else (
        echo eula.txt 存在, 但尚未同意 EULA
    )
) else (
    echo eula.txt 不存在
)

:: 如果未同意, 询问用户
if "!EULA_AGREED!"=="false" (
    echo.
    echo 详细请查看 Minecraft EULA ^(https://aka.ms/MinecraftEULA^)
    set /p EUL="是否同意? (y/n, 默认 n): "
    if "!EUL!"=="" set "EUL=n"

    if /i "!EUL!"=="y" (
        echo eula=true> "%EULA_FILE%"
        echo 已同意 EULA
    ) else (
        echo 拒绝 EULA, 无法启动服务器.
        exit /b 1
    )
)
echo.

:: -------------------------------------------------
:: 提取核心文件名(不含扩展名)并小写化
:: -------------------------------------------------
for %%F in ("!SERVER_JAR!") do set "BASE_JAR=%%~nF"
set "JAR_LOWER=!BASE_JAR!"
call :ToLower JAR_LOWER JAR_LOWER

:: -------------------------------------------------
:: 判断服务器类型
:: -------------------------------------------------
set "IS_FORGE=false"
set "IS_FABRIC=false"
set "IS_NEOFORGE=false"

echo !JAR_LOWER! | findstr /i "forge" >nul
if !errorlevel! equ 0 set "IS_FORGE=true"

echo !JAR_LOWER! | findstr /i "fabric" >nul
if !errorlevel! equ 0 set "IS_FABRIC=true"

echo !JAR_LOWER! | findstr /i "neoforge" >nul
if !errorlevel! equ 0 set "IS_NEOFORGE=true"

:: -------------------------------------------------
:: JVM 参数文件检查(提前, 保证 Forge 安装/启动可用)
:: -------------------------------------------------
if not exist user_jvm_args.txt (
    echo 创建 user_jvm_args.txt...
    echo !JVM_ARGS! > user_jvm_args.txt
    echo JVM参数已写入: !JVM_ARGS!
) else (
    echo user_jvm_args.txt 已存在
)
echo.

:: -------------------------------------------------
:: Forge 额外安装处理
:: -------------------------------------------------
if "!IS_FORGE!"=="true" (
    if not exist "libraries\net\minecraftforge\forge" (
        echo Forge 服务器未安装, 正在安装...
        %JAVA% -jar "!SERVER_JAR!" --installServer
        if errorlevel 1 (
            echo Forge 安装失败, 请检查错误信息
            pause
            exit /b 1
        )
        echo Forge 安装完成
    )
)

:: -------------------------------------------------
:: 启动服务器
:: -------------------------------------------------
echo 启动服务器...

set "FINAL_CMD="

if "!IS_FORGE!"=="true" (
    :: 找到 Forge 安装目录
    for /d %%D in ("libraries\net\minecraftforge\forge\*") do set "MC_FORGE_DIR=%%D"

    if not defined MC_FORGE_DIR (
        echo [错误] 找不到 Forge 安装目录!
        pause
        exit /b 1
    )

    if not exist "!MC_FORGE_DIR!\win_args.txt" (
        echo [错误] 找不到 Forge win_args.txt 文件: !MC_FORGE_DIR!\win_args.txt
        pause
        exit /b 1
    )

    if /i "!SERVER_GUI!"=="false" (
        "%JAVA%" @user_jvm_args.txt @"!MC_FORGE_DIR!\win_args.txt" --nogui %*
    ) else (
        "%JAVA%" @user_jvm_args.txt @"!MC_FORGE_DIR!\win_args.txt" %*
    )
) else (
    if /i "!SERVER_GUI!"=="false" (
        "%JAVA%" @user_jvm_args.txt -jar "!SERVER_JAR!" nogui %*
    ) else (
        "%JAVA%" @user_jvm_args.txt -jar "!SERVER_JAR!" %*
    )
)

:ToLower
:: 参数 %1 = 输入变量名, %2 = 输出变量名
setlocal enabledelayedexpansion
set "str=!%1!"
for %%A in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    set "str=!str:%%A=%%A!"
)
endlocal & set "%2=%str%"
goto :EOF
