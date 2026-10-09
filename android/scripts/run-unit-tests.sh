#!/usr/bin/env bash
# JVM unit tests for uly-engine (no device required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
./gradlew :uly-engine:testDebugUnitTest --stacktrace
