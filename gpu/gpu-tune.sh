#!/bin/bash

# ==========================================
# RTX 3080 Ti Tuning Script for Ubuntu 24.04
# ==========================================

# --- Configuration ---
GPU_INDEX=0                     # nvidia-smi and nvidia-settings index
DEFAULT_POWER_W=350             # Default power limit
CORE_MIN_MHZ=210                # Minimum idle core clock
MEM_OFFSET=-1000                # GDDR6X Memory offset 

# --- Inference Limits ---
INFERENCE_POWER_W=260
INFERENCE_CORE_MAX=1200

# --- Desktop / Eco Limits ---
ECO_POWER_W=120                 # Absolute minimum safe power floor
ECO_CORE_MAX=600                # Just enough to drive 4K 120Hz without UI stutter

# --- X11 Environment Variables ---
X_DISPLAY=":1"
X_AUTH="/run/user/1000/gdm/Xauthority"

# ==========================================

apply_inference() {
    echo -e "\nApplying limits for local LLM inference (260W / 1200MHz)..."
    sudo nvidia-smi -i $GPU_INDEX -pl $INFERENCE_POWER_W
    sudo nvidia-smi -i $GPU_INDEX -lgc $CORE_MIN_MHZ,$INFERENCE_CORE_MAX
    sudo env DISPLAY=$X_DISPLAY XAUTHORITY=$X_AUTH \
        nvidia-settings -a "[gpu:$GPU_INDEX]/GPUMemoryTransferRateOffsetAllPerformanceLevels=$MEM_OFFSET" > /dev/null
    echo "✅ Inference tuning applied successfully!"
}

apply_eco() {
    echo -e "\nEngaging Ultra-Low Power Desktop Mode (120W / 600MHz)..."
    sudo nvidia-smi -i $GPU_INDEX -pl $ECO_POWER_W
    sudo nvidia-smi -i $GPU_INDEX -lgc $CORE_MIN_MHZ,$ECO_CORE_MAX
    
    # We maintain the memory offset to ensure VRAM stays cool even while browsing
    sudo env DISPLAY=$X_DISPLAY XAUTHORITY=$X_AUTH \
        nvidia-settings -a "[gpu:$GPU_INDEX]/GPUMemoryTransferRateOffsetAllPerformanceLevels=$MEM_OFFSET" > /dev/null
    echo "🌱 Eco Mode applied. GPU choked for basic desktop use."
}

reset_clocks() {
    echo -e "\nReverting GPU to factory default behavior..."
    sudo nvidia-smi -i $GPU_INDEX -pl $DEFAULT_POWER_W
    sudo nvidia-smi -i $GPU_INDEX -rgc
    sudo env DISPLAY=$X_DISPLAY XAUTHORITY=$X_AUTH \
        nvidia-settings -a "[gpu:$GPU_INDEX]/GPUMemoryTransferRateOffsetAllPerformanceLevels=0" > /dev/null
    echo "🔄 Defaults restored."
}

show_status() {
    echo -e "\n--- Current Power Limit & Core Clock ---"
    nvidia-smi -i $GPU_INDEX -q -d CLOCK,POWER | grep -E "Power Limit|Graphics" | head -n 5
    echo -e "\n--- Current Memory Offset ---"
    DISPLAY=$X_DISPLAY XAUTHORITY=$X_AUTH nvidia-settings -q "[gpu:$GPU_INDEX]/GPUMemoryTransferRateOffset"
}

# --- Interactive Menu ---
while true; do
    echo -e "\n=========================================="
    echo "       RTX 3080 Ti Control Panel"
    echo "=========================================="
    echo "  1) Apply Inference Limits (260W / 1200MHz)"
    echo "  2) Apply Eco Desktop Mode (120W / 600MHz)"
    echo "  3) Reset to Factory Defaults"
    echo "  4) Check Current GPU Status"
    echo "  5) Exit"
    echo "=========================================="
    read -p "Select an option [1-5]: " choice

    case $choice in
        1) apply_inference ;;
        2) apply_eco ;;
        3) reset_clocks ;;
        4) show_status ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo -e "\n❌ Invalid option. Please enter a number from 1 to 5." ;;
    esac
done