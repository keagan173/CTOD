# CTOD Three-Industry Acceptance v1.0.0

Date: 2026-08-13
Environment: CTOD 002 Sandbox only
Production impact: none

## Objective

Prove that one CTOD multi-tenant core can support materially different business shapes without cloning the application or forking customer code.

## Acceptance tenants

### Commercial Tire
- Industry/template: 001 Tire/Automotive reference
- Active locations: 55
- Active roles: 14
- Existing published customer configuration retained
- Used as the real large multi-location reference tenant

### GreenScape Acceptance Co
- Industry template: LANDSCAPE v1.0.0
- Active locations: 1
- Active roles: 3
- Draft review questions: 3
- Draft rating items: 5
- Customer sandbox: GreenScape Initial Setup
- Validation: PASS
- Validation checksum: c51e97a7154fa0191095ec1fc2afcbc6

### Restaurant Acceptance Group
- Industry template: RESTAURANT v1.0.0
- Active locations: 5
- Active roles: 4
- Draft review questions: 4
- Draft rating items: 5
- Customer sandbox: Restaurant Group Initial Setup
- Validation: PASS
- Validation checksum: 89f24569346afd62cdf562ae578745f3

## Validation gates passed

Both new acceptance tenants passed all required customer configuration gates:
- at least one active location
- at least one active role
- at least one active review question
- rating scale present

## Template engine defect discovered and corrected

Initial LANDSCAPE and RESTAURANT provisioning correctly seeded locations, roles, and questions, but did not seed rating-scale items. This caused valid new tenant configurations to be structurally incomplete for CTOD review validation.

CTOD 002 was updated so `private.provision_company_from_template` now:
1. seeds a template-supplied `ratings` array when present;
2. otherwise provisions the standard CTOD five-level scale: Exceptional, Exceeds Expectations, Meets Expectations, Needs Improvement, Unsatisfactory.

The two pre-fix fictional acceptance tenants were backfilled with that same five-level scale and both subsequently passed validation.

## Isolation checks

The acceptance read found zero:
- question/configuration company mismatches;
- rating/configuration company mismatches;
- GreenScape lineage pointing to a non-LANDSCAPE template;
- Restaurant lineage pointing to a non-RESTAURANT template.

## Result

PASS for the core multi-industry tenant-shape requirement.

CTOD can provision and independently configure:
- a large multi-location tire company;
- a one-location landscaping company that can grow later;
- a five-location restaurant group;

from one platform and one database model, with industry differences represented as versioned tenant templates/configuration rather than separate application forks.

## Remaining work before platform release approval

- finish customer executive/location-scoped access acceptance for the new tenants;
- finish persistent Owner Console commercial workflow in the hosted application;
- audit authenticated SECURITY DEFINER RPCs;
- enable leaked-password protection / Production MFA plan;
- keep Platform Release 1.1.0 blocked until its security gate truthfully passes;
- do not merge or deploy 002 work into CTOD 001 Production outside the platform release process.
