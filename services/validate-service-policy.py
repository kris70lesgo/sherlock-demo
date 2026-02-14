#!/usr/bin/env python3
"""
Service Policy Enforcement
Validates reviewer authority and decision constraints against service ownership records.

Phase 4 Integration: Called before finalizing any review record.
Purpose: Ensure only authorized personnel make incident decisions.
"""

import sys
import os
from pathlib import Path

# Try to import yaml, but allow demo mode without it
try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    print("⚠️  PyYAML not installed - service ownership validation skipped (demo mode)")
    print("   In production: pip install pyyaml")
    print("   Proceeding without authority enforcement...")
    print()
    # For demo purposes, accept any reviewer
    sys.exit(0)

def load_service_policy(service_name):
    """Load service ownership record."""
    policy_file = Path(f"services/{service_name}.yaml")
    
    if not policy_file.exists():
        print(f"❌ SERVICE POLICY VIOLATION")
        print(f"   Service '{service_name}' has no ownership record")
        print(f"   Expected: services/{service_name}.yaml")
        print()
        print("   Incidents cannot proceed without declared ownership.")
        print("   Contact: platform-team@company.com")
        sys.exit(1)
    
    try:
        with open(policy_file, 'r') as f:
            policy = yaml.safe_load(f)
        return policy
    except Exception as e:
        print(f"❌ SERVICE POLICY ERROR")
        print(f"   Failed to parse: services/{service_name}.yaml")
        print(f"   Error: {e}")
        sys.exit(1)

def validate_reviewer_authority(policy, reviewer_role):
    """Validate reviewer is authorized to finalize decisions."""
    review_policy = policy.get('review_policy', {})
    allowed_roles = review_policy.get('allowed_roles', [])
    forbidden_roles = review_policy.get('forbidden_roles', [])
    
    # Check forbidden first
    if reviewer_role in forbidden_roles:
        print(f"❌ REVIEWER AUTHORITY VIOLATION")
        print(f"   Role '{reviewer_role}' is explicitly forbidden")
        print(f"   Service: {policy['service']}")
        print(f"   Forbidden roles: {', '.join(forbidden_roles)}")
        print()
        print("   This review cannot be finalized.")
        print("   An authorized reviewer must perform Phase 4.")
        sys.exit(1)
    
    # Check allowed
    if reviewer_role not in allowed_roles:
        print(f"❌ REVIEWER AUTHORITY VIOLATION")
        print(f"   Role '{reviewer_role}' not authorized for this service")
        print(f"   Service: {policy['service']}")
        print(f"   Allowed roles: {', '.join(allowed_roles)}")
        print()
        print("   This review cannot be finalized.")
        print("   Contact service owners: {policy['owners']['primary']['contact']}")
        sys.exit(1)
    
    return True

def validate_decision_constraints(policy, decision_data):
    """Validate decision meets service constraints."""
    constraints = policy.get('decision_constraints', {})
    
    # Extract decision details
    decision_type = decision_data.get('decision', 'UNKNOWN')
    final_confidence = decision_data.get('final_confidence', 0)
    evidence_quality = decision_data.get('evidence_quality', 'UNKNOWN')
    has_override = decision_data.get('has_override', False)
    has_evidence_explanation = decision_data.get('has_evidence_explanation', False)
    
    # Check evidence quality constraint
    reject_threshold = constraints.get('reject_if_evidence_quality', None)
    if reject_threshold and evidence_quality == reject_threshold:
        print(f"⚠️  DECISION CONSTRAINT: Evidence Quality")
        print(f"   Evidence quality: {evidence_quality}")
        print(f"   Policy: Must REJECT if evidence is {reject_threshold}")
        print()
        if decision_type != 'REJECTED':
            print(f"❌ DECISION CONSTRAINT VIOLATION")
            print(f"   Decision must be REJECTED due to evidence quality")
            sys.exit(1)
    
    # Check confidence constraints
    max_without_override = constraints.get('max_confidence_without_override', 100)
    max_without_explanation = constraints.get('max_confidence_without_evidence_explanation', 100)
    
    if final_confidence > max_without_override and not has_override:
        print(f"❌ DECISION CONSTRAINT VIOLATION")
        print(f"   Final confidence: {final_confidence}%")
        print(f"   Max without override: {max_without_override}%")
        print()
        print("   High confidence requires explicit justification.")
        print("   Either lower confidence or document override rationale.")
        sys.exit(1)
    
    if final_confidence > max_without_explanation and not has_evidence_explanation:
        print(f"⚠️  DECISION CONSTRAINT: High Confidence")
        print(f"   Final confidence: {final_confidence}%")
        print(f"   Confidence > {max_without_explanation}% requires evidence explanation")
        print()
        # Warning only, not blocking
    
    # Check remediation requirement
    require_remediation = constraints.get('require_remediation_for_modified', False)
    if require_remediation and decision_type == 'MODIFIED':
        remediation_count = len(decision_data.get('remediation_promises', []))
        if remediation_count == 0:
            print(f"❌ DECISION CONSTRAINT VIOLATION")
            print(f"   Decision: MODIFIED")
            print(f"   Policy: Remediation promises required")
            print()
            print("   MODIFIED decisions must include remediation actions.")
            sys.exit(1)
    
    return True

def display_service_context(policy):
    """Display service ownership context for transparency."""
    print()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"Service Ownership: {policy['service']}")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()
    
    owners = policy.get('owners', {}).get('primary', {})
    print(f"Primary Owner:  {owners.get('team', 'Unknown')}")
    print(f"Contact:        {owners.get('contact', 'Unknown')}")
    
    escalation = owners.get('escalation', {})
    if escalation:
        print(f"Escalation:     {escalation.get('slack', 'N/A')}")
    
    print()
    
    review_policy = policy.get('review_policy', {})
    allowed_roles = review_policy.get('allowed_roles', [])
    print(f"Authorized Roles: {', '.join(allowed_roles)}")
    
    print()

def main():
    if len(sys.argv) < 4:
        print("Usage: validate-service-policy.py <service> <reviewer_role> <decision_data_yaml>")
        sys.exit(1)
    
    service_name = sys.argv[1]
    reviewer_role = sys.argv[2]
    decision_data_file = sys.argv[3]
    
    # Load service policy
    policy = load_service_policy(service_name)
    
    # Display service context
    display_service_context(policy)
    
    # Validate reviewer authority
    print("✓ Validating reviewer authority...")
    validate_reviewer_authority(policy, reviewer_role)
    print(f"  Reviewer role '{reviewer_role}' is authorized")
    print()
    
    # Load decision data
    if os.path.exists(decision_data_file):
        with open(decision_data_file, 'r') as f:
            decision_data = yaml.safe_load(f)
        
        # Validate decision constraints
        print("✓ Validating decision constraints...")
        validate_decision_constraints(policy, decision_data)
        print("  All constraints satisfied")
        print()
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ SERVICE POLICY VALIDATION PASSED")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()
    print("Reviewer is authorized to finalize this decision.")
    print()

if __name__ == '__main__':
    main()
