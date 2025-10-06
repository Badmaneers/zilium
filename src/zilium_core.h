#ifndef ZILIUM_CORE_H
#define ZILIUM_CORE_H

#include <string>
#include <vector>
#include <cstdint>

// Progress callback interface for GUI integration
class ProgressCallback {
public:
    virtual void onProgress(int percent, const std::string& message) = 0;
    virtual void onLog(const std::string& message) = 0;
    virtual ~ProgressCallback() = default;
};

// Error codes
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

// Result structures
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

// Core structures (same as in cpp)
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

// API functions for GUI integration
extern "C" {
    // Progress and cancellation control
    void set_progress_callback(ProgressCallback* callback);
    void request_cancel();
    bool is_cancelled();
    void reset_cancel();
    
    // Configuration parsing
    bool parse_super_config(const std::string& json_path, const std::string& base_path, SuperConfig& config);
    
    // Validation and verification
    ValidationResult validate_configuration(const SuperConfig& config);
    bool verify_partition_files(const SuperConfig& config);
    bool verify_super_image(const std::string& super_img_path);
    
    // Build planning and estimation
    BuildPlan create_build_plan(const SuperConfig& config, const std::string& output_path);
    BuildEstimate estimate_build_time(const SuperConfig& config);
    SizeRecommendation calculate_optimal_size(const Partition& partition, 
                                              const std::string& base_path,
                                              uint32_t alignment);
    
    // Configuration export
    bool export_config_json(const SuperConfig& config, const std::string& output_path);
    
    // Build command generation
    std::string build_lpmake_command(const SuperConfig& config, const std::string& output_path);
    
    // Utility functions
    std::string find_lpmake();
    std::string find_lpdump();
    std::vector<std::string> find_json_files(const std::string& meta_path);
}

#endif // ZILIUM_CORE_H
