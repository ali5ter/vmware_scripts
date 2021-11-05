#!/usr/bin/env bash
# @file tmc_config.sh
# VMware Tanzu Mission Control account settings and preferences
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

# shellcheck disable=SC2034
TMC_CONTEXT='tmc-unstable'
TMC_API_TOKEN="$(cat ~/.config/$TMC_CONTEXT-token)"
TMC_MNGMT_CLUSTER='attached'
TMC_PROVISIONER='attached'
TMC_LOG_LEVEL='debug'
TMC_CLUSTER_NAME='alb-dev-local'
TMC_CLUSTER_GROUP='alb-test'
TMC_WORKSPACE='alb-test'
TMC_DESCRIPTION="🦄  Alister testing again. Please delete if needed."
TMC_LABELS='env=test,generatedFrom=vmware_scripts'
TMC_UPDATE_DATE="$HOME/.config/.tmc_last_update"