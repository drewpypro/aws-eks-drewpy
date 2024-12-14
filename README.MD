![eks-drewpy](img/aws_eks_drewpy_highlevel.png)

```
aws-eks-drewpy/
├── eks/
│   ├── eks.tf               # Main Terraform configuration for the EKS cluster
│   ├── main.tf              # Provider and base setup (may include variables or VPC setup)
│   ├── variables.tf         # Define variables like region, cluster name, etc.
│   ├── outputs.tf           # Outputs for reference (like cluster endpoint, kubeconfig, etc.)
│   └── iam.tf               # (Optional) IAM roles and policies for EKS
├── kubernetes/
│   ├── namespaces/
│   │   ├── namespace1.yaml  # Namespace configuration for Namespace1
│   │   └── namespace2.yaml  # Namespace configuration for Namespace2
│   ├── gateways/
│   │   ├── ingress-gateway.yaml  # Istio Ingress Gateway configuration
│   │   └── egress-gateway.yaml   # Istio Egress Gateway configuration
│   ├── virtual-services/
│   │   ├── service1-virtual-service.yaml  # VirtualService for routing to service in Namespace1
│   │   └── service2-virtual-service.yaml  # VirtualService for routing to service in Namespace2
│   └── deployments/
│       ├── app1-deployment.yaml  # Deployment configuration for app in Namespace1
│       └── app2-deployment.yaml  # Deployment configuration for app in Namespace2
└── README.md                   # Documentation on how to deploy and test
```

# TO DO
- Istio Created NLB security-group rules
- ArgoCD integration


# References
 - [Control Plane SG](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest#input_cluster_additional_security_group_ids)
 - aws s3 cp s3://logstorebucket/exportedlogs/ ./exportedlogs --recursive
# Goals
- Build EKS cluster
    - 2 worker nodes
    - 2 istio ingress nodes
    - 2 Pods with a namespace each
    - istio sidecar proxys in each pod.
- Build Security-Groups with appropriate rules
- Test Network connectivity (ping, ssh, http)
    - ec2 to namespace1 application 
        ```
        ec2->nlb->istio-ingress->istio-proxy->namespace1
        ```
    - ec2 to namespace2 application 
        ```
        ec2->nlb->istio-ingress->istio-proxy->namespace2
        ```
    - ec2 to pod
        ```
        ec2->pod1
        ```
    - ec2 to node
        ```
        ec2->node1
        ```
    - ec2 to eks-api-server
    - public internet to namespace1 app
        ```
        home_net->nlb->istio-ingress->istio-proxy->namespace1
        ```
    - Cloudflare WAF to ingress istio gateway. 
    - GWLB suricata on ingress (IDS or IPS)

# Validation

```


Step 1: Verify Access to the Cluster

	Ensure you can connect to your EKS cluster.

	rm ~/.kube/config
	aws eks update-kubeconfig --region us-east-1 --name eks-drewpy
	kubectl get nodes

Step 2: Verify Namespaces and Pods
	Check that Istio and your application namespaces are up and running.

	kubectl get namespaces
	kubectl get pods
	kubectl get pods -n istio-system
	kubectl get pods -n namespace1
	kubectl get pods -n namespace2


	Ensure the Istio pods (istio-ingressgateway, istiod, etc.) and your application pods (Nginx) are in the Running state.


Step 3: Verify the Nginx Service
	Get details about your Nginx service.

	kubectl get svc
	kubectl get svc -n istio-system
	kubectl describe svc istio-ingressgateway -n istio-system
	kubectl describe svc istiod -n istio-system

Step 5: Verify Ingress Gateway Configuration

	Check that Istio VirtualService and Gateway are configured correctly.

	kubectl get gateway -n namespace1
	kubectl describe gateway egress-gateway -n istio-system
	kubectl describe gateway ingress-gateway -n istio-system

	kubectl get virtualservice -n namespace1
	kubectl get virtualservice -n namespace2
	kubectl describe virtualservice service1-virtual-service -n namespace1
	kubectl describe virtualservice service2-virtual-service -n namespace2


Step 6: Test Access to Nginx from Inside the Cluster
	
	kubectl get pods -n <your-app-namespace>

	Execute a shell inside the Nginx pod:

	kubectl exec -it <nginx-pod-name> -n <your-app-namespace> -- /bin/bash

	Curl the Nginx server from within the pod:

	curl localhost

Step 8: Check Logs

	Check logs for troubleshooting.

	Nginx Pod Logs:

	kubectl logs <nginx-pod-name> -n <your-app-namespace>

	Istio Ingress Gateway Logs:

	kubectl logs -n istio-system $(kubectl get pods -n istio-system -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}')

kubectl describe nodes

kubectl describe nodes ip-10-0-1-116.ec2.internal
kubectl describe nodes ip-10-0-1-122.ec2.internal
kubectl describe nodes ip-10-0-2-110.ec2.internal
kubectl describe nodes ip-10-0-2-209.ec2.internal


find exportedlogs/ -name "*.gz" -exec gunzip {} \;
find 57c5917c-a76d-410c-b5e4-6d8bfcd974ff/ -exec cat {} + > dns_queries.csv
find exportedlogs/ -exec cat {} + > flow_logs.csv

```