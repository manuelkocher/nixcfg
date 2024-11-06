# Use `just <recipe>` to run a recipe
# https://just.systems/man/en/

# By default, run the `--list` command
default:
    @just --list

# Set default shell to bash

set shell := ["bash", "-c"]

# Variables

hostname := `hostname`
user := `whoami`

# Aliases

alias s := switch
alias ss := switch-simple
alias u := upgrade
alias c := cleanup
alias b := build
alias bh := build-on-home01
alias bc := build-on-caliban
alias p := push
alias sp := switch-push
alias fix-command-not-found-error := update-channels

[group('build')]
test:
    sudo nixos-rebuild test --flake .#{{ hostname }} -L

# https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-flake-check.html
[group('build')]
check:
    nix flake check --no-build --keep-going

[group('build')]
nix-switch:
    sudo nixos-rebuild switch --flake .#{{ hostname }} -L

# Build and switch to the new configuration for the current host (no notification)
[group('build')]
switch-simple:
    nh os switch -H {{ hostname }} .

# Build and switch to the new configuration for the current host (with notification, use "--max-jobs 1" to restict downloads)
[group('build')]
switch args='':
    #!/usr/bin/env bash
    echo "❄️ Running switch for {{ hostname }}..."
    start_time=$(date +%s)
    nh os switch -H {{ hostname }} . -- {{ args }}
    end_time=$(date +%s)
    exit_code=$?
    runtime=$((end_time - start_time))
    if [ $runtime -gt 10 ]; then
      if test -f ~/.config/neosay/config.json; then echo "❄️ nixcfg switch finished on {{ hostname }}, exit code: $exit_code (runtime: ${runtime}s)" | neosay; fi
    fi

# Build the current host with nix-rebuild
[group('build')]
nix-build:
    sudo nixos-rebuild build --flake .#{{ hostname }}

# Build a host with nh
[group('build')]
_build hostname:
    nh os build -H {{ hostname }} .

# Build the current host with nh
[group('build')]
build: (_build hostname)

# Build the current host on the Caliban host
[group('build')]
build-on-caliban:
    nixos-rebuild --build-host omega@caliban.netbird.cloud --flake .#{{ hostname }} build
    if test -f ~/.config/neosay/config.json; then echo "❄️ nixcfg build-on-caliban finished on {{ hostname }}" | neosay; fi

# Build the current host on the Sinope host
[group('build')]
build-on-sinope:
    nixos-rebuild --build-host omega@sinope.netbird.cloud --flake .#{{ hostname }} build
    if test -f ~/.config/neosay/config.json; then echo "❄️ nixcfg build-on-sinope finished on {{ hostname }}" | neosay; fi

# Build with nh on caliban (--build-host" not found)
[group('build')]
nh-build-on-caliban:
    nh os build -H {{ hostname }} . -- --build-host omega@caliban.netbird.cloud

# Build the current host on the Home01 host (use "--max-jobs 1" to restict downloads)
[group('build')]
build-on-home01 args='':
    nixos-rebuild --build-host omega@home01.lan --flake .#{{ hostname }} build {{ args }}
    if test -f ~/.config/neosay/config.json; then echo "❄️ nixcfg build-on-home01 finished on {{ hostname }}" | neosay; fi

# Build with nh on homew01 (--build-host" not found)
[group('build')]
nh-build-on-home01:
    nh os build -H {{ hostname }} . -- --build-host omega@home01.lan

[group('cache')]
switch-push: switch && push

[group('cache')]
switch-push-all: push-all push

# Update the flakes
[group('build')]
update:
    NIX_CONFIG="access-tokens = github.com=`cat ~/.secrets/github-token`" nix flake update

# Update the flakes and switch to the new configuration
[group('build')]
upgrade: update && switch

[group('cache')]
upgrade-push: upgrade push

[group('cache')]
upgrade-push-all: upgrade push-all push

[group('cache')]
push:
    -attic push main `which espanso` --no-closure
    -attic push qownnotes `which qownnotes` --no-closure
    -attic push qownnotes `which qc` --no-closure

[group('cache')]
push-all:
    ./scripts/push-all-to-attic.sh

[group('cache')]
push-local:
    attic push --ignore-upstream-cache-filter cicinas2:nix-store `which phpstorm` --no-closure
    attic push --ignore-upstream-cache-filter cicinas2:nix-store `which clion` --no-closure
    attic push --ignore-upstream-cache-filter cicinas2:nix-store `which goland` --no-closure

# Rekey the agenix secrets using ~/.ssh/agenix
[group('agenix')]
rekey-fallback:
    cd ./secrets && agenix -i ~/.ssh/agenix --rekey

# Rekey the agenix secrets
[group('agenix')]
rekey:
    cd ./secrets && agenix --rekey

# Show ssh keys for agenix
[group('agenix')]
keyscan:
    ssh-keyscan localhost

# Build an iso image
[group('build')]
build-iso:
    nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix

# Boot the built iso image in QEMU
[group('build')]
boot-iso:
    nix-shell -p qemu --run "qemu-system-x86_64 -m 256 -cdrom result/iso/nixos-*.iso"

[group('vm')]
boot-vm:
    QEMU_OPTS="-m 4096 -smp 4 -enable-kvm" QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-*-vm

