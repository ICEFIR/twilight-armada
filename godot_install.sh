#!/bin/bash

# GitHub repository details
REPO="limbonaut/limboai"
WORKFLOW_FILE="all_builds.yml"

# Default token file location
TOKEN_FILE="$HOME/.github_token"

# Function to read GitHub token from file
read_github_token() {
    if [ -f "$TOKEN_FILE" ]; then
        GITHUB_TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')
        if [ -n "$GITHUB_TOKEN" ]; then
            echo "Token read from $TOKEN_FILE"
            return 0
        fi
    fi
    return 1
}

# Function to check if the token has the required permissions
check_token_permissions() {
    local check_url="https://api.github.com/repos/$REPO/actions/artifacts"
    local response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" "$check_url")
    if [ "$response" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Function to guide user through token creation and storage
guide_token_creation() {
    echo "To download artifacts, you need a GitHub Personal Access Token with the 'actions:read' scope."
    echo "Please follow these steps to create one:"
    echo "1. Go to https://github.com/settings/tokens"
    echo "2. Click 'Generate new token' (classic)"
    echo "3. Give your token a descriptive name"
    echo "4. Under 'Select scopes', check the box for 'actions:read'"
    echo "5. Click 'Generate token' at the bottom of the page"
    echo "6. Copy the generated token"
    echo
    echo "You can either:"
    echo "a) Save it to $TOKEN_FILE:"
    echo "   echo 'your_token_here' > $TOKEN_FILE"
    echo "   chmod 600 $TOKEN_FILE"
    echo
    echo "b) Use it directly with the -t option:"
    echo "   $0 -t your_token_here"
    echo
    echo "Then run this script again."
    exit 1
}

# Function to add authentication to curl commands
curl_gh() {
    curl -H "Authorization: token $GITHUB_TOKEN" "$@"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS] [RUN_ID_OR_URL]"
    echo
    echo "This script downloads and installs the latest LimboAI Godot engine (regular version, not .NET) and export templates from the all_builds workflow."
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message and exit"
    echo "  -t TOKEN       Specify GitHub Personal Access Token"
    echo
    echo "Arguments:"
    echo "  RUN_ID_OR_URL  Optional. Specify a GitHub Actions run ID or full URL."
    echo "                 If not provided, the script will use the latest successful run from the all_builds workflow."
    echo
    echo "Examples:"
    echo "  $0                   # Install from the latest successful run (uses token from file)"
    echo "  $0 -t YOUR_TOKEN     # Use specified GitHub token"
    echo "  $0 10237889330       # Install from a specific run ID (uses token from file)"
    echo
    echo "Note: This script requires a GitHub Personal Access Token with the 'actions:read' scope."
    echo "      The token can be stored in $TOKEN_FILE or provided with the -t option."
    echo "      It will detect your system and download the appropriate version (excluding .NET version)."
    echo "      Export templates will be installed to ~/.local/share/godot/export_templates/."
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        *)
            RUN_ID_OR_URL="$1"
            break
            ;;
    esac
    shift
done

# If no token provided via command line, try to read from file
if [ -z "$GITHUB_TOKEN" ]; then
    if ! read_github_token; then
        echo "GitHub token not found in $TOKEN_FILE and not provided via -t option."
        guide_token_creation
    fi
fi

# Check token permissions
if ! check_token_permissions; then
    echo "The provided GitHub token does not have the required permissions."
    guide_token_creation
fi

# Function to get artifact download URLs
get_artifact_urls() {
    local run_id=$1
    local system_pattern=$2
    local api_url="https://api.github.com/repos/$REPO/actions/runs/$run_id/artifacts"
    echo "Downloading artifact information from $api_url" >&2
    local artifacts=$(curl_gh -s "$api_url")
    echo "Artifacts found:" >&2
    echo "$artifacts" | jq -r '.artifacts[].name' >&2
    echo "$artifacts" | jq -r --arg pattern "$system_pattern" '
        .artifacts[] | 
        select(
            (.name | contains($pattern) or contains("export-templates")) and 
            (.name | contains("dotnet") | not)
        ) | 
        .archive_download_url | 
        split("?")[0]
    '
}

# Function to extract run ID from URL or use it directly
get_run_id() {
    local input=$1
    if [[ $input =~ /runs/([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "$input"
    fi
}

# Detect system
detect_system() {
    local os=$(uname -s)
    local arch=$(uname -m)
    
    case "$os" in
        Linux*)
            case "$arch" in
                x86_64) echo "editor.linux.x86_64" ;;
                aarch64|arm64) echo "editor.linux.arm64" ;;
                *) echo "Unsupported Linux architecture: $arch" >&2; exit 1 ;;
            esac
            ;;
        Darwin*)
            echo "editor.macos.universal"
            ;;
        MINGW*|CYGWIN*|MSYS*)
            echo "editor.windows.x86_64"
            ;;
        *)
            echo "Unsupported operating system: $os" >&2
            exit 1
            ;;
    esac
}


# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        *)
            RUN_ID_OR_URL="$1"
            break
            ;;
    esac
    shift
done

# Check if a run ID or URL was provided
if [ -z "$RUN_ID_OR_URL" ]; then
    echo "Fetching the latest successful run from all_builds workflow..."
    LATEST_RUN_URL="https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW_FILE/runs?status=success&per_page=1"
    echo "Downloading from $LATEST_RUN_URL"
    RUN_ID=$(curl_gh -s "$LATEST_RUN_URL" | jq -r '.workflow_runs[0].id')
else
    RUN_ID=$(get_run_id "$RUN_ID_OR_URL")
fi

if [ -z "$RUN_ID" ]; then
    echo "Failed to get a valid run ID. Exiting."
    exit 1
fi

echo "Using run ID: $RUN_ID"

# Detect system and get artifact URLs
SYSTEM_PATTERN=$(detect_system)
echo "Detected system: $SYSTEM_PATTERN"
ARTIFACT_URLS=$(get_artifact_urls $RUN_ID $SYSTEM_PATTERN)

if [ -z "$ARTIFACT_URLS" ]; then
    echo "Failed to get artifact URLs. Exiting."
    exit 1
fi


# Function to extract filename from URL
get_filename_from_url() {
    local url=$1
    local filename=$(basename "$url")
    
    # Remove any query string
    filename=${filename%%\?*}
    
    # If filename ends with '/zip', remove it and add .zip extension
    if [[ $filename == "zip" ]]; then
        filename=$(basename $(dirname "$url")).zip
    fi
    
    echo "$filename"
}

# Function to download file if needed
download_if_needed() {
    local url="$1"
    local output_file="$2"
    
    if [ -f "$output_file" ]; then
        echo "File $output_file exists. skipping."
    else
        echo "Downloading $output_file..."
        curl_gh -o "$output_file" -L "$url"
    fi
    
    if [ $? -eq 0 ]; then
        echo "Download completed successfully."
        return 0
    else
        echo "Download failed."
        return 1
    fi
}

# Download and process artifacts
echo "Downloading and processing artifacts..."
mkdir -p limboai_temp
cd limboai_temp

echo "$ARTIFACT_URLS" | while read -r url; do
    filename=$(get_filename_from_url "$url")
    echo "Determined filename: $filename"
    
    if ! download_if_needed "$url" "$filename"; then
        echo "Failed to download or update ${filename}"
        exit 1
    fi

    echo "Unzipping ${filename}"
    unzip -n "$filename"
    
    # Check for and unzip godot-limboai.editor zip file
    LIMBOAI_ZIP=$(find . -name "godot-limboai.editor.*.zip" -type f)
    if [ -n "$LIMBOAI_ZIP" ]; then
        echo "Found LimboAI editor zip: $LIMBOAI_ZIP"
        echo "Unzipping LimboAI editor..."
        unzip -n -o "$LIMBOAI_ZIP"
    fi
done

# Find the Godot executable
GODOT_EXECUTABLE=$(find . -name "godot*" -type f -executable)

if [ -z "$GODOT_EXECUTABLE" ]; then
    echo "Failed to find the Godot executable. Exiting."
    exit 1
fi

# Extract version from Godot executable
FULL_GODOT_VERSION=$(./$GODOT_EXECUTABLE --version | tr -d '\r')
if [ -z "$FULL_GODOT_VERSION" ]; then
    echo "Failed to extract Godot version. Exiting."
    exit 1
fi
echo "Full Godot Version: $FULL_GODOT_VERSION"
# Extract the desired part of the version string
GODOT_VERSION=$(echo "$FULL_GODOT_VERSION" | grep -oP '[0-9\.]+\.limboai\+[a-zA-Z0-9\.]+(?=\.gha)')
echo "Detected Godot version: $GODOT_VERSION"

# Copy the Godot executable to /usr/bin/godot
echo "Copying Godot executable to /usr/bin/godot..."
sudo cp "$GODOT_EXECUTABLE" /usr/bin/godot

# Handle export templates
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates"
VERSION_TEMPLATES_DIR="$TEMPLATES_DIR/$GODOT_VERSION"
mkdir -p "$VERSION_TEMPLATES_DIR"

if [ -d "templates" ]; then
    echo "Installing export templates to $VERSION_TEMPLATES_DIR..."
    cp templates/* "$VERSION_TEMPLATES_DIR/"
else
    echo "Warning: Export templates not found."
fi

echo "Cleaning up..."
cd ..
rm -rf limboai_temp

echo "Installation completed."
echo "Godot executable copied to /usr/bin/godot"
echo "Export templates installed to $VERSION_TEMPLATES_DIR"