#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <cstdlib>
#include <sstream>
#include <atomic>
#include <ctime>
#include <algorithm>

// Platform-specific includes
#ifdef _WIN32
    #include <windows.h>
    #define PATH_MAX MAX_PATH
#else
    #include <unistd.h>
    #include <limits.h>
#endif

#include "../external/json/include/nlohmann/json.hpp" // You'll need nlohmann/json library

using json = nlohmann::json;
namespace fs = std::filesystem;

// Progress callback system for GUI integration
class ProgressCallback {
public:
    virtual void onProgress(int percent, const std::string& message) = 0;
    virtual void onLog(const std::string& message) = 0;
    virtual ~ProgressCallback() = default;
};

// Global state for GUI integration
static ProgressCallback* g_progress_callback = nullptr;
static std::atomic<bool> g_cancel_requested{false};

// Progress reporting functions
void set_progress_callback(ProgressCallback* callback) {
    g_progress_callback = callback;
}

void request_cancel() {
    g_cancel_requested = true;
}

bool is_cancelled() {
    return g_cancel_requested;
}

void reset_cancel() {
    g_cancel_requested = false;
}

void report_progress(int percent, const std::string& message) {
    if (g_progress_callback) {
        g_progress_callback->onProgress(percent, message);
    } else {
        std::cout << "[" << percent << "%] " << message << std::endl;
    }
}

void log_message(const std::string& message) {
    if (g_progress_callback) {
        g_progress_callback->onLog(message);
    } else {
        std::cout << message << std::endl;
    }
}

// Error codes for structured error handling
enum class ErrorCode {
    SUCCESS = 0,
    INVALID_PATH = 1,
    JSON_NOT_FOUND = 2,
    JSON_PARSE_ERROR = 3,
    MISSING_PARTITIONS = 4,
    SIZE_MISMATCH = 5,
    LPMAKE_FAILED = 6,
    CANCELLED = 7,
    LPDUMP_NOT_FOUND = 8,
    VERIFICATION_FAILED = 9
};

struct BuildResult {
    ErrorCode error_code;
    std::string error_message;
    std::string output_path;
    uint64_t output_size;
    int build_time_seconds;
};

struct ValidationResult {
    bool success;
    std::vector<std::string> errors;
    std::vector<std::string> warnings;
};

struct BuildPlan {
    std::string lpmake_command;
    std::vector<std::string> required_files;
    uint64_t estimated_output_size;
    std::string output_path;
};

struct BuildEstimate {
    uint64_t total_bytes_to_process;
    int estimated_seconds;
    std::string estimated_time_str;
};

struct SizeRecommendation {
    uint64_t current_size;
    uint64_t actual_file_size;
    uint64_t recommended_size;
    bool needs_resize;
};

// Get the directory where the executable is located
std::string get_executable_dir() {
#ifdef _WIN32
    // Windows implementation
    char result[MAX_PATH];
    DWORD count = GetModuleFileNameA(NULL, result, MAX_PATH);
    if (count != 0) {
        fs::path exe_path(result);
        return exe_path.parent_path().string();
    }
    return "";
#else
    // Linux/Unix implementation
    char result[PATH_MAX];
    ssize_t count = readlink("/proc/self/exe", result, PATH_MAX);
    if (count != -1) {
        result[count] = '\0';
        fs::path exe_path(result);
        return exe_path.parent_path().string();
    }
    return "";
#endif
}

