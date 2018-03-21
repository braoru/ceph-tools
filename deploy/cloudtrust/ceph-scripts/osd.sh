#!/bin/bash

set -x
set -e

if [[ -n $(find /var/lib/ceph/osd -prune -empty) ]]; then
  UUID=$(uuidgen)
  OSD_SECRET=$(ceph-authtool --gen-print-key)
  OSD_ID=$(echo "{\"cephx_secret\":\"${OSD_SECRET}\"}" | ceph --cluster ${CLUSTER} osd new "${UUID}" -i - -n client.bootstrap-osd -k /etc/ceph/osd.keyring)
  if [[ -z ${OSD_ID} ]]; then
    exit 1
  fi
  OSD_PATH="/var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/"
  mkdir -p ${OSD_PATH}
  chown -R ceph:ceph ${OSD_PATH}
  ceph-osd --cluster "${CLUSTER}" -i "${OSD_ID}" --mkfs --osd-uuid "${UUID}" --osd-journal "${OSD_PATH}/journal" --setuser ceph --setgroup ceph
  ceph-authtool --create-keyring "${OSD_PATH}"/keyring --name osd."${OSD_ID}" --add-key "${OSD_SECRET}" --setuser ceph --setgroup ceph
fi

for OSD_ID in $(find /var/lib/ceph/osd -maxdepth 1 -name "${CLUSTER}*" | sed 's/.*-//'); do
  exec /usr/bin/ceph-osd -d -i "${OSD_ID}" --setuser ceph --setgroup ceph
done

