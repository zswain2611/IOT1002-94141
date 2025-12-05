#!/bin/bash

# Zachary Swain

# This script reads the EmployeeNames.csv file to setup their accounts and groups on the computer
# Run script with sudo when adding Users/Groups

INPUT_FILE="EmployeeNames.csv" # List of employees to read
# Keeps track of how many user and groups are added (starting from 0)
new_users=0
new_groups=0

declare -A created_users
declare -A created_groups

# Read CSV line by line
while IFS=',' read -r first last dept; do
    # Skip header
    if [[ "$first" == "FirstName" ]]; then
        continue
    fi

    # Trim whitespace and carriage returns
    first=$(echo "$first" | tr -d '\r' | xargs)
    last=$(echo "$last" | tr -d '\r' | xargs)
    dept=$(echo "$dept" | tr -d '\r' | xargs)

    # Handles malformed row
    if [[ -z "$dept" ]]; then
        dept="$last"
        last="$first"
        first=""
    fi

    # Generate username with first letter of first name and first seven letters of last name
    uname="${first:0:1}${last:0:7}"
    uname="${uname,,}"

    # Check for duplicate in file
    if [[ ${created_users["$uname"]} ]]; then
        echo "Error: Duplicate user '$uname' in file. Skipping."
        continue
    fi

    # Check if user already exists
    if id "$uname" &>/dev/null; then
        echo "Error: User '$uname' already exists. Skipping."
        continue
    fi

    # Check if group exists
    if ! getent group "$dept" > /dev/null; then
        groupadd "$dept"
        echo "Group '$dept' created."
	# Adds to group counter
        ((new_groups++))
        created_groups["$dept"]=1
    else
        if [[ ${created_groups["$dept"]} ]]; then
            echo "Note: Group '$dept' already created in this run."
        else
            echo "Error: Group '$dept' already exists."
        fi
    fi

    # Create user and assign primary group
    useradd -m -g "$dept" "$uname"
    echo "User '$uname' created and added to group '$dept'."
    ((new_users++))
    created_users["$uname"]=1

done < "$INPUT_FILE"

# Final summary
echo "----------------------------------"
echo "Summary:"
echo "New users added: $new_users"
echo "New groups created: $new_groups"
echo "----------------------------------"
