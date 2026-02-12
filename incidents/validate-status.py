#!/usr/bin/env python3
"""
Incident Lifecycle State Validator
Enforces mechanical gating of pipeline phases based on incident state.

Core Principle: Human sets state. System enforces. AI never changes state.

State Model:
  OPEN → MITIGATING → MONITORING → RESOLVED → POSTMORTEM_COMPLETE

Phase Gates:
  Phase 1-3 (Investigation): OPEN, MITIGATING
  Phase 4 (Finalize RCA):    RESOLVED
  Phase 5 (Write Memory):    POSTMORTEM_COMPLETE
  Phase 6 (Execute Actions): MITIGATING
  Phase 7 (Trust Artifacts): POSTMORTEM_COMPLETE
"""

import sys
import os
from pathlib import Path
from datetime import datetime

# Valid lifecycle states
VALID_STATES = [
    'OPEN',
    'MITIGATING',
    'MONITORING',
    'RESOLVED',
    'POSTMORTEM_COMPLETE'
]

# State transition rules
ALLOWED_TRANSITIONS = {
    'OPEN': ['MITIGATING', 'RESOLVED'],  # Can skip straight to RESOLVED if quick fix
    'MITIGATING': ['MONITORING', 'RESOLVED'],
    'MONITORING': ['MITIGATING', 'RESOLVED'],  # Can regress if issue returns
    'RESOLVED': ['POSTMORTEM_COMPLETE', 'MITIGATING'],  # Can regress if issue returns
    'POSTMORTEM_COMPLETE': []  # Terminal state
}

# Role-based transition authorization
TRANSITION_ROLES = {
    'OPEN->MITIGATING': ['Incident Commander', 'SRE', 'SRE Lead'],
    'MITIGATING->MONITORING': ['Incident Commander', 'SRE Lead'],
    'MONITORING->RESOLVED': ['Incident Commander'],
    'RESOLVED->POSTMORTEM_COMPLETE': ['Incident Commander', 'SRE', 'SRE Lead'],
    # Regression paths (issue returns)
    'MONITORING->MITIGATING': ['Incident Commander', 'SRE Lead'],
    'RESOLVED->MITIGATING': ['Incident Commander'],
}

# Phase requirements
PHASE_REQUIREMENTS = {
    'investigate': ['OPEN', 'MITIGATING'],
    'finalize': ['RESOLVED'],
    'memory': ['POSTMORTEM_COMPLETE'],
    'actions': ['MITIGATING'],
    'trust': ['POSTMORTEM_COMPLETE'],
}

def parse_yaml_simple(file_path):
    """Simple YAML parser for status files."""
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    data = {}
    current_key = None
    history = []
    current_history_item = None
    notes = []
    
    for line in lines:
        line = line.rstrip('\n')
        
        # Skip empty lines and comments
        if not line.strip() or line.strip().startswith('#'):
            continue
        
        # Top-level keys
        if line and not line.startswith(' '):
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip().strip('"')
                
                if key in ('set_by', 'history', 'notes'):
                    current_key = key
                    if key == 'set_by':
                        data[key] = {}
                    elif value:
                        data[key] = value
                else:
                    data[key] = value if value else ''
                    current_key = key
        
        # Second-level indentation
        elif line.startswith('  ') and not line.startswith('    '):
            if current_key == 'set_by':
                if ':' in line:
                    key, value = line.strip().split(':', 1)
                    data['set_by'][key.strip()] = value.strip().strip('"')
            
            elif current_key == 'history':
                if line.strip().startswith('- state:'):
                    if current_history_item:
                        history.append(current_history_item)
                    current_history_item = {'state': line.split(':', 1)[1].strip()}
            
            elif current_key == 'notes':
                if line.strip().startswith('- '):
                    note = line.strip()[2:].strip().strip('"')
                    notes.append(note)
        
        # Third-level indentation (history details)
        elif line.startswith('    ') and current_history_item is not None:
            if ':' in line:
                key, value = line.strip().split(':', 1)
                current_history_item[key.strip()] = value.strip().strip('"')
    
    # Add last history item
    if current_history_item:
        history.append(current_history_item)
    
    if history:
        data['history'] = history
    if notes:
        data['notes'] = notes
    
    return data

def load_status(incident_id):
    """Load incident status file."""
    status_file = Path(f"incidents/{incident_id}.status.yaml")
    
    if not status_file.exists():
        return None
    
    try:
        return parse_yaml_simple(status_file)
    except Exception as e:
        print(f"❌ STATUS FILE ERROR")
        print(f"   Failed to parse: incidents/{incident_id}.status.yaml")
        print(f"   Error: {e}")
        sys.exit(1)

def get_current_state(incident_id):
    """Get current incident state."""
    status = load_status(incident_id)
    if not status:
        return None
    return status.get('status', 'UNKNOWN')