// Find lpmake binary - check bundled first, then system PATH
std::string find_lpmake() {
    // First, check in the same directory as zilium-super-compactor
    std::string exe_dir = get_executable_dir();
    if (!exe_dir.empty()) {
#ifdef _WIN32
        // Windows: Check lptools subdirectory first (packaged location)
        fs::path packaged_lpmake = fs::path(exe_dir) / "lptools" / "lpmake.exe";
        if (fs::exists(packaged_lpmake)) {
            return packaged_lpmake.string();
        }
        // Fallback: same directory as executable
        fs::path bundled_lpmake = fs::path(exe_dir) / "lpmake.exe";
        if (fs::exists(bundled_lpmake)) {
            return bundled_lpmake.string();
        }
#else
        // Linux: Check lptools subdirectory first (packaged location)
        fs::path packaged_lpmake = fs::path(exe_dir) / "lptools" / "lpmake";
        if (fs::exists(packaged_lpmake)) {
            return packaged_lpmake.string();
        }
        // Fallback: same directory as executable
        fs::path bundled_lpmake = fs::path(exe_dir) / "lpmake";
        if (fs::exists(bundled_lpmake)) {
            return bundled_lpmake.string();
        }
#endif
    }
    
    // Fall back to system PATH
#ifdef _WIN32
    return "lpmake.exe";
#else
    return "lpmake";
#endif
}

