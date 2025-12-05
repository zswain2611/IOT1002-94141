#!/bin/bash
# FolderCreation.sh – IOT1025 Semester Long Assignment – Part 4
# Creates /EmployeeData with six department folders and correct permissions
# Author: Zachary Swain
# Date: November 27, 2025

BASE="/EmployeeData"
folder_count=0

# Create base directory
sudo mkdir -p "$BASE"

# List of departments
declare -A depts=(
    ["HR"]="sensitive"
    ["Executive"]="sensitive"
    ["IT"]="normal"
    ["Finance"]="normal"
    ["Administrative"]="normal"
    ["CallCentre"]="normal"
)

# Create each department folder
for dept in "${!depts[@]}"; do
    path="$BASE/$dept"
    sudo mkdir -p "$path"
    ((folder_count++))

    # Set owner: root, group: department name
    sudo chown root:"$dept" "$path"

    # Sensitive folders (HR & Executive) no access for others
    if [[ "${depts[$dept]}" == "sensitive" ]]; then
        sudo chmod -R 770 "$path"
    else
        sudo chmod -R 775 "$path"
    fi
done

# Final message
echo "$folder_count folders were created"
