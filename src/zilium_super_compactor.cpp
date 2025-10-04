#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <cstdlib>
#include <sstream>
#include <unistd.h>
#include <limits.h>
#include "../external/json/include/nlohmann/json.hpp" // You'll need nlohmann/json library

using json = nlohmann::json;
namespace fs = std::filesystem;

// Get the directory where the executable is located
std::string get_executable_dir() {
    char result[PATH_MAX];
    ssize_t count = readlink("/proc/self/exe", result, PATH_MAX);
    if (count != -1) {
        result[count] = '\0';
        fs::path exe_path(result);
        return exe_path.parent_path().string();
    }
    return "";
}

// Find lpmake binary - check bundled first, then system PATH
std::string find_lpmake() {
    // First, check in the same directory as zilium-super-compactor
    std::string exe_dir = get_executable_dir();
    if (!exe_dir.empty()) {
        fs::path bundled_lpmake = fs::path(exe_dir) / "lpmake";
        if (fs::exists(bundled_lpmake)) {
            return bundled_lpmake.string();
        }
    }
    
    // Fall back to system PATH
    return "lpmake";
}

struct Partition {
    std::string name;
    std::string path;
    uint64_t size;
    std::string group_name;
    bool is_dynamic;
};

struct Group {
    std::string name;
    uint64_t maximum_size;
};

struct BlockDevice {
    std::string name;
    uint64_t size;
    uint32_t block_size;
    uint32_t alignment;
};

struct SuperConfig {
    std::vector<Partition> partitions;
    std::vector<Group> groups;
    BlockDevice block_device;
    std::string metadata_path;
    std::string nv_id;
    std::string base_path;
    uint32_t metadata_size;
    uint32_t metadata_slots;
    std::string super_name;
    uint32_t alignment_offset;
    bool virtual_ab;
};

void print_banner() {
    std::cout << "\n";
    std::cout << "╔═══════════════════════════════════════════╗\n";
    std::cout << "║      Zilium Super Compactor v1.0.0       ║\n";
    std::cout << "║    Realme/OPPO/OnePlus A/B Compatible    ║\n";
    std::cout << "╚═══════════════════════════════════════════╝\n";
    std::cout << "\n";
}

std::vector<std::string> find_json_files(const std::string& meta_path) {
    std::vector<std::string> json_files;
    
    if (!fs::exists(meta_path)) {
        std::cerr << "ERROR: META folder not found at: " << meta_path << std::endl;
        return json_files;
    }
    
    for (const auto& entry : fs::directory_iterator(meta_path)) {
        if (entry.path().extension() == ".json") {
            json_files.push_back(entry.path().filename().string());
        }
    }
    
    return json_files;
}

std::string select_json_file(const std::vector<std::string>& json_files) {
    if (json_files.empty()) {
        std::cerr << "ERROR: No JSON files found in META folder!" << std::endl;
        return "";
    }
    
    if (json_files.size() == 1) {
        std::cout << "Found JSON file: " << json_files[0] << std::endl;
        return json_files[0];
    }
    
    std::cout << "Multiple JSON files found. Please select one:\n\n";
    for (size_t i = 0; i < json_files.size(); i++) {
        std::cout << "  [" << (i + 1) << "] " << json_files[i] << std::endl;
    }
    std::cout << "\nEnter your choice (1-" << json_files.size() << "): ";
    
    int choice;
    std::cin >> choice;
    
    if (choice < 1 || choice > static_cast<int>(json_files.size())) {
        std::cerr << "ERROR: Invalid choice!" << std::endl;
        return "";
    }
    
    return json_files[choice - 1];
}

