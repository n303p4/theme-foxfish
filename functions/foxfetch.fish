#!/usr/bin/fish
# foxfetch
# Displays a minimal amount of info about the system
# Works across multiple distros

function foxfetch_os_release_pretty_name
    cat /etc/os-release | grep PRETTY_NAME | cut -f2 -d \"
end


function foxfetch_lsb_release_description
    lsb_release -d | cut -f2 -d : | string trim
end


function foxfetch_kib_value
    string replace "kB" "" $argv[1] | string trim
end


function foxfetch_mem_usage_in_mib
    set -l mem_used 0
    for line in (cat /proc/meminfo)
        set -l keyvaluepair (string split : $line)
        switch $keyvaluepair[1]
            case MemTotal
                set -l value (foxfetch_kib_value $keyvaluepair[2])
                set mem_used (math $mem_used+$value)
                set mem_total $value
            case Shmem
                set mem_used (math $mem_used+(foxfetch_kib_value $keyvaluepair[2]))
            case MemFree Buffers Cached SReclaimable
                set mem_used (math $mem_used-(foxfetch_kib_value $keyvaluepair[2]))
        end
    end
    if contains -- -p $argv
        set prefixspace " "
    end
    echo -s $prefixspace "Memory usage: " (math "round($mem_used/1024)") " MiB / " (math "round($mem_total/1024)") " MiB"
end


function foxfetch
    set -l bold (tput bold)
    set -l brwhite (set_color brwhite)
    set -l bg_magenta (set_color -b magenta)
    set -l normal (tput sgr0)(set_color normal)

    # The date
    echo -s $bg_magenta $brwhite " " (date +"%A, %B %d, %Y") " " $normal

    # Print username@hostname on OS version
    # If SSHed, only print hostname on OS version
    if not test -n "$SSH_TTY"
        echo -n -s " " (whoami)@(hostname) " on "
    else
        echo -n " Welcome to "
    end
    if test -e /etc/fedora-release
        cat /etc/fedora-release
    else if test -e /etc/os-release
        foxfetch_os_release_pretty_name
    else if which lsb_release &> /dev/null
        foxfetch_lsb_release_description
    else
        echo "an unrecognized OS"
    end

    # Print kernel name, version, and architecture
    echo -s " " (uname -srm)

    # Get and print memory usage
    foxfetch_mem_usage_in_mib -p

    # foxwhale
    if contains -- -w $argv; or contains -- --foxwhale $argv
        echo "  /\_/\__________   ____"
        echo " /               \_/  / \\"
        echo " | . .                \  \\"
        echo " |  w             _   /  /"
        echo " \_______________/ \__\_/"
    end
end

if not status --is-interactive
    foxfetch
end
