#!/bin/bash
# Description:
# This script does the backup for you in Linux Plesk servers.
# Author: David Canillas Racero, @Kartojal
#
# HOWTO:
# First, edit the backup.conf file, determining your vhost directory,
# backup directory, and the vhost domain names you want to backup.
# Them, just run the script without any arguments. 

function init_script {
    echo -e ""$script_name": Starting to backup. \n Written with <3 by Kartojal.\n"

}
function check_dir {
    if [ -d "$1" ]
    then
        echo "[OK] The dir "$1" exists."
        return 0
    else
        return 1
    fi
}
function check_backup_dir {
    if check_dir "$backup_dir" 
    then
        return
    else
        mkdir -p "$backup_dir"
        if [ $? -eq 0 ]
        then
            return
        else
            exiting 2 $1
        fi
    fi
}

function mk_url_dir {
    mkdir -p "$1"
    if [ $? -eq 0 ]
    then
        echo "Directory "$1" created."
        return
    else
        exiting 2 $1
    fi

}
function tar_backup {
    local url_backup="$1"
    local file_name="./"${url_backup:0:6}"_"$(date +"%d-%m-%Y")".tar.gz"
    local target="$2"
    tar -czf "./$file_name" -C "$target" httpdocs 
    if [ "$?" -eq 0 ] && [ -f "$file_name" ]
    then
       echo -e "[OK] The "$url_backup" backup has been finished succesfuly.\n" 
    else
       exiting 6 "$url_backup"  
    fi
        
}
function check_and_backup {
    echo -e "\n[INFO] Checks of "$1" starting."
    if check_dir "$2"
    then
        echo -e "[INFO] Backup of "$1" starting."
        tar_backup "$1" "$2"
    else
       exiting 3 "$1" "$2" 
    fi
}
function domain_loop {
    declare -a urls=("${!1}")
    local n_urls=${#urls[@]}
    cd $backup_dir
    
    if [ "$n_urls" -gt 0 ]
    then
        for url in "${urls[@]}"
        do
            local backup_url_dir=""$backup_dir"/"$url"/"$(date +"%d-%m-%Y")"" 
            local target_dir=""$vhost_dir"/"$url"" 

            if [ -d $backup_url_dir ]
            then
                cd "$backup_url_dir"
                if [ $? -eq 0 ]
                then
                    check_and_backup $url $target_dir
                fi
            else
                echo "[...] Cant found the backup dir. Let's make it for you."
                mk_url_dir $backup_url_dir
                cd "$backup_url_dir"
                check_and_backup $url $target_dir
            fi
        done
    else
        exiting 4
    fi
}



function exiting {
echo ""
case "$1" in
    0)
        echo ""$script_name": All done, the backups ends succesfully at "$(date)"."
        exit 0
        ;;
    2)
        echo ""$script_name": Error while creating this directory: "$2""
        exit 2
        ;;
    3)
        echo ""$script_name": Error while trying to backup the "$2" domain, the next directory doesn't exists: "$3""
        exit 3
        ;;

    4)
        echo ""$script_name": No domains names in the \$domains array"
        exit 4
        ;;
    6)
        echo ""$script_name": Error while trying to backup the "$2" domain."
        exit 6
        ;;
    *)
        echo ""$script_name": Unknown error, email to author if you find any bug, canillas.mail at gmail [dot] com ."
        exit 1
        ;;
esac
}
# Load backup config file
source backup.conf

# Script start
init_script

# Check backup directory, default $HOME/backups, if not exists, it make the dir
check_backup_dir

# Check the plesk vhost directory. It exits if not exists.
check_dir $vhost_dir

# Start to backup all the domains array
domain_loop domains[@]

# If all good, exit 0
exiting 0
