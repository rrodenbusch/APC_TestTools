#!/bin/bash

declare -a pins=(9,11,13,17,22,27);

for p in "${pins[@]}"
do
   gpio -g mode $u in
done
