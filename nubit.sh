#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/nubit.sh"

function install_node() {
    # 检查 screen 是否安装
    if ! command -v screen &> /dev/null
    then
        echo "screen 未安装，正在安装..."
        # 检查操作系统类型
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update
            sudo apt-get install screen -y
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install screen -y
        else
            echo "无法识别的包管理器，请手动安装 screen"
            exit 1
        fi
    else
        echo "screen 已安装"
    fi
        # 检查 curl 是否安装
    if ! command -v curl &> /dev/null
    then
        echo "curl 未安装，正在安装..."
        # 检查操作系统类型
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update
            sudo apt-get install curl -y
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install curl -y
        else
            echo "无法识别的包管理器，请手动安装 curl"
            exit 1
        fi
    else
        echo "curl 已安装"
    fi
    
    cd $HOME
    screen -ls | grep Detached | grep nubit | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
    screen -dmS nubit bash -c 'curl -sL https://nubit.sh | bash'
    echo "节点安装完成，请使用 'screen -r nubit' 查看日志。"
}

function restart() {
    screen -ls | grep Detached | grep nubit | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
    screen -dmS nubit bash -c 'curl -sL https://nubit.sh | bash'
    echo "节点已重启，请使用 'screen -r nubit' 查看日志。"
}

function backup() {
    # 定义目标文件夹
    TARGET_DIR="/root/nubit_key"

    # 检查目标文件夹是否存在，如果不存在则创建它
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
    fi

    # 复制文件和文件夹到目标文件夹
    cp -r /root/.nubit-light-nubit-alphatestnet-1/keys "$TARGET_DIR"
    cp /root/nubit-node/mnemonic.txt "$TARGET_DIR"

    echo "钱包数据已成功拷贝到 $TARGET_DIR"
}

function uninstall() {
    rm -rf $HOME/nubit-node
    rm -rf $HOME/.nubit-light-nubit-alphatestnet-1
    echo "节点已卸载。"
}

function check_service_status() {
    if screen -list | grep -q "nubit"; then
        screen -r nubit
    else
        echo "没有运行中的 nubit 节点。"
    fi
}

# 主菜单
function main_menu() {
    clear
    echo "==========================自用脚本=============================="
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志"
    echo "3. 重启节点"
    echo "4. 备份节点钱包数据"
    echo "5. 卸载节点"
    read -p "请输入选项（1-5）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) restart ;;
    4) backup ;;
    5) uninstall ;;
    *) 
        echo "无效选项。" 
        read -p "按任意键返回主菜单..."
        main_menu
        ;;
    esac
}

# 显示主菜单
main_menu
