# DysonNetwork Agent Guidelines

This document provides essential information for AI agents working on the DysonNetwork codebase.

## Project Structure

```
DysonNetwork/           # Main repository (this repo)
├── DysonNetwork.Padlock/     # Authentication & authorization service
├── DysonNetwork.Passport/    # User profiles & social features
├── DysonNetwork.Sphere/      # ActivityPub & federated content
├── DysonNetwork.Messager/    # Real-time messaging
├── DysonNetwork.Drive/       # File storage & E2EE (migrated to DysonFS: ../DysonFS)
├── DysonNetwork.Wallet/      # Payments & subscriptions
├── DysonNetwork.Ring/        # Real-time communication (calls)
├── DysonNetwork.Zone/        # Zones & communities (discontinued)
├── DysonNetwork.Develop/     # Developer portal & app management
├── DysonNetwork.Insight/     # AI features
└── DysonNetwork.Shared/      # Git submodule → NeTo repo

NeTo/                   # Shared library (separate repo: ../NeTo)
├── Models/             # Shared domain models
├── Proto/              # Generated gRPC/proto code
├── Registry/           # Service clients & helpers
├── Cache/              # Redis caching abstractions
├── EventBus/           # NATS event bus
├── Auth/               # Authentication middleware
├── Data/               # Database utilities
└── ...                 # Other shared utilities

Spec/                   # Protobuf definitions (separate repo: ../Spec)
└── proto/              # .proto files
```

## Protobuf Definitions (Spec)

**Important:** Protocol Buffer definitions are maintained in a separate repository.

- **Location:** `../Spec/` (sibling to this repo)
- **Proto files:** `../Spec/proto/*.proto`
- **Buf config:** `../Spec/buf.yaml`
- **Generation config:** `NeTo/buf.gen.yaml`
- **Generated C# code:** `NeTo/Proto/` (auto-generated, do not edit manually)
  - Regenerate with: `buf generate` under `NeTo/`

### Proto to C# Model Mapping

Models in `NeTo/Models/` have:

- `ToProto()` method for C# → Proto conversion
- `FromProtoValue()` static method for Proto → C# conversion

Always update both methods when adding new fields.

## Shared Module (NeTo)

**DysonNetwork.Shared is a git submodule pointing to the NeTo repository.**

- **Repository:** `ssh://git@compute01.latxa-bushi.ts.net/SoSYS/NeTo.git`
- **Submodule URL:** `https://src.solsynth.dev/SoSYS/NeTo.git`
- **Local path:** `DysonNetwork.Shared/` (submodule)

### What Goes in NeTo

- Models used by **multiple services** (e.g., `SnAccount`, `SnPost`, `SnCloudFile`)
- Proto/gRPC generated code
- Shared utilities (Cache, EventBus, Registry, etc.)

### What Stays in Service Repos

- Models used by **only one service** (e.g., `SnLiveStream` in Sphere, `SnMiniApp` in Develop)
- Service-specific logic, controllers, jobs

### Updating the Submodule

```bash
# Pull latest NeTo changes
cd DysonNetwork
git submodule update --remote

# Or init + update on fresh clone
git submodule update --init --recursive
```

## Adding a New Shared Model / Proto

When you need to add a new shared model or gRPC service definition, follow this workflow:

### Step 1: Add Protobuf Definition to Spec

```bash
cd ../Spec

# Edit or create .proto file
vi proto/my_new_service.proto

# Commit and push
git add -A
git commit -m "➕ add MyNewService proto definition"
git push
```

### Step 2: Regenerate Code in NeTo

```bash
cd ../NeTo

# Regenerate C# code from proto
buf generate

# Commit and push
git add -A
git commit -m "🔄 regenerate proto: add MyNewService"
git push
```

### Step 3: Update Submodules in Consuming Repos

```bash
# In DysonNetwork
cd ../DysonNetwork
git submodule update --remote
git add DysonNetwork.Shared
git commit -m "⬆️ update NeTo submodule (add MyNewService)"
git push

# In WattEngine (if applicable)
cd ../WattEngine
git submodule update --remote
git add NeTo
git commit -m "⬆️ update NeTo submodule (add MyNewService)"
git push
```

### Step 4: Add C# Model (if needed)

If the new proto requires a corresponding C# model:

