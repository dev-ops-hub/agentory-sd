# AWS CloudFormation Reference

Prefer the AWS CDK (synthesizes to CloudFormation, authored in a general-purpose language) for new work of meaningful complexity; use raw CloudFormation YAML/JSON directly for simple, static stacks or when the project is already committed to it.

## Stack Structure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, staging, prod]

Resources:
  AppVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      Tags:
        - { Key: Environment, Value: !Ref Environment }

Outputs:
  VpcId:
    Value: !Ref AppVpc
    Export:
      Name: !Sub '${AWS::StackName}-VpcId'
```

## Nested Stacks and Cross-Stack References

Nested stacks (`AWS::CloudFormation::Stack`) decompose a large template; cross-stack `Export`/`Fn::ImportValue` share values between independent stacks. Prefer nested stacks within one deployment unit, and cross-stack exports only across genuinely independent lifecycles (networking stack vs. application stack deployed separately) — a tight `ImportValue` coupling between stacks that should deploy together just adds deployment-order fragility.

## Change Sets

```bash
aws cloudformation create-change-set --stack-name app-prod --template-body file://template.yaml --change-set-name review-$(date +%s)
aws cloudformation describe-change-set --stack-name app-prod --change-set-name review-...
```

CloudFormation's equivalent of `terraform plan` — a change set previews Add/Modify/Remove before `execute-change-set` applies it. Never run `update-stack` directly against a production stack without first reviewing a change set.

## Drift Detection

```bash
aws cloudformation detect-stack-drift --stack-name app-prod
```

Detects manual out-of-band changes the same way Terraform's `plan` surfaces drift — run periodically, and treat recurring drift as a signal someone is bypassing the pipeline.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `update-stack` without a change set review on prod | Always create and review a change set first |
| Deep `ImportValue` coupling between independently-deployed stacks | Reserve cross-stack exports for genuinely independent lifecycles; nest otherwise |
| No `DeletionPolicy: Retain` on stateful resources (databases, buckets) | Set it explicitly so a stack deletion can't silently destroy data |
