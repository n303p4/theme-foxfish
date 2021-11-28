# name: foxfish
# A fish theme with :3 in mind.
# Based on ocean, a fish theme with ocean in mind.

set __foxfish_last_command_success ":3"
set __foxfish_last_command_failed ":<"
set __foxfish_glyph_flag "⚑"
set __foxfish_root_prompt "8<"


function _git_branch_name
    echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end


function _is_git_dirty
    echo (command git status -s --ignore-submodules=dirty 2> /dev/null)
end


function fish_prompt
    set -l last_status $status
    set -l red (set_color red)
    set -l cyan (set_color cyan)
    set -l white (set_color white)
    set -l brwhite (set_color brwhite)
    set -l black (set_color black)
    set -l blue (set_color blue)
    set -l magenta (set_color magenta)
    set -l bg_blue (set_color -b blue)
    set -l bg_green (set_color -b green)
    set -l bg_cyan (set_color -b cyan)
    set -l bg_magenta (set_color -b magenta)
    set -l bg_white (set_color -b white)
    set -l bg_red (set_color -b red)
    set -l bg_yellow (set_color -b yellow)
    set -l normal (set_color normal)
    set -l cwd $brwhite(prompt_pwd)
    set -l uid (id -u $USER)

    # Show a 8< for root privileges
    if [ $uid -eq 0 ]
        echo -n -s $bg_yellow $black " $__foxfish_root_prompt " $normal
    end

    # Display whether I am SSHed or not
    if test -n "$SSH_TTY"
        if test -n "$hostname"
            echo -n -s $bg_white $magenta " ssh:" (whoami) @ (hostname) " " $normal
        else
            echo -n -s $bg_white $magenta " ssh:" (whoami) @ $hostname " " $normal
        end
    end

    # Display current time
    echo -n -s $bg_magenta $brwhite " " (date +"%H:%M") " " $normal

    # Display virtualenv name if in a virtualenv
    if set -q VIRTUAL_ENV
        echo -n -s $bg_white $blue " " (basename "$VIRTUAL_ENV") " " $normal
    end

    # Display current path
    echo -n -s $bg_blue " $cwd " $normal

    # Show git branch and dirty state
    if [ (command -v git > /dev/null; and _git_branch_name) ]
        set -l git_branch (_git_branch_name)
        if [ (_is_git_dirty) ]
            echo -n -s $bg_cyan $black " git:$git_branch " $red "$__foxfish_glyph_flag " $normal
        else
            echo -n -s $bg_cyan $black " git:$git_branch " $normal
        end
    end

    # Show a :3 (turns red and :< if previous command failed)
    if test $last_status -ne 0
        echo -n -s $bg_red $brwhite " $__foxfish_last_command_failed "  $normal
    else
        echo -n -s $bg_green $brwhite " $__foxfish_last_command_success " $normal
    end

    # Terminate with a space
    echo -n -s " " $normal
end
