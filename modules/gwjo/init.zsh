##
## Personal Settings
##


## ZSH Options
## ===========

setopt NO_BEEP           # NO Beep on error in line editor. 
setopt    CHECK_JOBS     # check jobs when exiting

## Environment Options
## ===================

# Report who logs into my machines
LOGCHECK=60
WATCHFMT="[%B%T %w%b] %B%n%b has %a %B%l%b from %B%M%b"
WATCH=notme

# Report commands that run longer than a minute - useful for timing builds
REPORTTIME=60


## Aliases
## =======

# unalias which
#
# reverse unwanted aliasing of `which' by distribution startup
# files (e.g. /etc/profile.d/which*.sh); zsh's 'which' is perfectly
# good as is.
alias which >&/dev/null && unalias which



