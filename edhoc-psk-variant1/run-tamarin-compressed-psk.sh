#!/bin/bash

# Tamarin verification script for EDHOC PSK Variant 1
# Based on the compressed verification approach from lake-draft14

# Number of different commands that will be executed in parallel
# Each tamarin command uses 4 cores by default
# Set N based on available cores: N * 4 should be <= total cores
N=8

# Timeout for each command  
TIMEOUT='12h'

# Methods to use for verification
methods=(
    "tamarin-prover"
)

# PSK-specific verification commands
# Each line: "file lemma flags"
cmds=(
    "edhoc-psk-variant1.spthy --lemma=secretPSK -D=LeakPSK"
    "edhoc-psk-variant1.spthy --lemma=secretShares -D=LeakShare" 
    "edhoc-psk-variant1.spthy --lemma=secretR_PSK -D=LeakSessionKey"
    "edhoc-psk-variant1.spthy --lemma=secretI_PSK -D=LeakSessionKey"
    "edhoc-psk-variant1.spthy --lemma=forwardSecrecy_PSK -D=LeakSessionKey -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=honestauthRI_PSK_non_inj -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=honestauthIR_PSK_non_inj -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=sessionKeyAgreement_PSK"
    "edhoc-psk-variant1.spthy --lemma=data_authentication_I_to_R_PSK -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=data_authentication_R_to_I_PSK -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=psk_identity_privacy_variant1"
    "edhoc-psk-variant1.spthy --lemma=no_reflection_attacks_RI_PSK -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=no_reflection_attacks_IR_PSK -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=secretR_PRK_2e_PSK -D=LeakSessionKey -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=secretR_ks2_PSK -D=LeakSessionKey -D=LeakShare"
    "edhoc-psk-variant1.spthy --lemma=secretR_k3_PSK -D=LeakSessionKey -D=LeakShare"
)

IFS='' # required to keep tabs and spaces

# Function to execute a single verification command
exec_runner(){
    START=$(date +%s)
    filename=$(echo "$cmd $method" | sed "s/[^[:alnum:]-]//g")
    echo "START: timeout $TIMEOUT $method $cmd --prove +RTS -N4 -RTS"
    res=$(eval "timeout $TIMEOUT $method $cmd --prove +RTS -N4 -RTS")
    END=$(date +%s)
    DIFF=$(echo "$END - $START" | bc)
    res2=$(echo -n "$res" | grep "verified\|falsified" | tr '\n' ' ') 
    echo "$filename; $method; $res2; $DIFF;" >> "$outfilename"
    echo "$method $cmd : END"
}

# Output file
outfilename="csv-results/res-tam-compressed-psk.csv"

# Create output directory if it doesn't exist
mkdir -p csv-results

# Print headers
echo "filename; method; result; time;" > "$outfilename"

echo "Starting EDHOC PSK Variant 1 verification with Tamarin..."
echo "Results will be saved to: $outfilename"
echo "Number of parallel jobs: $N"
echo "Timeout per job: $TIMEOUT"
echo ""

# Execute verification commands
for method in "${methods[@]}"; do
    for cmd in "${cmds[@]}"; do
        ((i=i%N)); ((i++==0)) && wait	
        exec_runner &
    done
done

echo "All verification jobs started."
echo "WARNING: Some verification processes may still be running in the background."
echo "Monitor progress with: tail -f $outfilename"
