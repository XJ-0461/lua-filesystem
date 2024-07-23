
function(CopyTargetFile)

    set(options)
    set(oneValueArgs TARGET DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(copy_target_file "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT copy_target_file_TARGET)
        message(FATAL_ERROR "CopyTargetFile: TARGET not specified.")
    endif()

    if (NOT copy_target_file_DESTINATION)
        message(FATAL_ERROR "CopyTargetFile: DESTINATION not specified.")
    endif()

    get_target_property(target_output_name ${copy_target_file_TARGET} OUTPUT_NAME)

    add_custom_target(
        copy_target_file_${target_output_name}
        ALL
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${copy_target_file_TARGET}> ${copy_target_file_DESTINATION}
    )

    add_dependencies(
        copy_target_file_${target_output_name}
        ${copy_target_file_TARGET}
    )

endfunction()