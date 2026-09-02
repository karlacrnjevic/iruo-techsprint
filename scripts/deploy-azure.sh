#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-users.csv>"
  exit 1
fi

CSV_PATH=$(realpath "$1")
TERRAFORM_DIR="$(cd "$(dirname "$0")/../azure/full" && pwd)"

if [ ! -f "$CSV_PATH" ]; then
  echo "ERROR: CSV file does not exist: $CSV_PATH"
  exit 1
fi

if [ -z "${TF_VAR_moodle_db_password:-}" ]; then
  echo "ERROR: TF_VAR_moodle_db_password is not set."
  echo "Set it before deployment:"
  echo 'export TF_VAR_moodle_db_password="your-password"'
  exit 1
fi

echo "======================================"
echo " TechSprint Azure deployment"
echo "======================================"
echo "Users CSV: $CSV_PATH"
echo "Terraform: $TERRAFORM_DIR"
echo

terraform -chdir="$TERRAFORM_DIR" init
terraform -chdir="$TERRAFORM_DIR" validate

terraform -chdir="$TERRAFORM_DIR" apply \
  -var="users_csv_path=$CSV_PATH"
