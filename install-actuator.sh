OC_CMD=oc
MAO_IMAGE="quay.io/oglok/machine-api-operator:latest"
CAP_IMAGE="quay.io/oglok/cluster-api-provider-baremetal:latest"

echo "Disabling Cluster Version Operator"
$OC_CMD scale deployment cluster-version-operator -n openshift-cluster-version --replicas=0

echo "Deleting machinesets and machines..."
MACHINESET=$($OC_CMD get machineset -n openshift-machine-api | grep worker | awk '{print $1}')
$OC_CMD delete machineset $MACHINESET -n openshift-machine-api

MASTER=$($OC_CMD get machine -n openshift-machine-api | grep master | awk '{print $1}')
$OC_CMD delete machine $MASTER -n openshift-machine-api &

echo "Replacing configmaps..."
$OC_CMD delete configmap machine-api-operator-images -n openshift-machine-api
$OC_CMD create configmap machine-api-operator-images --from-file=images.json -n openshift-machine-api -o yaml | $OC_CMD apply -f -

$OC_CMD delete configmap cluster-config-v1 -n kube-system
$OC_CMD create configmap cluster-config-v1 --from-file=install-config -n kube-system -o yaml | $OC_CMD apply -f -

echo "Updating image from Machine API Operator..."
$OC_CMD set image deployment machine-api-operator -n openshift-machine-api machine-api-operator=$MAO_IMAGE

sleep 3
$OC_CMD get pods -n openshift-machine-api
#$OC_CMD scale deployment machine-api-operator -n openshift-machine-api --replicas=0
#$OC_CMD scale deployment machine-api-operator -n openshift-machine-api --replicas=1

echo "Updating image from Cluster API controllers..."
$OC_CMD set image deployment clusterapi-manager-controllers -n openshift-machine-api controller-manager=$CAP_IMAGE machine-controller=$CAP_IMAGE

sleep 3
$OC_CMD get pods -n openshift-machine-api


#$OC_CMD scale deployment clusterapi-manager-controllers -n openshift-machine-api --replicas=0
#$OC_CMD scale deployment clusterapi-manager-controllers -n openshift-machine-api --replicas=1
