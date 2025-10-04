# Usage Examples

This document provides real-world examples of using `zilium-super-compactor` for different scenarios.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Non-A/B Device Example](#non-ab-device-example)
- [A/B Device Example](#ab-device-example)
- [Advanced Scenarios](#advanced-scenarios)
- [Error Recovery](#error-recovery)
- [Tips and Tricks](#tips-and-tricks)

---

## Basic Usage

### Scenario: Rebuild Super Partition from Extracted Images

**Goal:** You have extracted individual partition images and want to rebuild super.img

**Steps:**

```bash
# 1. Extract original super.img
lpunpack super.img extracted_partitions/

# 2. Create config.json
cat > config.json << 'EOF'
{
    "metadata_size": 65536,
    "metadata_slots": 2,
    "super_partition_size": 9126805504,
    "block_size": 4096,
    "groups": [
        {
            "name": "main",
            "size": 9122611200
        }
    ],
    "partitions": [
        {
            "name": "system",
            "group": "main",
            "image": "extracted_partitions/system.img"
        },
        {
            "name": "vendor",
            "group": "main",
            "image": "extracted_partitions/vendor.img"
        },
        {
            "name": "product",
            "group": "main",
            "image": "extracted_partitions/product.img"
        }
    ]
}
EOF

# 3. Rebuild
./zilium-super-compactor config.json super_rebuilt.img

# 4. Flash
fastboot flash super super_rebuilt.img
```

---

## Non-A/B Device Example

### Real Device: Realme C11 2021 (RMX3231)

**Scenario:** Extract, modify system partition, rebuild super.img

**Device Info:**
- Non-A/B device
- ColorOS 11
- Super partition: 9126805504 bytes
- 2 metadata slots

**Complete Workflow:**

```bash
# Step 1: Create working directory
mkdir -p ~/realme_c11_rebuild/{partitions,output}
cd ~/realme_c11_rebuild

# Step 2: Extract original super.img
lpunpack ~/Downloads/super.img partitions/

# Expected output:
# Sparse image detected.
# .......... [1/10] system_a 
# .......... [2/10] system_b
# .......... [3/10] vendor_a
# ...

# Step 3: Check extracted partitions
ls -lh partitions/
# -rw-r--r-- 1 user user 1.2G Jan 10 10:00 system.img
# -rw-r--r-- 1 user user 512M Jan 10 10:05 vendor.img
# -rw-r--r-- 1 user user 256M Jan 10 10:07 product.img
# -rw-r--r-- 1 user user 128M Jan 10 10:08 odm.img

# Step 4: Modify system partition (example: add custom app)
mkdir -p mnt/system
sudo mount -o loop partitions/system.img mnt/system
sudo cp ~/MyApp.apk mnt/system/app/
sudo umount mnt/system

# Step 5: Get exact metadata from original super
lpdump super.img --json > metadata.json

# Step 6: Create config with correct values
cat > config.json << 'EOF'
{
    "metadata_size": 65536,
    "metadata_slots": 2,
    "super_partition_size": 9126805504,
    "block_size": 4096,
    "groups": [
        {
            "name": "main",
            "size": 9122611200
        }
    ],
    "partitions": [
        {
            "name": "system",
            "group": "main",
            "image": "partitions/system.img"
        },
        {
            "name": "vendor",
            "group": "main",
            "image": "partitions/vendor.img"
        },
        {
            "name": "product",
            "group": "main",
            "image": "partitions/product.img"
        },
        {
            "name": "odm",
            "group": "main",
            "image": "partitions/odm.img"
        }
    ]
}
EOF

# Step 7: Rebuild super partition
./zilium-super-compactor config.json output/super_rebuilt.img

# Expected output:
# ╔══════════════════════════════════════════════════╗
# ║           Zilium Super Compactor v1.0         ║
# ╚══════════════════════════════════════════════════╝
# 
# ℹ Reading configuration from: config.json
# ✓ Device Type: Non-A/B (2 metadata slots)
# ✓ Group: main
#   - system: 1258291200 bytes
#   - vendor: 536870912 bytes
#   - product: 268435456 bytes
#   - odm: 134217728 bytes
# ✓ Total group size: 2197815296 bytes
# 
# Building super partition...
# ✓ Super partition built successfully!
# Output: output/super_rebuilt.img

# Step 8: Flash to device
cd output
fastboot flash super super_rebuilt.img

# Step 9: Flash patched vbmeta (see VBMETA_COMPATIBILITY.md)
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
fastboot reboot
```

---

## A/B Device Example

### Real Device: OnePlus 9 Pro (OP9Pro)

**Scenario:** Rebuild super.img for A/B device with both slots

**Device Info:**
- A/B device (dual slots)
- OxygenOS 12
- Super partition: 8589934592 bytes
- 3 metadata slots

**Complete Workflow:**

```bash
# Step 1: Setup workspace
mkdir -p ~/oneplus9_rebuild/{partitions_a,partitions_b,output}
cd ~/oneplus9_rebuild

# Step 2: Extract both slots
lpunpack super.img partitions_a/ --slot=0
lpunpack super.img partitions_b/ --slot=1

# Step 3: Get metadata
lpdump super.img --json > metadata.json

# Step 4: Create A/B config
cat > config.json << 'EOF'
{
    "metadata_size": 65536,
    "metadata_slots": 3,
    "super_partition_size": 8589934592,
    "block_size": 4096,
    "groups": [
        {
            "name": "main_a",
            "size": 4290772992
        },
        {
            "name": "main_b",
            "size": 4290772992
        }
    ],
    "partitions": [
        {
            "name": "system_a",
            "group": "main_a",
            "image": "partitions_a/system_a.img"
        },
        {
            "name": "vendor_a",
            "group": "main_a",
            "image": "partitions_a/vendor_a.img"
        },
        {
            "name": "product_a",
            "group": "main_a",
            "image": "partitions_a/product_a.img"
        },
        {
            "name": "odm_a",
            "group": "main_a",
            "image": "partitions_a/odm_a.img"
        },
        {
            "name": "system_ext_a",
            "group": "main_a",
            "image": "partitions_a/system_ext_a.img"
        },
        {
            "name": "system_b",
            "group": "main_b",
            "image": "partitions_b/system_b.img"
        },
        {
            "name": "vendor_b",
            "group": "main_b",
            "image": "partitions_b/vendor_b.img"
        },
        {
            "name": "product_b",
            "group": "main_b",
            "image": "partitions_b/product_b.img"
        },
        {
            "name": "odm_b",
            "group": "main_b",
            "image": "partitions_b/odm_b.img"
        },
        {
            "name": "system_ext_b",
            "group": "main_b",
            "image": "partitions_b/system_ext_b.img"
        }
    ]
}
EOF

# Step 5: Rebuild
./zilium-super-compactor config.json output/super_rebuilt.img

# Expected output shows A/B detection:
# ✓ Device Type: A/B (3 metadata slots)
# ✓ Group: main_a (slot A)
#   - system_a: 1610612736 bytes
#   - vendor_a: 805306368 bytes
#   ...
# ✓ Group: main_b (slot B)
#   - system_b: 1610612736 bytes
#   - vendor_b: 805306368 bytes
#   ...

# Step 6: Flash (A/B devices flash to active slot)
fastboot flash super super_rebuilt.img
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
fastboot reboot
```

---

## Advanced Scenarios

### Scenario 1: Replace Single Partition

**Goal:** Only replace vendor partition, keep others intact

```bash
# Extract only vendor
lpunpack --partition=vendor super.img partitions/

# Get full metadata
lpdump super.img --json > metadata.json

# Modify config to only replace vendor
cat > config.json << 'EOF'
{
    "metadata_size": 65536,
    "metadata_slots": 2,
    "super_partition_size": 9126805504,
    "block_size": 4096,
    "groups": [
        {
            "name": "main",
            "size": 9122611200
        }
    ],
    "partitions": [
        {
            "name": "system",
            "group": "main",
            "image": "partitions/system.img"
        },
        {
            "name": "vendor",
            "group": "main",
            "image": "partitions/vendor_modified.img"  ← Custom vendor
        },
        {
            "name": "product",
            "group": "main",
            "image": "partitions/product.img"
        }
    ]
}
EOF

./zilium-super-compactor config.json super_custom_vendor.img
```

### Scenario 2: Add New Partition

**Goal:** Add custom partition to super.img

```bash
# Create custom partition image
truncate -s 100M custom_partition.img
mkfs.ext4 custom_partition.img
# ... populate with data ...

# Add to config
cat > config.json << 'EOF'
{
    "metadata_size": 65536,
    "metadata_slots": 2,
    "super_partition_size": 9126805504,
    "block_size": 4096,
    "groups": [
        {
            "name": "main",
            "size": 9122611200
        }
    ],
    "partitions": [
        {
            "name": "system",
            "group": "main",
            "image": "partitions/system.img"
        },
        {
            "name": "vendor",
            "group": "main",
            "image": "partitions/vendor.img"
        },
        {
            "name": "product",
            "group": "main",
            "image": "partitions/product.img"
        },
        {
            "name": "my_custom",
            "group": "main",
            "image": "custom_partition.img"  ← New partition
        }
    ]
}
EOF

./zilium-super-compactor config.json super_with_custom.img
```

### Scenario 3: Reduce Super Partition Size

**Goal:** Create smaller super.img for testing

```bash
# Calculate needed size
TOTAL_SIZE=$(du -sb partitions/*.img | awk '{sum+=$1} END {print sum}')
METADATA_OVERHEAD=262144  # 4 * 65536
NEEDED_SIZE=$((TOTAL_SIZE + METADATA_OVERHEAD))

# Round up to nearest 1MB
SUPER_SIZE=$(( (NEEDED_SIZE / 1048576 + 1) * 1048576 ))

cat > config.json << EOF
{
    "metadata_size": 65536,
    "metadata_slots": 2,
    "super_partition_size": ${SUPER_SIZE},
    "block_size": 4096,
    "groups": [
        {
            "name": "main",
            "size": $((SUPER_SIZE - METADATA_OVERHEAD))
        }
    ],
    "partitions": [
        ...
    ]
}
EOF
```

### Scenario 4: Port ROM Between Devices

**Goal:** Port custom ROM from one device to another

```bash
# Extract donor ROM's super.img
lpunpack donor_super.img donor_partitions/

# Get target device's metadata
lpdump target_super.img --json > target_metadata.json

# Create config using target device's sizes
cat > port_config.json << 'EOF'
{
    "metadata_size": 65536,
    "metadata_slots": 2,
    "super_partition_size": 9126805504,  ← Target device size
    "block_size": 4096,
    "groups": [
        {
            "name": "main",
            "size": 9122611200  ← Target device group size
        }
    ],
    "partitions": [
        {
            "name": "system",
            "group": "main",
            "image": "donor_partitions/system.img"  ← Donor ROM
        },
        {
            "name": "vendor",
            "group": "main",
            "image": "target_partitions/vendor.img"  ← Target vendor
        },
        {
            "name": "product",
            "group": "main",
            "image": "donor_partitions/product.img"  ← Donor ROM
        }
    ]
}
EOF

./zilium-super-compactor port_config.json ported_super.img
```

---

## Error Recovery

### Problem: "Partition images are too large"

**Error Message:**
```
❌ Error: Not enough space in group "main"
   Used: 9200000000 bytes
   Available: 9122611200 bytes
```

**Solution:**

```bash
# Option 1: Reduce partition sizes
for img in partitions/*.img; do
    e2fsck -f $img
    resize2fs -M $img  # Minimize
done

# Option 2: Remove unnecessary partitions
# Edit config.json and comment out optional partitions:
# - odm (can be empty)
# - product (can use system/product instead)

# Option 3: Increase group size (if super partition allows)
# Check actual super partition size:
lpdump original_super.img | grep "Size:"
```

### Problem: "Image file not found"

**Error Message:**
```
❌ Error: Failed to access partition image: partitions/system.img
```

**Solution:**

```bash
# Verify all paths are correct
for partition in $(jq -r '.partitions[].image' config.json); do
    if [ ! -f "$partition" ]; then
        echo "Missing: $partition"
    fi
done

# Use absolute paths if needed
sed -i 's|"partitions/|"/home/user/rebuild/partitions/|g' config.json
```

### Problem: Device Won't Boot After Flash

**Symptoms:** Stuck at bootloader or boot logo

**Recovery Steps:**

```bash
# 1. Flash original super.img back
fastboot flash super original_super.img

# 2. Clear userdata (if you have backup!)
fastboot erase userdata
fastboot erase metadata

# 3. Reboot to recovery
fastboot reboot recovery

# 4. Factory reset from recovery menu

# 5. Try rebuilding with verbose logging
./zilium-super-compactor -v config.json super_rebuilt.img
```

### Problem: Verification Failed

**Error in fastboot:**
```
FAILED (remote: 'Partition verification failed')
```

**Solution:**

```bash
# 1. Disable vbmeta verification
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img

# 2. Or use empty vbmeta
dd if=/dev/zero of=vbmeta_disabled.img bs=4096 count=1
fastboot flash vbmeta vbmeta_disabled.img

# 3. Then flash super
fastboot flash super super_rebuilt.img

# 4. Flash to all vbmeta partitions (some devices)
for part in vbmeta vbmeta_a vbmeta_b vbmeta_system; do
    fastboot flash $part vbmeta_disabled.img 2>/dev/null || true
done
```

---

## Tips and Tricks

### Tip 1: Quick Metadata Extraction

```bash
# One-liner to get metadata values
echo "Metadata Size: $(lpdump super.img | grep 'Metadata max size' | awk '{print $4}')"
echo "Metadata Slots: $(lpdump super.img | grep 'Metadata slot count' | awk '{print $4}')"
echo "Super Size: $(lpdump super.img | grep 'Size:' | head -1 | awk '{print $2}')"
echo "Block Size: $(lpdump super.img | grep 'Alignment:' | awk '{print $2}')"
```

### Tip 2: Validate Config Before Building

```bash
# Check JSON syntax
jq empty config.json && echo "✓ Valid JSON" || echo "✗ Invalid JSON"

# Verify all images exist
jq -r '.partitions[].image' config.json | while read img; do
    [ -f "$img" ] && echo "✓ $img" || echo "✗ Missing: $img"
done

# Calculate total size
jq -r '.partitions[].image' config.json | xargs du -cb | tail -1
```

### Tip 3: Compare Metadata

```bash
# Dump both original and rebuilt
lpdump original_super.img > original_metadata.txt
lpdump rebuilt_super.img > rebuilt_metadata.txt

# Compare (ignore timestamps)
diff -u original_metadata.txt rebuilt_metadata.txt | grep -v "Created:"
```

### Tip 4: Batch Processing

```bash
# Process multiple configs
for config in configs/*.json; do
    output="output/$(basename $config .json).img"
    echo "Building: $config → $output"
    ./zilium-super-compactor "$config" "$output"
done
```

### Tip 5: Automated Testing

```bash
#!/bin/bash
# Test script

echo "Building super.img..."
./zilium-super-compactor config.json test_super.img || exit 1

echo "Validating output..."
lpdump test_super.img > /dev/null || exit 1

echo "Checking partition count..."
EXPECTED=4
ACTUAL=$(lpdump test_super.img | grep "Name:" | wc -l)
if [ $ACTUAL -eq $EXPECTED ]; then
    echo "✓ Test passed: $ACTUAL partitions"
else
    echo "✗ Test failed: expected $EXPECTED, got $ACTUAL"
    exit 1
fi

echo "✓ All tests passed!"
```

---

## Quick Reference

### Essential Commands

```bash
# Extract super.img
lpunpack super.img output_dir/

# Dump metadata (human-readable)
lpdump super.img

# Dump metadata (JSON)
lpdump super.img --json > metadata.json

# Rebuild super.img
./zilium-super-compactor config.json output.img

# Flash super partition
fastboot flash super output.img

# Flash with disabled verification
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
```

### Config Template (Non-A/B)

```json
{
    "metadata_size": 65536,
    "metadata_slots": 2,
    "super_partition_size": YOUR_SIZE_HERE,
    "block_size": 4096,
    "groups": [
        {"name": "main", "size": GROUP_SIZE_HERE}
    ],
    "partitions": [
        {"name": "system", "group": "main", "image": "path/to/system.img"},
        {"name": "vendor", "group": "main", "image": "path/to/vendor.img"}
    ]
}
```

### Config Template (A/B)

```json
{
    "metadata_size": 65536,
    "metadata_slots": 3,
    "super_partition_size": YOUR_SIZE_HERE,
    "block_size": 4096,
    "groups": [
        {"name": "main_a", "size": GROUP_SIZE_HERE},
        {"name": "main_b", "size": GROUP_SIZE_HERE}
    ],
    "partitions": [
        {"name": "system_a", "group": "main_a", "image": "path/to/system_a.img"},
        {"name": "vendor_a", "group": "main_a", "image": "path/to/vendor_a.img"},
        {"name": "system_b", "group": "main_b", "image": "path/to/system_b.img"},
        {"name": "vendor_b", "group": "main_b", "image": "path/to/vendor_b.img"}
    ]
}
```

---

## Need More Help?

- Check [README.md](README.md) for basic setup
- See [VBMETA_COMPATIBILITY.md](VBMETA_COMPATIBILITY.md) for boot issues
- Open an issue on GitHub with your specific scenario
