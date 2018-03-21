#!/bin/bash

set -x
set -e

if [[ -n $(find /var/lib/ceph/mon -prune -empty) ]]; then
  UUID=$(uuidgen)
  MON_SECRET=$(ceph-authtool --gen-print-key)
  MON_ID=$HOSTNAME
  MON_PATH="/var/lib/ceph/mon/${CLUSTER}-${MON_ID}/"
  mkdir -p ${MON_PATH}
  chown -R ceph:ceph ${MON_PATH}
  ceph-mon --cluster "${CLUSTER}" -i "${MON_ID}" --mkfs --keyring /etc/ceph/mon.keyring --setuser ceph --setgroup ceph
fi

for MON_ID in $(find /var/lib/ceph/mon -maxdepth 1 -name "${CLUSTER}*" | sed 's/.*'"${CLUSTER}"'-//'); do
  exec /usr/bin/ceph-mon -d -i "${MON_ID}" --keyring /etc/ceph/mon.keyring --setuser ceph --setgroup ceph
done

