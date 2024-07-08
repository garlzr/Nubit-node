#!/bin/bash

function install_node() {
    # 检查是否以root用户运行脚本
    if [ "$(id -u)" != "0" ]; then
        echo "此脚本需要以root用户权限运行。"
        echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
        exit 1
    fi
    
    # 脚本保存路径
    SCRIPT_PATH="$HOME/Dedu.sh"
    
    # Define variables
    DOWNLOAD_URL="https://s.dekube.ai/dekube+client/1.0.3/dekube"
    FILE_NAME="dekube"
    INSTALL_DIR="/usr/local/bin"
    TARGET_DIR="$HOME/.dekube/.tool/taskmodule/"
    
    # Obtain sudo privileges
    if ! sudo -v; then
        echo "Failed to obtain sudo privileges."
        exit 1
    fi
    
    # Create and enter the directory
    mkdir -p dekube-client
    cd dekube-client || { echo "Failed to change directory to dekube-client"; exit 1; }
    
    # Download the file
    echo "Downloading $FILE_NAME from $DOWNLOAD_URL..."
    if curl -O "$DOWNLOAD_URL"; then
        echo "Download successful!"
    
        # Create the start script
        echo "Extracting $FILE_NAME..."
        cat << EOF > start_dekube.sh
#!/bin/bash
nohup dekube start > output.log 2>&1 &
sleep 3
dekube log
echo "To stop DEKUBE, type 'dekube stop'"
echo "To check DEKUBE status, type 'dekube status'"
EOF
    
        # Change file permissions and move the executable file
        chmod +x "$FILE_NAME" start_dekube.sh
        sudo mv "$FILE_NAME" "$INSTALL_DIR/$FILE_NAME"
        echo "Finished!"
    
        # Environment check
        RED='\033[0;31m'
        NC='\033[0m' # No Color
    
        echo "Starting environment check..."
    
        # Function to check if a command exists
        command_exists() {
            command -v "$1" >/dev/null 2>&1
        }
    
        # Commands to check
        commands=("lspci" "lshw" "dmidecode")
    
        for cmd in "${commands[@]}"; do
            if ! command_exists "$cmd"; then
                echo -e "${RED}$cmd is not installed. Please install it manually.${NC}"
            fi
        done
    
        # Check if the directory exists
        if [ -d "$TARGET_DIR" ]; then
            # If the directory exists, remove it
            rm -rf "$TARGET_DIR"
        fi
    
        echo "Environment check completed."
        echo "To register DEKUBE, type \`dekube register [your_login_key]\`"
        echo "To start DEKUBE, type \`dekube start\`"
        echo "To stop DEKUBE, type \`dekube stop\`"
        echo "To check DEKUBE status, type \`dekube status\`"
    else
        echo "Error: Download failed."
    fi
    
    read -p "请输入节点key: " SECRET
    dekube register "${SECRET}"
    sleep 5
    screen -dmS Dekube bash -c 'dekube start'
    echo "节点已重启，请使用 'screen -r Dekube' 查看日志。"
}

function check_service_status() {
    if screen -list | grep -q "Dekube"; then
        screen -r Dekube
    else
        echo "没有运行中的 Dekube 节点。"
    fi
}

function update() {
    # 设置新的参数值
    OS_NAME="Ubuntu 22.04 LTS"
    GPU_MODEL="NVIDIA GeForce RTX 4070"
    
    # 文件路径
    CONFIG_FILE="/root/.dekube/conf.ini"
    
    # 使用sed命令修改配置文件中的参数
    sed -i "s/^os_name=.*/os_name=${OS_NAME}/" "$CONFIG_FILE"
    sed -i "s/^gpu_model=.*/gpu_model=${GPU_MODEL}/" "$CONFIG_FILE"
    
    echo "配置文件已更新"
    dekube stop
    screen -ls | grep Detached | grep Dekube | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
    screen -dmS Dekube bash -c 'dekube start'
    echo "节点已重启，请使用 'screen -r Dekube' 查看日志。"
}

# 主菜单
function main_menu() {
    clear
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 修改参数"
    echo "3. 查看日志"
    read -p "请输入选项（1-3）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) update ;;
    3) check_service_status ;;
    *) 
        echo "无效选项。" 
        read -p "按任意键返回主菜单..."
        main_menu
        ;;
    esac
}

# 显示主菜单
main_menu
