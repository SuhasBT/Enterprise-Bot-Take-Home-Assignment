# Enterprise Bot Take‑Home Assignment

## How to Run

1. Ensure you have **Docker**, **kind**, **kubectl**, and **helm** installed.
2. Clone this repository and run:

cd Enterprise-Bot-Take-Home-Assignment

```bash
./setup.sh
```

## Verifying the Service

After running `./setup.sh`, verify that the service is running:

```bash
# Check pods
kubectl get pods -n demo

# Port-forward the service
kubectl port-forward svc/demo -n demo 8080:80

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/healthz
```


## How I Used AI

- I used Microsoft Copilot as an assistant to speed up repetitive tasks and boilerplate generation.
- Specifically, Copilot helped me:
  - Draft the initial Flask service code and Dockerfile structure.
  - Scaffold Helm chart templates (Deployment, Service, Ingress, ConfigMap).
  - Suggest an idempotent `setup.sh` script flow.
  - Provide structured outlines for the README and ANSWERS.md.
- I manually corrected and validated:
  - Helm template syntax (ensuring values.yaml keys were properly referenced).
  - Dockerfile multi-stage copy paths and non-root user setup.
  - Resource requests/limits to fit realistic demo workloads.
  - Cluster setup and ingress-nginx installation steps.
- I verified all commands and manifests locally in my own kind cluster.
- AI accelerated my workflow, but debugging, adjustments, and final validation were done by me.

## Continuous Integration

GitHub Actions runs on pushes and pull requests. It lints the Helm chart,
builds the service image, and scans it with Trivy. The workflow fails if the
image has any HIGH or CRITICAL vulnerabilities.
