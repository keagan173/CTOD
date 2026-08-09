# CTOD Multi-Industry Architecture

## Purpose
CTOD must evolve from a single Commercial Tire implementation into a reusable platform that can support Industry 001, Industry 002, Industry 003, and future industries without cloning the codebase.

## Current Reference Implementation
- Industry 001 = Commercial Tire
- Industry 001 is the production reference implementation used to prove the CTOD platform.
- Commercial Tire-specific data includes locations, job roles, review questions, coaching categories, hierarchy, and organization terminology.

## Core Principle
Build CTOD features once in the platform core, then configure each industry/company through data and administration rather than separate application forks.

### CTOD Core
Shared across every industry:
- Authentication and access management
- 6-digit employee identity and permanent history
- Locations and organization hierarchy
- Employee 360
- Reviews and review scheduling
- Coaching moments
- Carry-forward and two-cycle resolution logic
- Goals and development tracking
- Succession and depth
- Master dashboards and analytics
- Company, area, market, and location views
- Alerts and talent intelligence
- Transfers and assignment history
- Audit/history preservation

### Industry Configuration
Each industry should define only configuration, not custom application code:
- Industry code and name
- Default terminology
- Standard job roles
- Role-specific review questions
- Coaching types/categories
- Succession-critical roles
- Default review cadence
- Optional scoring/weighting rules
- Industry-level templates

### Company Configuration
Each company operating under an industry template should define:
- Company name and branding
- Locations
- Areas / markets / divisions
- Company-specific job roles or overrides
- Company-specific review questions or overrides
- User permissions
- Review cadence overrides
- Company coaching categories and terminology

## Target Hierarchy
Platform: CTOD

Industry:
- 001 Commercial Tire
- 002 Future Industry
- 003 Future Industry

Company:
- Commercial Tire Company
- Future client companies

Organization:
- Company -> Area -> Market -> Location

Employee:
- Permanent 6-digit employee identity
- History follows employee across all assignments and locations

## Blank Standard Master
A new industry must be creatable from a blank CTOD Master template containing all platform functions with no customer-specific operational data.

A blank industry starts with:
- No locations
- No employees
- No company-specific job roles
- No company-specific review questions
- No company-specific coaching history

But immediately includes:
- Reviews
- Coaching
- Employees
- People / Employee 360
- Review Schedule
- Locations administration
- Job Roles administration
- Succession
- Master dashboards
- Access Management
- Talent intelligence

The administrator then adds job roles, review questions, locations, hierarchy, and users.

## Future Industry Template Manager
Master should eventually include an Industry Template Manager that can:
1. Create a new industry code.
2. Start from Blank Standard Master or duplicate an existing template.
3. Configure roles and questions.
4. Configure coaching categories and terminology.
5. Configure succession-critical roles.
6. Publish a template.
7. Create companies from a published industry template.
8. Version templates without altering historical review records.

## Data Isolation Requirement
Every operational record must be scoped so one industry/company cannot see or modify another industry's/company's information. The future schema should support explicit industry and company tenancy with row-level security.

## Historical Integrity Requirement
Configuration changes must never rewrite history.
- Deactivate instead of destructively deleting roles, locations, or questions used historically.
- Finalized reviews retain the role/question/configuration version used when finalized.
- Employee history remains attached to the permanent employee identity.

## Engineering Rule
Do not create a separate repository or application fork for Industry 002. Refactor toward configuration-driven tenancy so improvements to CTOD Core automatically benefit every industry.

## Deferred Work
This architecture is documented for the next development session. Current priority is making Industry 001 (Commercial Tire) operationally ready through acceptance testing, security validation, data-integrity testing, workflow testing, and UI polish.
