function (make_valid_filename FROM_STRING OUT_NAME)
    string(REPLACE "::" "_" NAME "${FROM_STRING}")
    set(${OUT_NAME} ${NAME} PARENT_SCOPE)
endfunction()

function (generate_symbol_list FROM_TARGET)
    if (NOT MSVC)
        make_valid_filename(${FROM_TARGET} FROM_TARGET_FILENAME)
        add_custom_command(OUTPUT ${FROM_TARGET_FILENAME}.nm
                DEPENDS ${FROM_TARGET}
                COMMAND nm -g --defined-only -B $<TARGET_FILE:${FROM_TARGET}> | cut -d " " -f 3 | grep -v "gxx_personality" >${FROM_TARGET_FILENAME}.nm
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Generating list of all symbols for $<TARGET_FILE:${FROM_TARGET}>.")

        add_custom_target(
                ${FROM_TARGET_FILENAME}_nm
                DEPENDS
                    ${FROM_TARGET_FILENAME}.nm)
    endif()
endfunction()

function (create_localized_shared_lib TARGET TYPE DEP_LOCALIZE OUT_SRC_TARGET_VAR)
    if (MSVC)
        add_library(${TARGET} ${TYPE})
        set(${OUT_SRC_TARGET_VAR} ${TARGET} PARENT_SCOPE)
    else ()
        set(${OUT_SRC_TARGET_VAR} ${TARGET}r PARENT_SCOPE)

        add_library(${TARGET}r OBJECT)
        set_target_properties(${TARGET}r PROPERTIES POSITION_INDEPENDENT_CODE TRUE)

        make_valid_filename(${DEP_LOCALIZE} DEP_LOCALIZE_FILENAME)
        add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET}i.a
                DEPENDS ${TARGET}r ${DEP_LOCALIZE} ${DEP_LOCALIZE_FILENAME}_nm
                COMMAND ${CMAKE_LINKER} -Ur --whole-archive $<TARGET_OBJECTS:${TARGET}r> --no-whole-archive $<TARGET_FILE:${DEP_LOCALIZE}> -o lib${TARGET}i.a
                COMMAND ${CMAKE_OBJCOPY} -v --localize-symbols ${CMAKE_BINARY_DIR}/${DEP_LOCALIZE_FILENAME}.nm lib${TARGET}i.a
                COMMAND_EXPAND_LISTS
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Localizing all symbols from ${DEP_LOCALIZE} in lib${TARGET}i.a.")
        add_custom_target(${TARGET}it DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET}i.a)

        add_library(${TARGET}i STATIC IMPORTED)
        add_dependencies(${TARGET}i PRIVATE ${TARGET}it)
        target_link_libraries(${TARGET}i INTERFACE $<TARGET_PROPERTY:${TARGET}r,LINK_LIBRARIES>)
        set_target_properties(${TARGET}i PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET}i.a)

        file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/dummy.cpp "")

        add_library(${TARGET} ${TYPE})
        target_sources(${TARGET} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/dummy.cpp)
        # TODO shouldn't this be INTERFACE_LINK_LIBRARIES?
        target_link_libraries(${TARGET} PRIVATE ${TARGET}i $<TARGET_PROPERTY:${DEP_LOCALIZE},LINK_LIBRARIES>  )
    endif()
endfunction()
