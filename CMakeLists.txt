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

if (OBJCOPY_LOCALIZE)
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")
    include(localization)

    generate_symbol_list(static)

    create_localized_shared_lib(shared1 static "shared1.cpp")
    create_localized_shared_lib(shared2 static "shared2.cpp")
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

