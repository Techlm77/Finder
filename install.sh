#!/bin/bash

set -euo pipefail

# Function to append 'nav' to a shell configuration file if not already present
add_nav_function() {
    local shell_rc="$1"
    local shell_name="$2"

    if [ ! -f "$shell_rc" ]; then
        echo "Configuration file $shell_rc does not exist. Skipping."
        return
    fi

    # Check if 'nav' function is already defined
    if grep -q "^nav()" "$shell_rc"; then
        echo "'nav' function already exists in $shell_rc. Skipping."
        return
    fi

    # Append the 'nav' function
    cat >> "$shell_rc" << 'EOF'

nav() {
    local search_term result choice
    read -rp "Enter the file or folder name: " search_term

    if [[ -z "$search_term" ]]; then
        echo "No search term entered. Aborting."
        return 1
    fi

    # Define directories to search for performance (modify as needed)
    local search_dirs=("/home" "/usr" "/etc" "/var" "/opt")

    # Perform the search
    IFS=$'\n' read -r -d '' -a result < <(find "${search_dirs[@]}" -type d -name "$search_term" -o -type f -name "$search_term" 2>/dev/null && printf '\0')

    if [ "${#result[@]}" -eq 0 ]; then
        echo "No matches found for \"$search_term\"."
        return 1
    fi

    echo "Found locations:"
    for i in "${!result[@]}"; do
        printf "[%2d] %s\n" "$i" "${result[i]}"
    done

    while true; do
        read -rp "Enter the number to navigate to, or 'q' to quit: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "${#result[@]}" ]; then
            local target_dir
            target_dir="$(dirname "${result[choice]}")"
            if cd "$target_dir"; then
                echo "Navigated to: $(pwd)"
            else
                echo "Failed to navigate to: $target_dir"
            fi
            break
        elif [[ "$choice" =~ ^[qQ]$ ]]; then
            echo "Navigation aborted."
            break
        else
            echo "Invalid input. Please enter a valid number or 'q' to quit."
        fi
    done
}
EOF

    echo "Added 'nav' function to $shell_rc."
}

# Ensure required commands are available
for cmd in find grep printf read; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' is not available. Please install it and retry."
        exit 1
    fi
done

# Add 'nav' to .bashrc if it exists
add_nav_function "$HOME/.bashrc" "bash"

# Add 'nav' to .zshrc if it exists
add_nav_function "$HOME/.zshrc" "zsh"

echo "Installation complete. Please restart your terminal or source your shell configuration files to use the 'nav' function."
