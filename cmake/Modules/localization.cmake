function (generate_symbol_list FROM_TARGET)
    add_custom_command(OUTPUT ${FROM_TARGET}.nm
            DEPENDS ${FROM_TARGET}
            COMMAND nm -g --defined-only -B $<TARGET_FILE:${FROM_TARGET}> | cut -d " " -f 3 >${FROM_TARGET}.nm
            WORKING_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
            COMMENT "Generating list of all symbols for $<TARGET_FILE:${FROM_TARGET}>.")
endfunction()

function (create_localized_shared_lib TARGET DEP_LOCALIZE SOURCES)
    add_library(${TARGET}r OBJECT ${SOURCES})
    set_target_properties(${TARGET}r PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
    set_target_properties(${TARGET}r PROPERTIES LINK_FLAGS "-v")

    add_custom_command(OUTPUT lib${TARGET}i.a
            DEPENDS ${TARGET}r ${DEP_LOCALIZE} ${DEP_LOCALIZE}.nm
            COMMAND ${CMAKE_LINKER} -Ur $<TARGET_OBJECTS:${TARGET}r> $<TARGET_FILE:${DEP_LOCALIZE}> -o lib${TARGET}i.a
            COMMAND ${CMAKE_OBJCOPY} -v --localize-symbols ${DEP_LOCALIZE}.nm lib${TARGET}i.a
            WORKING_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
            COMMENT "Localizing all symbols from ${DEP_LOCALIZE} in lib${TARGET}i.a.")

    add_library(${TARGET}i INTERFACE)
    set_target_properties(${TARGET}i PROPERTIES INTERFACE_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET}i.a)
    set_target_properties(${TARGET}i PROPERTIES INTERFACE_LINK_LIBRARIES ${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET}i.a)

    add_library(${TARGET} SHARED dummy.cpp)
    target_link_libraries(${TARGET} PRIVATE ${TARGET}i $<TARGET_PROPERTY:${DEP_LOCALIZE},LINK_LIBRARIES>)
    set_target_properties(${TARGET} PROPERTIES LINK_FLAGS "-v")
endfunction()
