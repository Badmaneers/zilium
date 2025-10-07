cmake_minimum_required(VERSION 3.16)
project(ZiliumSuperCompactor VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Build flags
if(MSVC)
    # Windows / MSVC specific flags
    # /Zc:__cplusplus - Required for Qt6 to properly detect C++17
    # /W3 - Warning level 3
    # /MP - Multi-processor compilation
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W3 /MP /Zc:__cplusplus")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2")
    add_definitions(-DUNICODE -D_UNICODE -DWIN32_LEAN_AND_MEAN -DNOMINMAX)
else()
    # Linux / GCC/Clang flags
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
endif()

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
# LP Tools Configuration (Prebuilt Binaries)
# ============================================================================
option(USE_SYSTEM_LPMAKE "Use system installed lpmake instead of prebuilt" OFF)

if(NOT USE_SYSTEM_LPMAKE)
    # Determine platform-specific path for prebuilt LP tools
    if(WIN32)
        set(LPTOOLS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lptools-prebuilt/win")
        set(LPTOOLS_EXT ".exe")
    else()
        set(LPTOOLS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lptools-prebuilt/linux")
        set(LPTOOLS_EXT "")
    endif()
    
    set(LPMAKE_BIN "${LPTOOLS_DIR}/lpmake${LPTOOLS_EXT}")
    set(LPUNPACK_BIN "${LPTOOLS_DIR}/lpunpack${LPTOOLS_EXT}")
    set(LPDUMP_BIN "${LPTOOLS_DIR}/lpdump${LPTOOLS_EXT}")
    
    if(EXISTS "${LPTOOLS_DIR}")
        if(EXISTS "${LPMAKE_BIN}" AND EXISTS "${LPUNPACK_BIN}" AND EXISTS "${LPDUMP_BIN}")
            message(STATUS "✓ Found prebuilt LP tools:")
            message(STATUS "  - lpmake:   ${LPMAKE_BIN}")
            message(STATUS "  - lpunpack: ${LPUNPACK_BIN}")
            message(STATUS "  - lpdump:   ${LPDUMP_BIN}")
        else()
            message(WARNING "Some LP tools missing in ${LPTOOLS_DIR}")
            if(NOT EXISTS "${LPMAKE_BIN}")
                message(WARNING "  Missing: lpmake${LPTOOLS_EXT}")
            endif()
            if(NOT EXISTS "${LPUNPACK_BIN}")
                message(WARNING "  Missing: lpunpack${LPTOOLS_EXT}")
            endif()
            if(NOT EXISTS "${LPDUMP_BIN}")
                message(WARNING "  Missing: lpdump${LPTOOLS_EXT}")
            endif()
        endif()
    else()
        message(FATAL_ERROR "LP tools directory not found: ${LPTOOLS_DIR}")
    endif()
else()
    message(STATUS "Using system-installed LP tools")
endif()

# ============================================================================
# CLI Executable (zilium-super-compactor)
# ============================================================================
add_executable(zilium-super-compactor
    src/zilium_super_compactor.cpp
)

target_link_libraries(zilium-super-compactor
    Threads::Threads
)

# Platform-specific libraries
if(NOT WIN32)
    target_link_libraries(zilium-super-compactor stdc++fs)
endif()

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
        
        # Add Windows resource file (icon and version info)
        if(WIN32)
            set(WINDOWS_RC_FILE "${CMAKE_CURRENT_SOURCE_DIR}/windows/zilium.rc")
            if(EXISTS ${WINDOWS_RC_FILE})
                target_sources(zilium-gui PRIVATE ${WINDOWS_RC_FILE})
                message(STATUS "✓ Added Windows resource file: zilium.rc")
            endif()
        endif()
        
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
        )
        
        # Platform-specific libraries for GUI
        if(NOT WIN32)
            target_link_libraries(zilium-gui PRIVATE stdc++fs)
        endif()
        
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

# Install LP tools if using prebuilt binaries
if(NOT USE_SYSTEM_LPMAKE)
    if(EXISTS "${LPMAKE_BIN}")
        install(PROGRAMS ${LPMAKE_BIN}
            DESTINATION bin
        )
    endif()
    
    if(EXISTS "${LPUNPACK_BIN}")
        install(PROGRAMS ${LPUNPACK_BIN}
            DESTINATION bin
        )
    endif()
    
    if(EXISTS "${LPDUMP_BIN}")
        install(PROGRAMS ${LPDUMP_BIN}
            DESTINATION bin
        )
    endif()
endif()

# ============================================================================
# Build Summary
# ============================================================================
message(STATUS "========================================")
message(STATUS "Zilium Super Compactor Configuration:")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Platform: ${CMAKE_SYSTEM_NAME}")
message(STATUS "  Compiler: ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "  C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  Use system lpmake: ${USE_SYSTEM_LPMAKE}")
message(STATUS "  Build GUI: ${BUILD_GUI}")
if(BUILD_GUI AND TARGET zilium-gui)
    message(STATUS "  GUI status: ENABLED ✓")
    message(STATUS "  Qt6 version: ${Qt6_VERSION}")
else()
    message(STATUS "  GUI status: DISABLED")
endif()
message(STATUS "========================================")

# ============================================================================
# Windows-specific Configuration
# ============================================================================
if(WIN32)
    if(MSVC)
        # Enable standards-conforming compiler behavior
        add_compile_options(/permissive-)
        
        # Disable specific warnings
        add_compile_options(
            /wd4251  # needs to have dll-interface
            /wd4275  # non dll-interface class used as base
            /wd4267  # conversion from size_t to int, possible loss of data
            /wd4244  # conversion warnings
        )
        
        # Set runtime library
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
        
        # Additional Windows definitions
        add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    endif()
    
    # CPack configuration for Windows installers
    set(CPACK_GENERATOR "ZIP;NSIS")
    set(CPACK_PACKAGE_NAME "Zilium")
    set(CPACK_PACKAGE_VENDOR "Badmaneers")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Zilium Super Compactor - Android Super Partition Tool")
    set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "Zilium")
    
    # NSIS installer settings (if building installer)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/windows/zilium.ico")
        set(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}/windows/zilium.ico")
        set(CPACK_NSIS_MUI_UNIICON "${CMAKE_CURRENT_SOURCE_DIR}/windows/zilium.ico")
    endif()
    
    set(CPACK_NSIS_DISPLAY_NAME "Zilium Super Compactor")
    set(CPACK_NSIS_PACKAGE_NAME "Zilium Super Compactor")
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    set(CPACK_NSIS_MODIFY_PATH ON)
    set(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\\\zilium-gui.exe")
    set(CPACK_NSIS_HELP_LINK "https://github.com/Badmaneers/zilium")
    set(CPACK_NSIS_URL_INFO_ABOUT "https://github.com/Badmaneers/zilium")
    set(CPACK_NSIS_CONTACT "https://t.me/badmaneers")
    
    # Create Start Menu shortcuts
    if(BUILD_GUI AND TARGET zilium-gui)
        set(CPACK_NSIS_CREATE_ICONS_EXTRA
            "CreateShortCut '$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\Zilium Super Compactor.lnk' '$INSTDIR\\\\bin\\\\zilium-gui.exe'"
        )
        set(CPACK_NSIS_DELETE_ICONS_EXTRA
            "Delete '$SMPROGRAMS\\\\$START_MENU\\\\Zilium Super Compactor.lnk'"
        )
    endif()
    
    include(CPack)
endif()
