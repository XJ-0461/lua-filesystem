
# ---- Minimum Version ----
cmake_minimum_required(VERSION 3.23 FATAL_ERROR)

project(
    lua-filesystem-module-tests
    VERSION 0.1.0
    LANGUAGES CXX
)

if (TARGET lua)
    if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/../cool-vcpkg//vcpkg_installed/cool-vcpkg-custom-triplet/tools/lua/lua)
        add_executable(lua-interpreter IMPORTED)
        add_executable(lua-filesystem::lua-interpreter ALIAS lua-interpreter)
        set_target_properties(
            lua-interpreter
            PROPERTIES
            IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/../cool-vcpkg//vcpkg_installed/cool-vcpkg-custom-triplet/tools/lua/lua"
        )
    endif()
endif()

# Set up testing environment by copying over the testing dependencies

CopyTargetFile(
    TARGET lua-filesystem::lua-filesystem
    DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
)

file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/resources/foo"
    DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/resources/"
)

file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/lib/test.lua"
        "${CMAKE_CURRENT_LIST_DIR}/tests/directory_entry.lua"
        "${CMAKE_CURRENT_LIST_DIR}/tests/directory_iterator.lua"
        "${CMAKE_CURRENT_LIST_DIR}/tests/non_member_functions.lua"
        "${CMAKE_CURRENT_LIST_DIR}/tests/path.lua"
    DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
)

macro(MakeTestSuite)

    set(options)
    set(oneValueArgs LUA_FILENAME)
    set(multiValueArgs TESTS)

    cmake_parse_arguments(
        make_test_suite
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if (NOT make_test_suite_LUA_FILENAME)
        message(FATAL_ERROR "MakeTestSuite: LUA_FILENAME not specified.")
    endif()

    list(LENGTH make_test_suite_TESTS test_count)
    if (test_count EQUAL 0)
        message(FATAL_ERROR "MakeTestSuite: TESTS not specified.")
    endif()

    foreach(test_name IN LISTS make_test_suite_TESTS)
        add_test(
            NAME ${make_test_suite_LUA_FILENAME}-${test_name}-test
            COMMAND $<TARGET_FILE:lua-filesystem::lua-interpreter> ${make_test_suite_LUA_FILENAME}.lua ${test_name}
        )
    endforeach()

endmacro()

MakeTestSuite(
    LUA_FILENAME path
    TESTS
        tostring
        concat
        append
        eq
        lt
        le
        clear
        make_preferred
        remove_filename
        replace_filename
        replace_extension
        root_name
        root_directory
        root_path
        relative_path
        parent_path
        filename
        stem
        extension
        empty
        has_root_path
        has_root_directory
        has_relative_path
        has_parent_path
        has_filename
        has_stem
        has_extension
        is_absolute
        is_relative
        lexically_normal
        lexically_relative
        lexically_proximate
        elements
)

MakeTestSuite(
    LUA_FILENAME non_member_functions
    TESTS
        absolute
        canonical
        weakly_canonical
        relative
        proximate
        copy
        copy_file
        create_copy_read_symlink_status
        create_directory
        create_directories_remove_all
        create_hard_link_and_count
        create_directory_symlink
        current_path
        equivalent
        file_size_resize
#        permissions
        status_permissions
        rename
        space
        temp_directory_path
        last_write_time
        file_time
        file_time_now
        file_time_duration
        is_xyz
        enum_binary_operators
)

MakeTestSuite(
    LUA_FILENAME directory_entry
    TESTS
        assign
        replace_filename
        refresh_exists
        path
        is_xyz
        file_size
        hard_link_count
        last_write_time
        status
        symlink_status
)

MakeTestSuite(
    LUA_FILENAME directory_iterator
    TESTS
        directory_iterator
        directory_iterator_with_options
        recursive_directory_iterator
)
