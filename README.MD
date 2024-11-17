![eks-drewpy](img/aws_eks_drewpy_highlevel.png)

# Goals
- Build EKS cluster
    - 2 worker nodes
    - 2 istio ingress nodes
    - 2 Pods with a namespace each
    - istio sidecar proxys in each pod.
- Build Security-Groups with appropriate rules
- Test Network connectivity
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
    -ec2 to eks-api-server