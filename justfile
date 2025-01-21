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
alias fix-command-not-found-error := update-channels
alias nixfmt := nix-format

# Notify the user with neosay
@_notify text:
    if test -f ~/.config/neosay/config.json; then echo "❄️ nixcfg {{ text }}" | neosay; fi

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
      just _notify "switch finished on {{ hostname }}, exit code: $exit_code (runtime: ${runtime}s)"
    fi

# Build the current host with nix-rebuild
[group('build')]
nix-build:
    sudo nixos-rebuild build --flake .#{{ hostname }}

# Build a host with nh
[group('build')]
_build hostname:
    nh os build -H {{ hostname }} .
    just _notify "build finished on {{ hostname }}"

# Build the current host with nh
[group('build')]
build: (_build hostname)

# Build the current host on the Caliban host
[group('build')]
build-on-caliban:
    nixos-rebuild --build-host omega@caliban-1.netbird.cloud --flake .#{{ hostname }} build
    just _notify "build-on-caliban finished on {{ hostname }}"

# Build and deploy the astra host
[group('build')]
build-deploy-astra:
    nixos-rebuild --target-host omega@astra.netbird.cloud --flake .#astra build
    just _notify "build-deploy-astra finished on {{ hostname }}"

# Build and deploy the ally2 host
[group('build')]
build-deploy-ally2:
    nixos-rebuild --target-host omega@ally2.lan --flake .#ally2 build
    just _notify "build-deploy-ally2 finished on {{ hostname }}"

# Build the current host on the Sinope host
[group('build')]
build-on-sinope:
    nixos-rebuild --build-host omega@sinope.netbird.cloud --flake .#{{ hostname }} build
    just _notify "build-on-sinope finished on {{ hostname }}"

# Build with nh on caliban (--build-host" not found)
[group('build')]
nh-build-on-caliban:
    nh os build -H {{ hostname }} . -- --build-host omega@caliban-1.netbird.cloud

# Build the current host on the Home01 host (use "--max-jobs 1" to restict downloads)
[group('build')]
build-on-home01 args='':
    nixos-rebuild --build-host omega@home01.lan --flake .#{{ hostname }} build {{ args }}
    just _notify "build-on-home01 finished on {{ hostname }}"

# Build with nh on homew01 (--build-host" not found)
[group('build')]
nh-build-on-home01:
    nh os build -H {{ hostname }} . -- --build-host omega@home01.lan

# Update the flakes
[group('build')]
update:
    NIX_CONFIG="access-tokens = github.com=`cat ~/.secrets/github-token`" nix flake update

# Update the flakes and switch to the new configuration
[group('build')]
upgrade: update && switch

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

# Run a fish shell with all needed tools
[group('maintenance')]
shell:
    nix-shell --run fish

# Get the reverse dependencies of a nix store path
[group('maintenance')]
nix-store-reverse-dependencies:
    #!/usr/bin/env bash
    set -euxo pipefail
    nixStorePath=$(gum input --placeholder "Nix store path (e.g. /nix/store/hbldxn007k0y5qidna6fg0x168gnsmkj-botan-2.19.5.drv)")
    nix-store --query --referrers "$nixStorePath"

# Format the nix files
[group('maintenance')]
nix-format:
    nix-shell -p fd nixfmt-rfc-style --run "fd -e nix --exec-batch nixfmt"

# Format all justfiles
[group('linter')]
just-format:
    #!/usr/bin/env bash
    # Find all files named "justfile" recursively and run just --fmt --unstable on them
    find . -type f -name "justfile" -print0 | while IFS= read -r -d '' file; do
        echo "Formatting $file"
        just --fmt --unstable -f "$file"
    done
