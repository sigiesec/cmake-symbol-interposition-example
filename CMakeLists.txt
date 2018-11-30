cmake_minimum_required(VERSION 2.8)

project(test2)

option(DYNAMIC_DEEPBIND "enable dynamic loading of shared libraries with RTLD_DEEPBIND" OFF)
option(LINK_SYMBOLIC "enable linking with -Bsymbolic" OFF)
option(OBJCOPY_LOCALIZE "enable processing the library with objcopy" OFF)

if (DYNAMIC_DEEPBIND)
    add_compile_options(-DDYNAMIC_DEEPBIND)
endif()

add_library(static STATIC "static.cpp" "static.h")
target_link_libraries(static PRIVATE dl)
set_target_properties(static PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
if (LINK_SYMBOLIC)
    target_link_libraries(static PRIVATE "-Wl,-Bsymbolic")
    #target_link_libraries(static PUBLIC "-Xlinker -Bsymbolic")
endif()
#target_compile_options(static PRIVATE -fPIE)
#target_compile_options(static PUBLIC -fno-plt)

function (generate_symbol_list FROM_TARGET)
    add_custom_command(OUTPUT ${FROM_TARGET}.nm
            DEPENDS ${FROM_TARGET}
            COMMAND nm -g --defined-only -B $<TARGET_FILE:${FROM_TARGET}> | cut -d " " -f 3 >${FROM_TARGET}.nm
            WORKING_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
            COMMENT "Generating list of all symbols for $<TARGET_FILE:${FROM_TARGET}>.")
endfunction()

if (OBJCOPY_LOCALIZE)
    generate_symbol_list(static)

    add_library(shared1r OBJECT "shared1.cpp")
    set_target_properties(shared1r PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
    set_target_properties(shared1r PROPERTIES LINK_FLAGS "-v")

    add_custom_command(OUTPUT libshared1i.a
            DEPENDS shared1r static static.nm
            COMMAND ${CMAKE_LINKER} -Ur $<TARGET_OBJECTS:shared1r> $<TARGET_FILE:static> -o libshared1i.a
            COMMAND ${CMAKE_OBJCOPY} -v --localize-symbols static.nm libshared1i.a
            WORKING_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
            COMMENT "Localizing all symbols for libshared1i.a.")

    add_library(shared1i INTERFACE)
    set_target_properties(shared1i PROPERTIES INTERFACE_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/libshared1i.a)
    set_target_properties(shared1i PROPERTIES INTERFACE_LINK_LIBRARIES ${CMAKE_CURRENT_BINARY_DIR}/libshared1i.a)

    add_library(shared1 SHARED dummy.cpp)
    target_link_libraries(shared1 PRIVATE shared1i dl)
    set_target_properties(shared1 PROPERTIES LINK_FLAGS "-v")


    add_library(shared2r OBJECT "shared2.cpp")
    set_target_properties(shared2r PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
    set_target_properties(shared2r PROPERTIES LINK_FLAGS "-v")

    add_custom_command(OUTPUT libshared2i.a
            DEPENDS shared2r static static.nm
            COMMAND ${CMAKE_LINKER} -Ur $<TARGET_OBJECTS:shared2r> $<TARGET_FILE:static> -o libshared2i.a
            COMMAND ${CMAKE_OBJCOPY} -v --localize-symbols static.nm libshared2i.a
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            COMMENT "Localizing all symbols for libshared2i.a.")

    add_library(shared2i INTERFACE)
    set_target_properties(shared2i PROPERTIES INTERFACE_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/libshared2i.a)
    set_target_properties(shared2i PROPERTIES INTERFACE_LINK_LIBRARIES ${CMAKE_CURRENT_BINARY_DIR}/libshared2i.a)

    add_library(shared2 SHARED dummy.cpp)
    target_link_libraries(shared2 PRIVATE shared2i dl)
    set_target_properties(shared2 PROPERTIES LINK_FLAGS "-v")

else ()
    add_library(shared1 SHARED "shared1.cpp")
    target_link_libraries(shared1 PRIVATE static )
    #set_target_properties(shared1 PROPERTIES POSITION_INDEPENDENT_CODE FALSE)
    #target_compile_options(shared1 PRIVATE -fpic)
    add_library(shared2 SHARED "shared2.cpp")
    target_link_libraries(shared2 PRIVATE static )
    #set_target_properties(shared2 PROPERTIES POSITION_INDEPENDENT_CODE FALSE)
    #target_compile_options(shared2 PRIVATE -fpic)
endif()

#SET(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-shared")

add_executable(${PROJECT_NAME} "main.cpp")

if (DYNAMIC_DEEPBIND)
    target_link_libraries(${PROJECT_NAME} PRIVATE dl)
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE shared1 shared2)
endif()

