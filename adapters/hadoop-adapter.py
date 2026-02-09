#!/usr/bin/env python3
"""
Hadoop Log Adapter - Evidence Contract Enforcer

Converts raw Hadoop logs → Evidence Contract format
This adapter sits BEFORE Phase 1 validation.

Contract guarantees:
- ISO-8601 UTC timestamps
- Generic event types (no Hadoop jargon)
- Aggregated signals (count-based)
- Severity normalization (INFO/WARN/ERROR only)
"""

import re
import sys
from datetime import datetime
from collections import defaultdict
import json

# Evidence contract event type mappings
EVENT_TYPE_PATTERNS = [
    # Lifecycle events
    (r'STARTUP_MSG.*Starting', 'startup'),
    (r'SHUTDOWN_MSG.*Shutting down', 'shutdown'),
    (r'service.*starting', 'service_start'),
    
    # Resource allocation failures
    (r'failed to allocate.*block', 'resource_allocation_failure'),
    (r'Could not get block', 'io_error'),
    
    # Performance degradation
    (r'Slow.*write.*took', 'performance_degradation'),
    
    # Crashes and errors
    (r'OutOfMemoryError|SIGTERM|Exception in', 'process_crash'),
    (r'RECEIVED SIGNAL', 'signal_received'),
    
    # Operational events
    (r'Successfully sent block report', 'operational_success'),
    (r'Registered.*via JMX', 'registration'),
]

# Severity mapping (Hadoop → Contract)
SEVERITY_MAP = {
    'INFO': 'INFO',
    'WARN': 'WARN',
    'ERROR': 'ERROR',
    # Forbidden levels (adapter rejects):
    'DEBUG': None,
    'TRACE': None,
    'FATAL': None,
}

def parse_hadoop_timestamp(ts_str):
    """
    Parse Hadoop timestamp to ISO-8601 UTC
    Input: "2015-03-16 23:17:42,123"
    Output: "2015-03-16T23:17:42Z"
    """
    try:
        # Remove milliseconds for simplicity
        ts_clean = ts_str.split(',')[0]
        dt = datetime.strptime(ts_clean, "%Y-%m-%d %H:%M:%S")
        return dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return None

def classify_event(message):
    """
    Map Hadoop-specific message → generic event type
    Returns: event_type or None if unclassifiable
    """
    for pattern, event_type in EVENT_TYPE_PATTERNS:
        if re.search(pattern, message, re.IGNORECASE):
            return event_type
    return None

def extract_component(logger_name):
    """
    Extract logical component from Hadoop logger name
    Input: "org.apache.hadoop.hdfs.server.datanode.DataNode"
    Output: "storage_service"
    """
    if 'datanode' in logger_name.lower():
        return 'storage_service'
    elif 'namenode' in logger_name.lower():
        return 'metadata_service'
    elif 'resourcemanager' in logger_name.lower():
        return 'resource_manager'
    else:
        return 'unknown_service'

def parse_hadoop_log(log_content):
    """
    Parse raw Hadoop logs into evidence contract events
    
    Returns: list of events or None if parsing fails
    """
    # Regex for Hadoop log format
    # Format: YYYY-MM-DD HH:MM:SS,mmm LEVEL logger.Class: message
    log_pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\s+(INFO|WARN|ERROR|DEBUG|TRACE|FATAL)\s+([\w\.]+):\s+(.*)'
    
    events = []
    
    for line in log_content.split('\n'):
        line = line.strip()
        if not line or line.startswith('/***'):
            continue
        
        match = re.match(log_pattern, line)
        if not match:
            # Skip continuation lines (stack traces, etc.)
            continue
        
        timestamp_raw, severity_raw, logger, message = match.groups()
        
        # Contract validation: Severity normalization
        severity = SEVERITY_MAP.get(severity_raw)
        if severity is None:
            # Forbidden severity level (DEBUG/TRACE/FATAL)
            print(f"⚠️  Adapter: Skipping forbidden severity {severity_raw}", file=sys.stderr)
            continue
        
        # Contract validation: Timestamp normalization
        timestamp = parse_hadoop_timestamp(timestamp_raw)
        if not timestamp:
            print(f"❌ Adapter: Invalid timestamp {timestamp_raw}", file=sys.stderr)
            return None
        
        # Contract validation: Event type classification
        event_type = classify_event(message)
        if not event_type:
            # Skip unclassifiable events (too generic)
            continue
        
        # Extract logical component
        component = extract_component(logger)
        
        events.append({
            'timestamp': timestamp,
            'severity': severity,
            'event_type': event_type,
            'component': component,
            'raw_message': message[:100],  # Keep for debugging, truncated
        })
    
    return events

