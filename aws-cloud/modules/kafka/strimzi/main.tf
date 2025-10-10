# https://strimzi.io/quickstarts/
terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

provider "kubernetes" {
    config_path = "~/.kube/config"
}

provider "kubectl" {
  config_path = "~/.kube/config" 
}

provider "helm" {
    kubernetes = {
      config_path = "~/.kube/config"
    }
}

locals {
  kafka_namespace             = "kafka-system"
  kafka_name                  = "strimzi-kafka-${var.project}"
  kafka_subdomain             = "${local.kafka_namespace}.${var.project_domain}"
  kafka_broker_hostnames      = formatlist("kafka-%s.${local.kafka_subdomain}", range(var.kafka_broker_replicas))
  kafka_bootstrap_hostname    = "bootstrap.${local.kafka_subdomain}"
  kafka_broker_internal_cert  = "kafka-broker-internal-cert"
  kafka_external_port         = 9093
  sasl_scram_test_secret_name = "sasl-scram-test-secret"
  sasl_scram_test_secret_password_field = "password"
  sasl_scram_test_secret = {
    username = "sasl-scram-test-user"
    password = "sasl-scram-test-password"
  }
  base64_sasl_scram_test_secret_password = base64encode(local.sasl_scram_test_secret.password)
  strimzi_kafka_ssl_dir_path = "/strimzi-kafka-certs"
}
# CRDs are upgraded outside of helm:
# kubectl apply -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.47.0/strimzi-crds-0.47.0.yaml 

resource "helm_release" "strimzi" {
  count = 1
  name       = "strimzi-cluster-operator"
  repository = "oci://quay.io/strimzi-helm/"
  chart      = "strimzi-kafka-operator"
  namespace  = "strimzi"
  create_namespace = true
  version    = "0.48.0" # "0.35.0"
  set = [
    {
      name  = "replicas"
      value = 1
    },
    {
      name  = "watchAnyNamespace"
      value = true
    }
  ]
}

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = local.kafka_namespace
  }
}

resource "kubectl_manifest" "single_node_kafka_nodepool" {
  count = 1
  depends_on = [
    helm_release.strimzi,
  ]
  yaml_body = <<-EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaNodePool
metadata:
  name: dual-role
  labels:
    strimzi.io/cluster: single-node-cluster
spec:
  replicas: 1
  roles:
    - controller
    - broker
  storage:
    type: persistent-claim
    size: 30Gi
    deleteClaim: true
    kraftMetadata: shared
    class: gp2
EOF
}

resource "kubectl_manifest" "single_node_kafka_cluster" {
  count = 1
  depends_on = [
    helm_release.strimzi, kubectl_manifest.single_node_kafka_cluster
  ]
  yaml_body = <<-EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: single-node-cluster
  annotations:
    strimzi.io/node-pools: enabled
    strimzi.io/kraft: enabled
spec:
  kafka:
    version: 4.1.0
    metadataVersion: 4.1.0
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      default.replication.factor: 1
      min.insync.replicas: 1
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF
}

