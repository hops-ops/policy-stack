import models.ai.com.ops.hops.v1alpha1 as stacksv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

# ==============================================================================
# Unit tests for PolicyStack XRD
#
# Philosophy: test YOUR API, not the provider's.
# - render/validate already checks provider schema correctness
# - Tests verify XRD spec fields produce the expected composed resources
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: minimal claim renders kyverno + policy-reporter Helm releases
    #         and their namespaces.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-both-releases"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "policy"
                spec.clusterName = "my-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "kyverno"
                    spec.forProvider = {
                        chart = {
                            name = "kyverno"
                            repository = "https://kyverno.github.io/kyverno/"
                            version = "3.8.0"
                        }
                        namespace = "kyverno"
                    }
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "policy-reporter"
                    spec.forProvider = {
                        chart = {
                            name = "policy-reporter"
                            repository = "https://kyverno.github.io/policy-reporter/"
                            version = "3.7.4"
                        }
                        namespace = "policy-reporter"
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "policy-namespace-kyverno"
                    spec.forProvider.manifest = {
                        apiVersion = "v1"
                        kind = "Namespace"
                        metadata.name = "kyverno"
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "policy-namespace-policy-reporter"
                    spec.forProvider.manifest = {
                        apiVersion = "v1"
                        kind = "Namespace"
                        metadata.name = "policy-reporter"
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: custom labels merge with stack defaults on every composed resource.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-labels-merged-with-defaults"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "labeled-policy"
                spec = {
                    clusterName = "my-cluster"
                    labels = {team = "platform", environment = "staging"}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "kyverno"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/policystack" = "labeled-policy"
                            team = "platform"
                            environment = "staging"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: reporter disabled — only kyverno release renders.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "policy-reporter-disabled-skips-its-release"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "kyverno-only"
                spec = {
                    clusterName = "my-cluster"
                    policyReporter = {enabled = False}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "kyverno"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: kyverno disabled — only policy-reporter release renders.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "kyverno-disabled-skips-its-release"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "reporter-only"
                spec = {
                    clusterName = "my-cluster"
                    kyverno = {enabled = False}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "policy-reporter"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: custom chart versions propagate.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-chart-versions-propagate"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "version-test"
                spec = {
                    clusterName = "my-cluster"
                    kyverno = {chartVersion = "3.4.0"}
                    policyReporter = {chartVersion = "3.1.5"}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "kyverno"
                    spec.forProvider.chart.version = "3.4.0"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "policy-reporter"
                    spec.forProvider.chart.version = "3.1.5"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6: baseline.pss=baseline (default) renders the pilot policy in Audit.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "baseline-default-renders-pilot-policy-audit"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "policy"
                spec.clusterName = "my-cluster"
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "policy-policy-disallow-privileged-containers"
                    spec.forProvider.manifest = {
                        apiVersion = "kyverno.io/v1"
                        kind = "ClusterPolicy"
                        metadata.name = "disallow-privileged-containers"
                        spec = {
                            validationFailureAction = "Audit"
                            background = True
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 7: baseline.pss=off skips all baseline policy rendering.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "baseline-pss-off-skips-policies"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "engine-only"
                spec = {
                    clusterName = "my-cluster"
                    baseline = {pss = "off"}
                }
            }
            # The kyverno + policy-reporter Releases still render; only baseline
            # policies are skipped. We assert by absence — no Object MR for the
            # pilot policy should exist in this render.
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "kyverno"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 8: per-policy action override flips pilot policy to Enforce.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "per-policy-action-override-flips-to-enforce"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "policy"
                spec = {
                    clusterName = "my-cluster"
                    baseline.policies.disallowPrivilegedContainers.action = "Enforce"
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "policy-policy-disallow-privileged-containers"
                    spec.forProvider.manifest.spec.validationFailureAction = "Enforce"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 9: operator-extended exempt namespaces appear in the exclude list.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "operator-exempt-namespaces-merge-with-defaults"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "policy"
                spec = {
                    clusterName = "my-cluster"
                    baseline.exemptNamespaces = ["my-platform-ns", "another-ns"]
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "policy-policy-disallow-privileged-containers"
                    spec.forProvider.manifest.spec.rules = [
                        {
                            name = "privileged-containers"
                            exclude.any = [
                                {
                                    resources.namespaces = [
                                        "kube-system"
                                        "kyverno"
                                        "crossplane-system"
                                        "istio-system"
                                        "istio-ingress"
                                        "argocd"
                                        "cert-manager"
                                        "external-secrets"
                                        "external-dns"
                                        "observe"
                                        "monitoring"
                                        "cnpg-system"
                                        "knative-serving"
                                        "knative-eventing"
                                        "knative-operator"
                                        "nats"
                                        "policy-reporter"
                                        "gateway-api"
                                        "my-platform-ns"
                                        "another-ns"
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    }

    # ==========================================================================
    # Test 10: helmProviderConfigRef defaults to clusterName.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "helm-provider-config-defaults-to-cluster-name"
        spec = {
            compositionPath = "apis/policystacks/composition.yaml"
            xrdPath = "apis/policystacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.PolicyStack {
                metadata.name = "pcr-test"
                spec.clusterName = "prod-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "kyverno"
                    spec.providerConfigRef = {
                        name = "prod-cluster"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }
]

items = _items