def display_status(incident_id):
    """Display current incident status."""
    status = load_status(incident_id)
    
    if not status:
        print()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"Incident Status: {incident_id}")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        print("⚠️  NO STATUS FILE FOUND")
        print(f"   Expected: incidents/{incident_id}.status.yaml")
        print()
        print("   Incident lifecycle tracking not initialized.")
        print("   Run: ./sherlock status {incident_id} set OPEN")
        print()
        return
    
    print()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"Incident Status: {incident_id}")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()
    
    current_state = status.get('status', 'UNKNOWN')
    print(f"Current state: {current_state}")
    print(f"Last updated: {status.get('updated_at', 'Unknown')}")
    
    set_by = status.get('set_by', {})
    print(f"Set by: {set_by.get('name', 'Unknown')} ({set_by.get('role', 'Unknown')})")
    print()
    
    if 'notes' in status and status['notes']:
        print("Notes:")
        for note in status['notes']:
            print(f"  • {note}")
        print()
    
    # Show what's allowed at this state
    print("Phase Permissions:")
    
    if current_state in ['OPEN', 'MITIGATING']:
        print("  ✓ Investigation allowed (Phases 1-3)")
    else:
        print("  ✗ Investigation blocked - incident not OPEN or MITIGATING")
    
    if current_state == 'RESOLVED':
        print("  ✓ RCA finalization allowed (Phase 4)")
    else:
        print("  ✗ RCA finalization blocked - incident not RESOLVED")
    
    if current_state == 'MITIGATING':
        print("  ✓ Action execution allowed (Phase 6)")
    else:
        print("  ✗ Action execution blocked - incident not MITIGATING")
    
    if current_state == 'POSTMORTEM_COMPLETE':
        print("  ✓ Memory write allowed (Phase 5)")
        print("  ✓ Trust artifacts allowed (Phase 7)")
    else:
        print("  ✗ Memory write blocked - incident not POSTMORTEM_COMPLETE")
        print("  ✗ Trust artifacts blocked - incident not POSTMORTEM_COMPLETE")
    
    print()
    
    # Show transition options
    if current_state in ALLOWED_TRANSITIONS:
        allowed = ALLOWED_TRANSITIONS[current_state]
        if allowed:
            print(f"Allowed transitions: {' | '.join(allowed)}")
        else:
            print("No transitions allowed (terminal state)")
    print()

def validate_phase_gate(incident_id, phase):
    """Validate incident state allows requested phase."""
    status = load_status(incident_id)
    
    if not status:
        print()
        print("❌ LIFECYCLE VIOLATION")
        print(f"   No status file found for {incident_id}")
        print(f"   Expected: incidents/{incident_id}.status.yaml")
        print()
        print("   Incident lifecycle must be initialized before proceeding.")
        print(f"   Run: ./sherlock status {incident_id} set OPEN")
        print()
        sys.exit(1)
    
    current_state = status.get('status', 'UNKNOWN')
    
    if phase not in PHASE_REQUIREMENTS:
        print(f"⚠️  Unknown phase: {phase}")
        return True
    
    allowed_states = PHASE_REQUIREMENTS[phase]
    
    if current_state not in allowed_states:
        print()
        print("❌ INCIDENT STATE VIOLATION")
        print(f"   Cannot execute {phase} for {incident_id}")
        print(f"   Current state: {current_state}")
        print(f"   Required state: {' or '.join(allowed_states)}")
        print()
        
        # Helpful guidance
        if phase == 'finalize':
            print("   RCA finalization requires incident to be RESOLVED.")
            print("   If incident is still ongoing, continue investigation.")
            print(f"   Once resolved, run: ./sherlock status {incident_id} set RESOLVED")
        elif phase == 'memory':
            print("   Institutional memory write requires POSTMORTEM_COMPLETE.")
            print("   Finalize RCA first, then mark postmortem complete.")
            print(f"   Run: ./sherlock status {incident_id} set POSTMORTEM_COMPLETE")
        elif phase == 'actions':
            print("   Action execution requires incident to be MITIGATING.")
            print("   If still investigating, set state to MITIGATING first.")
            print(f"   Run: ./sherlock status {incident_id} set MITIGATING")
        
        print()
        sys.exit(1)
    
    return True

