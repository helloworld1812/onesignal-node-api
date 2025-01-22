#!/bin/bash

# Load environment variables from .env.local
if [ -f .env.local ]; then
  export $(grep -v '^#' .env.local | xargs)
fi

PACKAGE_PATH=$1
NPM_REGISTRY="https://npm.pkg.github.com"

# Read the package name and version from the package.json file in the given path
PACKAGE_NAME=$(jq -r .name < "$PACKAGE_PATH/package.json")
PACKAGE_VERSION=$(jq -r .version < "$PACKAGE_PATH/package.json")

# Check if the package version already exists on the registry
npm_config_registry=$NPM_REGISTRY npm view "$PACKAGE_NAME@$PACKAGE_VERSION" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "Version $PACKAGE_VERSION of $PACKAGE_NAME is already published. Exiting with success."
  exit 0
else
  # Try to publish the package if the version does not exist
  npm publish $PACKAGE_PATH --registry $NPM_REGISTRY --no-git-tag-version --no-push --yes
  PUBLISH_EXIT_CODE=$?

  if [ $PUBLISH_EXIT_CODE -eq 0 ]; then
    echo "Package published successfully."
    exit 0
  elif [ $PUBLISH_EXIT_CODE -eq 1 ]; then
    echo "Publish failed due to version conflict. Exiting with success."
    exit 0
  else
    echo "Publish failed with exit code $PUBLISH_EXIT_CODE. Exiting with failure."
    exit 1
  fi
fi
