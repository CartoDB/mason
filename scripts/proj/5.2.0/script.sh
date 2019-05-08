#!/usr/bin/env bash

MASON_NAME=proj
MASON_VERSION=5.2.0
MASON_LIB_FILE=lib/libproj.a
GRID_VERSION="1.8"

. ${MASON_DIR}/mason.sh

function mason_load_source {
    mason_download \
        http://download.osgeo.org/proj/proj-${MASON_VERSION}.tar.gz \
        b69905598b38339f917a3ab28f9d6a939ea986cd

    mason_extract_tar_gz

    export MASON_BUILD_PATH=${MASON_ROOT}/.build/${MASON_NAME}-${MASON_VERSION}
}

function mason_compile {
    curl --retry 3 -f -# -L http://download.osgeo.org/proj/proj-datumgrid-${GRID_VERSION}.zip -o proj-datumgrid-${GRID_VERSION}.zip
    cd nad
    unzip -o ../proj-datumgrid-${GRID_VERSION}.zip
    cd ../

    echo 'AUTOMAKE_OPTIONS = subdir-objects

EXTRA_DIST = CMakeLists.txt

noinst_HEADERS = gtest_include.h

AM_CPPFLAGS = -I$(top_srcdir)/src -I$(top_srcdir)/test -I$(top_srcdir)/test/googletest/include
AM_CXXFLAGS = @CXX_WFLAGS@ @NO_ZERO_AS_NULL_POINTER_CONSTANT_FLAG@

noinst_PROGRAMS = basic_test
noinst_PROGRAMS += pj_phi2_test
noinst_PROGRAMS += proj_errno_string_test

basic_test_SOURCES = basic_test.cpp main.cpp
basic_test_LDADD = ../../src/libproj.la ../../test/googletest/libgtest.la -lpthread

basic_test-check: basic_test
	./basic_test

pj_phi2_test_SOURCES = pj_phi2_test.cpp main.cpp
pj_phi2_test_LDADD = ../../src/libproj.la ../../test/googletest/libgtest.la -lpthread

pj_phi2_test-check: pj_phi2_test
	./pj_phi2_test

proj_errno_string_test_SOURCES = proj_errno_string_test.cpp main.cpp
proj_errno_string_test_LDADD= ../../src/libproj.la ../../test/googletest/libgtest.la -lpthread

proj_errno_string_test-check: proj_errno_string_test
	./proj_errno_string_test

check-local: basic_test-check
check-local: pj_phi2_test-check proj_errno_string_test-check
' > test/unit/Makefile.am

    # note CFLAGS overrides defaults (-g -O2) so we need to add optimization flags back
    ./autogen.sh
    export CFLAGS="${CFLAGS} -O3 -DNDEBUG"
    ./configure --prefix=${MASON_PREFIX} \
    --without-mutex ${MASON_HOST_ARG} \
    --with-jni=no \
    --enable-static \
    --disable-shared \
    --disable-dependency-tracking

    make -j${MASON_CONCURRENCY}
    make install
}

function mason_cflags {
    echo -I${MASON_PREFIX}/include
}

function mason_ldflags {
    echo "-lproj"
}

function mason_clean {
    make clean
}

mason_run "$@"
