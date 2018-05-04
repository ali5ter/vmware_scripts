#!/usr/bin/env bash
# @file cascade_deploy_wordpress.sh
# Deploy a helm based app to K8s cluster backing a Cascade Smart Cluster
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

type helm &> /dev/null || {
    echo 'Please install helm. Installation instructions are available from'
    echo 'https://docs.helm.sh/using_helm/#installing-helm'
    echo 'If you use homebrew on macOS, install using:'
    echo 'brew install kubernetes-helm'
    exit 1
}

source "$PWD/cascade_env.sh"

# select a smart cluster and generate kube-config file -----------------------

"$PWD/cascade_cluster_auth.sh"

# install/upgrade the K8s agent that helm talks to -----------------------------------

heading 'Install/upgrade helm agent (tiller) on the K8s cluster'
helm init --upgrade
sleep 5 ## give tiller a chance to upgrade

# deploy a helm chart for wordpress ------------------------------------------

heading 'Deploy chart for wordpress and wait for service to be externally available'
_prefix=$(echo "${DEPLOYMENT_PREFIX}-wp-$(date '+%s')" | tr '[:upper:]' '[:lower:]')
_doc="$PWD/$_prefix.txt"
echo -e "Chart documentation will be written to \n$_doc"
echo -n 'Deploying chart... '
helm install --name "$_prefix" stable/wordpress > "$_doc"
echo 'done'
echo -n 'Wait for the LB external IP to be assigned...'
kubectl get svc --namespace default -w "${_prefix}-wordpress" > /dev/null
echo 'done'

# test the deployment by using wordpress -------------------------------------

heading 'Show browsable URL to the wordpress site and kube dashboard'

## Unable to get the external IP using the following technique documented by 
## this wordpress chart
##_ip=$(kubectl get svc --namespace default "${_prefix}-wordpress" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

get_fqdn() { kubectl get svc --namespace default "${_prefix}-wordpress" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; }
echo -n "Waiting for ingress hostname..."
_fqdn=''
while [ "$_fqdn" == "" ]; do
    sleep 10; _fqdn=$(get_fqdn); echo -n '.'
done
echo 'done'

_url="http://${_fqdn}/admin"
echo -e "\nOpen the Wordpress admin UI using\n$_url"
[[ "$OSTYPE" == "darwin"* ]] && open "$_url"
echo "Refresh the webpage at this URL until the weberver responds."
_password=$(kubectl get secret --namespace default "${_prefix}-wordpress" -o jsonpath="{.data.wordpress-password}" | base64 --decode)
echo "Log in using credentials (user/$_password)"

# open kube dashboard --------------------------------------------------------

_fqdn=$(kubectl cluster-info | grep master | sed 's/.*is running at \(.*\):6443.*/\1/' | tr -d '[:cntrl:]' | sed 's/\[0;33m//')
_url="$_fqdn:30443/"
echo -e "\nOpen the Kube Dashboard using\n$_url"
[[ "$OSTYPE" == "darwin"* ]] && open "$_url"

# clean up -------------------------------------------------------------------

heading "Remove existing K8s deployments starting with $DEPLOYMENT_PREFIX"
read -p "Shall I clear out all existing deployments now? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && {
    for deployment in $(helm ls | grep "$DEPLOYMENT_PREFIX" | awk '{print $1}'); do
        read -p "Delete $deployment? [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && {
            helm del --purge "$deployment"
            [[ -f "$_doc" ]] && rm "$_doc"
        }
    done
}