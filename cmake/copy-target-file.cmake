
# Hacky thing to use target details to get around TARGET was not created in this directory issues

set(copy_target_thing_meta_counter 0)

# CopyTargetSomething(
#     COMMAND_NAME <name>
#     SOURCE <TARGET | VARIABLE>
#     DESTINATION <TARGET | VARIABLE>
# )
# where TARGET -> PROPERTY INPUT_TARGET
# where VARIABLE -> INPUT_VARIABLE

# PROPERTY can be like TARGET_RUNTIME_DLLS or TARGET_FILE or whatever

# The auto generated command name is so cryptic to try to avoid Windows path length issues
function(CopyTargetThing)

    set(oneValueArgs COMMAND_NAME)
    set(multiValueArgs SOURCE DESTINATION)
    cmake_parse_arguments(copy_target "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT copy_target_SOURCE)
        message(FATAL_ERROR "CopyTargetThing(SOURCE) must be specified.")
    endif()

    if (NOT copy_target_DESTINATION)
        message(FATAL_ERROR "CopyTargetThing(DESTINATION) must be specified.")
    endif()

    set(multiValueArgs TARGET VARIABLE)
    cmake_parse_arguments(source_args "" "" "${multiValueArgs}" ${copy_target_SOURCE})
    cmake_parse_arguments(destination_args "" "" "${multiValueArgs}" ${copy_target_DESTINATION})

    if (NOT source_args_TARGET AND NOT source_args_VARIABLE)
        message(FATAL_ERROR "CopyTargetThing(SOURCE) must specify either TARGET or VARIABLE.")
    endif()

    if (NOT destination_args_TARGET AND NOT destination_args_VARIABLE)
        message(FATAL_ERROR "CopyTargetThing(DESTINATION) must specify either TARGET or VARIABLE.")
    endif()

    set(source)
    set(destination)
    set(meta_command_name "CTT_")

    set(oneValueArgs PROPERTY INPUT_TARGET INPUT_VARIABLE)
    if (source_args_TARGET)
        cmake_parse_arguments(source_args "" "${oneValueArgs}" "" ${source_args_TARGET})
        if (NOT source_args_PROPERTY)
            message(FATAL_ERROR "CopyTargetThing(SOURCE TARGET) must specify PROPERTY.")
        endif()
        if (NOT source_args_INPUT_TARGET)
            message(FATAL_ERROR "CopyTargetThing(SOURCE TARGET) must specify INPUT_TARGET.")
        endif()
        set(source "$<${source_args_PROPERTY}:${source_args_INPUT_TARGET}>")
        get_target_property(source_output_name ${source_args_INPUT_TARGET} OUTPUT_NAME)
        string(APPEND meta_command_name "T_${source_output_name}_")
    else()
        cmake_parse_arguments(source_args "" "${oneValueArgs}" "" ${source_args_VARIABLE})
        if (NOT source_args_INPUT_VARIABLE)
            message(FATAL_ERROR "CopyTargetThing(SOURCE VARIABLE) must specify INPUT_VARIABLE.")
        endif()
        set(source "${source_args_VARIABLE}")
        string(APPEND meta_command_name "V_${source_args_VARIABLE}_")
    endif()

    if (destination_args_TARGET)
        cmake_parse_arguments(destination_args "" "${oneValueArgs}" "" ${destination_args_TARGET})
        if (NOT destination_args_PROPERTY)
            message(FATAL_ERROR "CopyTargetThing(DESTINATION TARGET) must specify PROPERTY.")
        endif()
        if (NOT destination_args_INPUT_TARGET)
            message(FATAL_ERROR "CopyTargetThing(DESTINATION TARGET) must specify INPUT_TARGET.")
        endif()
        set(destination "$<${destination_args_PROPERTY}:${destination_args_INPUT_TARGET}>")
        get_target_property(destination_output_name ${destination_args_INPUT_TARGET} OUTPUT_NAME)
        string(APPEND meta_command_name "T_${destination_output_name}")
    else()
        cmake_parse_arguments(destination_args "" "${oneValueArgs}" "" ${destination_args_VARIABLE})
        if (NOT destination_args_INPUT_VARIABLE)
            message(FATAL_ERROR "CopyTargetThing(DESTINATION VARIABLE) must specify INPUT_VARIABLE.")
        endif()
        set(destination "${${destination_args_INPUT_VARIABLE}}")
        string(APPEND meta_command_name "V_${destination_args_INPUT_VARIABLE}")
    endif()

    if (copy_target_COMMAND_NAME)
        set(meta_command_name "${copy_target_COMMAND_NAME}")
    else() # finish up generating the command name
        string(APPEND meta_command_name "_${copy_target_thing_meta_counter}")
        math(EXPR copy_target_thing_meta_counter "${copy_target_thing_meta_counter} + 1")
        set(copy_target_thing_meta_counter ${copy_target_thing_meta_counter} PARENT_SCOPE)
    endif()

    message(DEBUG "CopyTargetThing() - source: ${source}")
    message(DEBUG "CopyTargetThing() - destination: ${destination}")
    message(DEBUG "CopyTargetThing() - meta_command_name: ${meta_command_name}")

    add_custom_target(
        "${meta_command_name}"
        ALL
        COMMAND ${CMAKE_COMMAND} -E copy ${source} ${destination}
    )

    add_dependencies(
        "${meta_command_name}"
        ${source_args_INPUT_TARGET}
    )

endfunction()
