if status --is-interactive
    foxfetch -c -g -w
    echo -s " Type " (tput bold) help (tput sgr0) " for instructions on how to use fish"
end
