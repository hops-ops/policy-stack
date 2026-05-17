# policy-stack

Installs **Kyverno** (policy engine) and **Policy Reporter** (dashboard + Prometheus
metrics for PolicyReports) on a target Kubernetes cluster via two Helm Releases.

Cloud-neutral. Group: `hops.ops.com.ai`.

## What's included

- **Kyverno** — admission webhook + background controller + reports controller +
  cleanup controller. CRDs: `ClusterPolicy`, `ValidatingPolicy` (CEL, GA in 1.17),
  `MutatingPolicy`, `GeneratingPolicy`, `CleanupPolicy`, `PolicyException`, etc.
- **Policy Reporter** — UI + Prometheus exporter + alert routing over the
  `PolicyReport` CRD that Kyverno populates.

## What's NOT (yet) included

This first iteration is **engine only**. It installs the substrate. Baseline policy
content ships in subsequent iterations:

- Baseline PSS bundle (CEL `ValidatingPolicy` set)
- reports-server subchart with externally-managed Postgres
- Split webhook configurations (`failurePolicy: Fail` for security, `Ignore` for
  hygiene) — see [tasks/policy-stack-failurepolicy-split]
- Exemption strategy (label-based vs namespace-list — see
  [tasks/policy-stack-colima-spike])
- ObserveStack integration (ServiceMonitors, GrafanaDashboards, PrometheusRule)

## Minimal usage

```yaml
apiVersion: hops.ops.com.ai/v1alpha1
kind: PolicyStack
metadata:
  name: policy
  namespace: default
spec:
  clusterName: my-cluster
```

## Standard usage

```yaml
apiVersion: hops.ops.com.ai/v1alpha1
kind: PolicyStack
metadata:
  name: policy
  namespace: pat-local
spec:
  clusterName: pat-local
  kyverno:
    namespace: kyverno
    values:
      admissionController:
        replicas: 1   # 3 in production; colima default is 1
        # On colima keep failurePolicy: Ignore — Kyverno's own apiserver-wedge
        # incident report (zwindler, Feb 2026) is the cautionary tale.
        failurePolicy: Ignore
  policyReporter:
    namespace: policy-reporter
    values:
      ui:
        enabled: true
```

## Local testing

```bash
make render:all         # render both examples
make validate:all       # render + schema-validate
make test               # KCL unit tests
hops config install --path .   # install on colima
```

Apply a PolicyStack manifest and watch:

```bash
kubectl get policystacks -A
kubectl get releases.helm.m.crossplane.io
kubectl get pods -n kyverno
kubectl get pods -n policy-reporter
```

## References

- Spec: [specs/policy-stack] in GitKB
- Kyverno docs: https://kyverno.io/docs/
- Policy Reporter: https://github.com/kyverno/policy-reporter
- Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
