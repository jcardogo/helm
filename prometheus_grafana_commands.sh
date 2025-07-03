helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring

:<< 'END_COMMENT'
# Create a values.yaml file (e.g., vi my-monitoring-values.yaml)
# Example content to enable persistence for Grafana and Prometheus:
# my-monitoring-values.yaml
grafana:
  persistence:
    enabled: true
    # storageClassName: your-storage-class # Uncomment if you have a specific StorageClass
    size: 10Gi # Adjust size as needed
  adminPassword: your-secure-password # Set a strong password here for Grafana admin

prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi # Adjust size as needed
    # You might also want to enable or disable specific exporters here
    # nodeExporter:
    #   enabled: true
    # kube-state-metrics:
    #   enabled: true
# Note: Adjust the values according to your requirements.
# Install with custom values
helm install prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring -f my-monitoring-values.yaml
END_COMMENT

#Verify the deployment
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get deployments -n monitoring

# Access Grafana
kubectl get services -n monitoring | grep grafana # Look for a service named like 'prometheus-stack-grafana' or 'grafana'
kubectl port-forward svc/prometheus-stack-grafana 3000:85 -n monitoring # Access Grafana UI at http://localhost:3000
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode # Use the above command to get the Grafana admin password

#Access Prometheus
kubectl get services -n monitoring | grep prometheus-server # Look for a service named like 'prometheus-stack-prometheus'
kubectl port-forward svc/prometheus-stack-prometheus 9090:9090 -n monitoring # Access Prometheus UI 

# Install Local Path Provisioner for dynamic storage provisioning
helm repo add common https://charts.bitnami.com/common # Add Bitnami repo if you haven't already
helm repo update
helm install local-path-provisioner --namespace kube-system --create-namespace bitnami/local-path-provisioner

#PVC is created automatically by the Helm chart, but you can check it
kubectl get pvc -n monitoring | grep prometheus # Check if the PVC for Prometheus is created