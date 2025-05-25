#!/bin/bash

# Run Tamarin verification for EDHOC PSK Variant 1
# Based on the existing run-tamarin.sh script

set -e

echo "Starting Tamarin verification for EDHOC PSK Variant 1..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p results

# Model file
MODEL="edhoc-psk-variant1.spthy"

# Check if model exists
if [ ! -f "$MODEL" ]; then
    echo -e "${RED}Error: Model file $MODEL not found${NC}"
    exit 1
fi

echo -e "${BLUE}Verifying model: $MODEL${NC}"

# Basic verification - all lemmas
echo -e "${YELLOW}Running full verification...${NC}"
tamarin-prover --prove "$MODEL" > "results/tamarin-full-results.txt" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Full verification completed successfully${NC}"
else
    echo -e "${RED}Full verification failed or had issues${NC}"
fi

# Sanity checks only
echo -e "${YELLOW}Running sanity checks...${NC}"
tamarin-prover --prove --lemma="executable*" "$MODEL" > "results/tamarin-sanity-results.txt" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Sanity checks completed${NC}"
else
    echo -e "${RED}Sanity checks failed${NC}"
fi

# Confidentiality properties
echo -e "${YELLOW}Running confidentiality checks...${NC}"
tamarin-prover --prove --lemma="secret*" "$MODEL" > "results/tamarin-secret-results.txt" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Confidentiality checks completed${NC}"
else
    echo -e "${RED}Confidentiality checks failed${NC}"
fi

# Authentication properties
echo -e "${YELLOW}Running authentication checks...${NC}"
tamarin-prover --prove --lemma="*auth*" "$MODEL" > "results/tamarin-auth-results.txt" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Authentication checks completed${NC}"
else
    echo -e "${RED}Authentication checks failed${NC}"
fi

# Forward secrecy
echo -e "${YELLOW}Running forward secrecy checks...${NC}"
tamarin-prover --prove --lemma="forwardSecrecy*" "$MODEL" > "results/tamarin-fs-results.txt" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Forward secrecy checks completed${NC}"
else
    echo -e "${RED}Forward secrecy checks failed${NC}"
fi

# Generate summary
echo -e "${BLUE}Generating verification summary...${NC}"

cat > "results/verification-summary.txt" << EOF
EDHOC PSK Variant 1 Tamarin Verification Summary
================================================
Generated: $(date)

Model: $MODEL

Verification Results:
EOF

# Check results and add to summary
if grep -q "All lemmas verified" "results/tamarin-full-results.txt" 2>/dev/null; then
    echo "✓ Full verification: PASSED" >> "results/verification-summary.txt"
else
    echo "✗ Full verification: FAILED or INCOMPLETE" >> "results/verification-summary.txt"
fi

if grep -q "All lemmas verified" "results/tamarin-sanity-results.txt" 2>/dev/null; then
    echo "✓ Sanity checks: PASSED" >> "results/verification-summary.txt"
else
    echo "✗ Sanity checks: FAILED" >> "results/verification-summary.txt"
fi

if grep -q "All lemmas verified" "results/tamarin-secret-results.txt" 2>/dev/null; then
    echo "✓ Confidentiality: PASSED" >> "results/verification-summary.txt"
else
    echo "✗ Confidentiality: FAILED" >> "results/verification-summary.txt"
fi

if grep -q "All lemmas verified" "results/tamarin-auth-results.txt" 2>/dev/null; then
    echo "✓ Authentication: PASSED" >> "results/verification-summary.txt"
else
    echo "✗ Authentication: FAILED" >> "results/verification-summary.txt"
fi

if grep -q "All lemmas verified" "results/tamarin-fs-results.txt" 2>/dev/null; then
    echo "✓ Forward Secrecy: PASSED" >> "results/verification-summary.txt"
else
    echo "✗ Forward Secrecy: FAILED" >> "results/verification-summary.txt"
fi

echo "" >> "results/verification-summary.txt"
echo "Detailed results available in results/ directory" >> "results/verification-summary.txt"

# Display summary
echo -e "${BLUE}"
cat "results/verification-summary.txt"
echo -e "${NC}"

echo -e "${GREEN}Tamarin verification completed. Check results/ directory for detailed output.${NC}"
