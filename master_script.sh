#!/bin/bash

# Embedded URL of the .deb file
URL="https://github.com/Molecular-lang/GNU_Molecular_Compiler-Interpreter_toolchain/releases/download/Scpel_1.0-1_amd64/scpel_1.0-1_amd64.deb"
PKG_NAME="scpel"
OUTPUT="/tmp/$PKG_NAME.deb"
PACKAGE_INSTALLED=$(dpkg-query -W --showformat='${Status}\n' "$PKG_NAME" 2>/dev/null | grep "install ok installed")

# Colors for progress bars
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print each character with a delay and color
print_with_delay() {
  local str="$1"
  local delay="$2"
  local color="$3"
  for ((i = 0; i < ${#str}; i++)); do
    printf "${color}%c${NC}" "${str:i:1}"
    sleep "$delay"
  done
  echo ""
}

# Function to show installation progress with color
installation_with_progress() {
  local duration=10
  local progress=0
  local bar_length=50

  echo "Master Script: Installing $OUTPUT..."
  while [ $progress -lt $duration ]; do
    local percent=$((progress * 100 / duration))
    local filled_length=$((bar_length * percent / 100))
    local empty_length=$((bar_length - filled_length))

    printf "\r${BLUE}["
    for ((i = 0; i < filled_length; i++)); do printf "#"; done
    for ((i = 0; i < empty_length; i++)); do printf "."; done
    printf "] %d%%${NC}" $percent

    sleep 1
    progress=$((progress + 1))
  done
  echo ""
}

# Function to download file with custom progress bar using wget
download_with_progress() {
  local url="$1"
  local output="$2"

  wget --progress=dot $url -O $output 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk -v BLUE="$BLUE" -v NC="$NC" '
  BEGIN { 
    bar_length = 50;
  }
  {
    percent = $2;
    gsub(/[%\[\]]/, "", percent);
    filled_length = int(bar_length * percent / 100);
    empty_length = bar_length - filled_length;

    printf "\r" BLUE "[";
    for (i = 0; i < filled_length; i++) printf "#";
    for (i = 0; i < empty_length; i++) printf ".";
    printf "] %d%%" NC, percent;
  }
  END { print "" }'
}

# Check if the package is already installed
if [ "$PACKAGE_INSTALLED" ]; then
  print_with_delay "Master Script: Package $PKG_NAME is already installed." 0.05 "$YELLOW"
  read -p "Master Script: Do you want to uninstall, upgrade, or reinstall? (u/g/r): " choice
  case "$choice" in
    u|U)
      sudo apt-get remove --purge "$PKG_NAME"
      if [ $? -ne 0 ]; then
        print_with_delay "Master Script: Error: Uninstallation failed." 0.05 "$RED"
        exit 1
      fi
      print_with_delay "Master Script: Package uninstalled successfully." 0.05 "$GREEN"
      exit 0
      ;;
    g|G|r|R)
      print_with_delay "Master Script: Proceeding with download and installation..." 0.05 "$YELLOW"
      ;;
    *)
      print_with_delay "Master Script: Invalid choice. Exiting." 0.05 "$RED"
      exit 1
      ;;
  esac
fi

# Check if the file already exists
if [ -f "$OUTPUT" ]; then
  print_with_delay "Master Script: File $OUTPUT already exists." 0.05 "$YELLOW"
  read -p "Master Script: Do you want to delete it and redownload? (y/n): " choice
  if [ "$choice" == "y" ]; then
    rm "$OUTPUT"
    print_with_delay "Master Script: File deleted." 0.05 "$GREEN"
  else
    read -p "Master Script: Enter a new name for the downloaded file: " new_name
    OUTPUT="/tmp/$new_name"
  fi
fi

# Download the file with custom progress bar
print_with_delay "Master Script: Downloading standard package manager (MOLE)..." 0.05 "$BLUE"
download_with_progress "$URL" "$OUTPUT"

# Check the downloaded file size and handle network issues
FILE_SIZE=$(stat -c%s "$OUTPUT" 2>/dev/null)
if [ $? -ne 0 ] || [ "$FILE_SIZE" -le 0 ]; then
  print_with_delay "Master Script: Error: File $OUTPUT not found or could not be read." 0.05 "$RED"
  read -p "Master Script: There was a network issue. Do you want to retry download or exit? (r/e): " choice
  if [ "$choice" == "r" ]; then
    rm "$OUTPUT"
    print_with_delay "Master Script: Retrying download..." 0.05 "$YELLOW"
    download_with_progress "$URL" "$OUTPUT"
    FILE_SIZE=$(stat -c%s "$OUTPUT" 2>/dev/null)
    if [ $? -ne 0 ] || [ "$FILE_SIZE" -le 0 ]; then
      print_with_delay "Master Script: Error: Download failed again. Exiting." 0.05 "$RED"
      exit 1
    fi
  else
    print_with_delay "Exiting Master Script." 0.05 "$RED"
    exit 1
  fi
fi

print_with_delay "Master Script: Downloaded file size: $FILE_SIZE bytes" 0.05 "$GREEN"

# Simulate installation progress
installation_with_progress

# Install the downloaded deb file using dpkg and handle dependencies with apt-get
sudo dpkg -i "$OUTPUT"

if [ $? -ne 0 ]; then
  print_with_delay "Master Script: Error: Installation failed. Attempting to fix dependencies." 0.05 "$RED"
  sudo apt-get install -f -y
  if [ $? -ne 0 ]; then
    print_with_delay "Master Script: Error: Failed to fix dependencies." 0.05 "$RED"
    exit 1
  fi
fi

print_with_delay "Master Script: Installation completed successfully." 0.05 "$GREEN"
