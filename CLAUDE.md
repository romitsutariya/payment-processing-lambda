# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an AWS Lambda function for payment processing, built with Java 21 and deployed via AWS CodeBuild. The Lambda uses a simple request/response pattern with Jackson for JSON serialization.

**Package structure:** `org.walter`
**Lambda handler:** `org.walter.Handler` (implements `RequestHandler<Request, Response>`)

## Build & Development

### Build the Lambda package
```bash
mvn clean package
```

This creates a fat JAR in `target/` using maven-shade-plugin. The JAR includes all dependencies and is ready for Lambda deployment.

### Run tests
```bash
mvn test
```

### Clean build artifacts
```bash
mvn clean
```

## Architecture

The Lambda follows a straightforward handler pattern:

- **Handler.java** - Main Lambda entry point implementing `RequestHandler<Request, Response>`. Receives deserialized Request objects, processes them, and returns Response objects.
- **Request.java** - Input POJO with Jackson-compatible getters/setters for JSON deserialization
- **Response.java** - Output POJO with Jackson-compatible getters/setters for JSON serialization

Jackson (`jackson-databind`) handles automatic JSON ↔ POJO conversion via AWS Lambda runtime.

## Deployment

**AWS CodeBuild** is configured via `buildspec.yml`:
- Uses Amazon Corretto 21 runtime
- Runs `mvn clean package` during build phase
- Outputs `target/*.jar` as build artifact

The output JAR can be uploaded directly to AWS Lambda.

## Dependencies

- `aws-lambda-java-core` (1.2.3) - Core Lambda interfaces
- `aws-lambda-java-events` (3.11.4) - AWS event types (API Gateway, S3, etc.)
- `jackson-databind` (2.17.1) - JSON serialization/deserialization
- `junit` (3.8.1) - Testing framework
