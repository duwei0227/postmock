@echo off
setlocal enabledelayedexpansion

REM YAML 语法验证脚本 (Windows)
REM 用于验证项目中的 YAML 文件语法是否正确

echo ==========================================
echo YAML 语法验证工具
echo ==========================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [91m错误: Python 未安装，请先安装 Python 3[0m
    pause
    exit /b 1
)

REM 检查 PyYAML 是否安装
python -c "import yaml" >nul 2>&1
if errorlevel 1 (
    echo [93m警告: PyYAML 未安装，正在尝试安装...[0m
    pip install pyyaml
    if errorlevel 1 (
        echo [91m错误: PyYAML 安装失败，请手动安装: pip install pyyaml[0m
        pause
        exit /b 1
    )
    echo [92m成功: PyYAML 安装成功[0m
    echo.
)

echo [94m开始验证 YAML 文件...[0m
echo.

set TOTAL_FILES=0
set VALID_FILES=0
set INVALID_FILES=0
set EXIT_CODE=0

REM 如果提供了参数，验证指定的文件
if not "%~1"=="" (
    for %%F in (%*) do (
        call :validate_file "%%~F"
    )
) else (
    REM 验证 GitHub Actions 工作流
    if exist ".github\workflows" (
        echo [94m验证 GitHub Actions 工作流...[0m
        for %%F in (.github\workflows\*.yml .github\workflows\*.yaml) do (
            if exist "%%F" (
                call :validate_file "%%F"
            )
        )
        echo.
    )
    
    REM 验证其他 YAML 配置文件
    echo [94m验证其他 YAML 配置文件...[0m
    for %%F in (*.yml *.yaml) do (
        if exist "%%F" (
            call :validate_file "%%F"
        )
    )
)

echo.
echo ==========================================
echo 验证完成
echo ==========================================
echo 总文件数: !TOTAL_FILES!
echo [92m有效文件: !VALID_FILES![0m
if !INVALID_FILES! gtr 0 (
    echo [91m无效文件: !INVALID_FILES![0m
)
echo.

if !EXIT_CODE! equ 0 (
    echo [92m所有 YAML 文件语法正确！[0m
) else (
    echo [91m发现语法错误，请修复后重试[0m
)

pause
exit /b !EXIT_CODE!

:validate_file
set FILE=%~1
set /a TOTAL_FILES+=1

if not exist "%FILE%" (
    echo [91m错误: 文件不存在: %FILE%[0m
    set /a INVALID_FILES+=1
    set EXIT_CODE=1
    goto :eof
)

REM 使用 Python 验证 YAML 语法
python -c "import yaml; yaml.safe_load(open('%FILE%', 'r', encoding='utf-8'))" >nul 2>&1
if errorlevel 1 (
    echo [91m错误: %FILE% - 语法错误[0m
    python -c "import yaml; yaml.safe_load(open('%FILE%', 'r', encoding='utf-8'))" 2>&1
    set /a INVALID_FILES+=1
    set EXIT_CODE=1
) else (
    echo [92m成功: %FILE% - 语法正确[0m
    set /a VALID_FILES+=1
    
    REM 如果是 GitHub Actions 工作流，进行额外验证
    echo %FILE% | findstr /C:".github\workflows" >nul
    if not errorlevel 1 (
        call :validate_workflow "%FILE%"
    )
)
echo.
goto :eof

:validate_workflow
set WORKFLOW_FILE=%~1

REM 检查是否有 'on' 字段
findstr /B "on:" "%WORKFLOW_FILE%" >nul
if errorlevel 1 (
    echo [93m警告: %WORKFLOW_FILE% - 缺少 'on' 字段（触发条件）[0m
)

REM 检查是否有 'jobs' 字段
findstr /B "jobs:" "%WORKFLOW_FILE%" >nul
if errorlevel 1 (
    echo [91m错误: %WORKFLOW_FILE% - 缺少 'jobs' 字段[0m
    set EXIT_CODE=1
) else (
    REM 提取 job 名称（简化版本）
    echo [94m信息: %WORKFLOW_FILE% - GitHub Actions 工作流验证通过[0m
)
goto :eof
