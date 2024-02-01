# demo

this a demo repo to recreate https://github.com/syself/cluster-api-provider-hetzner/issues/1136 

To recreate the issue fill in the `HCLOUD_SSH_KEY`, `HCLOUD_TOKEN`, `GITHUB_TOKEN` environment variables on top of `script.sh`

> script.sh requires kubectl, clusterctl and kind to be available

Then run `bash script.sh` to create a cluster, destroy and recreate the kind cluster and reapply the cluster