bool parse_super_config(const std::string& json_path, const std::string& base_path, SuperConfig& config) {
    std::ifstream file(json_path);
    if (!file.is_open()) {
        std::cerr << "ERROR: Cannot open JSON file: " << json_path << std::endl;
        return false;
    }
    
    json j;
    try {
        file >> j;
    } catch (const std::exception& e) {
        std::cerr << "ERROR: Failed to parse JSON: " << e.what() << std::endl;
        return false;
    }
    
    config.base_path = base_path;
    
    // Parse nv_id
    if (j.contains("nv_id")) {
        config.nv_id = j["nv_id"].get<std::string>();
    }
    
    // Parse metadata configuration - CRITICAL for vbmeta compatibility
    config.metadata_size = 65536; // Default
    config.metadata_slots = 2; // Default for A/B
    config.super_name = "super"; // Default
    config.alignment_offset = 0; // Default
    config.virtual_ab = false; // Default
    
    // Detect slot configuration from groups
    // Non-A/B: has "main" group, metadata_slots = 2
    // A/B: has "main_a" and "main_b" groups, metadata_slots = 3
    bool is_ab_device = false;
    for (const auto& grp : j["groups"]) {
        std::string group_name = grp["name"].get<std::string>();
        if (group_name == "main_a" || group_name == "main_b") {
            is_ab_device = true;
            break;
        }
    }
    
    // Set metadata_slots based on device type
    if (is_ab_device) {
        config.metadata_slots = 3; // A/B devices use 3 slots (a, b, and one extra)
    } else {
        config.metadata_slots = 2; // Non-A/B devices use 2 slots
    }
    
    if (j.contains("lpmake")) {
        auto& lpmake = j["lpmake"];
        if (lpmake.contains("metadata_size")) {
            config.metadata_size = std::stoul(lpmake["metadata_size"].get<std::string>());
        }
        if (lpmake.contains("metadata_slots")) {
            config.metadata_slots = std::stoul(lpmake["metadata_slots"].get<std::string>());
        }
        if (lpmake.contains("super_name")) {
            config.super_name = lpmake["super_name"].get<std::string>();
        }
        if (lpmake.contains("alignment_offset")) {
            config.alignment_offset = std::stoul(lpmake["alignment_offset"].get<std::string>());
        }
        if (lpmake.contains("virtual_ab")) {
            config.virtual_ab = lpmake["virtual_ab"].get<bool>();
        }
    }
    
    // Parse block device
    if (j.contains("block_devices") && j["block_devices"].is_array() && !j["block_devices"].empty()) {
        auto& bd = j["block_devices"][0];
        config.block_device.name = bd["name"].get<std::string>();
        config.block_device.size = std::stoull(bd["size"].get<std::string>());
        config.block_device.block_size = std::stoul(bd["block_size"].get<std::string>());
        config.block_device.alignment = std::stoul(bd["alignment"].get<std::string>());
    }
    
    // Parse groups
    if (j.contains("groups") && j["groups"].is_array()) {
        for (const auto& grp : j["groups"]) {
            Group group;
            group.name = grp["name"].get<std::string>();
            group.maximum_size = 0;
            if (grp.contains("maximum_size")) {
                group.maximum_size = std::stoull(grp["maximum_size"].get<std::string>());
            }
            config.groups.push_back(group);
        }
    }
    
    // Parse partitions
    if (j.contains("partitions") && j["partitions"].is_array()) {
        for (const auto& part : j["partitions"]) {
            Partition partition;
            partition.name = part["name"].get<std::string>();
            partition.path = part["path"].get<std::string>();
            partition.size = std::stoull(part["size"].get<std::string>());
            partition.group_name = part["group_name"].get<std::string>();
            partition.is_dynamic = part["is_dynamic"].get<bool>();
            config.partitions.push_back(partition);
        }
    }
    
    // Parse metadata path
    if (j.contains("super_meta") && j["super_meta"].contains("path")) {
        config.metadata_path = j["super_meta"]["path"].get<std::string>();
    }
    
    std::cout << "\nConfiguration loaded successfully:" << std::endl;
    std::cout << "  - Block device size: " << config.block_device.size << " bytes" << std::endl;
    std::cout << "  - Block size: " << config.block_device.block_size << " bytes" << std::endl;
    std::cout << "  - Alignment: " << config.block_device.alignment << " bytes" << std::endl;
    std::cout << "  - Metadata size: " << config.metadata_size << " bytes" << std::endl;
    std::cout << "  - Metadata slots: " << config.metadata_slots << std::endl;
    std::cout << "  - Super name: " << config.super_name << std::endl;
    std::cout << "  - Groups: " << config.groups.size() << std::endl;
    std::cout << "  - Partitions: " << config.partitions.size() << std::endl;
    
    return true;
}

