### What's changed in v0.2.0

* feat: extend default exempt list with falco + trivy-system (by @patrickleet)

  SecurityStack landed (xrs/stacks/k8s/security/) — its Falco DaemonSet
  legitimately requires privileged: true and Trivy Operator spawns scan
  jobs across the cluster. Adding both to the platform exempt list so
  the baseline disallow-privileged-containers (and future restricted-PSS
  policies) stop firing audit-mode PolicyReports against them.

  Same precedent as cert-manager, observe, etc. — platform infrastructure
  gets exempt by default; only tenant namespaces evaluate against
  baseline policies.

  Implements [[tasks/security-stack-install]] (Finding 3)
  Refs [[tasks/policy-stack-baseline-bundle]]


See full diff: [v0.1.0...v0.2.0](https://github.com/hops-ops/policy-stack/compare/v0.1.0...v0.2.0)
