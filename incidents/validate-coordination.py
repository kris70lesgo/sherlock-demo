#!/usr/bin/env python3
"""
Incident Coordination Validator
Enforces governance boundaries for multi-service incidents.

Purpose: Ensure service sovereignty is preserved during coordination.
No cross-service approvals. No AI correlation. Explicit accountability only.
"""

import sys
import os
from pathlib import Path

def parse_yaml_simple(file_path):
    """Simple YAML parser for our coordination record format."""
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    data = {}
    current_key = None
    services = []
    current_service = None
    notes = []
    
    for line in lines:
        line = line.rstrip('\n')
        
        # Skip empty lines and comments
        if not line.strip() or line.strip().startswith('#'):
            continue
        
        # Top-level keys (no indentation)
        if line and not line.startswith(' '):
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip().strip('"')
                
                if key in ('declared_by', 'services', 'coordination_notes'):
                    current_key = key
                    if key == 'declared_by':
                        data[key] = {}
                    if value and key not in ('declared_by', 'services', 'coordination_notes'):
                        data[key] = value
                else:
                    data[key] = value if value else ''
                    current_key = key
        
        # Second-level indentation (2 spaces)
        elif line.startswith('  ') and not line.startswith('    '):
            if current_key == 'declared_by':
                if ':' in line:
                    key, value = line.strip().split(':', 1)
                    data['declared_by'][key.strip()] = value.strip().strip('"')
            
            elif current_key == 'services':
                if line.strip().startswith('- name:'):
                    # Save previous service
                    if current_service and 'name' in current_service:
                        services.append(current_service)
                    # Start new service
                    current_service = {'name': line.split(':', 1)[1].strip()}
            
            elif current_key == 'coordination_notes':
                if line.strip().startswith('- '):
                    note = line.strip()[2:].strip().strip('"')
                    notes.append(note)
        
        # Third-level indentation (4 spaces) - service properties
        elif line.startswith('    ') and current_service is not None:
            if ':' in line:
                key, value = line.strip().split(':', 1)
                current_service[key.strip()] = value.strip().strip('"')
    
    # Add last service
    if current_service and 'name' in current_service:
        services.append(current_service)
    
    if services:
        data['services'] = services
    if notes:
        data['coordination_notes'] = notes
    
    return data

def load_coordination_record(incident_id):
    """Load incident coordination record."""
    coord_file = Path(f"incidents/{incident_id}.coordination.yaml")
    
    if not coord_file.exists():
        print(f"⚠️  NO COORDINATION RECORD FOUND")
        print(f"   Incident: {incident_id}")
        print(f"   Expected: incidents/{incident_id}.coordination.yaml")
        print()
        print("   This appears to be a single-service incident.")
        print("   Proceeding with standard single-service workflow.")
        return None
    
    try:
        coord = parse_yaml_simple(coord_file)
        return coord
    except Exception as e:
        print(f"❌ COORDINATION RECORD ERROR")
        print(f"   Failed to parse: incidents/{incident_id}.coordination.yaml")
        print(f"   Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

def validate_service_in_coordination(coordination, service_name):
    """Validate requested service is part of incident scope."""
    if coordination is None:
        # Single-service incident, no validation needed
        return True
    
    services = coordination.get('services', [])
    service_names = [s.get('name') for s in services]
    
    if service_name not in service_names:
        print(f"❌ SERVICE NOT IN INCIDENT SCOPE")
        print(f"   Incident: {coordination.get('incident_id', 'Unknown')}")
        print(f"   Requested service: {service_name}")
        print(f"   Services in scope: {', '.join(service_names)}")
        print()
        print("   This service is not part of the coordinated incident.")
        print("   Update coordination record or use correct service name.")
        sys.exit(1)
    
    return True

def get_service_role(coordination, service_name):
    """Get the role of a service in the incident."""
    if coordination is None:
        return "single_service"
    
    services = coordination.get('services', [])
    for service in services:
        if service.get('name') == service_name:
            return service.get('role', 'unknown')
    
    return 'unknown'

def display_coordination_context(coordination, service_name):
    """Display coordination context for this service."""
    if coordination is None:
        print()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Single-Service Incident")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        print(f"Service: {service_name}")
        print("No coordination record found - standard single-service analysis")
        print()
        return
    
    print()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"Multi-Service Incident Coordination: {coordination.get('incident_id', 'Unknown')}")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()
    
    print(f"Incident Title: {coordination.get('incident_title', 'N/A')}")
    print(f"Severity: {coordination.get('incident_severity', 'N/A')}")
    print()
    
    declared_by = coordination.get('declared_by', {})
    print(f"Declared by: {declared_by.get('name', 'Unknown')} ({declared_by.get('role', 'Unknown')})")
    print()
    
    services = coordination.get('services', [])
    print(f"Services involved ({len(services)}):")
    for service in services:
        marker = "→" if service.get('name') == service_name else " "
        role = service.get('role', 'unknown').replace('_', ' ').title()
        print(f"  {marker} {service.get('name')} ({role})")
    print()
    
    # Show this service's role
    service_role = get_service_role(coordination, service_name)
    print(f"This service role: {service_role.replace('_', ' ').upper()}")
    print()
    
    if service_role == 'primary_candidate':
        print("⚠️  PRIMARY CAUSE CANDIDATE")
        print("   This service requires finalized analysis to close incident")
        print()
    elif service_role == 'downstream_impact':
        print("ℹ️  DOWNSTREAM IMPACT")
        print("   Affected by primary cause but may have contributing factors")
        print()
    elif service_role == 'symptom_only':
        print("ℹ️  SYMPTOM ONLY")
        print("   Surfaced alert but no fault expected")
        print("   No remediation required unless issues found")
        print()

