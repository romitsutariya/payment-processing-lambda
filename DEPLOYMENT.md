# AWS CodeDeploy Configuration Guide

## Overview
This project uses AWS CodeBuild and CodeDeploy to automate Lambda deployment with blue/green deployment strategy.

## Architecture

**CodeBuild** → Builds JAR → **S3 Artifact** → **CodeDeploy** → **Lambda (Blue/Green)**

## Files

### buildspec.yml
Defines the CodeBuild process:
- **Pre-build**: Validates Maven setup
- **Build**: Compiles and packages the Lambda JAR using `mvn clean package`
- **Post-build**: Renames artifact to `payment-processing-lambda.jar`
- **Artifacts**: Packages JAR, appspec.yml, and deployment scripts
- **Cache**: Caches Maven dependencies for faster builds

### appspec.yml
Defines the CodeDeploy Lambda deployment:
- **Resources**: Specifies Lambda function, alias, and version transition
- **Hooks**: Validation scripts that run before/after traffic shift

### Deployment Hooks

**scripts/before-allow-traffic.sh**
- Runs before traffic is shifted to the new Lambda version
- Tests the new version with a health check payload
- Fails deployment if validation doesn't pass

**scripts/after-allow-traffic.sh**
- Runs after traffic is shifted
- Validates the production alias is working correctly
- Final sanity check before marking deployment complete

## Setup Instructions

### 1. Create Lambda Function Hook Functions (for validation)

Create two Lambda functions for deployment hooks:

**BeforeAllowTrafficHook**:
```bash
aws lambda create-function \
  --function-name BeforeAllowTrafficHook \
  --runtime python3.12 \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-codedeploy-role \
  --handler index.handler \
  --zip-file fileb://hook.zip \
  --timeout 60
```

**AfterAllowTrafficHook**:
```bash
aws lambda create-function \
  --function-name AfterAllowTrafficHook \
  --runtime python3.12 \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-codedeploy-role \
  --handler index.handler \
  --zip-file fileb://hook.zip \
  --timeout 60
```

### 2. Create CodeBuild Project

```bash
aws codebuild create-project \
  --name payment-processing-lambda-build \
  --source type=GITHUB,location=https://github.com/YOUR_REPO/payment-processing-lambda.git \
  --artifacts type=S3,location=YOUR_S3_BUCKET \
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL \
  --service-role arn:aws:iam::YOUR_ACCOUNT:role/codebuild-service-role
```

### 3. Create CodeDeploy Application

```bash
aws deploy create-application \
  --application-name payment-processing-lambda-app \
  --compute-platform Lambda
```

### 4. Create Deployment Group

```bash
aws deploy create-deployment-group \
  --application-name payment-processing-lambda-app \
  --deployment-group-name payment-processing-lambda-dg \
  --deployment-config-name CodeDeployDefault.LambdaLinear10PercentEvery1Minute \
  --service-role-arn arn:aws:iam::YOUR_ACCOUNT:role/codedeploy-service-role
```

### 5. Create CodePipeline (Optional - for full CI/CD)

```bash
aws codepipeline create-pipeline \
  --cli-input-json file://pipeline.json
```

## Deployment Strategies

Configure different traffic shifting patterns in CodeDeploy:

- **CodeDeployDefault.LambdaCanary10Percent5Minutes**: 10% traffic for 5 minutes, then 100%
- **CodeDeployDefault.LambdaCanary10Percent10Minutes**: 10% traffic for 10 minutes, then 100%
- **CodeDeployDefault.LambdaLinear10PercentEvery1Minute**: 10% traffic increase every minute
- **CodeDeployDefault.LambdaLinear10PercentEvery2Minutes**: 10% traffic increase every 2 minutes
- **CodeDeployDefault.LambdaAllAtOnce**: All traffic shifted immediately

## Manual Deployment

### Trigger CodeBuild
```bash
aws codebuild start-build --project-name payment-processing-lambda-build
```

### Create Deployment
```bash
aws deploy create-deployment \
  --application-name payment-processing-lambda-app \
  --deployment-group-name payment-processing-lambda-dg \
  --s3-location bucket=YOUR_S3_BUCKET,key=build-artifact.zip,bundleType=zip
```

### Monitor Deployment
```bash
aws deploy get-deployment --deployment-id d-XXXXXXXXX
```

## IAM Roles Required

### CodeBuild Service Role
Permissions needed:
- S3 read/write for artifacts
- CloudWatch Logs write
- ECR pull (if using custom images)

### CodeDeploy Service Role
Permissions needed:
- Lambda update function
- Lambda invoke for hooks
- S3 read for artifacts

### Lambda Execution Role
Permissions needed:
- CloudWatch Logs write
- Any business logic permissions (DynamoDB, S3, etc.)

## Troubleshooting

### Build Fails
Check CodeBuild logs:
```bash
aws codebuild batch-get-builds --ids BUILD_ID
```

### Deployment Fails
Check deployment status:
```bash
aws deploy get-deployment --deployment-id DEPLOYMENT_ID
```

### Hook Validation Fails
Check Lambda hook logs in CloudWatch:
```bash
aws logs tail /aws/lambda/BeforeAllowTrafficHook --follow
```

## Rollback

CodeDeploy automatically rolls back if:
- Hook validation fails
- Lambda invocation errors exceed threshold
- Manual rollback triggered

Manual rollback:
```bash
aws deploy stop-deployment \
  --deployment-id DEPLOYMENT_ID \
  --auto-rollback-enabled
```
