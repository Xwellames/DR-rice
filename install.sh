#!/bin/bash

# Проверка и установка прав на выполнение для самого скрипта
if [ ! -x "$0" ]; then
    echo "Устанавливаем права на выполнение для install.sh..."
    chmod +x "$0" 2>/dev/null || { echo "Не удалось установить права на выполнение"; exit 1; }
    exec "$0" "$@"
    exit $?
fi

# Настройки языка
set_language() {
    clear
    echo -e "\033[1;36mВыберите язык / Select language:\033[0m"
    options=("Русский" "English")
    
    local current=0
    while true; do
        for i in "${!options[@]}"; do
            if [ $i -eq $current ]; then
                echo -e "\033[1;32m➤ ${options[i]}\033[0m"
            else
                echo "  ${options[i]}"
            fi
        done

        read -rsn1 key
        case "$key" in
            $'\x1b') # Escape sequence
                read -rsn2 -t 0.1 key
                case "$key" in
                    '[A') current=$(( (current - 1 + ${#options[@]}) % ${#options[@]} )) ;;
                    '[B') current=$(( (current + 1) % ${#options[@]} )) ;;
                esac
                ;;
            '') # Enter key
                LANG_CHOICE=$current
                break
                ;;
        esac
        clear
        echo -e "\033[1;36mВыберите язык / Select language:\033[0m"
    done

    case $LANG_CHOICE in
        0) # Русский
            MSG_FONTS="Установка шрифтов..."
            MSG_BASHRC="Настройка .bashrc"
            MSG_RESOLUTION="Выберите разрешение монитора:"
            MSG_REFRESH="Выберите частоту обновления:"
            MSG_GRUB="Установить тему GRUB?"
            MSG_GRUB_RES="Выберите разрешение для темы GRUB:"
            MSG_COMPLETE="Установка завершена успешно!"
            MSG_GRUB_PERM="Установка прав для скриптов GRUB..."
            OPT_1K="1k (1920x1080)"
            OPT_2K="2k (2560x1440)"
            OPT_60Hz="60Hz"
            OPT_144Hz="144Hz"
            OPT_YES="Да"
            OPT_NO="Нет"
            ;;
        1) # English
            MSG_FONTS="Installing fonts..."
            MSG_BASHRC="Configuring .bashrc"
            MSG_RESOLUTION="Select monitor resolution:"
            MSG_REFRESH="Select refresh rate:"
            MSG_GRUB="Install GRUB theme?"
            MSG_GRUB_RES="Select resolution for GRUB theme:"
            MSG_COMPLETE="Installation completed successfully!"
            MSG_GRUB_PERM="Setting execute permissions for GRUB scripts..."
            OPT_1K="1k (1920x1080)"
            OPT_2K="2k (2560x1440)"
            OPT_60Hz="60Hz"
            OPT_144Hz="144Hz"
            OPT_YES="Yes"
            OPT_NO="No"
            ;;
    esac
}

show_menu() {
    local prompt="$1"
    shift
    local options=("$@")
    local current=0

    while true; do
        clear
        echo -e "\033[1;36m$prompt\033[0m"
        for i in "${!options[@]}"; do
            if [ $i -eq $current ]; then
                echo -e "\033[1;32m➤ ${options[i]}\033[0m"
            else
                echo "  ${options[i]}"
            fi
        done

        read -rsn1 key
        case "$key" in
            $'\x1b') # Escape sequence
                read -rsn2 -t 0.1 key
                case "$key" in
                    '[A') current=$(( (current - 1 + ${#options[@]}) % ${#options[@]} )) ;;
                    '[B') current=$(( (current + 1) % ${#options[@]} )) ;;
                esac
                ;;
            '') # Enter key
                return $current
                ;;
        esac
    done
}

install_fonts() {
    clear
    echo -e "\033[1;34m$MSG_FONTS\033[0m"
    
    FONT_TMP_DIR=$(mktemp -d)
    
    echo -e "\033[1;33m• CaskaydiaCove Nerd Font...\033[0m"
    if wget -q --show-progress -P "$FONT_TMP_DIR" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip; then
        unzip -q "$FONT_TMP_DIR/CascadiaCode.zip" -d "$FONT_TMP_DIR/CaskaydiaCove"
    else
        echo -e "\033[1;31mОшибка загрузки / Download error\033[0m"
        exit 1
    fi
    
    echo -e "\033[1;33m• Font Awesome 6...\033[0m"
    if wget -q --show-progress -P "$FONT_TMP_DIR" https://github.com/FortAwesome/Font-Awesome/releases/download/6.4.0/fontawesome-free-6.4.0-desktop.zip; then
        unzip -q "$FONT_TMP_DIR/fontawesome-free-6.4.0-desktop.zip" -d "$FONT_TMP_DIR/FontAwesome6"
    else
        echo -e "\033[1;31mОшибка загрузки / Download error\033[0m"
        exit 1
    fi
    
    FONT_DIR="/usr/share/fonts/truetype/custom"
    sudo mkdir -p "$FONT_DIR"
    sudo cp -r "$FONT_TMP_DIR/CaskaydiaCove/"*.ttf "$FONT_DIR/"
    sudo cp "$FONT_TMP_DIR/FontAwesome6/otfs/Font Awesome 6 Free-Regular-400.otf" "$FONT_DIR/"
    sudo cp "$FONT_TMP_DIR/FontAwesome6/otfs/Font Awesome 6 Free-Solid-900.otf" "$FONT_DIR/"
    
    echo -e "\033[1;33m• Обновление кэша шрифтов / Updating font cache...\033[0m"
    sudo fc-cache -fv
    
    rm -rf "$FONT_TMP_DIR"
    echo -e "\033[1;32m✓ Шрифты установлены / Fonts installed\033[0m"
    sleep 1
}

install_bashrc() {
    clear
    echo -e "\033[1;34m$MSG_BASHRC\033[0m"
    
    if [ -f "conf/.bashrc" ]; then
        echo -e "\033[1;33m• Копирование .bashrc в ~/.bashrc...\033[0m"
        cp -f "conf/.bashrc" "$HOME/.bashrc"
        echo -e "\033[1;32m✓ .bashrc успешно настроен\033[0m"
    else
        echo -e "\033[1;33m• Файл conf/.bashrc не найден, пропускаем...\033[0m"
    fi
    sleep 1
}

copy_configs() {
    local config_dir=$1
    
    echo -e "\033[1;33m• Копирование конфигов в ~/.config/...\033[0m"
    if [ -d "conf/$config_dir" ]; then
        mkdir -p "$HOME/.config"
        cp -rf "conf/$config_dir"/* "$HOME/.config/"
        echo -e "\033[1;32m✓ Конфиги для $config_dir скопированы\033[0m"
    else
        echo -e "\033[1;31mПапка conf/$config_dir не найдена\033[0m"
        exit 1
    fi
    sleep 1
}

select_resolution() {
    show_menu "$MSG_RESOLUTION" "$OPT_1K" "$OPT_2K"
    local choice=$?
    
    if [ $choice -eq 0 ]; then
        config_dir="1k@60"
    else
        show_menu "$MSG_REFRESH" "$OPT_60Hz" "$OPT_144Hz"
        local hz_choice=$?
        [ $hz_choice -eq 0 ] && config_dir="2k@60" || config_dir="2k@144"
    fi
    
    echo -e "\033[1;32m✓ Выбрано: $config_dir\033[0m"
    copy_configs "$config_dir"
}

set_grub_permissions() {
    echo -e "\033[1;33m• $MSG_GRUB_PERM\033[0m"
    if [ -d "conf/grub/1k" ]; then
        find "conf/grub/1k" -name "*.sh" -exec chmod +x {} \;
    fi
    if [ -d "conf/grub/2k" ]; then
        find "conf/grub/2k" -name "*.sh" -exec chmod +x {} \;
    fi
    echo -e "\033[1;32m✓ Права установлены\033[0m"
    sleep 1
}

install_grub() {
    show_menu "$MSG_GRUB" "$OPT_YES" "$OPT_NO"
    local choice=$?
    
    if [ $choice -eq 0 ]; then
        set_grub_permissions
        
        show_menu "$MSG_GRUB_RES" "$OPT_1K" "$OPT_2K"
        local res_choice=$?
        [ $res_choice -eq 0 ] && grub_dir="conf/grub/1k" || grub_dir="conf/grub/2k"
        
        if [ -d "$grub_dir" ]; then
            echo -e "\033[1;33m• Установка темы GRUB...\033[0m"
            (cd "$grub_dir" && sudo ./install.sh)
            echo -e "\033[1;32m✓ Тема GRUB установлена\033[0m"
        else
            echo -e "\033[1;31mДиректория $grub_dir не найдена\033[0m"
        fi
    fi
    sleep 1
}

main() {
    set_language
    install_fonts
    install_bashrc
    select_resolution
    install_grub
    
    clear
    echo -e "\033[1;32m$MSG_COMPLETE\033[0m"
    source "$HOME/.bashrc" 2>/dev/null
}

main "$@"
