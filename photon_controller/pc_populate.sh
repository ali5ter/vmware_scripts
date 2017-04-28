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

photon deployment list &> /dev/null || {
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
LIMITS_LARGE="\
vm 20000 COUNT, vm.cost 20000 COUNT, vm.cpu 20000 COUNT, vm.memory 20000 GB, \
ephemeral-disk 20000 COUNT, ephemeral-disk.capacity 20000 GB, ephemeral-disk.cost 20000 GB, \
persistent-disk 20000 COUNT, persistent-disk.capacity 20000 GB, persistent-disk.cost 20000 GB, \
storage.LOCAL_VMFS 20000 COUNT, \
sdn.floatingip.size 20000 COUNT"
LIMITS_SMALL="\
vm 100 COUNT, vm.cost 100 COUNT, vm.cpu 100 COUNT, vm.memory 100 GB, \
ephemeral-disk 100 COUNT, ephemeral-disk.capacity 100 GB, ephemeral-disk.cost 100 GB, \
persistent-disk 100 COUNT, persistent-disk.capacity 100 GB, persistent-disk.cost 100 GB, \
storage.LOCAL_VMFS 100 COUNT, \
sdn.floatingip.size 100 COUNT"

set -x

# Inconsistent option to define the name. Probably should be --name ...
photon -n tenant create "$TEST_TENANT" --limits "$LIMITS_LARGE"

# Inconsistent option to define set. Probably should be set-default...
photon tenant set "$TEST_TENANT"

# Should be easier to get the ID of an object...
# Also show show default object if no ID supplied...
photon tenant show $(photon tenant list | grep -E "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")

# Should be allowed to identify an object by it's name OR ID.
# Also the name should be a named option, i.e. --name...
# Also a clearer alternative to --default-router-private-ip-cidr would be
#  --private-cidr...
photon -n project create "$TEST_PROJECT" --tenant "$TEST_TENANT" -limits "$LIMITS_LARGE" \
    --default-router-private-ip-cidr 10.0.10.0/16

photon project set "$TEST_PROJECT"

# Should be easier to get the ID of an object...
# Also show show default object if no ID supplied...
photon project show $(photon project list | grep -E "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")

# Should be an easier way to parse the ID...
# Object IDs are inconsistent...
router=$(photon router list | grep -Eo "[0-9a-f]{21}")

# Tenant and project options should use default...
photon -n router create --name "${TEST_PROJECT}-router-2" \
    --privateIpCidr 11.0.0.0/16

photon router list

# Clearer alternative to --privateIpCidr would be --private-cidr...
photon -n subnet create --name "${TEST_PROJECT}-subnet-1" \
    --description "$("$PWD/generate_word_string.sh" 12 ' ')" \
    --privateIpCidr 10.0.10.0/24 --router "$router" --type NAT
photon -n subnet create --name "${TEST_PROJECT}-subnet-2" \
    --description "$("$PWD/generate_word_string.sh" 10 ' ')" \
    --privateIpCidr 10.0.20.0/24 --router "$router" --type NAT

default_subnet=$(photon subnet list | grep -Eo "[0-9a-f]{21}" | tail -n 1)

photon -n subnet set-default "$default_subnet"

photon subnet list

# TODO: Create VMs

# TODO: Create Services

#
# Create filler Tenants and Projects
#

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

        photon -n project create "$project" --limits "$LIMITS_SMALL"
    done

done