bool verify_partition_files(const SuperConfig& config) {
    std::cout << "\nVerifying partition files..." << std::endl;
    bool all_exist = true;
    
    for (const auto& partition : config.partitions) {
        std::string full_path = config.base_path + "/" + partition.path;
        if (!fs::exists(full_path)) {
            std::cerr << "  ERROR: Partition file not found: " << full_path << std::endl;
            all_exist = false;
        } else {
            auto file_size = fs::file_size(full_path);
            std::cout << "  ✓ " << partition.name << " (" << file_size << " bytes)" << std::endl;
        }
    }
    
    return all_exist;
}



std::string build_lpmake_command(const SuperConfig& config, const std::string& output_path) {
    std::ostringstream cmd;
    
    // Use bundled lpmake if available, otherwise use system lpmake
    std::string lpmake_path = find_lpmake();
    cmd << lpmake_path;
    
    // Device size
    cmd << " --device-size=" << config.block_device.size;
    
    // Metadata size - MUST match original for vbmeta compatibility
    cmd << " --metadata-size=" << config.metadata_size;
    
    // Metadata slots - MUST match original (1 for non-A/B, 2 for A/B, 3 for A/B/C)
    cmd << " --metadata-slots=" << config.metadata_slots;
    
    // Block size
    cmd << " --block-size=" << config.block_device.block_size;
    
    // Alignment
    cmd << " --alignment=" << config.block_device.alignment;
    
    // Alignment offset if present
    if (config.alignment_offset > 0) {
        cmd << " --alignment-offset=" << config.alignment_offset;
    }
    
    // Super partition name - MUST match original
    if (!config.super_name.empty() && config.super_name != "super") {
        cmd << " --super-name=" << config.super_name;
    }
    
    // Virtual A/B flag if enabled
    if (config.virtual_ab) {
        cmd << " --virtual-ab";
    }
    
    // Add groups
    for (const auto& group : config.groups) {
        if (group.maximum_size > 0) {
            cmd << " --group=" << group.name << ":" << group.maximum_size;
        }
    }
    
    // Add partitions with correct attributes
    for (const auto& partition : config.partitions) {
        std::string full_path = config.base_path + "/" + partition.path;
        
        // Partition definition: name:attributes:size:group
        cmd << " --partition=" << partition.name << ":"
            << (partition.is_dynamic ? "readonly:" : "none:")
            << partition.size << ":"
            << partition.group_name;
        
        // Image file for this partition
        cmd << " --image=" << partition.name << "=" << full_path;
    }
    
    // Output file - use raw format (not sparse) for direct flashing
    cmd << " --output=" << output_path;
    
    return cmd.str();
}

