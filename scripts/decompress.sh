#!/bin/sh
find ../ath12k/ ../qcom -name "*.zst" -exec unzstd --rm {} \;
