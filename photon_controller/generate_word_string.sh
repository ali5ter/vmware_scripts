#!/usr/bin/env bash
# @file pc_create_flavors.sh
# Cheesy word string generator
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

WORDFILE="/usr/share/dict/words"
TOTAL_WORDS=$(awk 'NF!=0 {++c} END {print c}' $WORDFILE)
NUM_WORDS=${1:-3}

string=''
for i in $(seq $NUM_WORDS); do
    rnum=$((RANDOM%TOTAL_WORDS+1))
    word=$(sed -n "$rnum p" $WORDFILE)
    if [ "$string" == "" ]; then string="$word"
    else string="$string-$word"
    fi
done
echo "$string" | tr '[:upper:]' '[:lower:]'
