#!/bin/bash
# ============================================================
# 镰刀 KataGo 一键安装启动脚本
# 适用于 8x RTX 5090 Linux 服务器
# ============================================================

set -e

echo "=============================================="
echo "镰刀 KataGo 训练环境安装"
echo "=============================================="

# 配置变量
export BASEDIR="$HOME/scythe_training"
export BACKUP_DIR="$HOME/backup"

# 创建目录
echo "[1/8] 创建目录结构..."
mkdir -p $BASEDIR/{models,selfplay,shuffled,training,exported,logs,configs,scripts,sgf_data}
mkdir -p $BACKUP_DIR

# 检查上传的文件
echo "[2/8] 检查上传的文件..."
if [ ! -d "$HOME/upload_package" ]; then
    echo "错误：找不到 upload_package 目录"
    echo "请先用 WinSCP 上传文件到 $HOME/upload_package"
    exit 1
fi

# 移动文件
echo "[3/8] 移动文件到工作目录..."
cp -r $HOME/upload_package/katago $BASEDIR/
cp -r $HOME/upload_package/training/* $BASEDIR/
if [ -f "$HOME/upload_package/飞刀.tar.xz" ]; then
    cp "$HOME/upload_package/飞刀.tar.xz" $BASEDIR/
fi

# 解压棋谱
echo "[4/8] 解压棋谱文件..."
if [ -f "$BASEDIR/飞刀.tar.xz" ]; then
    cd $BASEDIR
    tar -xJf "飞刀.tar.xz"
    mv 飞刀 sgf_data/
    echo "    棋谱数量: $(ls -1 sgf_data/飞刀/*.sgf 2>/dev/null | wc -l)"
fi

# 安装依赖
echo "[5/8] 安装系统依赖..."
sudo apt-get update -qq
sudo apt-get install -y -qq cmake g++ libzip-dev zlib1g-dev libgoogle-perftools-dev python3-pip

# 安装 Python 依赖
echo "[6/8] 安装 Python 依赖..."
pip3 install --quiet torch numpy scipy tensorboard

# 下载基础模型
echo "[7/8] 下载基础模型 (b6c96)..."
cd $BASEDIR/models
if [ ! -f "base_b6c96.bin.gz" ]; then
    wget -q --show-progress -O base_b6c96.bin.gz \
        "https://media.katagotraining.org/uploaded/networks/models/kata1/kata1-b6c96-s175395328-d26788732.bin.gz"
fi

# 编译 KataGo
echo "[8/8] 编译 KataGo (CUDA 版本)..."
cd $BASEDIR/katago/cpp
mkdir -p build && cd build
cmake .. -DUSE_BACKEND=CUDA -DUSE_TCMALLOC=1 -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -5
make -j$(nproc) 2>&1 | tail -10

# 验证编译
if [ ! -f "$BASEDIR/katago/cpp/build/katago" ]; then
    echo "错误：KataGo 编译失败！"
    exit 1
fi

# 复制配置文件
echo ""
echo "复制配置文件..."
cp $BASEDIR/katago/cpp/configs/training/selfplay_scythe.cfg $BASEDIR/configs/

# 设置权限
chmod +x $BASEDIR/*.sh $BASEDIR/scripts/*.sh 2>/dev/null || true

echo ""
echo "=============================================="
echo "安装完成！"
echo "=============================================="
echo ""
echo "KataGo 位置: $BASEDIR/katago/cpp/build/katago"
echo "棋谱数量:    $(ls -1 $BASEDIR/sgf_data/飞刀/*.sgf 2>/dev/null | wc -l)"
echo "基础模型:    $BASEDIR/models/base_b6c96.bin.gz"
echo ""
echo "下一步运行:"
echo "  cd $BASEDIR && ./start_simple.sh"
echo ""
