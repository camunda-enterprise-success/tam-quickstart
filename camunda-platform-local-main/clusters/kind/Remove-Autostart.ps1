param(
[string]$ClusterName = "camunda-platform"
)

Write-Host "Setting restart policy to no..."

docker ps -a --filter "name=$ClusterName" --format "{{.Names}}" | % {
docker update --restart=no $_
}

Write-Host "Done. Nodes will not auto-start with Docker."