// Find lpdump binary - check bundled first, then system PATH
std::string find_lpdump() {
    std::string exe_dir = get_executable_dir();
    if (!exe_dir.empty()) {
#ifdef _WIN32
        // Windows: Check lptools subdirectory first (packaged location)
        fs::path packaged = fs::path(exe_dir) / "lptools" / "lpdump.exe";
        if (fs::exists(packaged)) {
            return packaged.string();
        }
        // Fallback: same directory as executable
        fs::path bundled = fs::path(exe_dir) / "lpdump.exe";
        if (fs::exists(bundled)) {
            return bundled.string();
        }
#else
        // Linux: Check lptools subdirectory first (packaged location)
        fs::path packaged = fs::path(exe_dir) / "lptools" / "lpdump";
        if (fs::exists(packaged)) {
            return packaged.string();
        }
        // Fallback: same directory as executable
        fs::path bundled = fs::path(exe_dir) / "lpdump";
        if (fs::exists(bundled)) {
            return bundled.string();
        }
#endif
    }
#ifdef _WIN32
    return "lpdump.exe";
#else
    return "lpdump";
#endif
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

// Forward declarations
std::string build_lpmake_command(const SuperConfig& config, const std::string& output_path);

void print_banner() {
    std::cout << "\n";
    std::cout << " ===============================================\n";
    std::cout << "|      Zilium Super Compactor v1.0.0            |\n";
    std::cout << "|    Realme/OPPO/OnePlus A/B Compatible         |\n";
    std::cout << " ===============================================\n";
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
    
    log_message("\nConfiguration loaded successfully:");
    log_message("  - Block device size: " + std::to_string(config.block_device.size) + " bytes");
    log_message("  - Block size: " + std::to_string(config.block_device.block_size) + " bytes");
    log_message("  - Alignment: " + std::to_string(config.block_device.alignment) + " bytes");
    log_message("  - Metadata size: " + std::to_string(config.metadata_size) + " bytes");
    log_message("  - Metadata slots: " + std::to_string(config.metadata_slots));
    log_message("  - Super name: " + config.super_name);
    log_message("  - Groups: " + std::to_string(config.groups.size()));
    log_message("  - Partitions: " + std::to_string(config.partitions.size()));
    
    return true;
}

bool verify_partition_files(const SuperConfig& config) {
    log_message("\nVerifying partition files...");
    bool all_exist = true;
    
    for (size_t i = 0; i < config.partitions.size(); i++) {
        if (is_cancelled()) {
            return false;
        }
        
        const auto& partition = config.partitions[i];
        report_progress((i * 100) / config.partitions.size(), 
                       "Verifying " + partition.name);
        
        // Skip partitions without a path (slot B placeholders for A/B devices)
        if (partition.path.empty()) {
            log_message("  o " + partition.name + ": Slot placeholder (no image file)");
            continue;
        }
        
        // Handle both relative and absolute paths
        std::string full_path;
        if (partition.path[0] == '/') {
            full_path = partition.path;
        } else {
            full_path = config.base_path + "/" + partition.path;
        }
        
        if (!fs::exists(full_path)) {
            std::cerr << "  X " << partition.name << ": MISSING - " << full_path << std::endl;
            all_exist = false;
        } else {
            auto file_size = fs::file_size(full_path);
            std::cout << "  OK " << partition.name << ": " << (file_size / 1024 / 1024) << " MB" << std::endl;
        }
    }
    
    return all_exist;
}

// Validate configuration before building
ValidationResult validate_configuration(const SuperConfig& config) {
    ValidationResult result;
    result.success = true;
    
    log_message("\nValidating configuration...");
    
    // Check partition files exist and sizes
    for (const auto& partition : config.partitions) {
        // Handle both relative and absolute paths
        std::string full_path;
        if (partition.path.empty()) {
            result.errors.push_back("Empty path for partition: " + partition.name);
            result.success = false;
            continue;
        }
        
        if (partition.path[0] == '/') {
            // Absolute path
            full_path = partition.path;
        } else {
            // Relative path
            full_path = config.base_path + "/" + partition.path;
        }
        
        if (!fs::exists(full_path)) {
            result.errors.push_back("Missing partition file: " + partition.name);
            result.success = false;
        } else {
            auto file_size = fs::file_size(full_path);
            if (file_size > partition.size) {
                result.warnings.push_back(partition.name + " file size (" + 
                    std::to_string(file_size) + ") exceeds declared size (" + 
                    std::to_string(partition.size) + ")");
            }
            if (file_size == 0) {
                result.warnings.push_back(partition.name + " is empty (0 bytes)");
            }
        }
    }
    
    // Validate total size doesn't exceed device size
    uint64_t total_size = 0;
    for (const auto& partition : config.partitions) {
        total_size += partition.size;
    }
    if (total_size > config.block_device.size) {
        result.errors.push_back("Total partition size (" + std::to_string(total_size) + 
            ") exceeds device size (" + std::to_string(config.block_device.size) + ")");
        result.success = false;
    }
    
    // Check for duplicate partition names
    std::vector<std::string> names;
    for (const auto& partition : config.partitions) {
        if (std::find(names.begin(), names.end(), partition.name) != names.end()) {
            result.errors.push_back("Duplicate partition name: " + partition.name);
            result.success = false;
        }
        names.push_back(partition.name);
    }
    
    // Display results
    if (!result.errors.empty()) {
        log_message("\nValidation Errors:");
        for (const auto& error : result.errors) {
            log_message("  X " + error);
        }
    }
    
    if (!result.warnings.empty()) {
        log_message("\nValidation Warnings:");
        for (const auto& warning : result.warnings) {
            log_message("  ! " + warning);
        }
    }
    
    if (result.success) {
        log_message("OK Configuration validation passed");
    }
    
    return result;
}

// Calculate optimal partition size
SizeRecommendation calculate_optimal_size(const Partition& partition, 
                                          const std::string& base_path,
                                          uint32_t alignment) {
    SizeRecommendation rec;
    std::string full_path = base_path + "/" + partition.path;
    
    rec.current_size = partition.size;
    rec.actual_file_size = fs::exists(full_path) ? fs::file_size(full_path) : 0;
    
    // Round up to alignment boundary
    if (rec.actual_file_size > 0) {
        rec.recommended_size = ((rec.actual_file_size + alignment - 1) / alignment) * alignment;
    } else {
        rec.recommended_size = alignment;
    }
    
    rec.needs_resize = (rec.recommended_size != rec.current_size);
    
    return rec;
}

// Create build plan (dry run)
BuildPlan create_build_plan(const SuperConfig& config, const std::string& output_path) {
    BuildPlan plan;
    plan.lpmake_command = build_lpmake_command(config, output_path);
    plan.output_path = output_path;
    plan.estimated_output_size = config.block_device.size;
    
    for (const auto& partition : config.partitions) {
        plan.required_files.push_back(config.base_path + "/" + partition.path);
    }
    
    return plan;
}

// Estimate build time
BuildEstimate estimate_build_time(const SuperConfig& config) {
    BuildEstimate estimate;
    estimate.total_bytes_to_process = 0;
    
    for (const auto& partition : config.partitions) {
        std::string full_path = config.base_path + "/" + partition.path;
        if (fs::exists(full_path)) {
            estimate.total_bytes_to_process += fs::file_size(full_path);
        }
    }
    
    // Rough estimate: 100 MB/s processing speed
    estimate.estimated_seconds = estimate.total_bytes_to_process / (100 * 1024 * 1024);
    if (estimate.estimated_seconds < 1) estimate.estimated_seconds = 1;
    
    int minutes = estimate.estimated_seconds / 60;
    int seconds = estimate.estimated_seconds % 60;
    estimate.estimated_time_str = std::to_string(minutes) + "m " + 
                                   std::to_string(seconds) + "s";
    
    return estimate;
}

// Export modified configuration to JSON
bool export_config_json(const SuperConfig& config, const std::string& output_path) {
    json j;
    
    try {
        // Rebuild JSON from config
        j["nv_id"] = config.nv_id;
        
        j["lpmake"]["metadata_size"] = std::to_string(config.metadata_size);
        j["lpmake"]["metadata_slots"] = std::to_string(config.metadata_slots);
        j["lpmake"]["super_name"] = config.super_name;
        j["lpmake"]["alignment_offset"] = std::to_string(config.alignment_offset);
        j["lpmake"]["virtual_ab"] = config.virtual_ab;
        
        // Block device
        j["block_devices"][0] = {
            {"name", config.block_device.name},
            {"size", std::to_string(config.block_device.size)},
            {"block_size", std::to_string(config.block_device.block_size)},
            {"alignment", std::to_string(config.block_device.alignment)}
        };
        
        // Groups
        j["groups"] = json::array();
        for (const auto& group : config.groups) {
            j["groups"].push_back({
                {"name", group.name},
                {"maximum_size", std::to_string(group.maximum_size)}
            });
        }
        
        // Partitions
        j["partitions"] = json::array();
        for (const auto& partition : config.partitions) {
            j["partitions"].push_back({
                {"name", partition.name},
                {"path", partition.path},
                {"size", std::to_string(partition.size)},
                {"group_name", partition.group_name},
                {"is_dynamic", partition.is_dynamic}
            });
        }
        
        // Metadata path
        if (!config.metadata_path.empty()) {
            j["super_meta"]["path"] = config.metadata_path;
        }
        
        std::ofstream file(output_path);
        if (!file.is_open()) {
            log_message("ERROR: Cannot write to " + output_path);
            return false;
        }
        
        file << j.dump(2);
        log_message("Configuration exported to: " + output_path);
        return true;
        
    } catch (const std::exception& e) {
        log_message("ERROR: Failed to export configuration: " + std::string(e.what()));
        return false;
    }
}

// Verify the built super image using lpdump
bool verify_super_image(const std::string& super_img_path) {
    if (!fs::exists(super_img_path)) {
        log_message("ERROR: Super image not found: " + super_img_path);
        return false;
    }
    
    log_message("\nVerifying super image with lpdump...");
    
    std::string lpdump_path = find_lpdump();
    std::string lpdump_cmd = lpdump_path + " " + super_img_path + " > /tmp/zilium_lpdump.log 2>&1";
    
    int result = system(lpdump_cmd.c_str());
    
    if (result == 0) {
        log_message("OK Super image verification passed");
        return true;
    } else {
        log_message("X Super image verification failed");
        log_message("  Check /tmp/zilium_lpdump.log for details");
        return false;
    }
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
        // Skip partitions without a path (slot B placeholders for A/B devices)
        if (partition.path.empty()) {
            // For empty slot partitions, only add partition definition without image
            log_message("  o Adding placeholder partition: " + partition.name + " (slot B)");
            cmd << " --partition=" << partition.name << ":"
                << (partition.is_dynamic ? "readonly:" : "none:")
                << "0:"  // Size 0 for placeholder partitions
                << partition.group_name;
            continue;
        }
        
        // Handle both relative and absolute paths
        std::string full_path;
        // Check if path is absolute (starts with /)
        if (partition.path[0] == '/') {
            // Absolute path - use as-is
            full_path = partition.path;
        } else {
            // Relative path - prepend base_path
            full_path = config.base_path + "/" + partition.path;
        }
        
        // Partition definition: name:attributes:size:group
        cmd << " --partition=" << partition.name << ":"
            << (partition.is_dynamic ? "readonly:" : "none:")
            << partition.size << ":"
            << partition.group_name;
        
        // Image file for this partition (only if file exists)
        if (fs::exists(full_path)) {
            cmd << " --image=" << partition.name << "=" << full_path;
        } else {
            log_message("WARNING: Image file not found for " + partition.name + ": " + full_path);
        }
    }
    
    // Output file - use raw format (not sparse) for direct flashing
    cmd << " --output=" << output_path;
    
    return cmd.str();
}

