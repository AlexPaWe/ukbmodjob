#!/usr/bin/env bash

set -xe

# Use a flag to turn on and of the gdb part of testing.
#RUN_GDB=0
#while getopts g: flag
#do
#  case "${flag}" in
#    g)
#      RUN_GDB=1
#  esac
#done

#apt-get install -y curl # already done in my container

QEMU_GUEST=${QEMU_GUEST:-$(which qemu-guest)}
BRIDGE=ukbench$WAYFINDER_CORE_ID0 # create a unique bridge
BRIDGE_IP="172.${WAYFINDER_CORE_ID0}.${WAYFINDER_CORE_ID1}.1"
UNIKERNEL_INITRD=${UNIKERNEL_INITRD:-"/usr/src/unikraft/apps/nginx/initramfs.cpio"}
UNIKERNEL_IMAGE=${UNIKERNEL_IMAGE:-"/usr/src/unikraft/apps/nginx/build/nginx_kvm-x86_64"}
UNIKERNEL_DBG="${UNIKERNEL_IMAGE}.dbg"
UNIKERNEL_IP="172.${WAYFINDER_CORE_ID0}.${WAYFINDER_CORE_ID1}.2"
NUM_PARALLEL_CONNS=${NUM_PARALLEL_CONNS:-30}
DURATION=${DURATION:-10}

ITERATIONS=10

UK_TRACE_SCRIPT=/usr/src/unikraft/unikraft/support/scripts/uk_trace/trace.py

if [[ ! -f $UNIKERNEL_IMAGE ]]; then
  echo "Missing unikernel image!"
  exit 1
fi

if [[ ! -f $UNIKERNEL_INITRD ]]; then
  echo "Missing initram image!"
  exit 1
fi

function cleanup {
  ifconfig $BRIDGE down || true
  brctl delbr $BRIDGE || true
  pkill qemu-system-x86_64 || true
}

trap "cleanup" EXIT


for (( i=1; i <= ITERATIONS; i++ )); do
  BRIDGE_IT=$BRIDGE$i
  BRIDGE_IP_IT="${BRIDGE_IP}${i}"

  UNIKERNEL_IP_IT="${UNIKERNEL_IP}${i}"

  echo "Creating bridge..."
  brctl addbr $BRIDGE || true
  ifconfig $BRIDGE down
  ifconfig $BRIDGE $BRIDGE_IP
  ifconfig $BRIDGE up

  echo "Starting unikernel..."
  taskset -c $WAYFINDER_CORE_ID0 \
    $QEMU_GUEST \
      -k $UNIKERNEL_IMAGE \
      -x \
      -g 123$i \
      -m 1024 \
      -i $UNIKERNEL_INITRD \
      -b $BRIDGE \
      -p $WAYFINDER_CORE_ID1 \
      -a "netdev.ipv4_addr=${UNIKERNEL_IP} netdev.ipv4_gw_addr=${BRIDGE_IP} netdev.ipv4_subnet_mask=255.255.255.0 vfs.rootdev=ramfs --"

  # make sure that the server has properly started
  sleep 5
  
  curl -Lvk http://$UNIKERNEL_IP:80

  echo "Starting experiment..."
  taskset -c $WAYFINDER_CORE_ID2 \
    wrk \
      -d $DURATION --latency \
      -t $NUM_PARALLEL_CONNS \
      -c $NUM_PARALLEL_CONNS http://$UNIKERNEL_IP:80/payload.txt &> /results$i.txt

  cat /results$i.txt

  echo "Starting gdb..."
  gdb -x run-gdb -ex "func 123$i" $UNIKERNEL_DBG
  echo "Completed dumping traces."

  pip3 install tabulate
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8
  $UK_TRACE_SCRIPT list traces.dat > traces$i.txt

  rm traces.dat

  ifconfig $BRIDGE down || true
  brctl delbr $BRIDGE || true
  pkill -f qemu-system-x86_64 #|| true

  # wait untill the vm has shut down
  #sleep 31

done

echo "Done!"