[group('vm')]
boot-vm-no-kvm:
    QEMU_OPTS="-m 4096 -smp 4" QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-*-vm

[group('vm')]
boot-vm-console:
    QEMU_OPTS="-nographic -serial mon:stdio" QEMU_KERNEL_PARAMS=console=ttyS0 QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-*-vm

[group('vm')]
boot-vm-server-console:
    QEMU_OPTS="-nographic -serial mon:stdio" QEMU_KERNEL_PARAMS=console=ttyS0 QEMU_NET_OPTS="hostfwd=tcp::2222-:2222" ./result/bin/run-*-vm

[group('vm')]
ssh-vm-server:
    ssh -p 2222 omega@localhost -t "tmux new-session -A -s pbek"

# Reset the VM
[group('vm')]
[confirm("Are you sure you want to reset the VM?")]
reset-vm:
    rm *.qcow2

[group('vm')]
ssh-vm:
    ssh -p 2222 omega@localhost -t "tmux new-session -A -s pbek"

[group('vm')]
build-vm-desktop:
    nixos-rebuild --flake .#vm-desktop build-vm

[group('vm')]
build-vm-server:
    nixos-rebuild --flake .#vm-server build-vm

[group('vm')]
build-vm-netcup02:
    nixos-rebuild --flake .#vm-netcup02 build-vm

# Rebuild the current host
[group('build')]
flake-rebuild-current:
    sudo nixos-rebuild switch --flake .#{{ hostname }}

# Update the flakes
[group('build')]
flake-update:
    nix flake update

# Clean up the system to free up space
[group('maintenance')]
[confirm("Are you sure you want to clean up the system?")]
cleanup:
    duf && \
    sudo journalctl --vacuum-time=3d && \
    docker system prune -f && \
    rm -rf ~/.local/share/Trash/* && \
    sudo nix-collect-garbage -d && \
    nix-collect-garbage -d && \
    duf

# Repair the nix store
[group('maintenance')]
repair-store:
    sudo nix-store --verify --check-contents --repair

# List the generations
[group('maintenance')]
list-generations:
    nix profile history --profile /nix/var/nix/profiles/system

# Garbage collect the nix store to free up space
[group('maintenance')]
optimize-store:
    duf && \
    nix store optimise && \
    duf

# Do firmware updates
[group('maintenance')]
fwup:
    -fwupdmgr refresh
    fwupdmgr update

# Open a terminal with the nixcfg session
[group('maintenance')]
term:
    zellij --layout term.kdl attach nixcfg -c

# Kill the nixcfg session
[group('maintenance')]
term-kill:
    zellij delete-session nixcfg -f

# Replace the current fish shell with a new one
[group('build')]
fish-replace:
    exec fish

# Use statix to check the nix files
[group('linter')]
linter-check:
    statix check

# Use statix to fix the nix files
[group('linter')]
linter-fix:
    statix fix

# Fix "command not found" error
[group('maintenance')]
update-channels:
    sudo nix-channel --update

# Build the Venus host with nix
[group('build')]
nix-build-venus:
    nixos-rebuild --flake .#venus build

# Build the Venus host with nh
[group('build')]
build-venus: (_build "venus")

# Show home-manager logs
[group('maintenance')]
home-manager-logs:
    sudo journalctl --since today | grep "hm-activate-" | bat

# Show home-manager service status
[group('maintenance')]
home-manager-status:
    systemctl status home-manager-{{ user }}.service

# Restart nix-serve (use on home01)
[group('maintenance')]
home01-restart-nix-serve:
    systemctl restart nix-serve

# Edit the QOwnNotes build file
[group('qownnotes')]
edit-qownnotes-build:
    kate ./apps/qownnotes/default.nix -l 23 -c 19

# Run a fish shell with all needed tools
[group('maintenance')]
shell:
    nix-shell --run fish

# Get the nix hash of a QOwnNotes release
[group('qownnotes')]
qownnotes-hash:
    #!/usr/bin/env bash
    set -euxo pipefail
    version=$(gum input --placeholder "QOwnNotes version number")
    url="https://github.com/pbek/QOwnNotes/releases/download/v${version}/qownnotes-${version}.tar.xz"
    nix-prefetch-url "$url" | xargs nix hash convert --hash-algo sha256

# Update the QOwnNotes release in the app
[group('qownnotes')]
qownnotes-update-release:
    ./scripts/update-qownnotes-release.sh

# Get the reverse dependencies of a nix store path
[group('maintenance')]
nix-store-reverse-dependencies:
    #!/usr/bin/env bash
    set -euxo pipefail
    nixStorePath=$(gum input --placeholder "Nix store path (e.g. /nix/store/hbldxn007k0y5qidna6fg0x168gnsmkj-botan-2.19.5.drv)")
    nix-store --query --referrers "$nixStorePath"

# Format all justfiles
[group('linter')]
just-format:
    #!/usr/bin/env bash
    # Find all files named "justfile" recursively and run just --fmt --unstable on them
    find . -type f -name "justfile" -print0 | while IFS= read -r -d '' file; do
        echo "Formatting $file"
        just --fmt --unstable -f "$file"
    done
