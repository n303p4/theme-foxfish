#!/usr/bin/fish
# foxfetch
# Displays a minimal amount of info about the system
# Works across multiple distros, and partially on macOS


function foxfetch_macos_name
    set -l os_name (sw_vers -productName)
    set -l os_version (sw_vers -productVersion)
    echo -s $os_name " " $os_version
end


function foxfetch_os_release_pretty_name
    cat /etc/os-release | grep PRETTY_NAME | cut -f2 -d \"
end


function foxfetch_lsb_release_description
    lsb_release -d | cut -f2 -d : | string trim
end


function foxfetch_cpu_model_linux
    set -l cpu_model (
        cat /proc/cpuinfo | grep -m 1 name | cut -f2 -d : | \
        sed "s/([^)]*)//g;s/ CPU//g;s/[^\ ]*-Core Processor//g" | string trim
    )
    if test -z "$cpu_model"
        set cpu_model "Unknown"
    end
    echo $cpu_model | tr -s " "
end


function foxfetch_cpu_cores_threads_linux
    set -l cores (cat /proc/cpuinfo | grep -m 1 "cpu cores" | cut -f2 -d : | string trim)
    if test -z "$cores"
        set cores (cat /proc/cpuinfo | grep "processor" | wc -l)
    end
    set -l threads (cat /proc/cpuinfo | grep "cpu cores" | wc -l)
    if [ $threads -eq "0" ]
        set threads $cores
    end
    echo -s $cores "C/" $threads "T"
end


function foxfetch_cpu_model_macos
    sysctl -n machdep.cpu.brand_string | \
        sed "s/([^)]*)//g;s/ CPU//g;s/[^\ ]*-Core Processor//g" | string trim
end


function foxfetch_kib_value
    string replace "kB" "" $argv[1] | string trim
end


function foxfetch_mem_usage_linux
    free -h | awk '/Mem:/ { printf("%sB / %sB \n", $3, $2) }'
end


function foxfetch_mem_usage_macos
    top -l 1 | grep -m 1 -E "^Phys" | cut -f2 -d : | string trim
end


function foxfetch_gpu_model_linux
    set -l glxinfo_data ""
    if command -v glxinfo > /dev/null
        set glxinfo_data (glxinfo -B 2> /dev/null | string collect)
    end
    if test -n "$glxinfo_data"
        echo "$glxinfo_data" | grep "Device" | cut -f2 -d : | \
             sed "s/(0x[^)]*)//g;s/([^)]*,[^)]*)//g;s/(R)//g;s/DRI//g;s/Mesa//g" | \
             cut -f1 -d / | string trim
        return
    else if not command -v lshw > /dev/null
        return
    end
    set -l gpus (lshw -numeric -C display 2> /dev/null | grep "product:" | cut -c17-)
    for i in (seq (count $gpus))
        if echo $gpus[$i] | grep "10DE" > /dev/null
            set gpu (echo $gpus[$i] | sed "s/\[....:.*\]//g;s/.*\[//g;s/\].*//g;")
            echo "NVIDIA $gpu"
        else if echo $gpus[$i] | grep "1002" > /dev/null
            echo "AMD $gpus[$i]" | sed "s/\[....:.*\]//g;"
        else if echo $gpus[$i] | grep "8086" > /dev/null
            echo "Intel $gpus[$i]" | sed "s/\[....:.*\]//g;"
        else
            echo "$gpus[$i]" | sed "s/\[....:.*\]//g;"
        end
    end
end


function foxfetch_gpu_model_macos
    set -l gpu_model (system_profiler SPDisplaysDataType | grep -m 1 Chipset)
    if test -n "$gpu_model"
        echo "$gpu_model" | cut -f2 -d : | string trim
    end
end


function foxwhale
    set -l prefix $argv[1]
    set -l fw " /\_/\__________   ____" \
              "/               \_/  / \\" \
              "| . .                \  \\" \
              "|  w             _   /  /" \
              "\_______________/ \__\_/"
    printf "$prefix%s\n" $fw
end


function foxfetch
    # Perform checks on arguments
    argparse t/trim p/plaindate d/disable=+ w/foxwhale l/lolwhale -- $argv

    if set -q _flag_lolwhale; and not command -v lolcat > /dev/null
        echo -s $_flag_lolwhale " requires lolcat to be installed"
        return
    end

    # Enable/disable leading/trailing spaces
    set -l bookend " "
    if set -q _flag_trim
        set bookend ""
    end

    # The date
    if not contains -- date $_flag_disable
        if set -q _flag_plaindate
            echo -s $bookend (date +"%A, %B %d, %Y")
        else
            set -l brwhite (set_color brwhite)
            set -l bg_magenta (set_color -b magenta)
            set -l normal (tput sgr0)(set_color normal)

            echo -s $bg_magenta $brwhite $bookend (date +"%A, %B %d, %Y") $bookend $normal
        end
    end

    # Print username@hostname on OS version
    # If SSHed, only print OS version
    if not contains -- host $_flag_disable
        if test -z "$SSH_TTY"
            if test -z "$hostname"
                echo -n -s $bookend (whoami) @ (hostname) " on "
            else
                echo -n -s $bookend (whoami) @ $hostname " on "
            end
        else
            echo -n -s $bookend "Welcome to "
        end
        if test -e /etc/fedora-release  # Fedora
            cat /etc/fedora-release
        else if test -e /etc/os-release  # distros with systemd
            foxfetch_os_release_pretty_name
        else if command -v lsb_release > /dev/null  # some other distros
            foxfetch_lsb_release_description
        else if command -v sw_vers > /dev/null  # macOS
            foxfetch_macos_name
        else
            echo "an unrecognized OS"
        end
    end

    # Print kernel name, version, and architecture
    if not contains -- uname $_flag_disable
        echo -s $bookend (uname -srm)
    end

    # Get and print CPU model, GPU model, and memory usage
    switch (uname)
    case Linux
        if not contains -- cpu $_flag_disable
            echo -s $bookend "CPU: " (foxfetch_cpu_model_linux) " (" (foxfetch_cpu_cores_threads_linux) ")"
        end
        if not contains -- gpu $_flag_disable
            set -l gpus (foxfetch_gpu_model_linux)
            set -l num_gpus (count $gpus)
            if [ $num_gpus -eq 1 ]
                echo -s $bookend "GPU: " $gpus[1]
            else if [ $num_gpus -ge 1 ]
                for i in (seq (count $gpus))
                    echo -s $bookend "GPU $i: " $gpus[$i]
                end
            end
        end
        if not contains -- memory $_flag_disable
            echo -s $bookend "Memory: " (foxfetch_mem_usage_linux)
        end
    case Darwin
        if not contains -- cpu $_flag_disable
            echo -s $bookend "CPU: " (foxfetch_cpu_model_macos)
        end
        if not contains -- gpu $_flag_disable
            set -l gpu_model (foxfetch_gpu_model_macos)
            if test -n "$gpu_model"
                echo -s $bookend "GPU: " $gpu_model
            end
        end
        if not contains -- memory $_flag_disable
            echo -s $bookend "Memory: " (foxfetch_mem_usage_macos)
        end
    end

    # foxwhale
    if set -q _flag_lolwhale
        # Detect whether lolcat is C or Ruby implementation
        if contains -- jaseg (lolcat --version)
            foxwhale $bookend | lolcat -r
        else
            foxwhale $bookend | lolcat
        end
    else if set -q _flag_foxwhale
        foxwhale $bookend
    end
end


if not status --is-interactive
    foxfetch $argv
end
