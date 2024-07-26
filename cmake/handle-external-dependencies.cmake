
# List of variables that can be set to control the behavior of this script.
# I tried to help users fall into the pit of success. The CMakePresets supplied with this project should make it trivial
# to build. Users are strongly recommended to use a preset or otherwise automatically fetch dependencies, which is
# driven by vcpkg and is very reliable.

# However, sometimes there are reasons to manually specify which dependencies to use.
# For example: This project links against a Lua library "liblua.*" but if the project you need to integrate this with is
# using a custom lua library named "liblua53.*", then we can use the manual setup to specify that.

# The "Manual" variables will take precedence over the "Auto" variables, to make it easy to achieve custom behavior
# as needed.
# The "Auto" mechanism uses cool-vcpkg to fetch, build, and install the dependencies locally.

# LuaFilesystem_ExternalDependency_Auto_DefaultTriplet - STRING
# LuaFilesystem_ExternalDependency_Auto_ChainLoadToolchainFilepath - FILEPATH
# LuaFilesystem_ExternalDependency_Auto_GitTag - STRING

# LuaFilesystem_ExternalDependency_lua_Manual_UseFindPackage - BOOL
# LuaFilesystem_ExternalDependency_lua_Manual_Library - list<FILEPATH>
# LuaFilesystem_ExternalDependency_lua_Manual_IncludeDirectories - list<PATH>
# LuaFilesystem_ExternalDependency_lua_Manual_LinkLibraries - list<FILEPATH>
# LuaFilesystem_ExternalDependency_lua_Manual_Interpreter - FILEPATH

# LuaFilesystem_ExternalDependency_lua_Auto_Fetch - BOOL
# LuaFilesystem_ExternalDependency_lua_Auto_Version - VERSION
# LuaFilesystem_ExternalDependency_lua_Auto_LibraryLinkage - STRING[SHARED|STATIC]
# LuaFilesystem_ExternalDependency_lua_Auto_Features - list<STRING>

# Helper method to check if a manual external dependency is being used, to make it easier to override auto setup.
macro(IsUsingManualExternalDependencies)

    set(oneValueArgs PACKAGE_NAME RESULT_VARIABLE)
    cmake_parse_arguments(check_manual "" "${oneValueArgs}" "" ${ARGN})

    if (NOT DEFINED check_manual_PACKAGE_NAME)
        message(FATAL_ERROR "IsUsingManualExternalDependencies(PACKAGE_NAME) must be set.")
    endif()

    if (NOT DEFINED check_manual_RESULT_VARIABLE)
        message(FATAL_ERROR "IsUsingManualExternalDependencies(RESULT_VARIABLE) must be set.")
    endif()

    if (LuaFilesystem_ExternalDependency_${check_manual_PACKAGE_NAME}_Manual_UseFindPackage
        OR LuaFilesystem_ExternalDependency_${check_manual_PACKAGE_NAME}_Manual_Library
        OR LuaFilesystem_ExternalDependency_${check_manual_PACKAGE_NAME}_Manual_IncludeDirectories
        OR LuaFilesystem_ExternalDependency_${check_manual_PACKAGE_NAME}_Manual_LinkLibraries
        OR LuaFilesystem_ExternalDependency_${check_manual_PACKAGE_NAME}_Manual_Interpreter)
        set(${check_manual_RESULT_VARIABLE} TRUE)
    else()
        set(${check_manual_RESULT_VARIABLE} FALSE)
    endif()

endmacro()