def aggregate_events(events):
    """
    Aggregate duplicate events into counted signals
    Contract requirement: count > 1 for repeated events
    """
    # Group by (event_type, severity, component)
    groups = defaultdict(list)
    
    for event in events:
        key = (event['event_type'], event['severity'], event['component'])
        groups[key].append(event)
    
    aggregated = []
    
    for (event_type, severity, component), group in groups.items():
        # Sort by timestamp
        group_sorted = sorted(group, key=lambda e: e['timestamp'])
        
        signal = {
            'event': event_type,
            'severity': severity,
            'component': component,
            'count': len(group),
            'first_seen': group_sorted[0]['timestamp'],
        }
        
        if len(group) > 1:
            signal['last_seen'] = group_sorted[-1]['timestamp']
        
        aggregated.append(signal)
    
    return aggregated

def generate_contract_output(aggregated_signals):
    """
    Generate final evidence contract output
    """
    # Check for quality issues
    has_errors = any(s['severity'] == 'ERROR' for s in aggregated_signals)
    has_warnings = any(s['severity'] == 'WARN' for s in aggregated_signals)
    has_startup = any(s['event'] == 'startup' for s in aggregated_signals)
    has_shutdown = any(s['event'] == 'shutdown' for s in aggregated_signals)
    has_crash = any(s['event'] == 'process_crash' for s in aggregated_signals)
    
    # Determine completeness
    completeness = 'COMPLETE'
    notes = []
    confidence_penalty = 0
    
    if not (has_startup or has_shutdown):
        completeness = 'PARTIAL'
        notes.append('No lifecycle events detected')
        confidence_penalty += 10
    
    if has_crash and not has_shutdown:
        notes.append('Crash detected without clean shutdown')
        confidence_penalty += 5
    
    if not (has_errors or has_warnings):
        completeness = 'LOW_SIGNAL'
        notes.append('No ERROR or WARN events detected')
        confidence_penalty += 20
    
    # Build contract output
    output = {
        'source': 'hadoop',
        'quality': {
            'completeness': completeness,
            'confidence_penalty': confidence_penalty,
            'notes': notes if notes else ['Evidence appears complete']
        },
        'signals': sorted(aggregated_signals, key=lambda s: s['first_seen'])
    }
    
    return output

def main():
    if len(sys.argv) < 2:
        print("Usage: hadoop-adapter.py <hadoop-log-file>", file=sys.stderr)
        sys.exit(1)
    
    log_file = sys.argv[1]
    
    try:
        with open(log_file, 'r') as f:
            log_content = f.read()
    except FileNotFoundError:
        print(f"❌ Adapter: Log file not found: {log_file}", file=sys.stderr)
        sys.exit(1)
    
    # Parse raw Hadoop logs
    events = parse_hadoop_log(log_content)
    
    if events is None:
        print("❌ Adapter: Failed to parse Hadoop logs (contract violation)", file=sys.stderr)
        sys.exit(1)
    
    if not events:
        print("❌ Adapter: No classifiable events found in logs", file=sys.stderr)
        sys.exit(1)
    
    # Aggregate into signals
    aggregated = aggregate_events(events)
    
    # Generate contract-compliant output
    contract_output = generate_contract_output(aggregated)
    
    # Output JSON
    print(json.dumps(contract_output, indent=2))
    
    # Debug stats to stderr
    print(f"✓ Adapter: Processed {len(events)} events → {len(aggregated)} aggregated signals", file=sys.stderr)
    print(f"  Quality: {contract_output['quality']['completeness']}", file=sys.stderr)
    if contract_output['quality']['confidence_penalty'] > 0:
        print(f"  Confidence penalty: {contract_output['quality']['confidence_penalty']}%", file=sys.stderr)

if __name__ == '__main__':
    main()
