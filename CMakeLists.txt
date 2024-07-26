
# ---- Minimum Version ----
cmake_minimum_required(VERSION 3.23 FATAL_ERROR)

# ---- Project ----
if (NOT LuaFilesystem_ExternalDependency_Auto_ChainLoadToolchainFilepath STREQUAL "")
    include("${LuaFilesystem_ExternalDependency_Auto_ChainLoadToolchainFilepath}")
endif()

project(
    lua-filesystem-module
    VERSION 0.1.0
    LANGUAGES CXX
)

include(cmake/copy-target-file.cmake)

set(CMAKE_VERBOSE_MAKEFILE TRUE)

# Static libraries will do nothing for us. Build a shared library.
set(BUILD_SHARED_LIBS TRUE)

include(GNUInstallDirs)
include(FetchContent)
include(ExternalProject)
include(CMakeDependentOption)

# ---- Include guards ----

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there.")
endif()

# ---- Find dependencies ----

include(cmake/handle-external-dependencies.cmake)
HandleExternalDependencies()

# ---- Create Library ----

add_library(
    lua-filesystem
    SHARED
    src/filesystem.cpp
)
add_library(lua-filesystem::lua-filesystem ALIAS lua-filesystem)

target_include_directories(
    lua-filesystem
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
)

target_link_libraries(
    lua-filesystem
    PRIVATE
    lua-filesystem::lua-libraries
)

target_compile_features(
    lua-filesystem
    PRIVATE
    cxx_std_17
)

set_target_properties(
    lua-filesystem
    PROPERTIES
    LINKER_LANGUAGE CXX
    POSITION_INDEPENDENT_CODE ON
    PREFIX ""
    OUTPUT_NAME "filesystem"
)

include(GenerateExportHeader)
generate_export_header(
    lua-filesystem
    EXPORT_MACRO_NAME LUA_FILESYSTEM_EXPORT
    NO_EXPORT_MACRO_NAME LUA_FILESYSTEM_NO_EXPORT
    EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/include/lua-filesystem/export/export.hpp"
    INCLUDE_GUARD_NAME LUA_FILESYSTEM_EXPORT_HPP_
)

# ---- Create an installable target ----

# Export my targets
install(
    TARGETS lua-filesystem
    EXPORT lua-filesystem-targets
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(
    EXPORT lua-filesystem-targets
    FILE lua-filesystem-targets.cmake
    NAMESPACE lua-filesystem::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/lua-filesystem"
)

include(CMakePackageConfigHelpers)

# Version file
write_basic_package_version_file(
        "lua-filesystem-config-version.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY ExactVersion
)

# Config file
configure_package_config_file(
    cmake/lua-filesystem-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/lua-filesystem-config.cmake
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/lua-filesystem"
)

install(
    FILES
    "${CMAKE_CURRENT_BINARY_DIR}/lua-filesystem-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/lua-filesystem-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/lua-filesystem"
)

#add_custom_command(
#    TARGET lua-filesystem::lua-filesystem
#    POST_BUILD
#    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:lua-filesystem::lua-filesystem> "${CMAKE_CURRENT_BINARY_DIR}/test"
#    COMMAND_EXPAND_LISTS
#)

# ---- Testing ----

enable_testing()
add_subdirectory(test)
