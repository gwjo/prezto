## Aliases

alias ctco='cleartool co -nc'
alias ctci='cleartool ci -cq'
alias ctact='cleartool lsact -cact -short'
alias cthijack='cleartool ls -visible | grep hijacked | cut -d "@" -f 1'

## autoload functions

autoload sv
autoload _clearcase_getviews

## Functions

function mkact() {

    if [[ -z $1 ]] ; then
        echo "Bug number required"
        return
    fi

    local project=$(cleartool lsproject -cview -short 2> /dev/null)

    if [[ -z $project ]] ; then
        echo "Not in a view"
    else
        cleartool mkact gowen_${(L)project}_$1
    fi
}

function ctlocks() {
    local project=$(cleartool lsproject -cview -short 2> /dev/null)

    if [[ -z $project ]] ; then
        echo "Not in a view"
    else
        local opts="-short"
        if [[ $1 == "-l"  ]] ; then
            opts=""
        fi

        cleartool lslock $opts brtype:${project}_integration@/projects
    fi

}

function ctpdiff() {
    local base
    local mode="pre"
    local disOpt="-graphical"

    while getopts hx opt; do
        case $opt in
            (h)
                mode="hijack"
                ;;
            (i)
                mode="integration"
                ;;
            (x)
                disOpt=""
                ;;
        esac
    done

    
    case $mode in
        (hijack)
            base=$(cleartool ls $2 | grep hijacked | cut -d " " -f 1)
            ;;
        (pre)
            disOpt="$disOpt -pre"
            ;;
        (integration)
            echo "Not currently supported"
            ;;
    esac

    cleartool diff $disOpt $1

}
