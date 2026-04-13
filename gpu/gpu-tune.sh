#!/bin/bash

# ==========================================
# RTX 3080 Ti Tuning Script for Ubuntu 24.04
# ==========================================

# --- Configuration ---
GPU_INDEX=0                     # nvidia-smi and nvidia-settings index
POWER_LIMIT_W=260               # Target power limit in watts
DEFAULT_POWER_W=350             # Default power limit for 3080 Ti
CORE_MIN_MHZ=210                # Minimum idle core clock
CORE_MAX_MHZ=1200               # Maximum load core clock
MEM_OFFSET=-1000                # GDDR6X Memory offset 

# --- X11 Environment Variables ---
X_DISPLAY=":1"
X_AUTH="/run/user/1000/gdm/Xauthority"

# ==========================================

apply_clocks() {
    echo -e "\nApplying safe limits for local LLM inference..."
    sudo nvidia-smi -i $GPU_INDEX -pl $POWER_LIMIT_W
    sudo nvidia-smi -i $GPU_INDEX -lgc $CORE_MIN_MHZ,$CORE_MAX_MHZ
    sudo env DISPLAY=$X_DISPLAY XAUTHORITY=$X_AUTH \
        nvidia-settings -a "[gpu:$GPU_INDEX]/GPUMemoryTransferRateOffsetAllPerformanceLevels=$MEM_OFFSET" > /dev/null
    echo "✅ Tuning applied successfully!"
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
    echo "  2) Reset to Factory Defaults"
    echo "  3) Check Current GPU Status"
    echo "  4) Exit"
    echo "=========================================="
    read -p "Select an option [1-4]: " choice

    case $choice in
        1) apply_clocks ;;
        2) reset_clocks ;;
        3) show_status ;;
        4) echo "Exiting..."; exit 0 ;;
        *) echo -e "\n❌ Invalid option. Please enter a number from 1 to 4." ;;
    esac
done