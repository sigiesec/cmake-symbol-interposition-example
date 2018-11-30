#!/bin/sh

build_with_option () {
	OPTION=$1
        DIRNAME=build-${OPTION}
	if [ ! -d ${DIRNAME} ] ; then mkdir ${DIRNAME} ; fi
	cd ${DIRNAME}
	if [ -f CMakeCache.txt ] ; then rm CMakeCache.txt ; fi
	cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON -D${OPTION}=ON
	cmake --build .
	./test2
	cd ..
}

build_with_option DYNAMIC_DEEPBIND
build_with_option LINK_SYMBOLIC
#build_with_option OBJCOPY_LOCALIZE
