#!/bin/bash

mkdir temp
cd temp

echo "Creating test files..."
for i in {0..10}
do 
    echo "Creating fakefile${i}M.txt with size ${i}M..." 
    truncate -s "${i}M" "fakefile${i}M.txt"
done
