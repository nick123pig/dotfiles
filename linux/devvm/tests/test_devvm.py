#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import contextlib
import io
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

REPO = Path(__file__).resolve().parent.parent
loader = importlib.machinery.SourceFileLoader("devvm", str(REPO / "bin/devvm"))
spec = importlib.util.spec_from_loader(loader.name, loader)
devvm = importlib.util.module_from_spec(spec)
loader.exec_module(devvm)


class DevvmTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "vms"
        self.home = self.base / "home"
        self.home.mkdir()
        (self.root / "target").mkdir(parents=True)
        self.patches = [mock.patch.object(devvm, "ROOT", self.root),
                        mock.patch.object(devvm, "HOME", self.home)]
        for patch in self.patches:
            patch.start()
            self.addCleanup(patch.stop)

    def vm(self, name, number):
        directory = self.root / "target" / name
        directory.mkdir()
        (directory / "VM.conf").write_text(f"ID={number}\n")
        return directory

    def test_repository_root_follows_script_symlink(self):
        link = self.base / "devvm"
        link.symlink_to(REPO / "bin/devvm")
        code = ("import importlib.machinery, importlib.util, sys; "
                "loader = importlib.machinery.SourceFileLoader('devvm', sys.argv[1]); "
                "spec = importlib.util.spec_from_loader(loader.name, loader); "
                "module = importlib.util.module_from_spec(spec); loader.exec_module(module); "
                "print(module.ROOT)")
        result = subprocess.run([sys.executable, "-c", code, str(link)],
                                env=dict(os.environ, DEVVM_ROOT=str(self.base)),
                                text=True, capture_output=True, check=True)
        self.assertEqual(Path(result.stdout.strip()), REPO.resolve())

    def test_allocation_and_bad_vms(self):
        self.assertEqual(devvm.allocate_id(), 1)
        self.vm("one", 1)
        self.vm("three", 3)
        self.assertEqual(devvm.allocate_id(), 2)
        duplicate = self.vm("duplicate", 3)
        with self.assertRaises(devvm.DevvmError):
            devvm.allocate_id()
        shutil.rmtree(duplicate)
        invalid = self.vm("invalid", 256)
        with self.assertRaises(devvm.DevvmError):
            devvm.allocate_id()
        shutil.rmtree(invalid)
        (self.root / "target" / "incomplete").mkdir()
        with self.assertRaises(devvm.DevvmError):
            devvm.allocate_id()

    def test_exhaustion_and_reuse(self):
        for number in range(1, 256):
            self.vm(f"p{number}", number)
        with self.assertRaises(devvm.DevvmError):
            devvm.allocate_id()
        shutil.rmtree(self.root / "target/p100")
        self.assertEqual(devvm.allocate_id(), 100)

    def test_names_and_options(self):
        self.assertEqual(devvm.validate_name("good-name"), "good-name")
        for name in ("../bad", "bad/name", "UPPER", "a" * 13):
            with self.assertRaises(devvm.DevvmError):
                devvm.validate_name(name)
        for values in (("admin", "8G", "0", "150G"), ("admin", "8G;bad", "2", "150G")):
            with self.assertRaises(devvm.DevvmError):
                devvm.validate_options(*values)

    def test_conf_is_not_executed(self):
        directory = self.vm("one", 1)
        (directory / "VM.conf").write_text("ID=$(touch /tmp/devvm-injected)\n")
        with self.assertRaises(devvm.DevvmError):
            devvm.allocate_id()

    def test_create_copies_keys_and_handles_custom_user(self):
        shutil.copytree(REPO / "template", self.root / "template", symlinks=True)
        with mock.patch.object(devvm, "find_dns", return_value="10.0.2.1"), \
             mock.patch.object(devvm, "output_or_empty", return_value=""):
            devvm.create_vm("first", "8G", "2", "150G", "admin")
            devvm.create_vm("second", "4G", "3", "20G", "developer")
        key = (self.root / "template/mkosi.extra/home/admin/.ssh/authorized_keys").read_bytes()
        for name, user in (("first", "admin"), ("second", "developer")):
            directory = self.root / "target" / name
            self.assertEqual((directory / "mkosi.extra/home" / user / ".ssh/authorized_keys").read_bytes(), key)
            private = directory / "mkosi.extra/etc/ssh/ssh_host_ed25519_key"
            self.assertEqual(private.stat().st_mode & 0o777, 0o600)
        conf = devvm.load_conf("second")
        self.assertEqual(conf["ID"], "2")
        self.assertEqual(conf["USER"], "developer")
        ssh_config = self.home / ".ssh/config.d/50-vms.conf"
        self.assertIn("User developer", ssh_config.read_text())
        for term, expected in (("xterm-ghostty", True), ("xterm-256color", False)):
            result = subprocess.run(["ssh", "-G", "-F", str(ssh_config), "second"],
                                    env=dict(os.environ, TERM=term), text=True, capture_output=True, check=True)
            self.assertEqual("setenv TERM=xterm-256color" in result.stdout, expected)
        self.assertEqual(os.readlink(self.root / "target/second/mkosi.extra/etc/systemd/system/systemd-firstboot.service"), "/dev/null")

    def test_postinstall_runs_in_image(self):
        script = REPO / "template/mkosi.postinst.d/10-basics.sh.chroot"
        self.assertTrue(script.is_file())
        self.assertTrue(os.access(script, os.X_OK))
        if shutil.which("mkosi"):
            summary = subprocess.run(["mkosi", "-C", str(REPO / "template"), "summary"],
                                     text=True, capture_output=True, check=True)
            self.assertIn(str(script), summary.stdout)

    def test_installed_ghostty_terminfo_and_ssh_config(self):
        if not shutil.which("tic") or not shutil.which("infocmp"):
            self.skipTest("ncurses tools are required")
        source = "xterm-ghostty|Ghostty test terminal,\n\tcols#80, lines#24, colors#256,\n"
        shutil.copytree(REPO / "template", self.root / "template", symlinks=True)
        with mock.patch.object(devvm, "find_dns", return_value="10.0.2.1"), \
             mock.patch.object(devvm, "output_or_empty", return_value=source):
            conf = devvm.create_vm("ghost", "8G", "2", "150G", "admin")
        self.assertEqual(conf["GHOSTTY_TERMINFO"], "installed")
        staged = self.root / "target/ghost/mkosi.extra/usr/lib/devvm/xterm-ghostty.terminfo"
        self.assertEqual(staged.read_text(), source)
        database = self.base / "terminfo"
        database.mkdir()
        subprocess.run(["tic", "-x", "-o", str(database), "-"], input=source, text=True, check=True)
        subprocess.run(["infocmp", "-x", "-A", str(database), "xterm-ghostty"],
                       capture_output=True, check=True)
        config = self.home / ".ssh/config.d/50-vms.conf"
        result = subprocess.run(["ssh", "-G", "-F", str(config), "ghost"],
                                env=dict(os.environ, TERM="xterm-ghostty"), text=True, capture_output=True, check=True)
        self.assertNotIn("setenv TERM=", result.stdout)

    def test_deploy_reload_and_reconfigure(self):
        directory = self.root / "target/first"
        directory.mkdir()
        conf = {"RAM": "8G", "CPUS": "2", "HOST_IP": "10.254.1.1"}
        calls = []
        def sudo(*args, **kwargs):
            calls.append((args, kwargs))
        with mock.patch.object(devvm, "sudo", side_effect=sudo), \
             mock.patch.object(devvm, "run", return_value=subprocess.CompletedProcess([], 0)):
            devvm.deploy_host_conf("first", conf)
        self.assertTrue(any(c[0] == ("networkctl", "reload") for c in calls))
        self.assertTrue(any(c[0] == ("networkctl", "reconfigure", "vt-first") for c in calls))
        service = next(c[1]["input_text"] for c in calls if c[0][0] == "tee")
        self.assertIn("--notify-ready=no", service)
        self.assertNotIn("Type=simple", service)

    def test_wait_and_stopped_vm(self):
        with mock.patch.object(devvm.socket, "create_connection") as connect:
            devvm.wait_for_ssh("first", "10.254.1.2")
            connect.assert_called_once()
        with mock.patch.object(devvm.socket, "create_connection", side_effect=OSError), \
             mock.patch.object(devvm, "is_running", return_value=False):
            with self.assertRaises(devvm.DevvmError):
                devvm.wait_for_ssh("first", "10.254.1.2")

    def test_list_vms_and_usage(self):
        def configured(name):
            directory = self.root / "target" / name
            directory.mkdir()
            (directory / "VM.conf").write_text(
                f"NAME={name}\nID=1\nHOST_IP=10.254.1.1\nVM_IP=10.254.1.2\n"
                "RAM=8G\nCPUS=2\nUSER=admin\n")
        for name in ("running", "stopped", "unavailable"):
            configured(name)
        (self.root / "target/incomplete").mkdir()
        def show(*args, **kwargs):
            unit = args[2]
            if "running" in unit:
                return subprocess.CompletedProcess(args, 0, "ActiveState=active\nMemoryCurrent=1073741824\nCPUUsageNSec=2500000000\n", "")
            if "stopped" in unit:
                return subprocess.CompletedProcess(args, 0, "ActiveState=inactive\nMemoryCurrent=[not set]\n", "")
            return subprocess.CompletedProcess(args, 1, "", "bus unavailable")
        output = io.StringIO()
        with mock.patch.object(devvm, "run", side_effect=show), \
             mock.patch.object(devvm, "sudo") as sudo, contextlib.redirect_stdout(output):
            devvm.main(["list"])
        sudo.assert_not_called()
        lines = output.getvalue().splitlines()
        self.assertIn("CPU TIME", lines[0])
        self.assertIn("incomplete", lines[1])
        self.assertIn("active", lines[2])
        self.assertIn("1.0GiB", lines[2])
        self.assertIn("2.5s", lines[2])
        self.assertIn("inactive", lines[3])
        self.assertIn("unknown", lines[4])
        self.assertEqual(devvm.format_bytes(str(2**64 - 1)), "-")

    def test_list_empty(self):
        output = io.StringIO()
        with mock.patch.object(devvm, "run") as run, contextlib.redirect_stdout(output):
            devvm.cmd_list()
        run.assert_not_called()
        self.assertIn("NAME", output.getvalue())

    def test_host_prerequisites(self):
        ok = subprocess.CompletedProcess([], 0)
        fail = subprocess.CompletedProcess([], 1)
        with mock.patch.object(devvm.shutil, "which", return_value="/usr/bin/tool"), \
             mock.patch.object(devvm.Path, "exists", return_value=True), \
             mock.patch.object(devvm, "run", return_value=ok) as run:
            devvm.check_host_prerequisites()
            self.assertEqual(run.call_count, 1)
        with mock.patch.object(devvm.shutil, "which", return_value=None):
            with self.assertRaisesRegex(devvm.DevvmError, "systemd-vmspawn not found"):
                devvm.check_host_prerequisites()
        with mock.patch.object(devvm.shutil, "which", return_value="/usr/bin/tool"), \
             mock.patch.object(devvm.Path, "exists", return_value=False):
            with self.assertRaisesRegex(devvm.DevvmError, "service not found"):
                devvm.check_host_prerequisites()
        with mock.patch.object(devvm.shutil, "which", return_value="/usr/bin/tool"), \
             mock.patch.object(devvm.Path, "exists", return_value=True), \
             mock.patch.object(devvm, "run", return_value=fail):
            with self.assertRaisesRegex(devvm.DevvmError, "systemd-networkd"):
                devvm.check_host_prerequisites()
        def which(name):
            return None if name == "mkosi" else "/usr/bin/tool"
        with mock.patch.object(devvm.shutil, "which", side_effect=which), \
             mock.patch.object(devvm.Path, "exists", return_value=True), \
             mock.patch.object(devvm, "run", side_effect=[ok, fail]):
            with self.assertRaisesRegex(devvm.DevvmError, "mkosi not found"):
                devvm.check_host_prerequisites()
        with mock.patch.object(devvm.shutil, "which", side_effect=which), \
             mock.patch.object(devvm.Path, "exists", return_value=True), \
             mock.patch.object(devvm, "run", return_value=ok) as run:
            devvm.check_host_prerequisites()
            self.assertEqual(run.call_args.args[:4], ("toolbox", "run", "--container", devvm.TOOLBOX))

    def test_new_checks_host_before_modifying_files(self):
        with mock.patch.object(devvm, "check_host_prerequisites", side_effect=devvm.DevvmError("missing")), \
             mock.patch.object(devvm, "sudo") as sudo, \
             mock.patch.object(devvm, "create_vm") as create:
            with self.assertRaisesRegex(devvm.DevvmError, "missing"):
                devvm.main(["new", "first"])
            sudo.assert_not_called()
            create.assert_not_called()

    def test_new_removes_output_only_after_ssh_ready(self):
        out = self.root / "target/first/out"
        out.mkdir(parents=True)
        (out / "system.raw").touch()
        args = devvm.argparse.Namespace(name="first", ram="8G", cpus="2", disk="150G", user="admin")
        conf = {"VM_IP": "10.254.1.2"}
        with mock.patch.object(devvm, "create_vm", return_value=conf), \
             mock.patch.object(devvm, "build_vm"), mock.patch.object(devvm, "sudo"), \
             mock.patch.object(devvm, "wait_for_ssh", side_effect=devvm.DevvmError("not ready")):
            with self.assertRaises(devvm.DevvmError):
                devvm.cmd_new(args)
        self.assertTrue((out / "system.raw").exists())
        with mock.patch.object(devvm, "create_vm", return_value=conf), \
             mock.patch.object(devvm, "build_vm"), mock.patch.object(devvm, "sudo"), \
             mock.patch.object(devvm, "wait_for_ssh"):
            devvm.cmd_new(args)
        self.assertFalse(out.exists())

    def test_systemctl_errors_fail_closed(self):
        for code, expected in ((0, True), (3, False), (4, False)):
            with mock.patch.object(devvm, "run", return_value=subprocess.CompletedProcess([], code, "", "")):
                self.assertEqual(devvm.is_running("first"), expected)
        with mock.patch.object(devvm, "run", return_value=subprocess.CompletedProcess([], 1, "", "bus unavailable")):
            with self.assertRaises(devvm.DevvmError):
                devvm.is_running("first")

    def test_build_refreshes_metadata_with_host_or_toolbox(self):
        for host_mkosi in (True, False):
            with self.subTest(host_mkosi=host_mkosi), \
                 mock.patch.object(devvm, "sudo", return_value=subprocess.CompletedProcess([], 1)), \
                 mock.patch.object(devvm.shutil, "which", return_value="/usr/bin/mkosi" if host_mkosi else None), \
                 mock.patch.object(devvm, "run", side_effect=RuntimeError("stop after command")) as run:
                with self.assertRaisesRegex(RuntimeError, "stop after command"):
                    devvm.build_vm("first", {"USER": "admin"})
                self.assertIn("--cache-only=never", run.call_args.args)
                self.assertEqual(run.call_args.args[0], "mkosi" if host_mkosi else "toolbox")

    def test_disk_existence_checked_as_root(self):
        with mock.patch.object(devvm, "sudo", return_value=subprocess.CompletedProcess([], 0)) as sudo:
            with self.assertRaises(devvm.DevvmError):
                devvm.build_vm("first", {"USER": "admin"})
            self.assertEqual(sudo.call_args.args[:2], ("test", "-e"))

    def test_preflight_check(self):
        image = self.base / "image"
        contexts = image / "etc/selinux/targeted/contexts/files/file_contexts"
        contexts.parent.mkdir(parents=True)
        contexts.write_text("contexts\n")
        mask = image / "etc/systemd/system/systemd-firstboot.service"
        mask.parent.mkdir(parents=True)
        mask.symlink_to("/dev/null")
        keys = image / "home/admin/.ssh/authorized_keys"
        keys.parent.mkdir(parents=True)
        keys.write_text("key\n")
        pam = image / "usr/lib64/security/pam_systemd.so"
        pam.parent.mkdir(parents=True)
        pam.touch()
        fake = self.base / "bin"
        fake.mkdir()
        tools = {
            "setfiles": 'exit "${FAIL_SETFILES:-0}"',
            "stat": 'echo "${MOCK_LABEL:-system_u:object_r:root_t:s0}"',
            "systemctl": 'case "$*" in *"${DISABLED_UNIT:-__none__}"*) exit 1;; esac',
        }
        for name, body in tools.items():
            path = fake / name
            path.write_text("#!/bin/sh\n" + body + "\n")
            path.chmod(0o755)
        env = dict(os.environ, SYSTEMD_DISSECT_ROOT=str(image), PATH=f"{fake}:{os.environ['PATH']}")
        def check(terminfo="fallback", **overrides):
            return subprocess.run([sys.executable, "-c", devvm.IMAGE_CHECK, "admin", terminfo],
                                  env=dict(env, **overrides), capture_output=True, text=True)
        self.assertEqual(check().returncode, 0)
        self.assertNotEqual(check("installed").returncode, 0)
        entry = image / "etc/terminfo/x/xterm-ghostty"
        entry.parent.mkdir(parents=True)
        entry.write_text("compiled")
        self.assertEqual(check("installed").returncode, 0)
        self.assertNotEqual(check(FAIL_SETFILES="1").returncode, 0)
        self.assertNotEqual(check(MOCK_LABEL="unlabeled").returncode, 0)
        self.assertNotEqual(check(DISABLED_UNIT="sshd.service").returncode, 0)
        mask.unlink()
        self.assertNotEqual(check().returncode, 0)
        mask.symlink_to("/dev/null")
        keys.unlink()
        self.assertNotEqual(check().returncode, 0)


if __name__ == "__main__":
    unittest.main()
