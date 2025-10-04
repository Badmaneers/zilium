cmake_minimum_required(VERSION 3.10)
project(ZiliumSuperCompactor VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")

# Find required packages
find_package(Threads REQUIRED)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/external/json/include
)

# Option to use system lpmake or build from source
option(USE_SYSTEM_LPMAKE "Use system installed lpmake instead of building" OFF)

if(NOT USE_SYSTEM_LPMAKE)
    # Check if lpunpack_and_lpmake exists
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake")
        message(STATUS "Found lpunpack_and_lpmake directory")
        
        # Check if binaries already exist
        set(LPMAKE_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpmake")
        set(LPUNPACK_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpunpack")
        set(LPDUMP_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpdump")
        
        if(NOT EXISTS "${LPMAKE_BIN}" OR NOT EXISTS "${LPUNPACK_BIN}" OR NOT EXISTS "${LPDUMP_BIN}")
            message(STATUS "LP tools not found, will be built by build.sh script")
            message(STATUS "Note: Run build.sh to build LP tools first")
        else()
            message(STATUS "LP tools already built (lpmake, lpunpack, lpdump)")
        endif()
        
        # We don't add a custom target here anymore - build.sh handles it
        # This prevents CMake from rebuilding LP tools every time
        
    else()
        message(WARNING "lpunpack_and_lpmake directory not found!")
        message(WARNING "Please clone it with: git clone https://github.com/LonelyFool/lpunpack_and_lpmake.git")
        message(FATAL_ERROR "Cannot proceed without lpmake source")
    endif()
endif()

# Main executable
add_executable(zilium-super-compactor
    src/zilium_super_compactor.cpp
)

target_link_libraries(zilium-super-compactor
    Threads::Threads
    stdc++fs  # For filesystem support
)

# Installation
install(TARGETS zilium-super-compactor
    RUNTIME DESTINATION bin
)

# Install lpmake and lpunpack binaries if built from source
if(NOT USE_SYSTEM_LPMAKE)
    set(LPMAKE_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpmake")
    set(LPUNPACK_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpunpack")
    set(LPDUMP_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpdump")
    
    if(EXISTS "${LPMAKE_BIN}")
        install(FILES ${LPMAKE_BIN}
            DESTINATION bin
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                        GROUP_READ GROUP_EXECUTE
                        WORLD_READ WORLD_EXECUTE
        )
    endif()
    
    if(EXISTS "${LPUNPACK_BIN}")
        install(FILES ${LPUNPACK_BIN}
            DESTINATION bin
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                        GROUP_READ GROUP_EXECUTE
                        WORLD_READ WORLD_EXECUTE
        )
    endif()
    
    if(EXISTS "${LPDUMP_BIN}")
        install(FILES ${LPDUMP_BIN}
            DESTINATION bin
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                        GROUP_READ GROUP_EXECUTE
                        WORLD_READ WORLD_EXECUTE
        )
    endif()
endif()

# Print build information
message(STATUS "========================================")
message(STATUS "Zilium Super Compactor Configuration:")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  Use system lpmake: ${USE_SYSTEM_LPMAKE}")
message(STATUS "========================================")