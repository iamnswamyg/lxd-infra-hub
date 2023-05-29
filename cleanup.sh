
#!/bin/bash

declare -a SCRIPT_PREFIX=(infra)
# Get the list of running containers
containers=$(lxc list -c ns --format=json | jq -r '.[] | .name')

# Loop through the containers and stop them
for container in $containers; do
    for script_pref in "${SCRIPT_PREFIX[@]}"
    do
    if echo "$container" | grep -q "${script_pref}"; then
        if [[ $(lxc info "$container"| grep Status | awk '{print $2}') == "RUNNING" ]]; then
            echo "Stopping container: $container"
            lxc stop "$container"
        fi    
        lxc delete "$container" --force
    fi
    done
done


# Get the list of profiles
profiles=$(lxc profile list --format=json | jq -r '.[] | .name')
# Loop through the profiles and delete them
for profile in $profiles; do
    if echo "$profile" | grep -q "${SCRIPT_PREFIX[0]}"; then
        echo "deleting profile: $profile"
        lxc profile delete "$profile"
    fi
done

# Get the list of networks
networks=$(lxc network list --format=json | jq -r '.[] | .name')
# Loop through the networks and delete them
for network in $networks; do
    if echo "$network" | grep -q "${SCRIPT_PREFIX[0]}"; then
        echo "deleting network: $network"
        lxc network delete "$network"
    fi
done

# Get the list of storage pools
pools=$(lxc storage list --format=json | jq -r '.[] | .name')


# Loop through the profiles and delete them
 for pool in $pools; do
    if echo "$pool" | grep -q "${SCRIPT_PREFIX[0]}"; then
        echo "deleting pool: $pool"
        lxc storage delete "$pool"
    fi
done

echo "listing the containers"
lxc list -c ns --format=json | jq -r '.[] | .name'
echo "listing networks"
lxc network list --format=json | jq -r '.[] | .name'
echo "lisiting storage pools"
lxc storage list --format=json | jq -r '.[] | .name'
echo "lisiting profiles"
lxc profile list --format=json | jq -r '.[] | .name'
