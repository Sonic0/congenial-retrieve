#!/usr/bin/env bash
set -euo pipefail # Uncomment to "unofficial bash strict mode"

# trap INIT QUIT and TERM exit signal
trap 'error "${SCRIPT_NAME}: FATAL ERROR at $(date "+%HH%M") (${SECONDS}s): Interrupt signal intercepted! Exiting now..." 2>&1; |
      exit 99;' INT QUIT TERM # terminal interrupt (CTRL+C, SIGINT)

 #== general variables ==#
#export RUST_BACKTRACE=1

SCRIPT_NAME="$(basename "${0}")" # scriptname without path
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" # script directory
SCRIPT_FULLPATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

# TODO -> check if target already added, otherwise add it. Useful in a ci/cd
# rustup target add x86_64-unknown-linux-musl

cd tbot-lambda
cargo build --release --target x86_64-unknown-linux-musl
cp target/x86_64-unknown-linux-musl/release/congenial-spork bootstrap &&
  zip lambda.zip bootstrap && rm bootstrap | exit 1

exit 0