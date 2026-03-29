#!/bin/bash

set -e

echo "Running Macast..."

cd "$(dirname "$0")/.."

swift run

echo "Macast started!"
