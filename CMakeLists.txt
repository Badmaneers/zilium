cmake_minimum_required(VERSION 3.16)
project(ZiliumSuperCompactor VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Build flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")

# Build options
option(BUILD_GUI "Build the Qt6 GUI application" OFF)

# Find required packages
find_package(Threads REQUIRED)

# Include directories for CLI
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/external/json/include
)

# ============================================================================
# LP Tools Configuration
# ============================================================================
option(USE_SYSTEM_LPMAKE "Use system installed lpmake instead of building" OFF)

if(NOT USE_SYSTEM_LPMAKE)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake")
        message(STATUS "Found lpunpack_and_lpmake directory")
        
        set(LPMAKE_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpmake")
        set(LPUNPACK_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpunpack")
        set(LPDUMP_BIN "${CMAKE_CURRENT_SOURCE_DIR}/lpunpack_and_lpmake/bin/lpdump")
        
        if(NOT EXISTS "${LPMAKE_BIN}" OR NOT EXISTS "${LPUNPACK_BIN}" OR NOT EXISTS "${LPDUMP_BIN}")
            message(STATUS "LP tools not found, will be built by build.sh script")
        else()
            message(STATUS "LP tools already built (lpmake, lpunpack, lpdump)")
        endif()
    else()
        message(WARNING "lpunpack_and_lpmake directory not found!")
        message(FATAL_ERROR "Cannot proceed without lpmake source")
    endif()
endif()

# ============================================================================
# CLI Executable (zilium-super-compactor)
# ============================================================================
add_executable(zilium-super-compactor
    src/zilium_super_compactor.cpp
)

target_link_libraries(zilium-super-compactor
    Threads::Threads
    stdc++fs
)

# ============================================================================
# GUI Executable (zilium-gui) - Optional
# ============================================================================
if(BUILD_GUI)
    message(STATUS "========================================")
    message(STATUS "Configuring Qt6 GUI...")
    message(STATUS "========================================")
    
    # Try to find Qt6
    set(CMAKE_PREFIX_PATH 
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6"
        "/usr/lib64/cmake/Qt6"
        "/usr/local/lib/cmake/Qt6"
        ${CMAKE_PREFIX_PATH}
    )
    
    find_package(Qt6 COMPONENTS Core Gui Widgets Quick QuickControls2 Qml QUIET)
    
    if(Qt6_FOUND)
        message(STATUS "✓ Qt6 ${Qt6_VERSION} found")
        message(STATUS "  Qt6 location: ${Qt6_DIR}")
        
        # Enable Qt6 automatic handling
        set(CMAKE_AUTOMOC ON)
        set(CMAKE_AUTORCC ON)
        set(CMAKE_AUTOUIC ON)
        
        # GUI source files
        set(GUI_SOURCES
            gui/src/main.cpp
            gui/src/ziliumcontroller.cpp
            gui/src/partitionmodel.cpp
            gui/src/superconfigmodel.cpp
        )
        
        # GUI header files (for MOC)
        set(GUI_HEADERS
            gui/src/ziliumcontroller.h
            gui/src/partitionmodel.h
            gui/src/superconfigmodel.h
        )
        
        # Qt resource file (QML + icons)
        set(GUI_RESOURCES
            gui/qml.qrc
        )
        
        # Create GUI executable
        add_executable(zilium-gui 
            ${GUI_SOURCES}
            ${GUI_HEADERS}
            ${GUI_RESOURCES}
        )
        
        # Set output directory for GUI
        set_target_properties(zilium-gui PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/gui"
            WIN32_EXECUTABLE TRUE
            MACOSX_BUNDLE TRUE
        )
        
        # Include directories for GUI
        target_include_directories(zilium-gui PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/external/json/include
            ${CMAKE_CURRENT_SOURCE_DIR}/gui/src
        )
        
        # Link Qt6 libraries to GUI
        target_link_libraries(zilium-gui PRIVATE
            Qt6::Core
            Qt6::Gui
            Qt6::Widgets
            Qt6::Quick
            Qt6::QuickControls2
            Qt6::Qml
            stdc++fs
        )
        
        message(STATUS "✓ GUI target 'zilium-gui' configured")
        message(STATUS "  Output: ${CMAKE_BINARY_DIR}/gui/zilium-gui")
        
    else()
        message(WARNING "========================================")
        message(WARNING "Qt6 not found! GUI will NOT be built.")
        message(WARNING "Install Qt6 with:")
        message(WARNING "  Ubuntu/Debian: sudo apt install qt6-base-dev qt6-declarative-dev")
        message(WARNING "  Fedora: sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel")
        message(WARNING "  Arch: sudo pacman -S qt6-base qt6-declarative")
        message(WARNING "========================================")
        set(BUILD_GUI OFF CACHE BOOL "Qt6 not available" FORCE)
    endif()
endif()

# ============================================================================
# Installation Rules
# ============================================================================
install(TARGETS zilium-super-compactor
    RUNTIME DESTINATION bin
)

if(BUILD_GUI AND TARGET zilium-gui)
    install(TARGETS zilium-gui
        RUNTIME DESTINATION bin
        BUNDLE DESTINATION .
    )
endif()

# Install LP tools if built from source
if(NOT USE_SYSTEM_LPMAKE)
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

# ============================================================================
# Build Summary
# ============================================================================
message(STATUS "========================================")
message(STATUS "Zilium Super Compactor Configuration:")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  Use system lpmake: ${USE_SYSTEM_LPMAKE}")
message(STATUS "  Build GUI: ${BUILD_GUI}")
if(BUILD_GUI AND TARGET zilium-gui)
    message(STATUS "  GUI status: ENABLED ✓")
else()
    message(STATUS "  GUI status: DISABLED")
endif()
message(STATUS "========================================")
