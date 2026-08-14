# eks-vanilla

Módulo Terraform que provisiona um cluster EKS básico (control plane + node group), consumindo a rede publicada pelo módulo [eks-network](https://github.com/MarcelliSarti/eks-network).

## O que este módulo cria

- **Cluster EKS** (control plane), com logging habilitado e secrets criptografados via KMS
- **Node Group** gerenciado, com autoscaling configurável
- **IAM Roles** do cluster e dos nodes
- **Access Entries** (autenticação via `API_AND_CONFIG_MAP`)
- **Addons gerenciados**: VPC CNI, CoreDNS, kube-proxy
- **Helm charts**: metrics-server e kube-state-metrics

## Como o módulo lê a rede

Este módulo **não recebe IDs de subnet diretamente** — ele recebe os **paths dos parâmetros no SSM** (publicados pelo `eks-network`) e busca os valores reais via `data "aws_ssm_parameter"`.

| Onde é usado | Subnets |
|---|---|
| Control plane do cluster (`vpc_config.subnet_ids`) | `ssm_private_subnets` |
| Node Group (`subnet_ids`) | `ssm_pod_subnets` |

> Ou seja: as subnets **privadas** hospedam o control plane (ENIs do cluster), e as subnets de **pod** hospedam os nodes do node group. Não confunda as duas na hora de montar as listas.

## Como usar

```hcl
module "cluster" {
  source = "github.com/MarcelliSarti/eks-vanilla?ref=0.0.1"

  project_name = var.project_name
  region       = var.region

  k8s_version = "1.31"

  ssm_vpc_id            = module.vpc.vpc_id
  ssm_public_subnets    = module.vpc.public_subnets
  ssm_private_subnets   = local.node_subnets   # ENIs do control plane
  ssm_pod_subnets       = local.pod_subnets    # subnets dos nodes
  ssm_database_subnets  = module.vpc.database_subnets

  nodes_instance_sizes = ["t3.medium"]

  auto_scale_options = {
    min     = 1
    max     = 3
    desired = 2
  }
}
```

## Variáveis

| Nome | Tipo | Obrigatória | Descrição |
|---|---|---|---|
| `project_name` | string | sim | Nome do projeto/cluster |
| `region` | string | sim | Região AWS |
| `k8s_version` | string | sim | Versão do Kubernetes |
| `ssm_vpc_id` | string | sim | Path do parâmetro SSM com o ID da VPC |
| `ssm_public_subnets` | list(string) | sim | Paths SSM das subnets públicas |
| `ssm_private_subnets` | list(string) | sim | Paths SSM das subnets usadas pelo control plane |
| `ssm_pod_subnets` | list(string) | sim | Paths SSM das subnets usadas pelo node group |
| `ssm_database_subnets` | list(string) | sim | Paths SSM das subnets de banco de dados |
| `nodes_instance_sizes` | list(string) | sim | Tipos de instância aceitos pelo node group |
| `auto_scale_options` | object({min, max, desired}) | sim | Configuração de autoscaling do node group |
| `addon_cni_version` | string | não | Versão do addon VPC CNI |
| `addon_coredns_version` | string | não | Versão do addon CoreDNS |
| `addon_kubeproxy_version` | string | não | Versão do addon kube-proxy |

## Observações

- O `desired_size` do node group é ignorado em updates subsequentes (`lifecycle.ignore_changes`), para não conflitar com autoscaling em runtime.
- O node group depende do `aws_eks_access_entry.nodes` — a autenticação dos nodes é feita via Access Entry, não via `aws-auth` ConfigMap legado.