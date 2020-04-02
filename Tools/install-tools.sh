# Kured
kubectl apply -f ./kured/rbac.yml
kubectl apply -f ./kured/deamonset.yml

# Descheduler
kubectl apply -f ./descheduler/rbac.yml
kubectl apply -f ./descheduler/configmap.yml
kubectl apply -f ./descheduler/cronjob.yml