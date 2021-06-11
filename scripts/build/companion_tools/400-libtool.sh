# Build script for libtool

do_companion_tools_libtool_get()
{
    CT_Fetch LIBTOOL
}

do_companion_tools_libtool_extract()
{
    CT_ExtractPatch LIBTOOL
}

do_companion_tools_libtool_for_build()
{
    CT_DoStep INFO "Installing libtool for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-libtool-build"
    do_libtool_backend \
        host=${CT_BUILD} \
        prefix="${CT_BUILD_COMPTOOLS_DIR}" \
        cflags="${CT_CFLAGS_FOR_BUILD}" \
        ldflags="${CT_LDFLAGS_FOR_BUILD}"
    CT_Popd
    CT_EndStep
}

do_companion_tools_libtool_for_host()
{
    CT_DoStep INFO "Installing libtool for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-libtool-host"
    do_libtool_backend \
        host=${CT_HOST} \
        prefix="${CT_PREFIX_DIR}" \
        cflags="${CT_CFLAGS_FOR_HOST}" \
        ldflags="${CT_LDFLAGS_FOR_HOST}"
    CT_Popd
    CT_EndStep
}

do_libtool_backend()
{
    local host
    local prefix
    local cflags
    local ldflags

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    # Build static executable if toolchain is static
    if [ "${CT_STATIC_TOOLCHAIN}" = "y" ]; then
        ldflags="-static $ldflags"
    fi

    CT_DoLog EXTRA "Configuring libtool"
    CT_DoExecLog CFG \
                     CFLAGS="${cflags}" \
                     LDFLAGS="${ldflags}" \
                      ${CONFIG_SHELL} \
                     "${CT_SRC_DIR}/libtool/configure" \
                     --host="${host}" \
                     --prefix="${prefix}"

    CT_DoLog EXTRA "Building libtool"
    CT_DoExecLog ALL make

    CT_DoLog EXTRA "Installing libtool"
    CT_DoExecLog ALL make install
}
