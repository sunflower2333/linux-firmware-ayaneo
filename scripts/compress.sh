#!/bin/sh
find ../ath12k/ ../qcom/ -type f -exec zstd --rm {} \;
