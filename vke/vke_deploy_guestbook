#!/usr/bin/env bash
# @file vke_deploy_guestbook.sh
# Deploy a example app onto kubernetes backing a VKE Smart Cluster
# @see https://kubernetes.io/docs/tutorials/stateless-application/guestbook/
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

cleanup() {
    heading 'Remove guestbook app'

    read -p "Shall I remove the guestbook application from the cluster? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && {
        erun kubectl delete deployment redis-master redis-slave frontend
        erun kubectl delete service -l app=redis
        erun kubectl delete service -l app=guestbook
    }
}
trap cleanup EXIT

source "$PWD/vke_env.sh"

# select a smart cluster and generate kube-config file -----------------------

"$PWD/vke_cluster_auth.sh"

# download config files ------------------------------------------------------

heading 'Download YAML config files'

cd ~/tmp
mkdir -p guestbook && cd guestbook
curl -O https://kubernetes.io/docs/tutorials/stateless-application/guestbook/redis-master-deployment.yaml
curl -O https://kubernetes.io/docs/tutorials/stateless-application/guestbook/redis-master-service.yaml
curl -O https://kubernetes.io/docs/tutorials/stateless-application/guestbook/redis-slave-deployment.yaml
curl -O https://kubernetes.io/docs/tutorials/stateless-application/guestbook/redis-slave-service.yaml
curl -O https://kubernetes.io/docs/tutorials/stateless-application/guestbook/frontend-deployment.yaml
curl -O https://kubernetes.io/docs/tutorials/stateless-application/guestbook/frontend-service.yaml

pod_status_of_name() {
    kubectl get pod "$1" -o json | jq -r '.status.phase'
}

pod_names_starting_with() {
    obj="$1"
    kubectl get pods -o json | jq -r --arg obj "$obj" '.items[] | select(.metadata.name | startswith($obj)) | .metadata.name'
}

# Start up redis master ------------------------------------------------------

heading 'Start up Redis master'

erun kubectl apply -f redis-master-deployment.yaml

REDIS_MASTER_NAME="$(pod_names_starting_with redis-master)"

echo "Waiting for $REDIS_MASTER_NAME to start..."
_pod_state="$(pod_status_of_name $REDIS_MASTER_NAME)"
until [ "$_pod_state" == "Running" ]; do
    sleep 10
    _pod_state="$(pod_status_of_name $REDIS_MASTER_NAME)"
    echo -e "\t$_pod_state"
done

erun kubectl get pod
erun kubectl logs --tail=100 "$REDIS_MASTER_NAME"

# Start up redis master service ----------------------------------------------

heading 'Start up Redis master service'

erun kubectl apply -f redis-master-service.yaml

erun kubectl get service 

# Start up redis master slaves -----------------------------------------------

heading 'Start up Redis slaves'

erun kubectl apply -f redis-slave-deployment.yaml

REDIS_SLAVE_NAMES="$(pod_names_starting_with redis-master)"

for _slave in $REDIS_SLAVE_NAMES; do
    echo "Waiting for $_slave to start..."
    _pod_state="$(pod_status_of_name $_slave)"
    until [ "$_pod_state" == "Running" ]; do
        sleep 10
        _pod_state="$(pod_status_of_name $_slave)"
    done
done

erun kubectl get pod

# Start up redis master service ----------------------------------------------

heading 'Start up Redis slave service'

erun kubectl apply -f redis-slave-service.yaml

erun kubectl get service 

# Start frontend -------------------------------------------------------------

heading 'Start up frontend'

erun kubectl apply -f frontend-deployment.yaml

frontend_pods_running() { 
    kubectl get pods -l app=guestbook -l tier=frontend | grep -Ec '1/1.*Running'
}

echo "Waiting for frontend to start..."
until [[ "$(frontend_pods_running)" == "3" ]]; do
    sleep 10
done

erun kubectl get pods

# Start up frontend service ----------------------------------------------

heading 'Start up frontend service'

sed -i '' 's/type: NodePort/# type: NodePort/g' frontend-service.yaml
sed -i '' 's/# type: LoadBalancer/type: LoadBalancer/g' frontend-service.yaml

erun kubectl apply -f frontend-service.yaml

erun kubectl get service 

frontend_hostname() { 
    kubectl get service frontend -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].hostname'
}

echo -n "Waiting for hostname to be assigned..."
_hostname="$(frontend_hostname)"
until [[ "$_hostname" != '' ]]; do
    sleep 10
    _hostname="$(frontend_hostname)"
    echo -n '.'
done
echo -e "\n\t$_hostname"

# scale up and down ----------------------------------------------------------

heading 'Scale out the frontend'
until [[ $REPLY =~ ^[0-9]+$ ]]; do
    read -p "How many frontend replicas do you want? "
done

erun kubectl scale deployment frontend --replicas="$REPLY"

max_allocated_compute() {
    _name=$(cat ~/.kube/config | grep current-context | sed 's/current-context: \(.*\)-context/\1/')
    _metrics=($(vke -o json cluster show $_name | jq -r '.details.actualSize.MemoryMB, .maxSize.MemoryMB, .details.actualSize.vCPU, .maxSize.vCPU' | tr "\n" " "))
    if [[ "${_metrics[0]}" == "${_metrics[1]}" ]]; then
        echo "!!! Memory is maxed out: Requested ${_metrics[0]} out of ${_metrics[1]} MB allocated"
        return 1
    elif [[ "${_metrics[2]}" == "${_metrics[3]}" ]]; then
        echo "!!!! vCPU is maxed out: Requested ${_metrics[2]} out of ${_metrics[3]} vCPUs allocated"
        return 1
    fi
    return 0
}

until [[ "$(frontend_pods_running)" == "$REPLY" ]]; do
    erun kubectl get pods
    max_allocated_compute || break
done