# ====================================================
# This script checks active connections and ...
# Return codes:
# - 0 -> PASS: no dangerous connections found
# - 1 -> FAIL: at least one dangerous connection found
# - 2 -> UNEXPECTED FAILURE
# ====================================================

set -uo pipefail

ALLOWED_IPS=(
    "127.0.0.1"  # Localhost
)

WARNING="\e[1;33mWARNING ("$0"):\e[0m"
RET=0

# Check both TCP (-t) and UDP (-u) sockets
# NOTE: ss requires sudo to see all system connections
if sudo -n true 2>/dev/null
then
    SS_CMD="sudo ss -tunp"
else
    echo -e ""$WARNING" running without sudo permissions. Some connections may be hidden."
    SS_CMD="ss -tunp"
    RET=2
fi

# List IP addresses from active connections
# - awk '{print $6}' : extracts the sixth columns, i.e. "remote-ip-address:port"
# - cut -d: -f1      : strips the port number away
# - sort -u          : sort the remote IPs and remove duplicates
#                      NOTE: does not distinguish TCP from UDP connections
while IFS= read -r ip
do
    if [ -z $ip ]
    then
        echo -e ""$WARNING" empty IP address provided in the allow-list"
        RET=2
    fi

    IP_IS_ALLOWED=0

    for allowed_ip in "${ALLOWED_IPS[@]}"
    do
        if [ "$ip" == "$allowed_ip" ]
        then
            IP_IS_ALLOWED=1
            break
        fi
    done

    if (($IP_IS_ALLOWED == 0))
    then
        echo -e ""$WARNING" found active outbound connection with non-allowed IP $ip"
        RET=1
    fi
done < <($SS_CMD --no-header | awk '{print $6}' | cut -d: -f1 | sort -u)

exit $RET