int main(int argc, char* argv[]) {
    print_banner();
    
    std::string export_path;
    std::string specific_json;  // Optional: specific JSON file to use
    std::string output_dir;     // Optional: custom output directory
    
    if (argc > 1) {
        export_path = argv[1];
        if (argc > 2) {
            specific_json = argv[2];  // Second argument: specific JSON filename
        }
        if (argc > 3) {
            output_dir = argv[3];     // Third argument: output directory
        }
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
    
    // If output directory specified, validate it
    if (!output_dir.empty()) {
        while (!output_dir.empty() && (output_dir.back() == '/' || output_dir.back() == '\\')) {
            output_dir.pop_back();
        }
        if (!fs::exists(output_dir)) {
            std::cerr << "ERROR: Output folder not found: " << output_dir << std::endl;
            return 1;
        }
    }
    
    std::string meta_path = export_path + "/META";
    
    // Find and select JSON file
    auto json_files = find_json_files(meta_path);
    std::string selected_json;
    
    // If a specific JSON file was provided, use it
    if (!specific_json.empty()) {
        // Check if the provided filename exists in the META folder
        bool found = false;
        for (const auto& file : json_files) {
            if (file == specific_json) {
                found = true;
                selected_json = specific_json;
                break;
            }
        }
        
        if (!found) {
            std::cerr << "ERROR: Specified JSON file not found: " << specific_json << std::endl;
            std::cerr << "Available files:" << std::endl;
            for (const auto& file : json_files) {
                std::cerr << "  - " << file << std::endl;
            }
            return 1;
        }
        
        std::cout << "Using specified configuration: " << selected_json << std::endl;
    } else {
        // Interactive selection if no specific JSON provided
        selected_json = select_json_file(json_files);
    }
    
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
    
    // Validate configuration
    report_progress(10, "Validating configuration");
    ValidationResult validation = validate_configuration(config);
    if (!validation.success) {
        std::cerr << "\nERROR: Configuration validation failed!" << std::endl;
        return static_cast<int>(ErrorCode::MISSING_PARTITIONS);
    }
    
    // Show build estimate
    BuildEstimate estimate = estimate_build_time(config);
    log_message("\nBuild Estimate:");
    log_message("  - Total data to process: " + 
                std::to_string(estimate.total_bytes_to_process / 1024 / 1024) + " MB");
    log_message("  - Estimated time: " + estimate.estimated_time_str);
    
    // Verify partition files
    report_progress(20, "Verifying partition files");
    if (!verify_partition_files(config)) {
        std::cerr << "\nERROR: Some partition files are missing!" << std::endl;
        return static_cast<int>(ErrorCode::MISSING_PARTITIONS);
    }
    
    if (is_cancelled()) {
        log_message("\nOperation cancelled by user");
        return static_cast<int>(ErrorCode::CANCELLED);
    }
    
    // Build super.img
    // Use custom output directory if provided, otherwise use ROM directory
    std::string output_path = output_dir.empty() ? 
        (export_path + "/super.img") : 
        (output_dir + "/super.img");
    log_message("\nBuilding super.img...");
    log_message("Output: " + output_path);
    
    std::string lpmake_cmd = build_lpmake_command(config, output_path);
    
    // Show dry run information
    BuildPlan plan = create_build_plan(config, output_path);
    log_message("\nBuild Plan:");
    log_message("  - Output: " + plan.output_path);
    log_message("  - Required files: " + std::to_string(plan.required_files.size()));
    log_message("  - Estimated output size: " + 
                std::to_string(plan.estimated_output_size / 1024 / 1024) + " MB");
    
    log_message("\nExecuting lpmake command...");
    log_message("Command: " + lpmake_cmd);
    
    report_progress(50, "Building super image");
    
#ifdef _WIN32
    // On Windows, lpmake (cygwin-based) needs a proper temp directory
    // Set TMPDIR to Windows TEMP converted to cygwin path format
    char* temp_env = std::getenv("TEMP");
    if (temp_env) {
        std::string temp_path = temp_env;
        // Convert Windows path to forward slashes for cygwin compatibility
        std::replace(temp_path.begin(), temp_path.end(), '\\', '/');
        std::string tmpdir_env = "TMPDIR=" + temp_path;
        _putenv(tmpdir_env.c_str());
        log_message("Set TMPDIR to: " + temp_path);
    }
#endif
    
    auto start_time = std::time(nullptr);
    int result = system(lpmake_cmd.c_str());
    auto end_time = std::time(nullptr);
    int build_time = end_time - start_time;
    
    report_progress(90, "Build complete, verifying");
    
    if (result == 0) {
        log_message("\nOK SUCCESS! Super image created at: " + output_path);
        
        if (fs::exists(output_path)) {
            auto output_size = fs::file_size(output_path);
            log_message("  Size: " + std::to_string(output_size) + " bytes (" + 
                       std::to_string(output_size / 1024 / 1024) + " MB)");
            log_message("  Build time: " + std::to_string(build_time) + " seconds");
        }
        
        // Verify the output image
        if (verify_super_image(output_path)) {
            report_progress(100, "Build and verification complete");
        } else {
            log_message("Warning: Image verification failed, but image was created");
        }
        
        // Display important vbmeta information
        std::cout << "\n" << std::string(60, '=') << std::endl;
        std::cout << "IMPORTANT: VBMETA COMPATIBILITY" << std::endl;
        std::cout << std::string(60, '=') << std::endl;
        std::cout << "\nThe super.img has been successfully created, but it will NOT boot" << std::endl;
        std::cout << "with the STOCK vbmeta due to hash verification." << std::endl;
        std::cout << "\nThis is NORMAL and EXPECTED behavior because:" << std::endl;
        std::cout << "  - Stock vbmeta contains a hash of the original super metadata" << std::endl;
        std::cout << "  - The rebuilt super.img has new metadata with a different hash" << std::endl;
        std::cout << "  - VBMeta verification will fail and prevent booting" << std::endl;
        
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
        std::cout << "   - Use vbmeta from a custom ROM (LineageOS, etc.)" << std::endl;
        std::cout << "   - Or create your own with avbtool" << std::endl;
        
        std::cout << "\n4. BOOT WITHOUT FLASHING (Temporary test):" << std::endl;
        std::cout << "   fastboot erase vbmeta" << std::endl;
        std::cout << "   fastboot flash super super.img" << std::endl;
        std::cout << "   fastboot reboot" << std::endl;
        
        std::cout << "\n" << std::string(60, '=') << std::endl;
        std::cout << "For more details, see: VBMETA_HASH_EXPLANATION.md" << std::endl;
        std::cout << std::string(60, '=') << std::endl;
        std::cout << std::endl;
        
    } else {
        std::cerr << "\nX ERROR: Failed to create super image!" << std::endl;
        std::cerr << "  Return code: " << result << std::endl;
        return static_cast<int>(ErrorCode::LPMAKE_FAILED);
    }
    
    reset_cancel();
    return static_cast<int>(ErrorCode::SUCCESS);
}