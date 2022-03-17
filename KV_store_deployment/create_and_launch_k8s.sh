cluster_name="kv-store-cluster"

gcloud container clusters create $cluster_name --num-nodes=3
kubectl apply -f ./kv_store_deploy.yml
kubectl apply -f ./load_balancer.yml