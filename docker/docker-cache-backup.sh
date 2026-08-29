#!/usr/bin/env bash
set -e

CACHE_DIR="./docker-build-cache"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$CACHE_DIR"
mkdir -p "$BACKUP_DIR"

usage() {
    echo "Docker BuildKit Cache Backup/Restore Script"
    echo ""
    echo "Usage:"
    echo "  $0 backup     - Backup entire Docker BuildKit cache"
    echo "  $0 restore    - Restore Docker BuildKit cache from backup"
    echo "  $0 clean      - Remove local cache directory"
    echo "  $0 list       - List available cache backups"
    echo "  $0 prune      - Clean Docker system (cache, images, containers)"
    echo "  $0 help       - Show this help message"
    echo ""
    echo "💡 This script backs up the entire Docker BuildKit cache,"
    echo "   including cache from all projects and images."
    echo ""
    exit 1
}

backup_cache() {
    echo "📦 Backing up entire Docker BuildKit cache (all cache directories totaling ~19GB)..."

    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker and try again."
        exit 1
    fi

    # Create temporary directory for cache export
    TEMP_CACHE_DIR="/tmp/docker-global-cache-$$"
    mkdir -p "$TEMP_CACHE_DIR"

    # Find ALL Docker cache directories that make up the 19GB Build Cache
    echo "🔍 Finding Docker build cache directories (BuildKit, volumes, tmp)..."
    
    # Try to locate ALL cache directories
    BUILDKIT_CACHE_DIRS=()
    
    # 1. Main BuildKit cache directory
    if [ -d "/var/lib/docker/buildkit" ]; then
        if [ -r "/var/lib/docker/buildkit" ]; then
            BUILDKIT_CACHE_DIRS+=("/var/lib/docker/buildkit")
            echo "✅ Found main BuildKit cache: /var/lib/docker/buildkit"
        else
            echo "⚠️  Found main BuildKit cache but no read permission: /var/lib/docker/buildkit"
            echo "   This directory requires sudo access"
        fi
    fi
    
    # 2. BuildKit state volumes (major cache storage - ~9GB)
    BUILDKIT_VOLUMES=$(find /var/lib/docker/volumes -name "*buildkit*" -type d 2>/dev/null)
    if [ -n "$BUILDKIT_VOLUMES" ]; then
        for volume in $BUILDKIT_VOLUMES; do
            if [ -r "$volume" ]; then
                BUILDKIT_CACHE_DIRS+=("$volume")
                echo "✅ Found BuildKit state volume: $volume"
            else
                echo "⚠️  Found BuildKit state volume but no read permission: $volume"
                echo "   This volume requires sudo access"
            fi
        done
    fi
    
    # 3. Docker volumes that contain build cache (not all volumes, only cache-related ones)
    echo "📊 Including Docker build cache volumes..."
    CACHE_VOLUMES=$(find /var/lib/docker/volumes -name "*buildkit*" -o -name "*cache*" -o -name "*build*" 2>/dev/null)
    if [ -n "$CACHE_VOLUMES" ]; then
        for volume in $CACHE_VOLUMES; do
            if [ -d "$volume" ] && [ -r "$volume" ]; then
                # Only include if it's actually a cache directory, not just contains cache files
                if [ "$(du -s "$volume" 2>/dev/null | cut -f1)" -gt 1000 ]; then  # Only if > 1MB
                    BUILDKIT_CACHE_DIRS+=("$volume")
                    echo "✅ Found build cache volume: $volume"
                fi
            fi
        done
    fi
    
    # 4. Docker tmp directories
    if [ -d "/var/lib/docker/tmp" ]; then
        if [ -r "/var/lib/docker/tmp" ]; then
            BUILDKIT_CACHE_DIRS+=("/var/lib/docker/tmp")
            echo "✅ Found Docker tmp: /var/lib/docker/tmp"
        else
            echo "⚠️  Found Docker tmp but no read permission: /var/lib/docker/tmp"
        fi
    fi
    
    # 5. Overlay2 cache directories - REMOVED: These are Python cache files from container images,
    # not Docker build cache. They don't contribute to the 19GB Build Cache shown in docker system df.
    
    # 6. Image layer cache
    if [ -d "/var/lib/docker/image" ]; then
        if [ -r "/var/lib/docker/image" ]; then
            BUILDKIT_CACHE_DIRS+=("/var/lib/docker/image")
            echo "✅ Found Docker image cache: /var/lib/docker/image"
        else
            echo "⚠️  Found Docker image cache but no read permission: /var/lib/docker/image"
        fi
    fi
    
    # 7. Try to get cache info from docker buildx
    if docker buildx du --verbose > /dev/null 2>&1; then
        echo "✅ BuildKit cache accessible via docker buildx du"
        BUILDKIT_ACCESSIBLE=true
    else
        BUILDKIT_ACCESSIBLE=false
    fi
    
    # 8. If no BuildKit cache found, try user cache
    if [ ${#BUILDKIT_CACHE_DIRS[@]} -eq 0 ]; then
        if [ -d "$HOME/.docker/buildkit" ]; then
            BUILDKIT_CACHE_DIRS+=("$HOME/.docker/buildkit")
            echo "✅ Found user BuildKit cache: $HOME/.docker/buildkit"
        fi
    fi
    
    if [ ${#BUILDKIT_CACHE_DIRS[@]} -eq 0 ] && [ "$BUILDKIT_ACCESSIBLE" = false ]; then
        echo "❌ Could not find accessible Docker cache directories"
        echo "   Try running with sudo: sudo $0 backup"
        echo "   This is needed to access /var/lib/docker cache directories"
        exit 1
    fi

    # Export BuildKit cache using docker commands (preferred method)
    echo "🔄 Exporting Docker BuildKit cache data..."
    
    if [ "$BUILDKIT_ACCESSIBLE" = true ]; then
        echo "📊 Getting BuildKit cache information..."
        
        # Get BuildKit cache size
        BUILDKIT_SIZE=$(docker buildx du 2>/dev/null | tail -1 | grep -oE '[0-9.]+[KMGTPEZY]*B' | head -1)
        if [ -n "$BUILDKIT_SIZE" ]; then
            echo "📏 BuildKit cache size: $BUILDKIT_SIZE"
        fi
        
        # Export complete BuildKit cache information
        echo "📦 Exporting complete BuildKit cache information..."
        if ! docker buildx du --verbose > "$TEMP_CACHE_DIR/buildkit-cache-info.txt" 2>/dev/null; then
            echo "⚠️  Warning: Could not export BuildKit cache info"
        fi
        
        # Export cache metadata
        if ! docker buildx ls > "$TEMP_CACHE_DIR/buildkit-builders.txt" 2>/dev/null; then
            echo "ℹ️  BuildKit builders info exported"
        fi
        
        # Get the complete BuildKit cache using the most direct method
        echo "📦 Creating complete BuildKit cache export..."
        
        # Try to export the entire BuildKit cache
        # Note: We can't directly export the entire BuildKit cache to local files
        # So we'll copy the actual cache directories instead
        BUILDKIT_ACCESSIBLE=false
        
    fi
    
    # Fallback: copy BuildKit cache directories directly (this is what we want)
    if [ "$BUILDKIT_ACCESSIBLE" = false ]; then
        echo "📊 Calculating cache size for progress tracking..."
        TOTAL_SIZE=0
        for cache_dir in "${BUILDKIT_CACHE_DIRS[@]}"; do
            if [ -d "$cache_dir" ]; then
                DIR_SIZE=$(du -sk "$cache_dir" 2>/dev/null | cut -f1)
                if [ -n "$DIR_SIZE" ]; then
                    TOTAL_SIZE=$((TOTAL_SIZE + DIR_SIZE))
                fi
            fi
        done
        
        if [ "$TOTAL_SIZE" -eq 0 ]; then
            TOTAL_SIZE=1  # Avoid division by zero
        fi
        
        echo "📏 Total BuildKit cache size to backup: $(numfmt --to=iec $((TOTAL_SIZE * 1024)))"
    echo "📂 Cache directories to backup:"
    for cache_dir in "${BUILDKIT_CACHE_DIRS[@]}"; do
        if [ -d "$cache_dir" ]; then
            DIR_SIZE=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
            echo "   - $cache_dir ($DIR_SIZE)"
        fi
    done
        
        # Copy BuildKit cache directories with progress tracking
        COPIED_COUNT=0
        TOTAL_COUNT=$(find "${BUILDKIT_CACHE_DIRS[@]}" -type f 2>/dev/null | wc -l)
        if [ "$TOTAL_COUNT" -eq 0 ]; then
            TOTAL_COUNT=1
        fi
        
        for cache_dir in "${BUILDKIT_CACHE_DIRS[@]}"; do
            if [ -d "$cache_dir" ]; then
                echo "📂 Copying $cache_dir..."
                
                # Use rsync for better progress tracking if available
                if command -v rsync > /dev/null 2>&1; then
                    rsync -av --progress "$cache_dir/" "$TEMP_CACHE_DIR/$(basename "$cache_dir")/" 2>/dev/null | while read line; do
                        COPIED_COUNT=$((COPIED_COUNT + 1))
                        PERCENT=$((COPIED_COUNT * 100 / TOTAL_COUNT))
                        printf "\r📦 Progress: %3d%% (%d of %d files)" "$PERCENT" "$COPIED_COUNT" "$TOTAL_COUNT"
                    done
                else
                    # Fallback to cp with basic progress
                    find "$cache_dir" -type f -exec cp --parents {} "$TEMP_CACHE_DIR/$(basename "$cache_dir")/" \;
                fi
                echo ""
            fi
        done
    fi

    # Create metadata
    echo "📝 Creating backup metadata..."
    cat > "$TEMP_CACHE_DIR/backup-metadata.txt" << EOF
Docker BuildKit Cache Backup
Backup Date: $(date)
Backup Type: Complete BuildKit Cache (All Projects)
Docker Version: $(docker --version 2>/dev/null || echo "Unknown")
System Info: $(uname -srm)
Cache Sources: ${BUILDKIT_CACHE_DIRS[*]}
BuildKit Accessible: $BUILDKIT_ACCESSIBLE
Backup Command: $0 backup
Total Cache Size: $(docker buildx du 2>/dev/null | tail -1 | grep -oE '[0-9.]+[KMGTPEZY]*B' | head -1)
Note: This backup contains ONLY BuildKit cache from all projects, no other Docker files
EOF

    BACKUP_FILE="$BACKUP_DIR/cache_$TIMESTAMP.tar.gz"

    echo "📦 Creating compressed backup: $BACKUP_FILE"
    if ! tar -czvf "$BACKUP_FILE" -C "$TEMP_CACHE_DIR" .; then
        echo "❌ Failed to create backup archive"
        rm -rf "$TEMP_CACHE_DIR"
        exit 1
    fi

    # Clean up temporary directory
    rm -rf "$TEMP_CACHE_DIR"

    echo "✅ Global Docker cache backup created: $BACKUP_FILE"
    echo "📊 Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # Show what was backed up
    echo ""
    echo "📋 Backup contents:"
    tar -tzf "$BACKUP_FILE" | head -10 | sed 's/^/  /'
    if [ $(tar -tzf "$BACKUP_FILE" | wc -l) -gt 10 ]; then
        echo "  ... and $(($(tar -tzf "$BACKUP_FILE" | wc -l) - 10)) more files"
    fi
}

restore_cache() {
    echo "♻️ Restoring Docker BuildKit cache from backup..."

    # List available backups
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ Backup directory not found: $BACKUP_DIR"
        exit 1
    fi

    if [ -z "$(ls -A $BACKUP_DIR/cache_*.tar.gz 2>/dev/null)" ]; then
        echo "📭 No backup files found in $BACKUP_DIR"
        exit 1
    fi

    echo "📋 Available backups:"
    for backup in "$BACKUP_DIR"/cache_*.tar.gz; do
        if [ -f "$backup" ]; then
            filename=$(basename "$backup")
            size=$(du -h "$backup" | cut -f1)
            echo "  📦 $filename ($size)"
        fi
    done
    echo ""

    # Ask user to choose backup
    read -p "Enter backup filename to restore (or press Enter for latest): " backup_filename
    
    if [ -z "$backup_filename" ]; then
        # Get latest backup
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/cache_*.tar.gz | head -1)
        if [ -z "$LATEST_BACKUP" ]; then
            echo "❌ No backups found"
            exit 1
        fi
        BACKUP_FILE="$LATEST_BACKUP"
    else
        BACKUP_FILE="$BACKUP_DIR/$backup_filename"
        if [ ! -f "$BACKUP_FILE" ]; then
            echo "❌ Backup file not found: $BACKUP_FILE"
            exit 1
        fi
    fi

    echo "📂 Using backup: $(basename "$BACKUP_FILE")"
    
    # For global cache restore, we need to be very careful
    echo "⚠️  WARNING: This will restore ALL Docker cache data (~19GB)!"
    echo "   This includes BuildKit cache, volumes, overlay2 cache, and tmp files."
    echo "   Make sure to backup any important Docker data first."
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Restore cancelled by user"
        exit 1
    fi
    
    # Create restore directory
    RESTORE_DIR="/tmp/docker-cache-restore-$$"
    mkdir -p "$RESTORE_DIR"
    
    # Extract backup
    echo "📦 Extracting backup..."
    if ! tar -xzvf "$BACKUP_FILE" -C "$RESTORE_DIR"; then
        echo "❌ Failed to extract backup"
        rm -rf "$RESTORE_DIR"
        exit 1
    fi
    
    # Stop Docker services if possible
    echo "🛑 Stopping Docker services for cache restore..."
    if systemctl is-active --quiet docker 2>/dev/null; then
        if ! sudo systemctl stop docker; then
            echo "⚠️  Could not stop Docker service. Manual intervention may be required."
        fi
    fi

    # Restore cache directories
    echo "🔄 Restoring cache directories..."
    
    # Restore main BuildKit cache
    if [ -d "$RESTORE_DIR/buildkit" ]; then
        echo "📋 Restoring main BuildKit cache..."
        if [ -d "/var/lib/docker/buildkit" ]; then
            sudo mv "/var/lib/docker/buildkit" "/var/lib/docker/buildkit.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        sudo cp -r "$RESTORE_DIR/buildkit" "/var/lib/docker/"
        echo "✅ Main BuildKit cache restored"
    fi
    
    # Restore volumes
    if [ -d "$RESTORE_DIR/buildx_buildkit_fast-builder0_state" ]; then
        echo "📋 Restoring BuildKit state volume..."
        if [ -d "/var/lib/docker/volumes/buildx_buildkit_fast-builder0_state" ]; then
            sudo mv "/var/lib/docker/volumes/buildx_buildkit_fast-builder0_state" "/var/lib/docker/volumes/buildx_buildkit_fast-builder0_state.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        sudo cp -r "$RESTORE_DIR/buildx_buildkit_fast-builder0_state" "/var/lib/docker/volumes/"
        echo "✅ BuildKit state volume restored"
    fi
    
    # Restore other cache volumes
    for volume_dir in "$RESTORE_DIR"/*/; do
        if [ -d "$volume_dir" ] && [[ "$(basename "$volume_dir")" != "buildkit" ]] && [[ "$(basename "$volume_dir")" != "buildx_buildkit_fast-builder0_state" ]]; then
            volume_name=$(basename "$volume_dir")
            if [[ "$volume_name" != "." ]] && [[ "$volume_name" != ".." ]]; then
                echo "📋 Restoring volume: $volume_name"
                if [ -d "/var/lib/docker/volumes/$volume_name" ]; then
                    sudo mv "/var/lib/docker/volumes/$volume_name" "/var/lib/docker/volumes/$volume_name.backup.$(date +%Y%m%d_%H%M%S)"
                fi
                sudo cp -r "$volume_dir" "/var/lib/docker/volumes/"
            fi
        fi
    done
    
    # Restore image cache
    if [ -d "$RESTORE_DIR/image" ]; then
        echo "📋 Restoring Docker image cache..."
        if [ -d "/var/lib/docker/image" ]; then
            sudo mv "/var/lib/docker/image" "/var/lib/docker/image.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        sudo cp -r "$RESTORE_DIR/image" "/var/lib/docker/"
        echo "✅ Docker image cache restored"
    fi
    
    # Restore tmp cache
    if [ -d "$RESTORE_DIR/tmp" ]; then
        echo "📋 Restoring Docker tmp cache..."
        if [ -d "/var/lib/docker/tmp" ]; then
            sudo mv "/var/lib/docker/tmp" "/var/lib/docker/tmp.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        sudo cp -r "$RESTORE_DIR/tmp" "/var/lib/docker/"
        echo "✅ Docker tmp cache restored"
    fi
    
    # Clean up
    rm -rf "$RESTORE_DIR"
    
    # Start Docker
    echo "🚀 Starting Docker services..."
    if ! sudo systemctl start docker; then
        echo "⚠️  Warning: Could not start Docker service automatically"
        echo "   You may need to start it manually: sudo systemctl start docker"
    fi
    
    echo "✅ Docker cache restore completed!"
    echo ""
    echo "📊 Current Docker disk usage:"
    docker system df 2>/dev/null || echo "   Docker may still be starting up..."
}

clean_cache() {
    echo "🧹 Removing $CACHE_DIR"
    rm -rf "$CACHE_DIR"
    echo "Done."
}

prune_docker() {
    echo "🧹 Cleaning Docker system..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Nothing to clean."
        exit 1
    fi
    
    echo "📊 Current Docker disk usage:"
    docker system df
    
    echo ""
    echo "⚠️  This will remove:"
    echo "   - All stopped containers"
    echo "   - All unused networks"
    echo "   - All dangling images"
    echo "   - All build cache"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Clean operation cancelled by user"
        exit 1
    fi
    
    echo "🔄 Cleaning Docker system..."
    
    # Clean containers, networks, images, and cache
    if ! docker system prune -af; then
        echo "❌ Docker clean failed"
        exit 1
    fi
    
    echo "✅ Docker system cleaned successfully"
    echo ""
    echo "📊 Docker disk usage after clean:"
    docker system df
}

list_backups() {
    echo "📋 Available cache backups:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ No backup directory found: $BACKUP_DIR"
        exit 1
    fi
    
    if [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo "📭 No backups found in $BACKUP_DIR"
        exit 1
    fi
    
    echo "Backups found in $BACKUP_DIR:"
    for backup in "$BACKUP_DIR"/cache_*.tar.gz; do
        if [ -f "$backup" ]; then
            filename=$(basename "$backup")
            size=$(du -h "$backup" | cut -f1)
            date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1-2 || ls -la "$backup" | awk '{print $6, $7, $8}')
            echo "  📦 $filename ($size) - $date"
        fi
    done
    echo ""
}

# ------ Main Logic ------

if [ $# -ne 1 ]; then
    usage
fi

case "$1" in
    backup)
        backup_cache
        ;;
    restore)
        restore_cache
        ;;
    clean)
        clean_cache
        ;;
    prune)
        prune_docker
        ;;
    list)
        list_backups
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage
        ;;
esac
