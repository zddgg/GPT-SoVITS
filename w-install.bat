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

:: 设置Miniconda安装的URL和目标文件夹
set "MINICONDA_URL=https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Windows-x86_64.exe"
set "MINICONDA_INSTALLER=Miniconda3-latest-Windows-x86_64.exe"

:: 检查Miniconda是否已安装
if not exist "%INSTALL_DIR%\Scripts\conda.exe" (

    echo Downloading Miniconda from: %MINICONDA_URL%
    curl -L -o %MINICONDA_INSTALLER% %MINICONDA_URL%
    if %errorlevel% neq 0 (
        echo Failed to download Miniconda.
        exit /b %errorlevel%
    )

    :: 安装Miniconda到指定目录
    echo Installing Miniconda...
    start /wait "" "%MINICONDA_INSTALLER%" /InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /S /D=%INSTALL_DIR%
    if %errorlevel% neq 0 (
        echo Failed to install Miniconda.
        exit /b %errorlevel%
    )

) else (
    echo Miniconda is already installed.
)

:: 检查Conda环境是否已创建
if not exist "%ENV_DIR%\python.exe" (
    :: 创建新的conda环境并安装Python 3.10
    echo Creating conda environment with Python 3.10...

    %INSTALL_DIR%\Scripts\conda.exe create --yes --prefix %ENV_DIR% python=3.10 -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/

    if %errorlevel% neq 0 (
        echo Failed to create conda environment.
        exit /b %errorlevel%
    )
) else (
    echo Conda environment already exists.
)

:: 激活新创建的conda环境
echo Activating conda environment...
call "%INSTALL_DIR%\Scripts\activate.bat" %ENV_DIR%
if %errorlevel% neq 0 (
    echo Failed to activate conda environment.
    exit /b %errorlevel%
)

:: 安装torch依赖
echo Installing torch
%ENV_PIP% install --no-warn-script-location torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 -i https://mirror.sjtu.edu.cn/pytorch-wheels/cu121
if %errorlevel% neq 0 (
    echo Failed to install torch.
    exit /b %errorlevel%
)

:: 安装requirements.txt中的依赖
echo Installing requirements from requirements.txt...
%ENV_PIP% install -r requirements.txt --no-warn-script-location -i https://pypi.tuna.tsinghua.edu.cn/simple
if %errorlevel% neq 0 (
    echo Failed to install requirements.
    exit /b %errorlevel%
)

echo Setup complete.

:: 清理下载的Miniconda安装程序
if exist %MINICONDA_INSTALLER% (
    del %MINICONDA_INSTALLER%
)

:: 定义下载文件的Python脚本
set "PYTHON_SCRIPT=w-download.py"

:: 检查Python是否安装
echo 检查Python是否安装...
%ENV_PYTHON% --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python未安装.
    exit /b %errorlevel%
)

:: 检查huggingface_hub库是否安装
echo 检查huggingface_hub库是否安装...
%ENV_PYTHON% -c "import huggingface_hub" >nul 2>&1
if %errorlevel% neq 0 (
    echo huggingface_hub未安装. 正在安装...
    %ENV_PIP% install huggingface_hub --no-warn-script-location -i https://pypi.tuna.tsinghua.edu.cn/simple
    if %errorlevel% neq 0 (
        echo 安装huggingface_hub失败.
        exit /b %errorlevel%
    )
)

:: 创建Python脚本
echo 创建Python脚本...
echo import os, sys > %PYTHON_SCRIPT%
echo from huggingface_hub import hf_hub_download >> %PYTHON_SCRIPT%
echo repo_id = sys.argv[1] >> %PYTHON_SCRIPT%
echo filename = sys.argv[2] >> %PYTHON_SCRIPT%
echo output_dir = sys.argv[3] >> %PYTHON_SCRIPT%
echo file_path = os.path.join(output_dir, filename) >> %PYTHON_SCRIPT%
echo if not os.path.exists(file_path): >> %PYTHON_SCRIPT%
echo     print(f"文件 {file_path} 不存在. 正在下载...") >> %PYTHON_SCRIPT%
echo     hf_hub_download(repo_id, filename, local_dir=output_dir, resume_download=True, local_dir_use_symlinks=False) >> %PYTHON_SCRIPT%
echo else: >> %PYTHON_SCRIPT%
echo     print(f"文件 {file_path} 已存在. 跳过下载.") >> %PYTHON_SCRIPT%

:: 运行Python脚本进行下载
echo 下载 ffmpeg
%ENV_PYTHON% %PYTHON_SCRIPT% "wenliang001/project" "ffmpeg.exe" "%cd%"
%ENV_PYTHON% %PYTHON_SCRIPT% "wenliang001/project" "ffprobe.exe" "%cd%"

echo 下载 nltk_data
%ENV_PYTHON% %PYTHON_SCRIPT% "wenliang001/nltk_data" "corpora/cmudict.zip" "%ENV_DIR%\nltk_data"
%ENV_PYTHON% %PYTHON_SCRIPT% "wenliang001/nltk_data" "taggers/averaged_perceptron_tagger.zip" "%ENV_DIR%\nltk_data"

echo 下载 GPT_SoVITS modal
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "s1bert25hz-2kh-longer-epoch=68e-step=50232.ckpt" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "s2D488k.pth" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "s2G488k.pth" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "chinese-hubert-base/config.json" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "chinese-hubert-base/preprocessor_config.json" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "chinese-hubert-base/pytorch_model.bin" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "chinese-roberta-wwm-ext-large/config.json" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "chinese-roberta-wwm-ext-large/pytorch_model.bin" "%cd%\GPT_SoVITS\pretrained_models"
%ENV_PYTHON% %PYTHON_SCRIPT% "lj1995/GPT-SoVITS" "chinese-roberta-wwm-ext-large/tokenizer.json" "%cd%\GPT_SoVITS\pretrained_models"

:: 删除Python脚本
echo 删除Python脚本...
del %PYTHON_SCRIPT%

endlocal
