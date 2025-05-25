#!/bin/bash

# Run ProVerif verification for EDHOC PSK Variant 1
# Based on the existing run-proverif.sh script

set -e

echo "Starting ProVerif verification for EDHOC PSK Variant 1..."

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

echo -e "${BLUE}Converting and verifying model: $MODEL${NC}"

# Convert Tamarin model to ProVerif format
echo -e "${YELLOW}Converting to ProVerif format...${NC}"

# First extract ProVerif-compatible properties
tamarin-prover --export=proverif "$MODEL" > "edhoc-psk-variant1.pv" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Model conversion completed${NC}"
else
    echo -e "${RED}Model conversion failed${NC}"
    echo "Check if the model has ProVerif-compatible exports"
    exit 1
fi

# Run ProVerif verification
echo -e "${YELLOW}Running ProVerif verification...${NC}"

# Basic verification
proverif "edhoc-psk-variant1.pv" > "results/proverif-results.txt" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}ProVerif verification completed${NC}"
else
    echo -e "${RED}ProVerif verification failed${NC}"
fi

# Run with additional options for detailed analysis
echo -e "${YELLOW}Running detailed ProVerif analysis...${NC}"

proverif -html "results/proverif-detailed" "edhoc-psk-variant1.pv" > "results/proverif-detailed-results.txt" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Detailed ProVerif analysis completed${NC}"
else
    echo -e "${RED}Detailed ProVerif analysis failed${NC}"
fi

# Generate ProVerif summary
echo -e "${BLUE}Generating ProVerif summary...${NC}"

cat > "results/proverif-summary.txt" << EOF
EDHOC PSK Variant 1 ProVerif Verification Summary
=================================================
Generated: $(date)

Model: $MODEL
ProVerif file: edhoc-psk-variant1.pv

Verification Results:
EOF

# Check results and add to summary
if grep -q "RESULT.*true" "results/proverif-results.txt" 2>/dev/null; then
    echo "✓ ProVerif basic verification: Properties verified" >> "results/proverif-summary.txt"
elif grep -q "RESULT.*false" "results/proverif-results.txt" 2>/dev/null; then
    echo "✗ ProVerif basic verification: Some properties failed" >> "results/proverif-summary.txt"
else
    echo "? ProVerif basic verification: Unclear result" >> "results/proverif-summary.txt"
fi

# Count successful and failed queries
SUCCESS_COUNT=$(grep -c "RESULT.*true" "results/proverif-results.txt" 2>/dev/null || echo "0")
FAILURE_COUNT=$(grep -c "RESULT.*false" "results/proverif-results.txt" 2>/dev/null || echo "0")

echo "" >> "results/proverif-summary.txt"
echo "Query Results:" >> "results/proverif-summary.txt"
echo "- Successful queries: $SUCCESS_COUNT" >> "results/proverif-summary.txt"
echo "- Failed queries: $FAILURE_COUNT" >> "results/proverif-summary.txt"

if [ -f "results/proverif-detailed.html" ]; then
    echo "- Detailed HTML report: results/proverif-detailed.html" >> "results/proverif-summary.txt"
fi

echo "" >> "results/proverif-summary.txt"
echo "Detailed results available in results/ directory" >> "results/proverif-summary.txt"

# Display summary
echo -e "${BLUE}"
cat "results/proverif-summary.txt"
echo -e "${NC}"

# Show some key results
if [ -f "results/proverif-results.txt" ]; then
    echo -e "${YELLOW}Key ProVerif Results:${NC}"
    grep "RESULT" "results/proverif-results.txt" | head -10
fi

echo -e "${GREEN}ProVerif verification completed. Check results/ directory for detailed output.${NC}"
