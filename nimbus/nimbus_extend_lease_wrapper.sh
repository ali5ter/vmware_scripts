#!/usr/bin/env bash
# @file nimbus_extend_lease_wrapper.sh
# Extend the lease on a Nimbus testbed
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e
set -x

source "$PWD/nimbus_config.sh"
NIMBUS="$NUMBUS_HOST"

#ssh "$USER"@"$HOST" /usr/bin/env bash <<"EOT"
cat <<"EOT" > /tmp/foo
set -x
NIMBUS="$NUMBUS_HOST"
echo "Checking remaining days on the lease of testbed $PREFIX..."
EXP_DATE=$(/mts/git/bin/nimbus-ctl --nimbusLocation=sc --testbed list | grep 'lease expires' | sed 's/.*expires at \(.*\), .*/\1/')
REMAINING=$(( ($(date -d $EXP_DATE +%s) - $(date +%s) )/(60*60*24) ))
if [[ "$REMAINING" == '1' ]]; then
    /mts/git/bin/nimbus-ctl --nimbusLocation=sc --lease "$LEASE_DAYS" --testbed extend_lease "$PREFIX"
else
    echo "Still have $REMAINING days left"
fi
EOT
cat /tmp/foo

# TODO: put launchd plist into ~/Library/LaunchAgents
