devvm
=====

Build and run persistent Fedora VMs using mkosi, KVM and
systemd-vmspawn. The guest uses a static private address and NAT through
systemd-networkd. Its disk persists across restarts.

Setup
-----

devvm finds its repository from the location of bin/devvm, including when
invoked through a symlink. The host needs KVM, systemd-vmspawn, systemd-networkd, sudo, mkosi,
policycoreutils (for setfiles), and uv with Python 3.11 or newer. devvm is
a uv script with no third-party Python dependencies. On a Fedora Atomic host, install any missing host packages and reboot:

    sudo rpm-ostree install qemu-system-x86 edk2-ovmf
    systemctl reboot

Install mkosi on the host or in the toolbox named vms-build. For example:

    toolbox create -y --container vms-build --image fedora:44
    toolbox run --container vms-build -- sudo dnf -y install mkosi

Enable host networking once:

    sudo systemctl enable --now systemd-networkd

Review your existing host network configuration before enabling networkd.
Machine registration uses systemd-machined, which is normally D-Bus activated
on demand and does not need to be enabled or kept running. The new command
checks that networkd is active and that vmspawn and mkosi are available; it
does not enable services or create the toolbox.
Add the repository's bin/ directory to PATH, or invoke bin/devvm by its full path.

If upgrading from an older devvm installation, inspect any old overrides in
/etc/systemd/system/systemd-vmspawn@.service and
/etc/systemd/system/devvm@.service, and the old network file
/etc/systemd/network/80-vm-vt.network. Remove obsolete devvm-owned files
manually if they conflict, then run sudo systemctl daemon-reload and sudo
networkctl reload. Do not remove files needed by other workloads.

Before creating a VM, check the public keys in:

    template/mkosi.extra/home/admin/.ssh/authorized_keys

These keys are copied to every new VM. The default guest user is admin, with
passwordless sudo; SSH root login is disabled.

Usage
-----

    devvm new blog --ram 4G --cpus 4 --disk 150G --user admin
    devvm list
    ssh blog

`devvm list` shows configured vCPUs and RAM, the systemd unit state, and
host-side memory and cumulative CPU time for active VMs. Usage includes the
VM's host processes, not just guest workloads; unavailable accounting is shown
as `-`. An unknown state means systemd could not report it; incomplete entries
have missing or invalid VM configuration. Listing does not require sudo.

Defaults are 8G RAM, 2 CPUs, a 150G sparse disk and user admin. They can be
changed with DEVVM_RAM, DEVVM_CPUS, DEVVM_DISK and DEVVM_ADMIN. VM names must
start with a lowercase letter and contain at most 12 lowercase letters,
digits or hyphens.

Creation builds the image, installs it under /var/lib/machines/blog, writes
host network and systemd configuration, creates an SSH alias and starts the
VM. devvm waits for port 22 to accept connections, but does not verify SSH
authentication. The SSH alias is written to
~/.ssh/config.d/50-vms.conf; devvm adds an Include to ~/.ssh/config if needed.

    sudo systemctl start systemd-vmspawn@blog
    sudo machinectl poweroff blog                 # graceful shutdown
    sudo systemctl stop systemd-vmspawn@blog      # force stop
    sudo systemctl enable systemd-vmspawn@blog    # start at boot
    machinectl list
    machinectl status blog
    sudo journalctl -u systemd-vmspawn@blog -e

    devvm destroy blog        # confirm and permanently delete the VM
    devvm destroy blog --yes  # skip confirmation

Destroy removes the disk and all guest data, VM files, host configuration and SSH
alias. To rebuild from scratch, destroy the VM and create it again.

Storage and updates
-------------------

The live disk is /var/lib/machines/<name>/system.raw. Guest files, packages
and containers persist across stops. Use dnf inside the guest for updates.
The VM boots with a kernel and initrd staged separately on the host; updating
the guest kernel does not automatically update those boot files.

The Fedora targeted SELinux policy is included in new images. Check getenforce
and file labels in the guest; installing the policy alone does not guarantee
enforcing mode.

Builds refresh package metadata but retain the package download cache.

The template is in template/. Generated VM files live in target/,
which Git ignores because it contains private SSH host keys and build caches.
After a successful start, devvm removes the temporary mkosi out/ directory.
Back up VM customizations and secrets separately. The template's public
SSH authorized keys are part of the repository.

Troubleshooting
---------------

If SSH fails, wait for boot and inspect the VM and its network:

    machinectl status blog
    sudo journalctl -u systemd-vmspawn@blog -e
    networkctl status vt-blog
    ssh -v blog

Each VM gets a subnet 10.254.<id>.0/30. IDs are derived from existing VM
configurations and the lowest available ID is reused. If creation fails before
VM.conf is written, remove or repair that incomplete VM directory before
creating another VM.

When available on the host, devvm copies Ghostty's xterm-ghostty terminfo
entry into each new image. It is installed under /etc/terminfo for all users,
including sudo. If the entry is unavailable on the host, the generated SSH
alias falls back to xterm-256color; other terminals are unchanged. Existing
VMs keep the fallback unless their terminfo is installed separately.

Tests
-----

    uv run --script tests/test_devvm.py -v
