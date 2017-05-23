#!/usr/bin/env bash
# @file pc_populate.sh
# Populate an instance with some objects
# @see https://github.com/vmware/photon-controller/wiki/Command-Line-Cheat-Sheet
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

type photon &> /dev/null || {
    echo "Please install photon CLI by downloading it from the release page at"
    echo "https://github.com/vmware/photon-controller/releases"
    echo "Add execute permissions and move into your path, e.g."
    echo "  chmod +x ~/Downloads/photon-darwin64-1.2-dd9d360"
    echo "  sudo mv ~/Downloads/photon-darwin64-1.2-dd9d360 /usr/local/bin/photon"
    exit 1
}

photon target info | grep -q Version || {
    echo "Set your Photon Platform target and log into it, e.g."
    echo "  photon target set -c https://192.168.0.10:443"
    echo "  photon target login --username administrator@local --password 'passwd'"
    exit 1
}

read -p "Shall I clear out all existing objects from this instance? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && "$PWD/pc_clean.sh"

read -p "Shall I create flavors for this instance? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && "$PWD/pc_create_flavors.sh"

read -p "Shall I upload images to this instance? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && "$PWD/pc_upload_images.sh"

NUM_TENANTS=10
TENANT_NAMES=$(seq $NUM_TENANTS | xargs -Iz "$PWD/generate_word_string.sh")
TEST_TENANT='Test-Tenant'
TEST_PROJECT='Test-Project'
TEST_VM='Test-VM'
TEST_SERVICE='Test-Service'

limits() {
    local spec="\
vm.count %d COUNT, vm.cost %d COUNT, vm.cpu %d COUNT, vm.memory %d GB, \
ephemeral-disk %d COUNT, ephemeral-disk.capacity %d GB, ephemeral-disk.cost %d GB, \
persistent-disk %d COUNT, persistent-disk.capacity %d GB, persistent-disk.cost %d GB, \
storage.LOCAL_VMFS %d COUNT, storage.VSAN %d COUNT, \
sdn.floatingip.size %d COUNT"
    local v=${1-100}
    printf "$spec" "$v" "$v" "$v" "$v" "$v" "$v" "$v" "$v" "$v" "$v" "$v" "$v" "$v"
}

LIMITS_LARGE=$(limits 20000)
LIMITS_SMALL=$(limits 100)

set -x

# Inconsistent option to define the name. Probably should be --name ...
photon -n tenant create "$TEST_TENANT" --limits "$LIMITS_LARGE"

# Inconsistent positional option for object name...
photon -n tenant quota update "$TEST_TENANT" --limits 'ephemeral-disk.flavor.vm-disk 20000 COUNT'
photon -n tenant quota update "$TEST_TENANT" --limits 'persistent-disk.flavor.vm-disk 20000 COUNT'

# Inconsistent option to define set. Probably should be set-default...
photon tenant set "$TEST_TENANT"

# Should be easier to get the ID of an object...
# Also show show default object if no ID supplied...
photon tenant show "$(photon tenant list | grep "$TEST_TENANT" | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")"
echo

# Should be allowed to identify an object by it's name OR ID.
# Also the name should be a named option, i.e. --name...
# Also a clearer alternative to --default-router-private-ip-cidr would be
#  --private-cidr...
photon -n project create "$TEST_PROJECT" --tenant "$TEST_TENANT" -limits "$LIMITS_LARGE" \
    --default-router-private-ip-cidr 10.0.10.0/16

# Should be easier to get the ID of an object...
project_id=$(photon project list | grep "$TEST_PROJECT" | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")

# Inconsistent positional option for object name...
photon -n project quota update "$project_id" --limits 'ephemeral-disk.flavor.vm-disk 20000 COUNT'
photon -n project quota update "$project_id" --limits 'persistent-disk.flavor.vm-disk 20000 COUNT'

# Should be able to use name or ID...
photon project set "$TEST_PROJECT"

# Also show show default object if no ID supplied...
photon project show "$project_id"
echo

# Should be an easier way to parse the ID...
# Object IDs are inconsistent...
router=$(photon router list | grep -Eo "[0-9a-f]{21}")

# Tenant and project options should use default...
photon -n router create --name "${TEST_PROJECT}-router-2" \
    --privateIpCidr 11.0.0.0/16

photon router list
echo

# Clearer alternative to --privateIpCidr would be --private-cidr...
photon -n subnet create --name "${TEST_PROJECT}-subnet-1" \
    --description "$("$PWD/generate_word_string.sh" 12 ' ')" \
    --privateIpCidr 10.0.10.0/24 --router "$router" --type NAT

default_subnet=$(photon subnet list | grep -Eo "[0-9a-f]{21}" | tail -n 1)

photon -n subnet set-default "$default_subnet"

photon subnet list
echo

image_id=$(photon image list | grep photon1 | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")

photon -n vm create --name "${TEST_VM}-1" --flavor tiny-vm --image "$image_id" --boot-disk-flavor vm-disk

vm_id=$(photon vm list | grep "${TEST_VM}-1" | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")

network_id=$(photon vm networks "$vm_id" | grep True | grep -Eo "[0-9a-f]{21}")

photon vm acquire-floating-ip --network_id "$network_id" "$vm_id"

# Unable to create affinity with vm created - throws error using...
#photon -n disk create --name "${TEST_PROJECT}-disk-1" --flavor vm-disk --capacityGB 100 --affinities "vm:$vm_id"
photon -n disk create --name "${TEST_PROJECT}-disk-1" --flavor vm-disk --capacityGB 100

disk_id=$(photon disk list | grep "${TEST_PROJECT}-disk-1" | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")

photon disk show "$disk_id"
echo

# Attach disk sometimes fails...
photon -n vm attach-disk --disk "$disk_id" "$vm_id"

vm_id_list=$(photon vm list | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")

for vm_id in $vm_id_list; do
    photon -n vm start "$vm_id"
done

for vm_id in $vm_id_list; do
    photon vm show "$vm_id"
    echo
done

photon vm list
echo

# Should be able to get service type from the image list...
photon system info | grep -q KUBERNETES || {

    image_id=$(photon image list | grep kube | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")
    photon -n deployment enable-service-type --type KUBERNETES -image-id "$image_id"
}

set +x
read -p "Shall I create a Kubernetes cluster service? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && {
    set -x
    # Currently throws error when creating etcd VM...
    # Worker count option has inconsistent syntax; should be -number-of-workers...
    photon -n service create --name "$TEST_SERVICE" --type KUBERNETES \
        --number-of-masters 1 --worker_count 1 --number-of-etcds 1 \
        --container-network 10.2.0.0/16 --vm_flavor kube-worker-vm --disk_flavor vm-disk &
    set +x
}

read -p "Should I fill out the UI with more tenants and projects? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && {
    set -x

    for tenant in $TENANT_NAMES; do
        photon -n tenant create "$tenant" --limits "$LIMITS_SMALL"
    done

    # Should be easier to get the name of an object...
    for tenant in $(photon tenant list | grep -E "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}" | awk '{print $2}'); do

        # Should be allowed to identify an object by it's name OR ID...
        photon tenant set "$tenant"

        set +x
        NUM_PROJECTS=$(( ( RANDOM % 10 )  + 1 ))
        PROJECT_NAMES=$(seq $NUM_PROJECTS | xargs -Iz "$PWD/generate_word_string.sh")
        set -x

        for project in $PROJECT_NAMES; do

            # Percent option should probably be --limit-percentage...
            photon -n project create "$project" --percent 10
        done
    done
}
