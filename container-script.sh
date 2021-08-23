#!/bin/bash
for file in /mnt/catalyst/specs/*.spec; do
    catalyst -f "$file"
done
