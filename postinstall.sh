#!/bin/sh
#
# /etc/postinstall/<package>.sh -- Custom installation steps
#
# -- NOTE: This script will be run under /bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/X11R6/bin:$PATH

set -e

Environment()
{
    #  Define variables to the rest of the script

    dest=${1:-""}           # install destination

    if [ "$dest" ]; then
        #  Delete trailing slash
        dest=$(echo $dest | sed -e 's,/$,,' )
    fi

    package="geoip"

    #   This file will be installed as
    #   /etc/postinstall/<package>.sh so derive <package>
    #   But if this file is run from CYGIN-PATCHES/postinstall.sh
    #   then we do not know the package name

    name=$(echo $0 | sed -e 's,.*/,,' -e 's,\.sh,,' )

    if [ "$name" != "postinstall" ]; then
        package="$name"
    fi

    bindir="$dest/usr/bin"
    libdir="$dest/usr/lib"
    libdirx11="$dest/usr/lib/X11"
    includedir="$dest/usr/include"

    sharedir="$dest/usr/share"
    infodir="$sharedir/info"
    docdir="$sharedir/doc"
    etcdir="$dest/etc"

    #   1) list of files to be copied to /etc
    #   2) Source locations

    conffiles_to="$etcdir/preremove/$package-manifest.lst"
    conffiles_from="$etcdir/preremove/$package-manifest-from.lst"
}

Warn ()
{
    echo "$@" >&2
}

Run ()
{
    ${test+echo} "$@"
}

InstallConffiles ()
{
    [ ! -f $conffiles_to ] && return

    #  Install default configuration files for system wide

    latest=$(LC_ALL=C find $dest/usr/share/doc/$package*/ -maxdepth 0 -type d \
             | sort | tail -1 | sed 's,/$,,')

    if [ ! "$latest" ]; then
        Warn "$0: [FATAL]] Cannot find $package install doc dir"
        exit 1
    fi

    [ ! -f $conffiles_from ] && return
    [ ! -f $conffiles_to   ] && return

    paste $conffiles_from $conffiles_to  |
    {
        while read from to
        do
            from=$(echo $from | sed "s,\$PKGDOCDIR,$pkgdocdir$latest," )
            to=$(echo $dest$to | sed "s,\$PKG,$pkgdocdir," )

            [ ! -f $to ] && Run install -m 0644 $from $to
        done
    }
}

Main()
{
    Environment "$@"    &&
    InstallConffiles
}

Main "$@"

# End of file