```bash
cd ../NeTo

# Add model file
vi Models/MyNewModel.cs

# Ensure it has:
# - ToProto() method
# - FromProtoValue() static method

# Commit and push
git add -A
git commit -m "➕ add MyNewModel with proto mapping"
git push

# Update submodules again (repeat Step 3)
```

## JSON Serialization

**All APIs use snake_case for JSON property names.**

```csharp
// Configured in Startup/ServiceCollectionExtensions.cs
options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
options.JsonSerializerOptions.DictionaryKeyPolicy = JsonNamingPolicy.SnakeCaseLower;
```

### Example

```csharp
// C# model
public class UserProfile
{
    public string DisplayName { get; set; }
    public DateTime CreatedAt { get; set; }
}

// JSON output
{
    "display_name": "John Doe",
    "created_at": "2024-01-15T10:30:00Z"
}
```

### Exceptions

Some external integrations use `CamelCase` or `PropertyNamingPolicy = null`:

- ActivityPub payloads (federation compatibility)
- Third-party OAuth providers (Google, Discord, etc.)
- External payment webhooks

## API Gateway & URL Routing

### Production Gateway

In production, a gateway sits in front of all services. API routes are transformed:

```
Local Development:     /api/controller/action
                       ↓
Production Gateway:    /{service}/controller/action
```

### Service Name Mapping

| Service Project       | Route Prefix    |
| --------------------- | --------------- |
| DysonNetwork.Padlock  | `/padlock/...`  |
| DysonNetwork.Passport | `/passport/...` |
| DysonNetwork.Sphere   | `/sphere/...`   |
| DysonNetwork.Messager | `/messager/...` |
| DysonNetwork.Drive    | `/drive/...`    |
| DysonNetwork.Wallet   | `/wallet/...`   |
| DysonNetwork.Ring     | `/ring/...`     |
| DysonNetwork.Develop  | `/develop/...`  |
| DysonNetwork.Insight  | `/insight/...`  |

### Example

```
Local:    /api/auth/login          (Padlock)
Production: /padlock/auth/login

Local:    /api/users/me            (Passport)
Production: /passport/users/me
```

### Route Configuration

Controllers use `[Route("/api/...")]` attribute. The gateway strips `/api` and prepends the service name.

```csharp
[Route("/api/auth")]  // Becomes /padlock/auth in production
public class AuthController : ControllerBase { }
```

### Discovery Endpoint Exceptions

Some endpoints have fixed paths (not transformed):

```
/.well-known/openid-configuration
/.well-known/jwks
/.well-known/webfinger
```

## Database Conventions

### EF Core Naming

All `AppDatabase.cs` files use snake_case naming convention:

```csharp
.UseSnakeCaseNamingConvention()
```

Database tables and columns will be in snake_case:

- Table: `auth_sessions`
- Column: `created_at`, `account_id`

### Model Base Class

Models inherit from `ModelBase` which provides:

```csharp
public class ModelBase
{
    public Instant CreatedAt { get; set; }
    public Instant UpdatedAt { get; set; }
}
```

## gRPC Services

Services communicate via gRPC when possible:

- Client factories: `NeTo/Registry/LazyGrpcClientFactory.cs`
- DI (prefer this way to add clients): `NeTo/Registry/ServiceInjectionHelper.cs`
- Service definitions: `NeTo/Proto/*Grpc.cs`
- Service implementations: `*Grpc.cs` files in each service

### Common Pattern

```csharp
// In the consuming service
public class MyService
{
    private readonly DyCustomAppService.DyCustomAppServiceClient _customApps;

    public MyService(LazyGrpcClientFactory<DyCustomAppService.DyCustomAppServiceClient> factory)
    {
        _customApps = factory.GetClient();
    }
}
```

## NodaTime

All date/time handling uses NodaTime:

```csharp
using NodaTime;

public class MyEntity
{
    public Instant CreatedAt { get; set; }
    public Instant? ExpiredAt { get; set; }
}
```

- `Instant` for timestamps
- `Duration` for time spans
- `ZonedDateTime` rarely used (prefer UTC)

## Cache Service

Redis caching via `ICacheService`:

```csharp
public interface ICacheService
{
    Task SetAsync<T>(string key, T value, TimeSpan? expiry = null);
    Task<T?> GetAsync<T>(string key);
    Task<(bool Found, T? Value)> GetAsyncWithStatus<T>(string key);
    Task RemoveAsync(string key);
}
```

