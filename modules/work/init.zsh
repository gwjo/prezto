## Some development related stuff
##
## Only run on work machines
[[ $HOSTNAME[1,4] != "acme" ]] && return

## {{{ Fix various things on my development machine

[[ -e $HOME/.man.config ]] && alias man="nocorrect man -C $HOME/.man.config" || alias man="nocorrect man"

## }}}
## {{{ update tags and cscopte

function uptags() {

    local ccviewtop=`ccbase`

    if [[ -z ${ccviewtop} ]] ; then
        echo "Not in a clearcase view!"
        return
    fi

    print -rC1 ${ccviewtop}/**/*.[ch](|pp) > ${ccviewtop}/cscope.files

    #/usr/bin/cscope -b -i $ccviewtop/cscope.files -f $ccviewtop/cscope.out
    /usr/bin/ctags -L $ccviewtop/cscope.files --extra=+q -o $ccviewtop/tags
}

## }}}

## {{{ change to directory based on SD stream
#
# Usage:
#
#  sd_cd <SD2 dir> <SD4 dir>
#
function sd_cd() {

    local cc_base=`/usr/local/acme/bin/ccbase`

    if [[ -z ${cc_base} ]] ; then
        echo "Not in a clearcase view"
        return
    fi

    if [[ -d ${cc_base}/$1 ]] ; then
        cd ${cc_base}/$1
    else
        cd ${cc_base}/$2
    fi
}

## }}}
## {{{ change to a acme directory

function acme_cd() {
    sd_cd acme/$1 sd_iv/acme/$2
}

## }}}
## {{{ change to an app directory
function app_cd() {
    acme_cd bin/$1 apps/$1
}

## }}}
## {{{ alias to move around the code base

alias base='sd_cd . .'
alias acme='acme_cd . .'
alias apps='app_cd .'
alias bin='app_cd .'
alias inc='acme_cd include/acme include'

alias acli='app_cd acli'
alias algd='app_cd algd'   # sd2 only
alias atcp='app_cd atcp'
alias collect='app_cd collect'
alias h248='app_cd h248'
alias h323='app_cd h323'
alias lem='app_cd lem'
alias mbcd='app_cd mbcd'
alias mgcp='app_cd algd'   # use this instead of algd (sd2 only)
alias sip='app_cd sip'

alias account='acme_cd lib/accounting lib/accounting'
alias common='acme_cd lib/common lib/common'
alias dam='acme_cd lib/dam lib/dam'
alias sig='acme_cd lib/sig lib/sig' # sd4 only

## }}}
## {{{ rebase and build an stream
#
# Usage:
#
#  rebase [make]
#  rebase <view> [make]
#
function rebase() {

    local do_make
    local cc_view
    local cc_base

    ## see if the first parameter is a view
    if [[ -n $1 && $1 != "make" ]] ; then
        cc_view=$1
        shift
    fi

    ## check for make option
    if [[ -n $1 && $1 == "make" ]] ; then
        do_make="true"
    fi

    # change to speficied view
    if [[ -n $cc_view ]] ; then
        sv $cc_view
    fi

    cc_base=$(/usr/local/acme/bin/ccbase)
    if [[ -z $cc_base ]] ; then
        echo "Not in a view"
        return
    fi

    /usr/local/acme/bin/ccrebase -latest
    /usr/local/acme/bin/ccrebase -complete

    if [[ -n $do_make ]] ; then
        sdmake
    fi
}

## }}}
## {{{ Application launch aliases

alias wireshark='wireshark -a filesize:102400'

alias uas='sipp -bind_local -i 192.168.138.210 -sf '
alias uac='sipp -bind_local -i 192.168.140.210 192.168.140.211 -sf '

alias rsh='/usr/bin/rsh'
alias rcp='/usr/bin/rcp'

## }}}
## {{{ set CCBASE environment variable

function cc_set_ccbase() {
    local base=`/usr/local/acme/bin/ccbase`

    CC_BASE=""
    if [[ "x$base" != "x" ]] ; then
        if [[ -d $base/sd_iv ]] ; then
            CC_BASE=$base/sd_iv
        else
            CC_BASE=$base
        fi
    elif [[ "x$CC_BASE" = "x" ]] ; then
        echo "**********************************"
        echo "*** ERROR: No CC View selected ***"
        echo "**********************************"
        return 1
    fi
}

## }}}
## {{{ Pentium objdump

function od() {
    sd_objdump -i $*
}

function mipsod() {
    sd_objdump -m $*
}

function ppcod() {
    sd_objdump $*
}

## }}}
## {{{ Setup build environment
function setup_sd_env() {
    emulate -L zsh

    # Pesky bash WINDVERSION changes uses the non-standard bash format:
    #
    # if [ $string == "blah" ]
    #
    # which means we need to ensure the EQUALS option is not set
    #
    unsetopt equals

    cc_set_ccbase

    local WIND_VERSION=`bash $CC_BASE/acme/lib/common/acmeVersion.sh -wind`

    # TCLLIBPATH:
    # Need to save and restore the environ variable because of a stupid bug
    # the environment setup script that relies on some incorrect behavior
    # of BASH
    local savedTclLibPath=${TCLLIBPATH}
    TCLLIBPATH=""

    # setup environment
    $WIND_VERSION

    # Restore TCLLIBPATH
    TCLLIBPATH=${savedTclLibPath}
}
## }}}
## {{{ Objdump (by default ppc)

function sd_objdump() {
    emulate -L zsh

    local opt
    local objectfile
    local disOpt="d"
    local sourceOpt="Sl"
    local baseOpt=""
    local dumpCmd="objdumpppc"

    # loop continues till options finished
    while getopts ahimstwo: opt; do
        case $opt in
            (a)
                disOpt="D"
                ;;
            (i)
                dumpCmd="objdumppentium"
                ;;
            (m)
                dumpCmd="objdumpmips"
                ;;
            (o)
                objectfile="$OPTARG"
                ;;
            (s)
                sourceOpt=""
                ;;
            (t) # Display symbols
                disOpt=""
                sourceOpt=""
                baseOpt="t"
                ;;
            (h|\?)
                echo >&2 \
                "usage:  $0 [-a] [-s] [-o objectfile] <start address> <end address>" \
                "        $0 [-t] [-o objectfile]"

                return 1
                ;;
        esac
    done
    (( OPTIND > 1 )) && shift $(( OPTIND - 1 ))


    if [[ -z ${2} && ${baseOpt} != "t" ]]; then
        echo >&2 \
            "usage: $0 [-a] [-i] [-s] [-o objectfile] <start address> <end address>"
        return 1
    fi


    # default objectfile?
    if [[ -z $objectfile ]]; then
        objectfile="vxWorks";

        if [[ $WIND_VERSION == "vxe33a" ]]; then
            objectfile="vxKernel.sm"
        fi
    fi

    setup_sd_env

    # always use wide-screen and demangle names options
    echo "$dumpCmd -wC${baseOpt}${disOpt}${sourceOpt} --start-address=${1} --stop-address=${2} $objectfile"
    $dumpCmd -wC${baseOpt}${disOpt}${sourceOpt} --start-address=${1} --stop-address=${2} $objectfile
}

## }}}