int main(int argc, char* argv[]) {
    print_banner();
    
    std::string export_path;
    
    if (argc > 1) {
        export_path = argv[1];
    } else {
        std::cout << "Enter the path to your export ROM folder: ";
        std::getline(std::cin, export_path);
    }
    
    // Remove trailing slashes
    while (!export_path.empty() && (export_path.back() == '/' || export_path.back() == '\\')) {
        export_path.pop_back();
    }
    
    if (!fs::exists(export_path)) {
        std::cerr << "ERROR: Export folder not found: " << export_path << std::endl;
        return 1;
    }
    
    std::string meta_path = export_path + "/META";
    
    // Find and select JSON file
    auto json_files = find_json_files(meta_path);
    std::string selected_json = select_json_file(json_files);
    
    if (selected_json.empty()) {
        return 1;
    }
    
    std::string json_path = meta_path + "/" + selected_json;
    std::cout << "\nUsing configuration: " << selected_json << std::endl;
    
    // Parse configuration
    SuperConfig config;
    if (!parse_super_config(json_path, export_path, config)) {
        return 1;
    }
    
    // Verify partition files
    if (!verify_partition_files(config)) {
        std::cerr << "\nERROR: Some partition files are missing!" << std::endl;
        return 1;
    }
    
    // Build super.img
    std::string output_path = export_path + "/super.img";
    std::cout << "\nBuilding super.img..." << std::endl;
    std::cout << "Output: " << output_path << std::endl;
    
    std::string lpmake_cmd = build_lpmake_command(config, output_path);
    
    std::cout << "\nExecuting lpmake command..." << std::endl;
    std::cout << "Command: " << lpmake_cmd << std::endl;
    
    int result = system(lpmake_cmd.c_str());
    
    if (result == 0) {
        std::cout << "\n✓ SUCCESS! Super image created at: " << output_path << std::endl;
        
        if (fs::exists(output_path)) {
            auto output_size = fs::file_size(output_path);
            std::cout << "  Size: " << output_size << " bytes (" << (output_size / 1024 / 1024) << " MB)" << std::endl;
        }
        
        // Display important vbmeta information
        std::cout << "\n" << std::string(60, '=') << std::endl;
        std::cout << "IMPORTANT: VBMETA COMPATIBILITY" << std::endl;
        std::cout << std::string(60, '=') << std::endl;
        std::cout << "\nThe super.img has been successfully created, but it will NOT boot" << std::endl;
        std::cout << "with the STOCK vbmeta due to hash verification." << std::endl;
        std::cout << "\nThis is NORMAL and EXPECTED behavior because:" << std::endl;
        std::cout << "  • Stock vbmeta contains a hash of the original super metadata" << std::endl;
        std::cout << "  • The rebuilt super.img has new metadata with a different hash" << std::endl;
        std::cout << "  • VBMeta verification will fail and prevent booting" << std::endl;
        
        std::cout << "\n" << std::string(60, '-') << std::endl;
        std::cout << "SOLUTION - Choose ONE of these options:" << std::endl;
        std::cout << std::string(60, '-') << std::endl;
        
        std::cout << "\n1. DISABLE VERIFICATION (Easiest - for testing):" << std::endl;
        std::cout << "   fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img" << std::endl;
        std::cout << "   fastboot flash super super.img" << std::endl;
        
        std::cout << "\n2. FLASH EMPTY VBMETA (Disables verification):" << std::endl;
        std::cout << "   dd if=/dev/zero of=vbmeta_disabled.img bs=4096 count=1" << std::endl;
        std::cout << "   fastboot flash vbmeta vbmeta_disabled.img" << std::endl;
        if (config.metadata_slots > 1) {
            std::cout << "   fastboot flash vbmeta_a vbmeta_disabled.img" << std::endl;
            std::cout << "   fastboot flash vbmeta_b vbmeta_disabled.img" << std::endl;
        }
        std::cout << "   fastboot flash super super.img" << std::endl;
        
        std::cout << "\n3. USE PATCHED VBMETA (Recommended for custom ROMs):" << std::endl;
        std::cout << "   • Use vbmeta from a custom ROM (LineageOS, etc.)" << std::endl;
        std::cout << "   • Or create your own with avbtool" << std::endl;
        
        std::cout << "\n4. BOOT WITHOUT FLASHING (Temporary test):" << std::endl;
        std::cout << "   fastboot erase vbmeta" << std::endl;
        std::cout << "   fastboot flash super super.img" << std::endl;
        std::cout << "   fastboot reboot" << std::endl;
        
        std::cout << "\n" << std::string(60, '=') << std::endl;
        std::cout << "For more details, see: VBMETA_HASH_EXPLANATION.md" << std::endl;
        std::cout << std::string(60, '=') << std::endl;
        std::cout << std::endl;
        
    } else {
        std::cerr << "\n✗ ERROR: Failed to create super image!" << std::endl;
        std::cerr << "  Return code: " << result << std::endl;
        return 1;
    }
    
    return 0;
}