def set_status(incident_id, new_state, user_name, user_role, user_id, notes_text=None):
    """Set incident status with validation."""
    status_file = Path(f"incidents/{incident_id}.status.yaml")
    
    # Validate state
    if new_state not in VALID_STATES:
        print(f"❌ INVALID STATE: {new_state}")
        print(f"   Allowed states: {', '.join(VALID_STATES)}")
        sys.exit(1)
    
    # Load existing status
    existing = load_status(incident_id)
    
    if existing:
        current_state = existing.get('status', 'UNKNOWN')
        
        # Validate transition
        if current_state in ALLOWED_TRANSITIONS:
            allowed = ALLOWED_TRANSITIONS[current_state]
            if new_state not in allowed:
                print()
                print("❌ INVALID STATE TRANSITION")
                print(f"   Current: {current_state}")
                print(f"   Requested: {new_state}")
                print(f"   Allowed: {', '.join(allowed) if allowed else 'None (terminal state)'}")
                print()
                sys.exit(1)
        
        # Validate role authorization
        transition_key = f"{current_state}->{new_state}"
        if transition_key in TRANSITION_ROLES:
            allowed_roles = TRANSITION_ROLES[transition_key]
            if user_role not in allowed_roles:
                print()
                print("❌ AUTHORITY VIOLATION")
                print(f"   Role '{user_role}' cannot transition {current_state} → {new_state}")
                print(f"   Allowed roles: {', '.join(allowed_roles)}")
                print()
                sys.exit(1)
    
    # Generate new status file
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    
    # Build history
    history_entries = []
    if existing and 'history' in existing:
        history_entries = existing['history']
    
    # Add new history entry
    history_entry = {
        'state': new_state,
        'set_by': user_name,
        'timestamp': timestamp,
    }
    if notes_text:
        history_entry['notes'] = notes_text
    
    history_entries.append(history_entry)
    
    # Write new status
    with open(status_file, 'w') as f:
        f.write("# Incident Lifecycle State\n")
        f.write("# Purpose: Gate pipeline behavior based on real-world incident progression\n")
        f.write("# Rule: Human sets state. System enforces. AI never changes state.\n\n")
        
        f.write(f"incident_id: {incident_id}\n\n")
        
        f.write(f"status: {new_state}\n")
        f.write("# Allowed values:\n")
        f.write("#   OPEN                   - Incident declared, investigation starting\n")
        f.write("#   MITIGATING            - Actions/changes in progress\n")
        f.write("#   MONITORING            - Waiting to confirm stability\n")
        f.write("#   RESOLVED              - Incident over, RCA allowed\n")
        f.write("#   POSTMORTEM_COMPLETE   - Analysis finalized, memory write allowed\n\n")
        
        f.write("set_by:\n")
        f.write(f'  name: "{user_name}"\n')
        f.write(f'  role: "{user_role}"\n')
        f.write(f'  identifier: "{user_id}"\n\n')
        
        f.write(f'updated_at: "{timestamp}"\n\n')
        
        # Write history
        f.write("history:\n")
        for entry in history_entries:
            f.write(f"  - state: {entry['state']}\n")
            f.write(f"    set_by: \"{entry['set_by']}\"\n")
            f.write(f"    timestamp: \"{entry['timestamp']}\"\n")
            if 'notes' in entry:
                f.write(f"    notes: \"{entry['notes']}\"\n")
        
        # Write current notes if provided
        if notes_text:
            f.write("\nnotes:\n")
            f.write(f'  - "{notes_text}"\n')
        elif existing and 'notes' in existing:
            f.write("\nnotes:\n")
            for note in existing['notes']:
                f.write(f'  - "{note}"\n')
    
    print()
    print("✓ Incident state updated")
    print(f"  {incident_id}: {existing.get('status', 'NEW') if existing else 'NEW'} → {new_state}")
    print(f"  Updated by: {user_name} ({user_role})")
    print()

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  validate-status.py <incident_id> display")
        print("  validate-status.py <incident_id> check <phase>")
        print("  validate-status.py <incident_id> set <state> <name> <role> <id> [notes]")
        sys.exit(1)
    
    incident_id = sys.argv[1]
    action = sys.argv[2] if len(sys.argv) > 2 else 'display'
    
    if action == 'display':
        display_status(incident_id)
    
    elif action == 'check':
        if len(sys.argv) < 4:
            print("Usage: validate-status.py <incident_id> check <phase>")
            sys.exit(1)
        phase = sys.argv[3]
        validate_phase_gate(incident_id, phase)
        print(f"✓ Phase '{phase}' allowed at current incident state")
    
    elif action == 'set':
        if len(sys.argv) < 7:
            print("Usage: validate-status.py <incident_id> set <state> <name> <role> <id> [notes]")
            sys.exit(1)
        
        new_state = sys.argv[3]
        user_name = sys.argv[4]
        user_role = sys.argv[5]
        user_id = sys.argv[6]
        notes_text = sys.argv[7] if len(sys.argv) > 7 else None
        
        set_status(incident_id, new_state, user_name, user_role, user_id, notes_text)
    
    else:
        print(f"Unknown action: {action}")
        sys.exit(1)

if __name__ == '__main__':
    main()
