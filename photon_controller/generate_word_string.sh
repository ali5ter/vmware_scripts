#!/usr/bin/env bash
# @file generate_word_string
# Cheesy word string generator
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

[[ -n $DEBUG ]] && set -x
set -eou pipefail

WORDFILE="/usr/share/dict/words"
TOTAL_WORDS=$(awk 'NF!=0 {++c} END {print c}' $WORDFILE)
NUM_WORDS=${1:-3}
DELIM=${2:--}

string=''
# shellcheck disable=SC2034
# shellcheck disable=SC2086
for i in $(seq $NUM_WORDS); do
    rnum=$(perl -e 'print int rand $ARGV[0], "\n"; ' -- "$TOTAL_WORDS")
    word=$(sed -n "$rnum p" $WORDFILE)
    if [ "$string" == "" ]; then string="$word"
    else string="${string}${DELIM}$word"
    fi
done
echo "$string" | sed s/\'//g | tr '[:upper:]' '[:lower:]'