## Event Bus

NATS-based event bus for inter-service communication:

```csharp
// Publish
await eventBus.PublishAsync(new MyEvent { ... });

// Subscribe (in background service)
eventBus.Subscribe<MyEvent>("my-event", async (data, headers) => {
    // Handle event
    return (Success: true, ShouldAck: true);
});
```

## Testing

- No testing

## Code Style

- Nullable reference types enabled
- File-scoped namespaces preferred
- Implicit usings enabled
- No comments unless explicitly requested
- Follow existing patterns in the codebase

## 🚨 Hardcoded Solian/Solsynth URLs (Self-Host Checklist)

This project has **extensive hardcoded references** to Solsynth LLC infrastructure.
Below is a comprehensive inventory grouped by category.

> **Goal**: Replace ALL of these before deploying to your own domain.

### 1. AppSettings — Replace with Your Domain

| File | Key | Current Value |
|------|-----|---------------|
| `DysonNetwork.Padlock/appsettings.json` | `OidcProvider:IssuerUri` | `https://nt.solian.app` |
| `DysonNetwork.Passport/appsettings.json` | `OidcProvider:IssuerUri` | `https://nt.solian.app` |
| `DysonNetwork.Sphere/appsettings.json` | `ActivityPub:Domain` | `solian.app` |
| `DysonNetwork.Sphere/appsettings.json` | `ActivityPub:FileBaseUrl` | `https://solian.app/files` |
| `DysonNetwork.Sphere/appsettings.json` | `SiteUrl` | `https://solian.app` |
| `DysonNetwork.Passport/appsettings.json` | `AppleWallet:WebServiceUrl` | `https://api.solian.app/passport/passkit/v1` |
| — *.appsettings.json | `Authentication:Schemes:Bearer:ValidIssuer` | `solar-network` |
| — *.appsettings.json | `Oidc:Apple:ClientId` | `dev.solsynth.solian` |
| `DysonNetwork.Ring/appsettings.json` | `Email:FromAddress` / `Email:Username` | `no-reply@mail.solsynth.dev` |
| `DysonNetwork.Ring/appsettings.json` | `Email:SubjectPrefix` | `Solar Network` |

### 2. Publish Settings — Same Pattern

| File | Key | Current Value |
|------|-----|---------------|
| `publish/settings/pass.json` | `SiteUrl` | `https://id.solian.app` |
| `publish/settings/sphere.json` | `SiteUrl` | `https://solian.app` |
| `publish/settings/drive.json` | `OidcProvider:IssuerUri` | `https://nt.solian.app` |
| `publish/settings/drive.json` | `Notifications:Topic` | `dev.solsynth.solian` |
| `publish/settings/drive.json` | `Email:FromAddress` | `no-reply@mail.solsynth.dev` |
| `publish/settings/drive.json` | `Storage:Remote[0]:Bucket` | `solar-network-development` |
| `publish/settings/drive.json` | `Storage:Remote[1]:Bucket` | `solar-network` |
| `publish/settings/ring.json` | `Email:FromAddress` / `Email:Username` | `no-reply@mail.solsynth.dev` |

### 3. C# Source Code — Replace Defaults

| File | Hardcoded Value |
|------|----------------|
| `DysonNetwork.Padlock/Auth/AuthJwtService.cs` | Default Issuer: `"solar-network"` |
| `DysonNetwork.Padlock/Auth/OidcProvider/Controllers/OidcProviderController.cs` | Default SiteUrl: `"https://solsynth.dev"` |
| `DysonNetwork.Padlock/Startup/ApplicationConfiguration.cs` | Default Apple AppId: `"W7HPZ53V6B.dev.solsynth.solian"` |
| `DysonNetwork.Padlock/Startup/ApplicationConfiguration.cs` | Default Android PackageName: `"dev.solsynth.solian"` |
| `DysonNetwork.Sphere/ActivityPub/WebFingerController.cs` | Default server username: `"solar-network"` |
| `DysonNetwork.Sphere/ActivityPub/ServerActorController.cs` | Default PreferredUsername: `"solar-network"` |
| `DysonNetwork.Wallet/Payment/SubscriptionService.cs` | Subscription group identifier: `"solian.stellar"` |
| `DysonNetwork.Insight/SnChan/SnChanConfig.cs` | Official publisher name: `"solsynth"` |

### 4. Deep Links & URL Schemes

