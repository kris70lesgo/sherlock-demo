#!/bin/bash
# Fresh Sherlock Demo - INC-123
# Clears previous state and runs investigation

echo "🧹 Clearing previous investigation state..."
rm -f incidents/INC-123.status.yaml
rm -f reports/*INC-123*
rm -f incidents/INC-123.yaml
echo ""

echo "🚀 Starting fresh investigation of INC-123"
echo "   (You'll be prompted for decision at Phase 4)"
echo ""

# Auto-answer Phase 4 prompts for non-interactive demo
# Decision: ACCEPT, Reviewer: Demo Reviewer, Role: SRE, Email: demo@sherlock.ai, Finalize: Y
{ echo "A"; echo "Demo Reviewer"; echo "SRE"; echo "demo@sherlock.ai"; echo "Y"; } | ./sherlock investigate INC-123
