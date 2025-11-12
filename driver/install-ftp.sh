#!/bin/bash

# NVIDIA Driver Installation Script via FTP
# This script reads FTP credentials and driver file path from .env file

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to load environment variables
load_env() {
    local env_file="../.env"
    
    if [ ! -f "$env_file" ]; then
        print_error "Environment file $env_file not found!"
        print_error "Please create $env_file with the following format:"
        print_error "FTP_USERNAME=your_username"
        print_error "FTP_PASSWORD=your_password"
        print_error "FTP_HOST=ftp_host_or_ip"
        print_error "DRIVER_FILE_PATH=path/to/driver/file"
        exit 1
    fi
    
    # Load environment variables
    source "$env_file"
    
    # Validate required variables
    if [ -z "$FTP_USERNAME" ] || [ -z "$FTP_PASSWORD" ] || [ -z "$FTP_HOST" ] || [ -z "$DRIVER_FILE_PATH" ]; then
        print_error "Missing required variables in $env_file!"
        print_error "Required variables: FTP_USERNAME, FTP_PASSWORD, FTP_HOST, DRIVER_FILE_PATH"
        exit 1
    fi
    
    print_success "Environment variables loaded successfully"
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root!"
        print_error "Please run: sudo $0"
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_warning "curl is not installed. Installing..."
        apt update
        apt install -y curl
    fi
    
    # Check if wget is installed
    if ! command -v wget &> /dev/null; then
        print_warning "wget is not installed. Installing..."
        apt update
        apt install -y wget
    fi
    
    # Check if basic build tools are installed
    if ! command -v make &> /dev/null || ! command -v gcc &> /dev/null; then
        print_warning "Build tools not found. Installing build-essential..."
        apt update
        apt install -y build-essential
    fi
    
    print_success "System requirements checked"
}

# Function to clean up previous installations
cleanup_previous() {
    print_status "Cleaning up previous installations..."
    
    # Remove any existing NVIDIA packages
    apt remove --purge -y "*nvidia*" "*cuda*" || true
    
    # Remove any existing driver files
    rm -f /tmp/nvidia*.run
    rm -f /tmp/nvidia*.deb
    
    # Clean up module dependencies
    depmod -a || true
    
    print_success "Cleanup completed"
}

# Function to download NVIDIA driver from FTP
download_driver() {
    print_status "Downloading NVIDIA driver from FTP..."
    
    local ftp_url="ftp://${FTP_USERNAME}:${FTP_PASSWORD}@${FTP_HOST}/${DRIVER_FILE_PATH}"
    local driver_name=$(basename "$DRIVER_FILE_PATH")
    local download_path="/tmp/${driver_name}"
    
    print_status "Downloading from: $ftp_url"
    print_status "Saving to: $download_path"
    
    # Try to download using curl first
    if curl -f -L "$ftp_url" -o "$download_path"; then
        print_success "Driver downloaded successfully"
    else
        print_error "Failed to download driver using curl"
        
        # Try alternative method with wget
        print_status "Trying alternative download method with wget..."
        if wget --user="$FTP_USERNAME" --password="$FTP_PASSWORD" -O "$download_path" "ftp://${FTP_HOST}/${DRIVER_FILE_PATH}"; then
            print_success "Driver downloaded successfully using wget"
        else
            print_error "Failed to download driver using wget as well"
            print_error "Please check your FTP credentials and network connection"
            exit 1
        fi
    fi
    
    # Verify the downloaded file
    if [ ! -f "$download_path" ]; then
        print_error "Downloaded file not found!"
        exit 1
    fi
    
    # Check if it's a valid driver file
    if [[ "$driver_name" =~ \.(run|deb|tgz|tar\.gz)$ ]]; then
        print_success "Driver file verified: $driver_name"
    else
        print_warning "Unrecognized driver file format: $driver_name"
        print_warning "Expected formats: .run, .deb, .tgz, .tar.gz"
    fi
}

# Function to stop X server
stop_x_server() {
    print_status "Stopping X server for driver installation..."
    
    # Check if we're running in a graphical environment
    if [ -n "$DISPLAY" ]; then
        print_warning "Detected running X server (DISPLAY=$DISPLAY)"
        print_status "Attempting to stop X server..."
        
        # Try to stop the display manager
        if systemctl is-active --quiet gdm; then
            systemctl stop gdm
            print_success "Stopped GDM display manager"
        elif systemctl is-active --quiet lightdm; then
            systemctl stop lightdm
            print_success "Stopped LightDM display manager"
        elif systemctl is-active --quiet sddm; then
            systemctl stop sddm
            print_success "Stopped SDDM display manager"
        elif systemctl is-active --quiet xdm; then
            systemctl stop xdm
            print_success "Stopped XDM display manager"
        else
            print_warning "No known display manager found via systemctl"
        fi
        
        # Try alternative methods
        if [ -n "$DISPLAY" ]; then
            print_status "Trying alternative X server stop methods..."
            
            # Try to kill Xorg process
            if pgrep -x "Xorg" > /dev/null; then
                pkill -x "Xorg" || true
                print_success "Killed Xorg process"
            fi
            
            # Try to use systemctl to stop graphical.target
            if systemctl is-active --quiet graphical.target; then
                systemctl isolate multi-user.target
                print_success "Switched to multi-user target"
            fi
        fi
    else
        print_status "No X server detected (DISPLAY not set)"
    fi
}