| Location | Content |
|----------|---------|
| `DysonNetwork.Padlock/Auth/QrLoginController.cs` | `solian://auth/qr/{id}` deep link scheme |
| `DysonNetwork.Passport/Nfc/*.cs` | `solian://phpass` URL scheme (NFC pass) |
| `DysonNetwork.Passport/Account/AccountCurrentController.cs` | File name: `"solian-member.pkpass"` |
| `docs/OAUTH_DEVICE_FLOW.md` | References `api.solsynth.dev`, `solsynth.dev` |

### 5. Git Submodules

| File | URL |
|------|-----|
| `.gitmodules` (NeTo) | `https://src.solsynth.dev/SoSYS/NeTo.git` |
| `AGENTS.md` (NeTo SSH) | `ssh://git@compute01.latxa-bushi.ts.net/SoSYS/NeTo.git` |

### 6. Apple Wallet / Push Notifications

| Config | Value |
|--------|-------|
| Apple Pass Type ID | `pass.solian.app.member` |
| Apple Team ID | `W7HPZ53V6B` (shared across services) |
| Apple Key ID | `B668YP4KBG` |
| Push Notification Topic | `dev.solsynth.solian` |
| APNs Bundle ID | `dev.solsynth.solian` / `dev.solsynth.solian.voip` |

### 7. OAuth/OIDC External Provider IDs

| Provider | Client ID |
|----------|-----------|
| Google OAuth | `961776991058-963m1qin2vtp8fv693b5fdrab5hmpl89.apps.googleusercontent.com` |
| Apple OIDC | `dev.solsynth.solian` |

### 8. Subscription Identifiers (Wallet)

All subscription product IDs use the `solian.*` prefix:
- `solian.stellar.primary`, `solian.stellar.nova`, `solian.stellar.supernova`
- `solian.creator.plus`, `solian.creator.pro`
- `solian.wallet` (payment method)
- Afdian plan IDs map to `solian.stellar.*` identifiers

## Docker Deployment

### Architecture

Each service is containerized with its own Dockerfile. The stack includes:

- **YARP Reverse Proxy** (`gateway`) — entry point, routes `/api/*` paths to services
- **8 microservices** — each runs on HTTP:8080 / HTTPS:7001 internally
- **Redis** (`cache`) — shared caching + rate limiting
- **NATS** (`queue`) — inter-service event bus with JetStream
- **PostgreSQL** — one database per service (configured via ConnectionStrings:App)
- **OpenTelemetry** — OTLP export to Aspire dashboard

### docker-compose.yaml (root)

Routes production traffic via YARP gateway on port 5001:

```
gateway:5001 → routes per path prefix → {service}:8080/api/...
```

Each service connects via:
- `ConnectionStrings__cache=cache:6379,password=${CACHE_PASSWORD}`
- `ConnectionStrings__queue=nats://nats:${QUEUE_PASSWORD}@queue:4222`
- `services__{name}__http__0=http://{name}:8080` (service discovery)
- `services__{name}__grpc__0=https://{name}:5001` (gRPC)

### Environment Variables (`.env`)

| Variable | Purpose |
|----------|---------|
| `CACHE_PASSWORD` | Redis password |
| `QUEUE_PASSWORD` | NATS password |
| `RING_IMAGE`, `PASS_IMAGE`, etc. | Container image tags |

### Required External Services

- **S3-compatible storage** (Minio / Cloudflare R2 / AWS S3) — configured in `Storage:Remote`
- **PostgreSQL** — one database per service
- **LiveKit** (optional) — real-time audio/video chat, configured in appsettings
- **Sentry** (optional) — error tracking

## Self-Host Prerequisites

1. **Own domain** — replace all `*.solian.app`, `*.solsynth.dev`, `solsynth.dev`
2. **PostgreSQL** — create 8 databases (`dyson_padlock`, `dyson_pass`, `dyson_sphere`, etc.)
3. **Redis** — for caching
4. **NATS** — for event bus (with JetStream enabled)
5. **S3 storage** — for file uploads (Minio works for self-host)
6. **SSL certificates** — for HTTPS + gRPC
7. **Apple Developer account** (optional) — for Apple OIDC / Apple Wallet / Push Notifications
8. **OIDC provider keys** — generate new RSA key pair for JWT signing
9. **Reverse proxy** — YARP gateway or external nginx/caddy in front