# This macro will handle setup of dependencies for the project. Namely lua.
# If desired, we can use cool-vcpkg to handle the installation of lua.
macro(HandleExternalDependencies)

    set(setup_cool_vcpkg FALSE)

    if (LuaFilesystem_ExternalDependency_lua_Auto_Fetch)
        set(setup_cool_vcpkg TRUE)
    endif()

    IsUsingManualExternalDependencies(PACKAGE_NAME lua RESULT_VARIABLE is_using_manual_lua)

    # Auto setup section
    if (setup_cool_vcpkg)

        message(STATUS "Fetching external dependencies with cool-vcpkg.")

        if (NOT DEFINED LuaFilesystem_ExternalDependency_Auto_DefaultTriplet
            OR LuaFilesystem_ExternalDependency_Auto_DefaultTriplet STREQUAL "")
            message(FATAL_ERROR "LuaFilesystem_ExternalDependency_Auto_DefaultTriplet must be set.")
        endif()

        include(FetchContent)
        FetchContent_Declare(
            cool_vcpkg_latest
            GIT_REPOSITORY https://github.com/XJ-0461/cool-vcpkg.git
            GIT_TAG v0.1.2 #"${LuaFilesystem_ExternalDependency_Auto_GitTag}"
            SOURCE_SUBDIR automatic-setup
        )
        FetchContent_MakeAvailable(cool_vcpkg_latest)

        include(CoolVcpkg)
        cool_vcpkg_SetUpVcpkg(
            DEFAULT_TRIPLET ${LuaFilesystem_ExternalDependency_Auto_DefaultTriplet}
            ROOT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/../external/cool-vcpkg/"
            CHAIN_LOAD_TOOLCHAIN ${LuaFilesystem_ExternalDependency_Auto_ChainLoadToolchainFilepath}
            OVERLAY_PORT_LOCATIONS ${CMAKE_CURRENT_LIST_DIR}/myport/lua_5_3_5_7 # todo
        )

        if (LuaFilesystem_ExternalDependency_lua_Auto_Fetch AND NOT is_using_manual_lua)
            cool_vcpkg_DeclarePackage(
                NAME lua
                VERSION "${LuaFilesystem_ExternalDependency_lua_Auto_Version}"
                LIBRARY_LINKAGE ${LuaFilesystem_ExternalDependency_lua_Auto_LibraryLinkage}
                FEATURES "${LuaFilesystem_ExternalDependency_lua_Auto_Features}"
            )
        endif()

        cool_vcpkg_InstallPackages()

        if (LuaFilesystem_ExternalDependency_lua_Auto_Fetch AND NOT is_using_manual_lua)
            find_package(unofficial-lua CONFIG REQUIRED)
        endif()

    endif()

    # Manual setup section
    if (LuaFilesystem_ExternalDependency_lua_Manual_UseFindPackage)
        find_package(Lua REQUIRED)
    endif()

    # Normalize lua targets for our project
    # Our project will use:
    # lua-filesystem::lua-libraries
    # lua-filesystem::lua-interpreter

    if (NOT "${LuaFilesystem_ExternalDependency_lua_Manual_LinkLibraries}" STREQUAL "")
        add_library(lua-filesystem::lua-libraries SHARED IMPORTED)
        set_target_properties(
            lua-filesystem::lua-libraries
            PROPERTIES
            IMPORTED_LOCATION "${LuaFilesystem_ExternalDependency_lua_Manual_Library}"
            INTERFACE_INCLUDE_DIRECTORIES "${LuaFilesystem_ExternalDependency_lua_Manual_IncludeDirectories}"
        )
        message(STATUS "Lua libraries imported from ${LuaFilesystem_ExternalDependency_lua_Manual_LinkLibraries}")
        message(STATUS "Lua include directories are ${LuaFilesystem_ExternalDependency_lua_Manual_IncludeDirectories}")
    elseif (TARGET unofficial::lua::lua)
        add_library(lua-filesystem::lua-libraries ALIAS unofficial::lua::lua)
    endif()

    if (NOT "${LuaFilesystem_ExternalDependency_lua_Manual_Interpreter}" STREQUAL "")
        add_executable(lua-filesystem::lua-interpreter IMPORTED)
        set_target_properties(lua-filesystem::lua-interpreter PROPERTIES
            IMPORTED_LOCATION "${LuaFilesystem_ExternalDependency_lua_Manual_Interpreter}"
        )
        message(STATUS "Lua interpreter imported from ${LuaFilesystem_ExternalDependency_lua_Manual_Interpreter}")
    elseif (TARGET unofficial::lua::lua-interpreter)
        add_executable(lua-filesystem::lua-interpreter ALIAS unofficial::lua::lua-interpreter)
    endif()

endmacro()
