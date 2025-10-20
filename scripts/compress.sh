#!/bin/sh
find ath12k/ qcom/ renesas_usb_fw.mem -type f -exec zstd --rm {} \;