# Function to start X server after installation
start_x_server() {
    print_status "Starting X server after driver installation..."
    
    # Start the display manager
    if systemctl is-enabled --quiet gdm; then
        systemctl start gdm
        print_success "Started GDM display manager"
    elif systemctl is-enabled --quiet lightdm; then
        systemctl start lightdm
        print_success "Started LightDM display manager"
    elif systemctl is-enabled --quiet sddm; then
        systemctl start sddm
        print_success "Started SDDM display manager"
    elif systemctl is-enabled --quiet xdm; then
        systemctl start xdm
        print_success "Started XDM display manager"
    else
        print_warning "No display manager configured to start automatically"
        print_status "You may need to manually start your display manager"
    fi
}

# Function to install NVIDIA driver
install_driver() {
    print_status "Installing NVIDIA driver..."
    
    # Stop X server before installation
    stop_x_server
    
    local driver_name=$(basename "$DRIVER_FILE_PATH")
    local driver_path="/tmp/${driver_name}"
    
    case "$driver_name" in
        *.run)
            print_status "Installing .run driver package..."
            
            # Make the installer executable
            chmod +x "$driver_path"
            
            # Run the installer with recommended options
            "$driver_path" --silent --dkms --no-opengl-files
            
            if [ $? -eq 0 ]; then
                print_success "NVIDIA driver installed successfully"
            else
                print_error "Driver installation failed"
                exit 1
            fi
            ;;
        *.deb)
            print_status "Installing .deb driver package..."
            
            # Install dependencies
            apt install -y linux-headers-$(uname -r) build-essential dkms
            
            # Install the driver package
            dpkg -i "$driver_path"
            
            # Fix any dependency issues
            apt install -f -y
            
            if [ $? -eq 0 ]; then
                print_success "NVIDIA driver installed successfully"
            else
                print_error "Driver installation failed"
                exit 1
            fi
            ;;
        *.tgz|*.tar.gz)
            print_status "Installing .tgz/.tar.gz driver package..."
            
            # Extract the archive
            local extract_dir="/tmp/nvidia-driver"
            mkdir -p "$extract_dir"
            tar -xzf "$driver_path" -C "$extract_dir"
            
            # Find and run the installer
            local installer_script=$(find "$extract_dir" -name "*.run" -o -name "install" | head -1)
            if [ -f "$installer_script" ]; then
                chmod +x "$installer_script"
                "$installer_script" --silent --dkms --no-opengl-files
                
                if [ $? -eq 0 ]; then
                    print_success "NVIDIA driver installed successfully"
                else
                    print_error "Driver installation failed"
                    exit 1
                fi
            else
                print_error "No installer script found in the archive"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported driver file format: $driver_name"
            print_error "Supported formats: .run, .deb, .tgz, .tar.gz"
            exit 1
            ;;
    esac
}

# Function to verify installation
verify_installation() {
    print_status "Verifying NVIDIA driver installation..."
    
    # Check if nvidia-smi is available
    if command -v nvidia-smi &> /dev/null; then
        print_success "nvidia-smi is available"
        
        # Display GPU information
        print_status "GPU Information:"
        nvidia-smi
        
        # Check if NVIDIA module is loaded
        if lsmod | grep -q nvidia; then
            print_success "NVIDIA kernel module is loaded"
        else
            print_warning "NVIDIA kernel module not loaded"
            print_status "Attempting to load module..."
            modprobe nvidia || print_error "Failed to load NVIDIA module"
        fi
    else
        print_error "nvidia-smi not found - installation may have failed"
        exit 1
    fi
    
    # Check if X server is using NVIDIA driver (if running)
    if [ -n "$DISPLAY" ]; then
        print_status "Checking X server configuration..."
        if glxinfo | grep -q "OpenGL renderer"; then
            print_success "OpenGL renderer information:"
            glxinfo | grep "OpenGL renderer"
        else
            print_warning "Could not detect OpenGL renderer"
        fi
    fi
}

# Function to clean up temporary files
cleanup_temp() {
    print_status "Cleaning up temporary files..."
    
    # Remove downloaded driver file
    rm -f /tmp/nvidia*.run
    rm -f /tmp/nvidia*.deb
    rm -rf /tmp/nvidia-driver
    
    print_success "Cleanup completed"
}

# Main function
main() {
    echo "========================================"
    echo "NVIDIA Driver Installation Script"
    echo "========================================"
    
    # Load environment variables
    load_env
    
    # Check system requirements
    check_requirements
    
    # Clean up previous installations
    cleanup_previous
    
    # Download driver from FTP
    download_driver
    
    # Install driver
    install_driver
    
    # Start X server after installation (if it was running before)
    start_x_server
    
    # Verify installation
    verify_installation
    
    # Clean up temporary files
    cleanup_temp
    
    echo "========================================"
    print_success "NVIDIA driver installation completed successfully!"
    echo "========================================"
    
    # Display next steps
    echo ""
    echo "Next steps:"
    echo "1. Reboot your system to complete the installation"
    echo "2. Run 'nvidia-smi' to verify the driver is working"
    echo "3. Check 'dmesg | grep nvidia' for any kernel messages"
    echo "4. If X server was stopped, restart your display manager or reboot"
}

# Run main function
main "$@"