$NAME = "podman-machine-default"
$CPUS = 8
$MEMORY = 12288
$DISK = 100

podman machine rm -f $NAME 2>$null

podman machine init `
  --cpus $CPUS `
  --memory $MEMORY `
  --disk-size $DISK `
  $NAME

podman machine start $NAME

podman machine ssh $NAME -- sudo sysctl -w net.ipv4.ip_unprivileged_port_start=0
podman machine ssh $NAME -- echo "net.ipv4.ip_unprivileged_port_start=0" | sudo tee /etc/sysctl.d/99-unprivileged-ports.conf
podman machine ssh $NAME -- sudo sysctl --system

podman machine stop $NAME
podman machine start $NAME