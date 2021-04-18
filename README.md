# foxfish

![Preview](preview.png)

A theme for the friendly interactive shell (fish). Based on [ocean](https://github.com/oh-my-fish/theme-ocean) by Bruno Ferreira Pinto.

## Instructions

`config.fish` contains a simple template that makes use of the `foxfetch` command.

### [Fisher](https://github.com/jorgebucaran/fisher)

```
fisher add gitlab.com/n303p4/theme-foxfish
```

### [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish)

```
omf repo add https://gitlab.com/n303p4/oh-my-fish
omf install foxfish
```

## foxfetch.fish

Requires fish 3.1 or higher. Memory usage only works on Linux for now.

### Optional arguments

* `-d`, `--plaindate`: Date is printed without magenta background.
* `-t`, `--trim`: Leading and trailing spaces are trimmed.
* `-c`, `--cpuinfo`: Prints CPU info.
* `-g`, `--gpuinfo`: Prints GPU info.
* `-m`, `--meminfo`: Prints memory info.
* `-w`, `--foxwhale`: Prints an ASCII foxwhale.
* `-l`, `--lolwhale`: The foxwhale is piped through `lolcat` if available.
