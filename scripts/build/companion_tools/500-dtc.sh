# Build script for DTC (device tree compiler)

do_companion_tools_dtc_get()
{
    CT_Fetch DTC
}

do_companion_tools_dtc_extract()
{
    CT_ExtractPatch DTC
}

do_companion_tools_dtc_for_build()
{
    CT_DoStep INFO "Installing dtc for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-dtc-build"
    do_dtc_backend \
        host=${CT_BUILD} \
        prefix="${CT_BUILD_COMPTOOLS_DIR}" \
        cflags="${CT_CFLAGS_FOR_BUILD}" \
        ldflags="${CT_LDFLAGS_FOR_BUILD}"
    CT_Popd
    CT_EndStep
}

do_companion_tools_dtc_for_host()
{
    CT_DoStep INFO "Installing dtc for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-dtc-host"
    do_dtc_backend \
        host=${CT_HOST} \
        prefix="${CT_PREFIX_DIR}" \
        cflags="${CT_CFLAGS_FOR_HOST}" \
        ldflags="${CT_LDFLAGS_FOR_HOST}"
    CT_Popd
    CT_EndStep
}

do_dtc_backend()
{
    local host
    local prefix
    local cflags
    local ldflags
    local -a extra_opts

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    # Build static executable if toolchain is static
    if [ "${CT_STATIC_TOOLCHAIN}" = "y" ]; then
        ldflags="-static $ldflags"
    fi

    # Override PKG_CONFIG: if pkg-config is not installed, DTC's makefile
    # misinterprets the error code and tries to enable YAML support while
    # not linking against libyaml. NO_YAML=1 is sufficient to make the build
    # pass; PKG_CONFIG=/bin/true just suppresses some scary error messages.
    extra_opts=( \
        CC="${host}-gcc" \
        AR="${host}-ar" \
        PREFIX="${prefix}" \
        LDFLAGS="${ldflags}" \
        PKG_CONFIG=/bin/true \
        NO_PYTHON=1 \
        NO_YAML=1 \
        BIN=dtc \
        )
    if [ -n "${CT_DTC_VERBOSE}" ]; then
        extra_opts+=( V=1 )
    fi
    case "${host}" in
    *-mingw32)
        # Turn off warnings: mingw32 hosts complain about %zd formats even though
        # they seem to be supported by mingw32. Only build 'dtc', again, because
        # other binaries use syscalls not available under mingw32, but we also
        # do not need them. Hijack WARNINGS to override lstat with stat (Windows
        # does not have symlinks).
        extra_opts+=( BIN=dtc WARNINGS=-Dlstat=stat )
        ;;
    esac

    CT_DoExecLog ALL cp -av "${CT_SRC_DIR}/dtc/." .

    # Modify Makefile to only build dtc
    sed -i 's/install-bin: all/install-bin: dtc/g' Makefile

    CT_DoLog EXTRA "Building dtc"
    CT_DoExecLog ALL make dtc ${CT_JOBSFLAGS} "${extra_opts[@]}"

    # Only install binaries, we don't support shared libraries in installation
    # directory yet.
    CT_DoLog EXTRA "Installing dtc"
    CT_DoExecLog ALL make install-bin "${extra_opts[@]}"
}
