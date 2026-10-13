# Service Mapping (Orientation Aid)

**This table is an orientation aid for finding candidate services to investigate, not a
claim that mapped services are functionally identical.** Two services in the same row
can differ in consistency model, operational maturity, regional availability, pricing
model, and failure behavior. Before recommending a mapped service, read the actual
behavior in that provider's reference file (`azure.md`, `aws.md`, `gcp.md`) — don't
reason from this table alone, and don't use it to "translate" an Azure design into AWS
or GCP by swapping names.

| Capability | Azure | AWS | GCP |
|---|---|---|---|
| Serverless function | Azure Functions | Lambda | Cloud Functions (2nd gen) |
| Serverless containers | Container Apps | Fargate (ECS or EKS launch type) | Cloud Run |
| Managed Kubernetes | AKS | EKS | GKE (Autopilot or Standard) |
| VM / IaaS compute | Virtual Machines | EC2 | Compute Engine |
| PaaS app hosting | App Service | Elastic Beanstalk | App Engine |
| Object storage | Blob Storage | S3 | Cloud Storage |
| Block storage | Managed Disks | EBS | Persistent Disk |
| File storage (shared) | Azure Files | EFS / FSx | Filestore |
| Relational DB (managed) | Azure SQL / PostgreSQL / MySQL | RDS / Aurora | Cloud SQL |
| Globally-distributed strongly-consistent DB | Cosmos DB (tunable consistency) | DynamoDB global tables (key-value) | Cloud Spanner (relational, strong consistency) |
| Wide-column NoSQL | Table Storage | DynamoDB | Bigtable |
| In-memory cache | Azure Cache for Redis | ElastiCache | Memorystore |
| Data warehouse / analytics | Synapse Analytics | Redshift | BigQuery |
| Secrets management | Key Vault | Secrets Manager | Secret Manager |
| Key management (encryption) | Key Vault (Managed HSM) | KMS | Cloud KMS |
| Workforce identity / SSO | Microsoft Entra ID | IAM Identity Center | Cloud Identity |
| Resource permissions / IAM | Microsoft Entra ID (RBAC) | IAM | Cloud IAM |
| Workload identity (no static keys) | Managed Identities | IAM roles (instance profiles, IRSA) | Service Accounts + Workload Identity Federation |
| Virtual network | Virtual Network (VNet) — regional | VPC — regional | VPC — global |
| Global HTTP(S) load balancing + CDN + WAF | Front Door | CloudFront + Global Accelerator + Shield/WAF | Global External Application LB + Cloud CDN + Cloud Armor |
| Regional HTTP(S) load balancing | Application Gateway | Application Load Balancer | Regional External Application LB |
| L4 load balancing | Load Balancer | Network Load Balancer | Network Load Balancer (passthrough) |
| DNS + failover routing | Traffic Manager | Route 53 | Cloud DNS |
| Private connectivity to managed services | Private Link | PrivateLink | Private Service Connect |
| API management (full gateway + portal) | API Management | API Gateway (narrower scope) | Apigee |
| Pub/sub messaging | Service Bus / Event Grid | SNS / EventBridge | Pub/Sub |
| Event streaming | Event Hubs | Kinesis / MSK | Pub/Sub + Dataflow |
| Simple queue | Queue Storage | SQS | Cloud Tasks |
| Workflow orchestration | Logic Apps | Step Functions | Workflows |
| Metrics / logs / dashboards | Azure Monitor + Log Analytics | CloudWatch | Cloud Monitoring + Cloud Logging |
| Distributed tracing | Application Insights | X-Ray | Cloud Trace |
| API-call audit logging | Azure Activity Log | CloudTrail | Cloud Audit Logs |
| IaC (first-party) | Bicep / ARM | CloudFormation | Deployment Manager (legacy; Terraform is the de facto default) |
| IaC (cross-provider, de facto default on all three) | Terraform | Terraform | Terraform |
| Cost / recommendation tooling | Azure Advisor + Cost Management | Trusted Advisor + Cost Explorer | Recommender |
| Chaos / fault injection | Azure Chaos Studio | AWS Fault Injection Simulator | No first-party equivalent (open-source, e.g. Chaos Mesh) |
| WAF / DDoS protection | Front Door/App Gateway WAF + DDoS Protection | WAF + Shield | Cloud Armor |
| LLM / generative AI API | Azure OpenAI | Bedrock | Vertex AI (Model Garden) |
| Custom ML training/MLOps | Azure Machine Learning | SageMaker | Vertex AI |

## Rows Where "Equivalent" Is Especially Misleading

- **Globally-distributed strongly-consistent DB row**: Cosmos DB, DynamoDB global
  tables, and Cloud Spanner solve adjacent but different problems — Cosmos DB and
  DynamoDB are multi-model/key-value with tunable consistency, Spanner is relational
  with strong consistency at global scale. Don't treat them as interchangeable based on
  "multi-region" alone.
- **Workforce identity / SSO row**: Entra ID is a single platform spanning both human
  and workload identity; IAM Identity Center and Cloud Identity are narrower in scope
  than Entra ID and sit alongside (not inside) IAM/Cloud IAM.
- **Virtual network row**: regional (Azure, AWS) vs. global (GCP) is a structural
  difference, not a naming difference — it changes the default multi-region network
  design.
- **Serverless containers row**: Fargate is a launch type for ECS/EKS, not a standalone
  product the way Container Apps or Cloud Run are — the operational model differs even
  though the end-user pitch ("containers without managing servers") is similar.
- **IaC (first-party) row**: Bicep/ARM and CloudFormation are each tightly coupled to
  their own provider; GCP's own first-party option (Deployment Manager) is legacy and
  Google itself points most users to Terraform — this row is the weakest "parity" claim
  in the whole table.

> Use this table to generate a shortlist of services to investigate per the Multi-Cloud
> Comparison Methodology in `decision-frameworks.md` — never as the comparison itself.