def validate_primary_candidate_finalization(coordination):
    """Ensure primary candidate has finalized review before incident closure."""
    if coordination is None:
        return True
    
    services = coordination.get('services', [])
    primary_services = [s for s in services if s.get('role') == 'primary_candidate']
    
    if not primary_services:
        print("⚠️  NO PRIMARY CANDIDATE DECLARED")
        print("   Multi-service incidents should have at least one primary candidate")
        return True
    
    for service in primary_services:
        service_name = service.get('name')
        incident_id = coordination.get('incident_id', 'Unknown')
        review_file = Path(f"reports/review-record-{incident_id}-{service_name}.yaml")
        
        if not review_file.exists():
            print(f"⚠️  PRIMARY CANDIDATE NOT REVIEWED")
            print(f"   Service: {service_name}")
            print(f"   Role: primary_candidate")
            print(f"   Missing: {review_file}")
            print()
            print("   Incident cannot be closed until primary candidate is reviewed")
            return False
        
        # Check if finalized
        try:
            with open(review_file, 'r') as f:
                content = f.read()
            
            if 'status: FINALIZED' not in content:
                print(f"⚠️  PRIMARY CANDIDATE NOT FINALIZED")
                print(f"   Service: {service_name}")
                print()
                print("   Incident cannot be closed until primary candidate is finalized")
                return False
        except Exception as e:
            print(f"⚠️  CANNOT VALIDATE PRIMARY CANDIDATE")
            print(f"   Service: {service_name}")
            print(f"   Error: {e}")
            return False
    
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: validate-coordination.py <incident_id> [service_name] [action]")
        print()
        print("Actions:")
        print("  display    - Show coordination context (requires service_name)")
        print("  validate   - Validate service in scope (requires service_name)")
        print("  check-primary - Check primary candidate finalization")
        sys.exit(1)
    
    incident_id = sys.argv[1]
    
    # Check if second arg is an action (for check-primary)
    if len(sys.argv) >= 3 and sys.argv[2] == 'check-primary':
        action = 'check-primary'
        service_name = None
    else:
        service_name = sys.argv[2] if len(sys.argv) >= 3 else None
        action = sys.argv[3] if len(sys.argv) >= 4 else "display"
    
    # Load coordination record
    coordination = load_coordination_record(incident_id)
    
    if action == "display":
        if not service_name:
            print("Error: display action requires service_name")
            sys.exit(1)
        display_coordination_context(coordination, service_name)
        
        if coordination:
            service_role = get_service_role(coordination, service_name)
            print("✓ Coordination context displayed")
            print(f"  Service role: {service_role}")
            print()
    
    elif action == "validate":
        if not service_name:
            print("Error: validate action requires service_name")
            sys.exit(1)
        validate_service_in_coordination(coordination, service_name)
        print(f"✓ Service '{service_name}' is in incident scope")
        print()
    
    elif action == "check-primary":
        if validate_primary_candidate_finalization(coordination):
            print("✓ Primary candidate finalization satisfied")
        else:
            print("❌ Primary candidate finalization required")
            sys.exit(1)
    
    else:
        print(f"Unknown action: {action}")
        sys.exit(1)

if __name__ == '__main__':
    main()
