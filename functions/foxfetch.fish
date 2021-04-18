#!/usr/bin/fish
# foxfetch
# Displays a minimal amount of info about the system
# Works across multiple distros, and partially on macOS

function foxfetch_macos_name
    set -l software_version (sw_vers)
    set -l os_name (echo $software_version[1] | cut -f2 -d : | string trim)
    set -l os_version (echo $software_version[2] | cut -f2 -d : | string trim)
    echo -s $os_name " " $os_version
end


function foxfetch_os_release_pretty_name
    cat /etc/os-release | grep PRETTY_NAME | cut -f2 -d \"
end


function foxfetch_lsb_release_description
    lsb_release -d | cut -f2 -d : | string trim
end


function foxfetch_cpu_model
    cat /proc/cpuinfo | grep -m 1 name | cut -f2 -d : | sed "s/([^)]*)//g;s/ CPU//g;s/[^\ ]*-Core Processor//g" | string trim
end


function foxfetch_cpu_cores_threads
    set -l cores (cat /proc/cpuinfo | grep -m 1 "cpu cores" | cut -f2 -d : | string trim)
    set -l threads (cat /proc/cpuinfo | grep "cpu cores" | wc -l)
    echo -s $cores "C/" $threads "T"
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
    echo -s "Memory: " (math "round($mem_used/1024)") " MiB / " (math "round($mem_total/1024)") " MiB"
end


function foxfetch_gpu_model
	set -l gpu_model (glxinfo -B 2> /dev/null | grep Device)
    if [ -n "$gpu_model" ]
        echo "$gpu_model" | cut -f2 -d : | sed "s/([^)]*)//g;s/Mesa DRI//g" | string trim
    end
end


function foxwhale
    set -l prefix $argv[1]
    set -l fw " /\_/\__________   ____" "/               \_/  / \\" "| . .                \  \\" "|  w             _   /  /" "\_______________/ \__\_/"
    printf "$prefix%s\n" $fw
end


function foxfetch
    # Perform checks on arguments
    argparse t/trim d/plaindate disable=+ w/foxwhale l/lolwhale -- $argv; or return

    if set -q _flag_lolwhale; and not which lolcat &> /dev/null
        echo -s $_flag_lolwhale " requires lolcat to be installed"
        return
    end

    # Enable/disable leading/trailing spaces
    set -l bookstand " "
    if set -q _flag_trim
        set bookstand ""
    end

    # The date
    if not contains -- date $_flag_disable
        if set -q _flag_plaindate
            echo -s $bookstand (date +"%A, %B %d, %Y")
        else
            set -l brwhite (set_color brwhite)
            set -l bg_magenta (set_color -b magenta)
            set -l normal (tput sgr0)(set_color normal)

            echo -s $bg_magenta $brwhite $bookstand (date +"%A, %B %d, %Y") $bookstand $normal
        end
    end

    # Print username@hostname on OS version
    # If SSHed, only print hostname on OS version
    if not contains -- host $_flag_disable
        if not test -n "$SSH_TTY"
            echo -n -s $bookstand (whoami)@(hostname) " on "
        else
            echo -n -s $bookstand "Welcome to "
        end
        if test -e /etc/fedora-release  # Fedora
            cat /etc/fedora-release
        else if test -e /etc/os-release  # distros with systemd
            foxfetch_os_release_pretty_name
        else if which lsb_release &> /dev/null  # some other distros
            foxfetch_lsb_release_description
        else if which sw_vers &> /dev/null  # macOS
            foxfetch_macos_name
        else
            echo "an unrecognized OS"
        end
    end

    # Print kernel name, version, and architecture
    if not contains -- uname $_flag_disable
        echo -s $bookstand (uname -srm)
    end

    # Get and print CPU model, GPU model, and memory usage (Linux only)
    if [ (uname) = "Linux" ]
        if not contains -- cpu $_flag_disable
            echo -s $bookstand "CPU: " (foxfetch_cpu_model) " (" (foxfetch_cpu_cores_threads) ")"
        end
        if not contains -- gpu $_flag_disable; and which glxinfo &> /dev/null
            set -l gpu_model (foxfetch_gpu_model)
            if [ -n "$gpu_model" ]
                echo -s $bookstand "GPU: " $gpu_model
            end
        end
        if not contains -- memory $_flag_disable
            echo -s $bookstand (foxfetch_mem_usage_in_mib)
        end
    end

    # foxwhale
    if set -q _flag_lolwhale
        foxwhale $bookstand | lolcat -r
    else if set -q _flag_foxwhale
        foxwhale $bookstand
    end
end


if not status --is-interactive
    foxfetch $argv
end
