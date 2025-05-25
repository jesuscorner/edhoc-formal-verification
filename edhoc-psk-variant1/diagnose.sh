#!/bin/bash

# EDHOC PSK Variant 1 Verification Analysis Script
# Diagnoses why verification is stalling

echo "=== EDHOC PSK Variant 1 Verification Diagnosis ==="
echo ""

cd /opt/lake-edhoc/edhoc-psk-variant1

echo "1. Model Structure Analysis:"
echo "- Main file lines: $(wc -l < edhoc-psk-variant1.spthy)"
echo "- Properties file lines: $(wc -l < LakePropertiesPSK.splib)"
echo ""

echo "2. Checking lemma count:"
grep -c "lemma " LakePropertiesPSK.splib
echo ""

echo "3. Model complexity indicators:"
echo "- Process definitions: $(grep -c "let.*=" edhoc-psk-variant1.spthy)"
echo "- New variable generations: $(grep -c "new ~" edhoc-psk-variant1.spthy)"
echo "- Events: $(grep -c "event " edhoc-psk-variant1.spthy)"
echo "- Parallel processes: $(grep -c "|" edhoc-psk-variant1.spthy)"
echo ""

echo "4. Testing simplified verification approaches:"

# Test 1: Try to verify just one simple lemma with timeout
echo "Test 1: Attempting secretPSK verification with tight constraints..."
timeout 30 tamarin-prover edhoc-psk-variant1.spthy --lemma=secretPSK --heuristic=S --bound=3 2>&1 | head -n 20

echo ""
echo "Test 2: Checking if model can at least start proof search..."
timeout 10 tamarin-prover edhoc-psk-variant1.spthy --lemma=secretPSK --heuristic=C --bound=2 2>&1 | head -n 10

echo ""
echo "5. Recommendations based on analysis:"
echo ""
echo "IDENTIFIED ISSUES:"
echo "- Model runs multiple concurrent PSK setups creating exponential state space"
echo "- Complex cryptographic operations with extensive key derivation chains"  
echo "- Rich event structure tracking many protocol details"
echo "- Universal quantification over many variables in lemmas"
echo ""
echo "RECOMMENDED SOLUTIONS:"
echo "1. IMMEDIATE: Reduce to single PSK setup instance"
echo "2. MEDIUM: Simplify cryptographic operations to abstract functions"
echo "3. LONG-term: Split complex lemmas into smaller, targeted properties"
echo "4. Use more aggressive bounds (--bound=2 or --bound=3)"
echo "5. Try different heuristics: --heuristic=o, --heuristic=S, --heuristic=C"
echo ""
