#!/bin/bash

set -e

echo "Building Macast..."

cd "$(dirname "$0")/.."

swift build -c release

echo "Build completed successfully!"
