#!/bin/bash
set -e

# Terraform execution script
# This script provides a convenient way to execute common Terraform commands

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage information
function show_usage {
  echo -e "${BLUE}Usage:${NC} $0 [command] [environment] [options]"
  echo
  echo -e "${BLUE}Commands:${NC}"
  echo "  init       - Initialize Terraform working directory"
  echo "  plan       - Create an execution plan"
  echo "  apply      - Apply the changes required to reach the desired state"
  echo "  destroy    - Destroy the Terraform-managed infrastructure"
  echo "  validate   - Validate the configuration files"
  echo "  fmt        - Reformat configuration files to canonical format"
  echo "  help       - Show this help message"
  echo
  echo -e "${BLUE}Environments:${NC}"
  echo "  dev        - Development environment"
  echo "  staging    - Staging environment"
  echo "  prod       - Production environment"
  echo
  echo -e "${BLUE}Options:${NC}"
  echo "  -auto-approve  - Skip interactive approval (for apply/destroy)"
  echo "  -var-file      - Specify a variable file"
  echo
  echo -e "${BLUE}Examples:${NC}"
  echo "  $0 init dev"
  echo "  $0 plan prod"
  echo "  $0 apply staging"
  echo "  $0 destroy dev -auto-approve"
  echo "  $0 apply prod -var-file=custom.tfvars"
}

# Function to check if environment directory exists
function check_env_dir {
  local env=$1
  if [ ! -d "environments/$env" ]; then
    echo -e "${RED}Error:${NC} Environment '$env' not found. Available environments:"
    ls -1 environments 2>/dev/null || echo "  No environments found. Create an environment directory first."
    exit 1
  fi
}

# Function to detect operating system
function detect_os {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/debian_version ]; then
      echo "debian"
    elif [ -f /etc/redhat-release ]; then
      echo "redhat"
    else
      echo "linux-other"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

# Function to install Terraform
function install_terraform {
  local os=$1
  echo -e "${YELLOW}Attempting to install Terraform...${NC}"
  
  case $os in
    debian)
      echo -e "${BLUE}Installing Terraform on Debian/Ubuntu...${NC}"
      sudo apt-get update
      sudo apt-get install -y gnupg software-properties-common curl
      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      sudo apt-get update
      sudo apt-get install -y terraform
      ;;
    redhat)
      echo -e "${BLUE}Installing Terraform on CentOS/RHEL...${NC}"
      sudo yum install -y yum-utils
      sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      sudo yum -y install terraform
      ;;
    macos)
      echo -e "${BLUE}Installing Terraform on macOS...${NC}"
      if command -v brew &> /dev/null; then
        brew install terraform
      else
        echo -e "${RED}Error:${NC} Homebrew is not installed. Please install Homebrew first:"
        echo "  /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
      fi
      ;;
    *)
      echo -e "${RED}Error:${NC} Automatic installation not supported for your OS."
      echo -e "${BLUE}Please install Terraform manually:${NC}"
      echo "  Download from: https://www.terraform.io/downloads.html"
      return 1
      ;;
  esac
  
  # Verify installation
  if command -v terraform &> /dev/null; then
    echo -e "${GREEN}Terraform installed successfully!${NC}"
    return 0
  else
    echo -e "${RED}Failed to install Terraform.${NC}"
    return 1
  fi
}

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
  echo -e "${YELLOW}Terraform is not installed.${NC}"
  read -p "Do you want to install Terraform automatically? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    OS=$(detect_os)
    if ! install_terraform "$OS"; then
      echo -e "${RED}Error:${NC} Failed to install Terraform. Please install it manually."
      echo -e "${BLUE}Installation instructions:${NC}"
      echo "  Ubuntu/Debian: sudo apt-get install terraform"
      echo "  CentOS/RHEL: sudo yum install terraform"
      echo "  macOS: brew install terraform"
      echo "  Or download from: https://www.terraform.io/downloads.html"
      exit 1
    fi
  else
    echo -e "${RED}Error:${NC} Terraform is required to continue. Please install Terraform first."
    echo -e "${BLUE}Installation instructions:${NC}"
    echo "  Ubuntu/Debian: sudo apt-get install terraform"
    echo "  CentOS/RHEL: sudo yum install terraform"
    echo "  macOS: brew install terraform"
    echo "  Or download from: https://www.terraform.io/downloads.html"
    exit 1
  fi
fi

# Parse command line arguments
if [ $# -lt 1 ]; then
  show_usage
  exit 1
fi

COMMAND=$1
shift

# Handle help command
if [ "$COMMAND" == "help" ]; then
  show_usage
  exit 0
fi

# Check if environment is specified
if [ $# -lt 1 ]; then
  echo -e "${RED}Error:${NC} Environment not specified."
  show_usage
  exit 1
fi

ENV=$1
shift

# Create environments directory if it doesn't exist
if [ ! -d "environments" ]; then
  mkdir -p "environments"
  echo -e "${YELLOW}Warning:${NC} Created 'environments' directory. You need to create environment-specific directories inside it."
fi

# Handle commands that don't require environment check
if [ "$COMMAND" == "fmt" ]; then
  echo -e "${GREEN}Running:${NC} terraform fmt"
  terraform fmt -recursive
  exit $?
fi

# Check if environment exists (except for init which might create it)
if [ "$COMMAND" != "init" ]; then
  check_env_dir "$ENV"
fi

# Create environment directory if it doesn't exist (for init)
if [ "$COMMAND" == "init" ] && [ ! -d "environments/$ENV" ]; then
  mkdir -p "environments/$ENV"
  echo -e "${GREEN}Created environment directory:${NC} environments/$ENV"
fi

# Check if tfvars file exists for the environment
TFVARS_FILE="environments/$ENV/terraform.tfvars"
if [ -f "$TFVARS_FILE" ]; then
  VAR_FILE_ARG="-var-file=$TFVARS_FILE"
else
  echo -e "${YELLOW}Warning:${NC} No terraform.tfvars file found for environment '$ENV'"
  VAR_FILE_ARG=""
fi

# Execute the appropriate Terraform command
case "$COMMAND" in
  init)
    echo -e "${GREEN}Running:${NC} terraform init $*"
    terraform init "$@"
    ;;
  plan)
    echo -e "${GREEN}Running:${NC} terraform plan $VAR_FILE_ARG $*"
    terraform plan "$VAR_FILE_ARG" "$@"
    ;;
  apply)
    echo -e "${GREEN}Running:${NC} terraform apply $VAR_FILE_ARG $*"
    terraform apply "$VAR_FILE_ARG" "$@"
    ;;
  destroy)
    echo -e "${GREEN}Running:${NC} terraform destroy $VAR_FILE_ARG $*"
    terraform destroy "$VAR_FILE_ARG" "$@"
    ;;
  validate)
    echo -e "${GREEN}Running:${NC} terraform validate $*"
    terraform validate "$@"
    ;;
  *)
    echo -e "${RED}Error:${NC} Unknown command: $COMMAND"
    show_usage
    exit 1
    ;;
esac
