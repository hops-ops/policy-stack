### What's changed in v0.1.0

* feat: initial scaffold — Kyverno + Policy Reporter + pilot baseline policy (by @patrickleet)

  Cloud-neutral PolicyStack XRD (group hops.ops.com.ai) composing:
  - Kyverno engine (chart 3.8.0 / app v1.18.0 — meets spec CVE pipeline)
  - Policy Reporter (chart 3.7.4) + UI
  - Pilot baseline policy `disallow-privileged-containers` (Audit mode)
    vendored from kyverno/policies/pod-security/baseline with namespace-list
    exemption strategy (~18 platform namespaces, operator-extensible).

  Engine + reporter validated end-to-end on pat-local EKS:
  - 4 Kyverno controllers + 2 Policy Reporter pods Running
  - ClusterPolicy live, background scan generating PolicyReports
  - 10/10 KCL render tests pass

  Implements [[tasks/policy-stack-install]]
  Tracking [[tasks/policy-stack-baseline-bundle]]