resource "kubectl_manifest" "kafka_cluster_old" {
  count = 0
  # https://sourcegraph.iap.tmachine.io/git.gaia.tmachine.io/diffusion/CORE/-/blob/experimental/bwithers/kafka_operator/strimzi/kafka-cluster.yaml
  yaml_body = <<-EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: ${local.kafka_name}
  namespace: ${local.kafka_namespace}
spec:
  kafka:
    version: ${var.kafka_version}
    replicas: ${var.kafka_broker_replicas}
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9095
        type: internal
        tls: true
        authentication:
          type: tls
        configuration:
          brokerCertChainAndKey:
            secretName: ${local.kafka_broker_internal_cert}
            certificate: tls.crt
            key: tls.key
      - name: scram
        port: 9097
        type: internal
        tls: true
        authentication:
          type: scram-sha-512
        configuration:
          brokerCertChainAndKey:
            secretName: ${local.kafka_broker_internal_cert}
            certificate: tls.crt
            key: tls.key
      - name: external
        port: ${local.kafka_external_port}
        type: ingress
        tls: true
        authentication:
          type: scram-sha-512
        configuration:
          class: ${var.ingress_class_name}
          bootstrap:
            host: ${local.kafka_bootstrap_hostname}
            annotations:
            #  kubernetes.io/ingress.class: ${var.ingress_class_name}
          brokers:
          - broker: 0
            host: ${local.kafka_broker_hostnames[0]}
            annotations:
              external-dns.alpha.kubernetes.io/hostname: ${local.kafka_broker_hostnames[0]}
            #  kubernetes.io/ingress.class: ${var.ingress_class_name}
          - broker: 1
            host: ${local.kafka_broker_hostnames[1]}
            annotations:
              external-dns.alpha.kubernetes.io/hostname: ${local.kafka_broker_hostnames[1]}
            #  kubernetes.io/ingress.class: ${var.ingress_class_name}
          - broker: 2
            host:  ${local.kafka_broker_hostnames[2]}
            annotations:
              external-dns.alpha.kubernetes.io/hostname: ${local.kafka_broker_hostnames[2]}
            #  kubernetes.io/ingress.class: ${var.ingress_class_name}
          brokerCertChainAndKey:
            secretName: ${local.kafka_broker_internal_cert}
            certificate: tls.crt
            key: tls.key
    storage:
      type: persistent-claim
      class: gp2
      size: 4Gi
      deleteClaim: true
    config:
      offsets.topic.replication.factor: ${var.kafka_topc_replication_factor}
      default.replication.factor: ${var.kafka_topc_replication_factor}
      auto.create.topics.enable: false
      unclean.leader.election.enable: false
      delete.topic.enable: true
      allow.everyone.if.no.acl.found: true
      auto.create.topics.enable: false
      delete.topic.enable: true
      leader.imbalance.check.interval.seconds: 10
      log.retention.hours: 168
      message.max.bytes: 4194304
      min.insync.replicas: 2
      num.partitions: 1
      num.recovery.threads.per.data.dir: 16
      num.replica.fetchers: 2
      offsets.retention.minutes: 20160
      replica.fetch.max.bytes: 5242880
      replica.socket.timeout.ms: 10000
  # clusterCa:
  #   generateCertificateAuthority: false
  # clientsCa:
  #   generateCertificateAuthority: false
    resources:
      requests:
        memory: 64Gi
        cpu: "8"
      limits:
        memory: 64Gi
        cpu: "12"

  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 20Gi
      class: gp2
      deleteClaim: true
  entityOperator:
    topicOperator: {}
    userOperator:
      watchedNamespace:  ${local.kafka_namespace}
      reconciliationIntervalSeconds: 10
EOF 
  depends_on = [
    helm_release.strimzi,
    kubectl_manifest.kafka_test_sasl_secret
  ]
}

# test sasl scram 
# nosemgrep: resource-not-on-allowlist
resource "kubectl_manifest" "kafka_test_sasl_secret" {
  count = 0
  depends_on      = [helm_release.strimzi]
  yaml_body = <<-EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${local.sasl_scram_test_secret_name}
  namespace: ${kubernetes_namespace.kafka.id}
data:
  ${local.sasl_scram_test_secret_password_field}: ${local.base64_sasl_scram_test_secret_password}
  EOF
}

resource "time_sleep" "kafka_test_sasl_secret_wait" {
  depends_on      = [kubectl_manifest.kafka_test_sasl_secret]
  create_duration = "3s"
}

# nosemgrep: resource-not-on-allowlist
resource "kubectl_manifest" "kafka_test_sasl_secret_kafkauser" {
  count = 0
  depends_on = [time_sleep.kafka_test_sasl_secret_wait]
  yaml_body  = <<-EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: ${local.sasl_scram_test_secret.username}
  namespace: ${kubernetes_namespace.kafka.id}
  labels:
    strimzi.io/cluster: ${local.kafka_name}
spec:
  authentication:
    type: scram-sha-512
    password:
      valueFrom:
        secretKeyRef:
          name: ${local.sasl_scram_test_secret_name}
          key: ${local.sasl_scram_test_secret_password_field}
  EOF
}

# nosemgrep: resource-not-on-allowlist
resource "kubectl_manifest" "kafka_broker_internal_cert" {
  count = 0
  yaml_body = <<-EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${local.kafka_broker_internal_cert}
  namespace: ${kubernetes_namespace.kafka.id}
spec:
  secretName: ${local.kafka_broker_internal_cert}
  issuerRef:
    name: ${var.cert_manager_selfsigned_cluster_issuer}
    kind: ClusterIssuer
    group: cert-manager.io
  subject:
    organizationalUnits:
      - "kafka"
    organizations:
      - "Thought Machine Ltd"
  dnsNames:
    - "*.${local.kafka_subdomain}"
  EOF
}
