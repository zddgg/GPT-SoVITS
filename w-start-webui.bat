@echo off
chcp 65001
setlocal

REM 切换到脚本所在目录
cd /D "%~dp0"

set "HF_ENDPOINT=https://hf-mirror.com"

set "INSTALL_DIR=%cd%\runtime"
set "ENV_DIR=%INSTALL_DIR%\myenv"
set "ENV_PYTHON=%ENV_DIR%\python"
set "ENV_PIP=%ENV_PYTHON% -m pip"

REM 检查Python是否存在
if not exist "%ENV_DIR%\python.exe" (
    echo.
    echo Python未找到，请确保已正确设置Conda环境。
    goto end
)

%ENV_PYTHON% webui.py

endlocal
