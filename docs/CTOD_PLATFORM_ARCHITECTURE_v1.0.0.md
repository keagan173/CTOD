# CTOD Platform Architecture

Version 1.0.0
Locked: 2026-08-13
Status: Governing architecture decision for CTOD commercial product development

## Core Decision

CTOD is one multi-tenant SaaS platform owned and operated by CTOD. It is not a separate custom codebase for each customer.

CTOD must support businesses across multiple industries, including but not limited to tire/automotive, landscaping, restaurants, construction, manufacturing, retail, and general business.

Every customer receives an isolated Company Master/Tenant inside the CTOD platform. Customer-specific questions, roles, locations, workflows, scoring, competencies, development programs, and data collection requirements are configuration, not forks of the application.

## Environment Model

### CTOD Production

CTOD Production is the commercial system sold to customers.

Production contains:
- CTOD Platform Owner control plane
- Industry Template Library
- Customer tenant provisioning
- Customer Company Masters
- Customer live configurations
- Customer-specific sandboxes/drafts
- Platform release records
- Customer configuration release history
- Access, invitation, subscription, support, audit, and operational controls

The permanent Platform Owner experience belongs in Production. Planned owner route: `owner.ctod.app`. Planned customer route: `app.ctod.app` or equivalent final production domain.

### CTOD Development / Sandbox (002)

CTOD 002 Sandbox is the permanent development, staging, testing, and acceptance environment for CTOD itself.

002 is not the commercial master and is not sold to customers.

Use 002 to:
- build platform features
- test schema and application changes
- test security and permissions
- test industry templates
- test customer-specific configuration workflows
- test migrations, releases, rollback, and deployment controls
- validate changes before Production deployment

### CTOD 001

CTOD 001 remains the protected current production baseline/reference until the multi-tenant platform architecture proven in 002 is ready for controlled production promotion. Do not treat 001 and 002 as separate customer products.

## Customer Model

Every customer is a tenant under CTOD Production.

Examples:

Commercial Tire
- Industry: Tire/Automotive
- Many locations
- Company Master with regions/markets/locations, roles, employees, reviews, development, succession and talent intelligence

ABC Landscaping
- Industry: Landscaping
- One location today
- Must support adding locations as the business grows

Restaurant Group
- Industry: Restaurant
- Five restaurants
- Company Master across all locations with location-scoped and company-wide access

Customers remain isolated from one another. A change for one customer must not affect another customer unless the change is an approved platform release intended for multiple tenants.

## Industry Template Model

CTOD owns a versioned Industry Template Library. Initial examples:
- General Business
- Automotive / Tire
- Landscaping
- Restaurant
- Construction
- Manufacturing
- Retail
- Custom / Blank

A template is starter DNA only. After provisioning, each customer's configuration can evolve independently.

## Two Separate Release Paths

### Platform Release

Used when CTOD itself changes.

Build -> CTOD 002 Sandbox -> Test -> Security Test -> Acceptance Test -> Approve -> Deploy to CTOD Production -> Roll out to selected or all customers.

Examples: succession dashboard, review engine improvements, permission system, reporting, new modules.

### Customer Configuration Release

Used when only one customer's setup changes.

Customer Live -> Customer Sandbox/Draft -> Configure -> Validate -> Promote -> Customer Live.

Examples: Commercial Tire asks for different review questions or a custom dashboard. Landscaping and Restaurant customers remain unchanged.

## Owner and Customer Access

CTOD Platform Owner controls the software platform, production releases, customer provisioning, templates, support, customer sandboxes, deployment and rollback.

Customers never receive CTOD application editing rights.

Customer access is scoped inside their tenant:
- Location / middle management: authorized locations only
- Senior leadership / master viewer: company-wide read visibility as authorized
- Customer executive administrator: company-wide visibility plus invitations/access management
- CTOD Platform Owner: platform-level control across tenants

## Customer Change Management

CTOD must allow the Platform Owner to open a customer-specific sandbox, make or stage configuration changes, validate them, promote them only to that customer's live environment, retain release history, and roll back when necessary.

Customer customization must be configuration-first. Application forks are prohibited unless an explicit future architecture decision overrides this rule.

## Commercial Operating Principle

Selling CTOD means provisioning a new customer tenant, choosing a starting industry template, configuring the company, inviting authorized customer users, and going live. Selling CTOD must not mean cloning or rebuilding the CTOD application.

## Cloud-Readiness Rule

Every design decision must continue to pass the existing CTOD cloud-readiness test: could the same logic operate in the full cloud platform without redesign? If not, redesign before implementation.
