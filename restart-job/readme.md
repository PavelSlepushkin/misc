### Restart job.
The idea of this job is to restart deployments during cluster upgrades or different nodes reconfigurations.
The idea - select nodes by filter and exit if there is no nodes found.
if nodes found - find node in evictions, find blocking PDB (with allowed disruptions=0), if there's any deployment on node in eviction state - execute kubectl restart rollout deployment and sleep for some time.
Repeat until completion.
Known issue - it doesn't work with StatefulSets, but:
 - we do not want to restart STS
 - at the moment all STS in clusters have more than 1 pod and were not blocking upgrades

Job will be cleaned up 86400 seconds after compeltion.
This will not be needed when https://github.com/kubernetes/kubernetes/issues/93476 will be fixed

The approach can be used for different automations
Chart can be easily reused for other scripts. Roles(templates/clusterrole.yaml) for serviceaccount should be checked/rewritten in case of using other scripts.
