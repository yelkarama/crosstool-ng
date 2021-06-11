# Build script for ltrace

do_debug_ltrace_get() {
    CT_Fetch LTRACE
}

do_debug_ltrace_extract() {
    CT_ExtractPatch LTRACE
}

do_debug_ltrace_build() {
    local ltrace_host
    local cflags="${CT_TARGET_CFLAGS}"
    local ldflags="${CT_TARGET_LDFLAGS}"

    CT_DoStep INFO "Installing ltrace"

    CT_DoLog EXTRA "Copying sources to build dir"
    CT_DoExecLog ALL cp -av "${CT_SRC_DIR}/ltrace/." \
                            "${CT_BUILD_DIR}/build-ltrace"
    CT_Pushd "${CT_BUILD_DIR}/build-ltrace"

    # Build static executable if toolchain is static
    if [ "${CT_STATIC_TOOLCHAIN}" = "y" ]; then
        ldflags="-static $ldflags"
    fi

    # autoreconf required after patches
    CT_DoLog DEBUG "Running autoreconf"
    CT_DoExecLog ALL autoreconf -fvi

    CT_DoLog EXTRA "Configuring ltrace"
    CT_DoExecLog CFG        \
    ${CONFIG_SHELL}         \
    ./configure             \
        --build=${CT_BUILD} \
        --host=${CT_TARGET} \
        --prefix=/usr

    CT_DoLog EXTRA "Building ltrace"
    CT_DoExecLog ALL make ${CT_JOBSFLAGS}

    CT_DoLog EXTRA "Installing ltrace"
    CT_DoExecLog ALL make DESTDIR="${CT_DEBUGROOT_DIR}" install

    CT_Popd
    CT_EndStep
}
