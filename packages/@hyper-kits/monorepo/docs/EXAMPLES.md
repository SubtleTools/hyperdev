# Examples & Use Cases

> Real-world examples and patterns for using @hypergen/monorepo-pack

## Table of Contents

- [Quick Start Examples](#quick-start-examples)
- [Frontend Projects](#frontend-projects)
- [Backend Services](#backend-services)
- [Full-Stack Applications](#full-stack-applications)
- [Enterprise Solutions](#enterprise-solutions)
- [Open Source Projects](#open-source-projects)
- [Migration Examples](#migration-examples)
- [Custom Workflows](#custom-workflows)

## Quick Start Examples

### Minimal Setup (30 seconds)

```bash
# Fastest possible setup with Bun
hypergen monorepo new quick-start --preset modern-bun

cd quick-start
bun install
bun run dev
```

**Generated in ~15 seconds:**
- Bun package manager
- Biome linting & formatting  
- Bun Test framework
- TypeScript ready
- Moon workspace

### Traditional Setup (Enterprise-Ready)

```bash
# Stable, well-supported tools
hypergen monorepo new enterprise-app --preset traditional-node

cd enterprise-app  
npm install
npm run dev
```

**Generated in ~25 seconds:**
- npm package manager
- ESLint + Prettier
- Vitest testing
- GitHub Actions CI/CD
- Comprehensive tooling

## Frontend Projects

### React Design System

Create a comprehensive design system with Storybook and component testing.

```bash
hypergen monorepo new design-system \
  --preset modern-bun \
  --packages ui,components,icons,tokens \
  --apps storybook,playground \
  --storybook
```

**Generated structure:**
```
design-system/
├── apps/
│   ├── storybook/           # Component documentation
│   └── playground/          # Development playground
├── packages/
│   ├── ui/                  # Core UI components
│   ├── components/          # Complex components
│   ├── icons/               # Icon library
│   └── tokens/              # Design tokens
└── .storybook/              # Storybook configuration
```

**Key features:**
- Component isolation and testing
- Visual regression testing  
- Design token management
- Automated documentation
- Cross-package dependencies

### Next.js Multi-Site Platform

Build a multi-tenant platform with shared components.

```bash
hypergen monorepo new multi-site \
  --preset modern-bun \
  --packages shared,ui,auth,analytics \
  --apps marketing,app,admin,docs
```

**Generated structure:**
```
multi-site/
├── apps/
│   ├── marketing/           # Marketing site (Next.js)
│   ├── app/                 # Main application  
│   ├── admin/               # Admin dashboard
│   └── docs/                # Documentation site
├── packages/
│   ├── shared/              # Shared utilities
│   ├── ui/                  # Component library
│   ├── auth/                # Authentication
│   └── analytics/           # Analytics helpers
└── packages.json            # Workspace configuration
```

**Development workflow:**
```bash
cd multi-site

# Install dependencies
bun install

# Start all apps in development
bun run dev

# Start specific app
bun run dev:marketing

# Build for production
bun run build

# Run tests across workspace
bun test
```

### Mobile-First Progressive Web App

Create a PWA-optimized monorepo with mobile considerations.

```bash
hypergen monorepo new mobile-pwa \
  --preset performance \
  --packages pwa,offline,push,ui \
  --apps web,mobile-web \
  --typescript-strict
```

**Optimized for:**
- Fast build times with pnpm
- Efficient caching strategies
- Mobile-first performance
- Offline functionality
- Push notifications

## Backend Services

### Microservices Architecture

Build a scalable microservices platform with shared libraries.

```bash
hypergen monorepo new microservices \
  --preset performance \
  --packages database,auth,logging,messaging \
  --apps user-service,order-service,payment-service,api-gateway \
  --docker
```

**Generated structure:**
```
microservices/
├── apps/
│   ├── user-service/        # User management API
│   ├── order-service/       # Order processing API
│   ├── payment-service/     # Payment handling API
│   └── api-gateway/         # API gateway/proxy
├── packages/
│   ├── database/            # Database utilities
│   ├── auth/                # Authentication middleware
│   ├── logging/             # Centralized logging
│   └── messaging/           # Message queue utilities
├── docker-compose.yml       # Local development
└── Dockerfile               # Production containers
```

**Key capabilities:**
- Service isolation with shared code
- Docker containerization
- Database connection pooling
- Centralized authentication
- Inter-service communication

### GraphQL API Platform

Create a unified GraphQL API with multiple data sources.

```bash
hypergen monorepo new graphql-platform \
  --preset traditional-node \
  --packages schema,resolvers,datasources,auth \
  --apps graphql-server,admin-api,webhook-handler
```

**Features:**
- Schema stitching and federation
- Resolver composition
- DataLoader integration
- Authentication/authorization
- Real-time subscriptions

### Serverless Functions

Build serverless functions with shared utilities.

```bash
hypergen monorepo new serverless-api \
  --preset modern-bun \
  --packages utils,validation,database,auth \
  --apps api-functions,webhook-functions,scheduled-functions
```

**Deployment ready for:**
- Vercel Functions
- AWS Lambda
- Cloudflare Workers
- Netlify Functions

## Full-Stack Applications

### E-commerce Platform

Complete e-commerce solution with multiple frontends.

```bash
hypergen monorepo new ecommerce \
  --preset enterprise \
  --packages cart,products,payments,shipping,reviews \
  --apps storefront,admin,mobile,api \
  --storybook \
  --docker
```

**Generated structure:**
```
ecommerce/
├── apps/
│   ├── storefront/          # Customer-facing store
│   ├── admin/               # Admin dashboard
│   ├── mobile/              # Mobile app (React Native)
│   └── api/                 # Backend API
├── packages/
│   ├── cart/                # Shopping cart logic
│   ├── products/            # Product management
│   ├── payments/            # Payment processing
│   ├── shipping/            # Shipping calculations
│   └── reviews/             # Review system
└── .storybook/              # Component library docs
```

**Business features:**
- Multi-channel sales (web, mobile, admin)
- Shared business logic
- Component consistency
- End-to-end testing
- Deployment automation

### SaaS Application

Multi-tenant SaaS platform with role-based access.

```bash
hypergen monorepo new saas-platform \
  --preset performance \
  --packages auth,billing,analytics,notifications \
  --apps app,marketing,admin,api \
  --typescript-strict
```

**SaaS-specific features:**
- Multi-tenancy support
- Role-based permissions
- Subscription billing
- Usage analytics
- Email notifications
- Marketing site integration

### Content Management System

Headless CMS with multiple frontends.

```bash
hypergen monorepo new headless-cms \
  --preset modern-bun \
  --packages content,media,api-client,ui \
  --apps cms-admin,website,blog,api
```

**Content features:**
- Headless architecture
- Media management
- Content versioning
- Multi-site deployment
- SEO optimization

## Enterprise Solutions

### Banking Application

High-security, compliant financial application.

```bash
hypergen monorepo new banking-app \
  --preset enterprise \
  --packages security,transactions,reporting,audit \
  --apps customer-portal,admin-console,mobile,api \
  --typescript-strict
```

**Compliance features:**
- Security-first architecture
- Audit logging
- Transaction tracking
- Regulatory reporting
- Role-based access control
- Jest for comprehensive testing

### Healthcare Platform

HIPAA-compliant healthcare management system.

```bash
hypergen monorepo new healthcare \
  --preset enterprise \
  --packages patient,scheduling,billing,compliance \
  --apps patient-portal,provider-app,admin,api \
  --typescript-strict \
  --docker
```

**Healthcare-specific:**
- HIPAA compliance patterns
- Patient data encryption
- Audit trails
- Integration APIs
- Mobile-responsive design

### Education Platform

Learning management system with multi-role support.

```bash
hypergen monorepo new education \
  --preset traditional-node \
  --packages courses,users,assessments,content \
  --apps student-app,teacher-app,admin,api
```

**Education features:**
- Course management
- Assessment tools
- User role management
- Content delivery
- Progress tracking

## Open Source Projects

### Component Library

Open source React component library with documentation.

```bash
hypergen monorepo new ui-library \
  --preset modern-bun \
  --packages components,themes,icons,utils \
  --apps docs,playground \
  --storybook
```

**Open source ready:**
- MIT license included
- Contributing guidelines
- GitHub Actions CI/CD
- Automated releases
- Documentation site
- Component playground

### CLI Tool Suite

Collection of command-line tools with shared utilities.

```bash
hypergen monorepo new cli-tools \
  --preset performance \
  --packages core,utils,config,plugins \
  --apps main-cli,dev-cli,build-cli
```

**CLI-specific features:**
- Shared CLI framework
- Plugin architecture
- Configuration management
- Cross-platform support
- Self-updating capabilities

### Developer Tools

Development tooling with multiple packages.

```bash
hypergen monorepo new dev-tools \
  --preset modern-bun \
  --packages parser,formatter,linter,bundler \
  --apps cli,vscode-extension,web-interface
```

## Migration Examples

### From Create-React-App Monorepo

Migrate existing CRA-based monorepo to modern tooling.

```bash
# 1. Generate new structure
hypergen monorepo new modernized-app \
  --preset modern-bun \
  --packages shared,components,utils \
  --apps web,mobile

# 2. Copy existing code
cp -r old-monorepo/packages/* modernized-app/packages/
cp -r old-monorepo/apps/* modernized-app/apps/

# 3. Update configurations (automated by Hypergen)
cd modernized-app
bun install
bun run migrate:cra
```

### From Lerna to Moon

Migrate from Lerna-based workspace to Moon.

```bash
# 1. Generate Moon-based structure  
hypergen monorepo new moon-workspace \
  --preset enterprise \
  --packages $(ls lerna-workspace/packages)

# 2. Migration script provided
cd moon-workspace
bun run migrate:lerna ../lerna-workspace
```

### From Nx Workspace

Convert Nx workspace to Hypergen + Moon.

```bash
# 1. Analyze existing Nx setup
hypergen analyze nx-workspace

# 2. Generate equivalent structure
hypergen monorepo new nx-converted \
  --preset performance \
  --packages libs,shared \
  --apps web,api

# 3. Automated migration utilities
cd nx-converted
bun run migrate:nx ../nx-workspace
```

## Custom Workflows

### Multi-Environment Deployment

Setup for different deployment environments.

```bash
hypergen monorepo new multi-env \
  --preset enterprise \
  --environments dev,staging,prod \
  --apps web,api \
  --packages shared
```

**Generated environments:**
```
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml
│       ├── deploy-staging.yml
│       └── deploy-prod.yml
├── environments/
│   ├── dev.env
│   ├── staging.env
│   └── prod.env
└── deployment/
    ├── dev/
    ├── staging/
    └── prod/
```

### Feature Flag Integration

Monorepo with feature flag management.

```bash
hypergen monorepo new feature-flags \
  --preset modern-bun \
  --packages flags,experiments,analytics \
  --apps web,api,admin
```

**Feature flag capabilities:**
- Runtime feature toggles
- A/B testing framework
- Analytics integration
- Progressive rollouts
- Environment-specific flags

### Multi-Language Support

Internationalized applications with shared translations.

```bash
hypergen monorepo new i18n-app \
  --preset traditional-node \
  --packages i18n,translations,ui \
  --apps web,mobile,admin \
  --languages en,es,fr,de
```

**I18n features:**
- Shared translation keys
- Language-specific builds
- RTL support
- Date/number formatting
- Translation validation

## Performance Optimization Examples

### High-Traffic Application

Optimized for performance and scalability.

```bash
hypergen monorepo new high-traffic \
  --preset performance \
  --packages cache,monitoring,optimization \
  --apps web,api,worker \
  --performance-optimized
```

**Performance features:**
- Built-in caching strategies
- Performance monitoring
- Bundle optimization
- Lazy loading patterns
- Worker thread utilization

### Large-Scale Monorepo

Configuration for very large codebases (100+ packages).

```bash
hypergen monorepo new large-scale \
  --preset performance \
  --packages $(seq -f "package-%g" 1 100) \
  --apps $(seq -f "app-%g" 1 10) \
  --cache-optimization \
  --parallel-builds
```

**Large-scale optimizations:**
- Intelligent build caching
- Parallel task execution  
- Incremental builds
- Selective testing
- Memory-efficient processing

## Testing Examples

### Comprehensive Test Suite

Full testing setup with multiple strategies.

```bash
hypergen monorepo new test-comprehensive \
  --preset enterprise \
  --packages utils,components,api \
  --apps web,mobile \
  --test-strategies unit,integration,e2e,visual
```

**Testing capabilities:**
- Unit tests with Jest
- Integration testing
- End-to-end with Playwright
- Visual regression testing
- Performance testing
- Contract testing

### TDD Workflow

Test-driven development optimized setup.

```bash
hypergen monorepo new tdd-workflow \
  --preset modern-bun \
  --packages core,utils \
  --apps web \
  --tdd-optimized
```

**TDD features:**
- Fast test feedback (Bun Test)
- Watch mode optimization
- Test-first templates
- Coverage reporting
- Continuous testing

## Integration Examples

### Third-Party Service Integration

Monorepo with external service integrations.

```bash
hypergen monorepo new integrations \
  --preset traditional-node \
  --packages stripe,sendgrid,aws,analytics \
  --apps web,api \
  --integrations stripe,sendgrid,aws,mixpanel
```

**Integration templates:**
- Payment processing (Stripe)
- Email service (SendGrid)
- Cloud services (AWS)
- Analytics (Mixpanel)
- Authentication (Auth0)

### Database Multi-Tenant

Multi-tenant database architecture.

```bash
hypergen monorepo new multi-tenant \
  --preset performance \
  --packages database,migrations,models \
  --apps api,admin \
  --database postgresql \
  --multi-tenant
```

**Multi-tenant features:**
- Tenant isolation
- Schema migrations
- Data partitioning
- Connection pooling
- Backup strategies

## Custom Template Examples

### Industry-Specific Templates

Create templates for specific industries.

```bash
# Fintech template
hypergen monorepo new fintech-app \
  --template fintech \
  --preset enterprise \
  --compliance pci,sox

# E-commerce template  
hypergen monorepo new store \
  --template ecommerce \
  --preset performance \
  --features cart,payments,inventory

# Healthcare template
hypergen monorepo new clinic \
  --template healthcare \
  --preset enterprise \
  --compliance hipaa,hitech
```

## Development Workflow Examples

### Git Workflow Integration

Optimized Git workflows with automation.

```bash
hypergen monorepo new git-workflow \
  --preset enterprise \
  --git-flow gitflow \
  --packages core,utils \
  --apps web,api
```

**Git workflow features:**
- Automated branch protection
- PR templates
- Commit message validation
- Release automation
- Changelog generation

### Continuous Integration

Advanced CI/CD pipeline setup.

```bash
hypergen monorepo new ci-cd \
  --preset performance \
  --ci-provider github \
  --packages shared,utils \
  --apps web,api \
  --deployment vercel,aws
```

**CI/CD capabilities:**
- Matrix testing
- Parallel builds
- Deployment previews
- Automated releases
- Security scanning
- Performance monitoring

These examples demonstrate the flexibility and power of @hypergen/monorepo-pack for various use cases and project requirements. Each example is production-ready and follows best practices for the chosen tools and architecture patterns.