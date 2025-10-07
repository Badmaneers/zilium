# Windows-specific CMake configuration for Zilium
# This file contains Windows-specific settings and adjustments

if(WIN32)
    # Set Windows-specific compiler flags
    if(MSVC)
        # Enable parallel compilation
        add_compile_options(/MP)
        
        # Set warning level
        add_compile_options(/W3)
        
        # Enable standards-conforming compiler behavior
        add_compile_options(/permissive-)
        
        # Disable specific warnings
        add_compile_options(
            /wd4251  # needs to have dll-interface
            /wd4275  # non dll-interface class used as base
        )
        
        # Set runtime library
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
        
        # Enable Unicode
        add_definitions(-DUNICODE -D_UNICODE)
    endif()
    
    # Windows-specific definitions
    add_definitions(
        -DWIN32_LEAN_AND_MEAN
        -DNOMINMAX
        -D_CRT_SECURE_NO_WARNINGS
    )
    
    # Set executable icon and version info (if building GUI)
    if(BUILD_GUI)
        set(WINDOWS_RC_FILE "${CMAKE_CURRENT_LIST_DIR}/zilium.rc")
        
        if(EXISTS ${WINDOWS_RC_FILE})
            target_sources(zilium-gui PRIVATE ${WINDOWS_RC_FILE})
        endif()
    endif()
    
    # Set console/GUI subsystem
    if(BUILD_GUI)
        # GUI application - no console window
        set_target_properties(zilium-gui PROPERTIES
            WIN32_EXECUTABLE TRUE
        )
    else()
        # CLI application - console window
        set_target_properties(zilium-super-compactor PROPERTIES
            WIN32_EXECUTABLE FALSE
        )
    endif()
    
    # Install configuration
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        # Install executables
        install(TARGETS zilium-super-compactor
                RUNTIME DESTINATION bin)
        
        if(BUILD_GUI)
            install(TARGETS zilium-gui
                    RUNTIME DESTINATION bin)
        endif()
        
        # Install LP tools if available
        if(EXISTS "${CMAKE_SOURCE_DIR}/lpunpack_and_lpmake/windows")
            install(DIRECTORY "${CMAKE_SOURCE_DIR}/lpunpack_and_lpmake/windows/"
                    DESTINATION lptools
                    FILES_MATCHING PATTERN "*.exe")
        endif()
        
        # Install documentation
        install(FILES 
                "${CMAKE_SOURCE_DIR}/README.md"
                "${CMAKE_SOURCE_DIR}/LICENSE"
                DESTINATION .)
        
        install(DIRECTORY "${CMAKE_SOURCE_DIR}/docs"
                DESTINATION docs)
        
        # Qt deployment will be handled by windeployqt in build script
    endif()
    
    # CPack configuration for Windows
    set(CPACK_GENERATOR "ZIP;NSIS")
    set(CPACK_PACKAGE_NAME "Zilium")
    set(CPACK_PACKAGE_VENDOR "Badmaneers")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Zilium Super Compactor - Android Super Partition Tool")
    set(CPACK_PACKAGE_VERSION "1.0.0")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "Zilium")
    
    # NSIS-specific settings
    set(CPACK_NSIS_DISPLAY_NAME "Zilium Super Compactor")
    set(CPACK_NSIS_PACKAGE_NAME "Zilium Super Compactor")
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    set(CPACK_NSIS_MODIFY_PATH ON)
    set(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_LIST_DIR}/zilium.ico")
    set(CPACK_NSIS_MUI_UNIICON "${CMAKE_CURRENT_LIST_DIR}/zilium.ico")
    set(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\\\zilium-gui.exe")
    set(CPACK_NSIS_HELP_LINK "https://github.com/Badmaneers/zilium")
    set(CPACK_NSIS_URL_INFO_ABOUT "https://github.com/Badmaneers/zilium")
    set(CPACK_NSIS_CONTACT "https://t.me/badmaneers")
    
    # Create Start Menu shortcuts
    set(CPACK_NSIS_CREATE_ICONS_EXTRA
        "CreateShortCut '$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\Zilium Super Compactor.lnk' '$INSTDIR\\\\bin\\\\zilium-gui.exe'"
    )
    set(CPACK_NSIS_DELETE_ICONS_EXTRA
        "Delete '$SMPROGRAMS\\\\$START_MENU\\\\Zilium Super Compactor.lnk'"
    )
    
    include(CPack)
endif()
