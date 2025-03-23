#!/bin/bash
set -e

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

INSTALL_DIR="${HOME}/.book-tools"
BIN_DIR="${HOME}/.local/bin"
REPO_URL="https://github.com/yourusername/book-tools.git"

# Print header
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   Book Tools CLI Installation Script    ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed. Please install git first.${NC}"
    exit 1
fi

# Create installation directory if it doesn't exist
echo -e "${YELLOW}Creating installation directory...${NC}"
mkdir -p "${INSTALL_DIR}"
mkdir -p "${BIN_DIR}"

# Clone or update the repository
if [ -d "${INSTALL_DIR}/.git" ]; then
    echo -e "${YELLOW}Book Tools already installed, updating...${NC}"
    cd "${INSTALL_DIR}"
    git pull origin main
else
    echo -e "${YELLOW}Downloading Book Tools...${NC}"
    git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

# Make scripts executable
echo -e "${YELLOW}Making scripts executable...${NC}"
cd "${INSTALL_DIR}/src"
chmod +x make-scripts-executable.sh
./make-scripts-executable.sh

# Create wrapper script in bin directory
echo -e "${YELLOW}Creating book-tools command...${NC}"
cat > "${BIN_DIR}/book-tools" << 'EOF'
#!/bin/bash

TOOLS_DIR="${HOME}/.book-tools"

function show_help {
    echo "Book Tools CLI"
    echo ""
    echo "Usage: book-tools [command] [arguments]"
    echo ""
    echo "Available commands:"
    echo "  create BOOKNAME [language] [--copy-scripts]   Create a new book project"
    echo "  build [options]                            Build a book"
    echo "  help                                       Show this help message"
    echo ""
    echo "For more information, see the documentation at:"
    echo "https://github.com/yourusername/book-tools"
}

# Check if the command exists
if [ -z "$1" ]; then
    show_help
    exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
    create)
        "${TOOLS_DIR}/src/scripts/create-book.sh" "$@"
        ;;
    build)
        "${TOOLS_DIR}/src/scripts/build.sh" "$@"
        ;;
    help)
        show_help
        ;;
    *)
        echo "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
EOF

chmod +x "${BIN_DIR}/book-tools"

# Check if BIN_DIR is in PATH, if not, suggest adding it
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo -e "${YELLOW}NOTE: ${BIN_DIR} is not in your PATH.${NC}"
    echo -e "${YELLOW}To add it, run one of the following commands:${NC}"
    echo -e ""
    echo -e "${GREEN}For bash:${NC} echo 'export PATH=\"\${HOME}/.local/bin:\${PATH}\"' >> ~/.bashrc"
    echo -e "${GREEN}For zsh:${NC} echo 'export PATH=\"\${HOME}/.local/bin:\${PATH}\"' >> ~/.zshrc"
    echo -e ""
    echo -e "${YELLOW}Then restart your terminal or run:${NC} source ~/.bashrc (or ~/.zshrc)"
fi

echo -e "${GREEN}Installation successful!${NC}"
echo -e "${GREEN}You can now use Book Tools by running:${NC} book-tools [command]"
echo -e ""
echo -e "${BLUE}Examples:${NC}"
echo -e "${BLUE}- Create a new book:${NC} book-tools create my-book"
echo -e "${BLUE}- Build a book:${NC} book-tools build"
echo -e "${BLUE}- Show help:${NC} book-tools help"
echo -e ""
echo -e "${YELLOW}For more information, visit:${NC} https://github.com/yourusername/book-tools" 