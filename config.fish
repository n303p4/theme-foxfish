if status --is-interactive
    foxfetch --disable cpu --disable gpu -w
    echo -s " Type " (tput bold) help (tput sgr0) " for instructions on how to use fish"
end
