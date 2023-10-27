#!/bin/zsh
#
function echoTS(){
echo "$(date -u +%Y-%m-%dT%H:%M:%S%Z): $1"
}
echoTS "starting job"
cd /tmp
V="1.24.7"
SLEEPINTERVAL=120
curl -LO "https://it4it-nexus-tp-repo.swissbank.com/repository/public-bin-crossplatform-kubectl/v${V}/bin/linux/amd64/kubectl"
chmod a+x kubectl
./kubectl get no
# list of nodes of version 1.26.4 - can used during upgrade
#./kubectl get no -o go-template='{{range .items}}{{if eq .status.nodeInfo.kubeletVersion "v1.26.4" }}{{.metadata.name}} {{"\n"}}{{end}}{{end}}' |wc -l
while true ; do 
  echoTS "checking count of nodes to change"
  CNT=$(./kubectl get no -o go-template='{{range .items}}{{if eq .status.nodeInfo.kubeletVersion "v1.25.6" }}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' |wc -l)
  echoTS "count of nodes to change: ${CNT}"
  if [[ ${CNT} -eq 0 ]]; then
    # no more nodes for process, job can exist with success
    echoTS "no more nodes to process"
    ./kubectl get no
    exit 0
  fi
  # loop over all unchedulable nodes
  for NODE in $(./kubectl get no -o go-template='{{range .items}}{{if .spec.unschedulable}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'); do
    # loop over PDB with no disruptions allowed
    for PDB in $(./kubectl get pdb -A -o go-template='{{range .items}}{{if not .status.disruptionsAllowed }}{{printf "%s,%s \n" .metadata.namespace .metadata.name }}{{end}}{{end}}') ; do
      PARTS=(${(s:,:)PDB})
      NAMESPACE=${PARTS[1]}
      DEPLOY=${PARTS[2]}
      echo "checking pdb ${NAMESPACE}/${DEPLOY}"
      # that trick with selector is directly from https://kubernetes.io/docs/reference/kubectl/cheatsheet/
      # search for "list name of the pod that belong to Particular RC"
      # in our case - we get selector from PDB
      SEL=${$(./kubectl get pdb -n ${NAMESPACE} ${DEPLOY} -ojson | jq -j '.spec.selector.matchLabels | to_entries | .[] | "\(.key)=\(.value),"')%?}
      CNTPODS=$(./kubectl -n ${NAMESPACE} get po --selector=${SEL} -o wide |grep ${NODE} |wc -l)
      if [[ ${CNTPODS} -eq 0 ]]; then
        echoTS "No pods from pdb ${NAMESPACE}/${DEPLOY} on node ${NODE}."
      else
        echoTS "Restarting deployment from pdb ${NAMESPACE}/${DEPLOY} to free up node ${NODE}"
        ./kubectl rollout restart deploy -n ${NAMESPACE} --selector=${SEL}
      fi  
    done
  done
  echoTS "sleeping for ${SLEEPINTERVAL} seconds"
  sleep ${SLEEPINTERVAL}
done
