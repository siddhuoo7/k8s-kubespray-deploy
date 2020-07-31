echo "Declaring configuration variable"
echo "******************************************" 
# config variables

DNSNAME="kubeservice-aks"
logging_ns="logging"
monitoring_ns="monitoring"
messaging_ns="kafka"
load_balancer_ns="load-balancer"
operations_ns="operations"
deployment_ns="deployment"
slack_token="xoxb-1075050838129-1068657729780-eqo8RLuSRy8jdwMq8GNtyRBW"
slack_channel="#random"
elk_replicas="1"

echo "creating namespaces"
echo "******************************************" 
# create namespaces

kubectl create ns $load_balancer_ns
kubectl create ns $operations_ns
#kubectl create ns $logging_ns
kubectl create ns $monitoring_ns
kubectl create ns $messaging_ns
kubectl create ns mongo

#echo "creating namespaces"
#docker run --name rancher --restart=always -d -p 7000:80 -p 7010:443 -v rancher-data:/var/lib/rancher rancher/rancher:v2.3.5

#echo "Deploying elk in Kubernetes"
#echo "******************************************" 
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
#helm repo add elastic https://helm.elastic.co
#helm install  elasticsearch elastic/elasticsearch --set replicas=$elk_replicas -n $logging_ns
#kubectl wait --for=condition=Ready pods --all -n $logging_ns --timeout=60s
#helm install  kibana elastic/kibana --set service.type=LoadBalancer -n $logging_ns
#kubectl label nodes master-node dedicated=master
#sed -i "s|namespace: logging|namespace: $logging_ns|g" /root/database/logging/filebeat.yml
#kubectl wait --for=condition=Ready pods --all -n $logging_ns --timeout=60s
#kubectl create -f /root/database/logging/filebeat.yml

#echo "Deploying Prometheus and Grafana"
#echo "******************************************" 
#helm install grafana stable/grafana --values /root/database/monitoring/grafana.value -n $monitoring_ns
#helm install prometheus stable/prometheus --values  /root/database/monitoring/prometheus.value -n $monitoring_ns

echo "Deploying Kubernetes Event Exporter"
echo "******************************************" 
sed -i "s|slack_token|$slack_token|g" /root/database/monitoring/eventExporter/01-config.yaml
sed -i "s|slack_channel|$slack_channel|g" /root/database/monitoring/eventExporter/01-config.yaml
kubectl create -f /root/database/monitoring/eventExporter

echo "installing pod auto scaler"
echo "******************************************" 
 kubectl apply -f /root/database/hpa
 
echo "Install WeaveScope"
echo "******************************************" 
sed -i "s|namespace: monitoring|namespace: $monitoring_ns|g" /root/database/monitoring/weave.yaml
kubectl apply -f /root/database/monitoring/weave.yaml

echo "Deploying database"
echo "******************************************" 
kubectl apply -f /root/database/database/mongodb-workload.yaml -n mongo
kubectl apply -f /root/database/database/mongodbDnsMap -f /root/database/database/pgadmin-workload.yaml -f /root/database/database/postgres-workload.yaml

echo "Deploying kafka"
echo "******************************************" 
helm repo add strimzi https://strimzi.io/charts/
helm install kafka strimzi/strimzi-kafka-operator -n kafka
helm ls -A
kubectl wait --for=condition=Ready pods --all -n $messaging_ns
kubectl apply -f /root/database/messaging/kafka-persistent-2.yaml -n kafka 
kubectl apply -f /root/database/messaging/kafkaMapDns.yml

echo "Installing Kong API Gateway"
echo "******************************************" 
kubectl create -f /root/database/load-balancer/kong.yaml
# $IP="23.101.60.87"
IP=( $(kubectl get svc -n kong| grep kong-proxy | awk '{print $4}'))
PUBLICIPID=( $(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv))
#PUBLICIPID=az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv
az network public-ip update --ids $PUBLICIPID --dns-name $DNSNAME
az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[dnsSettings.fqdn]" -o table
         