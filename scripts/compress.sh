#!/bin/sh
find . \
  -type f \
  ! -name '*.zst' \
  ! -name '*.md' \
  ! -path '*/.*' \
  ! -path '*/scripts/*' \
  -exec zstd --rm {} \;
