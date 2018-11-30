cmake_minimum_required(VERSION 2.8)

project(test2)

option(DYNAMIC_DEEPBIND "enable dynamic loading of shared libraries with RTLD_DEEPBIND" OFF)
option(LINK_SYMBOLIC "enable linking with -Bsymbolic" OFF)
option(OBJCOPY_LOCALIZE "enable processing the library with objcopy" OFF)

if (DYNAMIC_DEEPBIND)
    add_compile_definitions(DYNAMIC_DEEPBIND)
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

if (OBJCOPY_LOCALIZE)
    message(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "=${CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS}")
    SET(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "")

    add_library(shared1r SHARED "shared1.cpp")
    target_link_libraries(shared1r PRIVATE static)

    SET_TARGET_PROPERTIES(shared1r PROPERTIES LINK_FLAGS "-Wl,-r -v")

   # SET(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
   # SET(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
   # SET(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "")

    add_library(shared2r SHARED "shared2.cpp")
    target_link_libraries(shared2r PRIVATE static)
    SET_TARGET_PROPERTIES(shared2r PROPERTIES LINK_FLAGS "-r")

    # this doesnt work, since dynamic symbols cannot be changed by objcopy, we must follow https://stackoverflow.com/questions/29391965/what-is-partial-linking-in-gnu-linker

    add_custom_command(TARGET shared1r POST_BUILD
            COMMAND ${CMAKE_OBJCOPY} -v --localize-symbol _Z8RegisterPKc libshared1r.a
            WORKING_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
            COMMENT "Localizing all symbols for libshared1r.a.")
    add_custom_command(TARGET shared2r POST_BUILD
            COMMAND ${CMAKE_OBJCOPY} -v --localize-symbol _Z8RegisterPKc libshared2r.a
            WORKING_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
            COMMENT "Localizing all symbols for libshared2.a.")

        add_library(shared1 SHARED dummy.cpp)
        target_link_libraries(shared1 PRIVATE shared1r)
        add_library(shared2 SHARED dummy.cpp)
        target_link_libraries(shared2 PRIVATE shared2r)

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
if (OBJCOPY_LOCALIZE)
    SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-shared")
endif()

if (DYNAMIC_DEEPBIND)
    target_link_libraries(${PROJECT_NAME} PRIVATE dl)
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE shared1 shared2)
endif()

