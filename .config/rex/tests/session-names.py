#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# ///

"""Test session naming against a real local Rex server without touching existing sessions."""

import json
import os
import pathlib
import selectors
import shlex
import subprocess
import tempfile
import time
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "scripts/session-names.lua"


class SessionNamesTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="rex-session-names-")
        self.addCleanup(temporary.cleanup)
        self.root = pathlib.Path(temporary.name).resolve()
        self.state = self.root / "state"
        self.environment = os.environ.copy()
        for key in ("REX_SERVER", "REX_SESSION", "REX_BLOCK", "REX_CLIENT"):
            self.environment.pop(key, None)
        self.sessions = []
        self.addCleanup(self.destroy_sessions)
        self.watcher = None
        self.addCleanup(self.stop_watcher)
        self.start_watcher()

    def rex(self, *, arguments):
        result = subprocess.run(
            args=["rex", "--autostart=false", *arguments],
            env=self.environment, capture_output=True, text=True, check=True, timeout=10,
        )
        return result.stdout

    def start_watcher(self):
        self.watcher = subprocess.Popen(
            args=["rex", "--autostart=false", "do", "--all", str(SCRIPT), f"state_dir={self.state}"],
            env=self.environment, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True,
        )
        with selectors.DefaultSelector() as selector:
            selector.register(fileobj=self.watcher.stderr, events=selectors.EVENT_READ)
            if selector.select(timeout=10):
                message = self.watcher.stderr.readline()
                self.assertIn("listening:", message)
                return
        self.fail("Watcher did not start within 10 seconds")

    def stop_watcher(self):
        if self.watcher is None:
            return
        self.watcher.terminate()
        try:
            self.watcher.wait(timeout=3)
        except subprocess.TimeoutExpired:
            self.watcher.kill()
            self.watcher.wait(timeout=3)
        self.watcher.stderr.close()
        self.watcher = None

    def destroy_sessions(self):
        for session_id in self.sessions:
            self.rex(arguments=["kill", session_id])

    def wait_for(self, *, predicate):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.1)
        self.fail("Expected naming change did not happen within 8 seconds")

    def label(self, *, session_id):
        return json.loads(self.rex(arguments=["session", "inspect", session_id, "--json"]))["label"]

    def assert_label(self, *, session_id, expected):
        self.wait_for(predicate=lambda: self.label(session_id=session_id) == expected)

    def shell_command(self, *, directory, report_directory=True):
        command = f"cd {shlex.quote(str(directory))}"
        if report_directory:
            command += f" && printf '\\033]7;%s\\a' {shlex.quote(directory.as_uri())}"
        return command

    def new_session(self, *, directory, report_directory=True):
        created = json.loads(self.rex(arguments=[
            "new", "--json", "--shell=none", "--", "/bin/sh", "-c",
            self.shell_command(directory=directory, report_directory=report_directory) + "; exec /bin/sh",
        ]))
        self.sessions.append(created["session_id"])
        return created["session_id"], created["initial_windows"][0]["block_ids"][0]

    def change_directory(self, *, session_id, block_id, directory, report_directory=True):
        command = self.shell_command(directory=directory, report_directory=report_directory)
        self.rex(arguments=["send", "-s", session_id, "-b", block_id, command])
        self.rex(arguments=["send-key", "-s", session_id, "-b", block_id, "enter"])
        if not report_directory:
            return
        self.wait_for(predicate=lambda: json.loads(self.rex(arguments=[
            "block", "call", "-s", session_id, "-b", block_id, "pwd",
        ]))["pwd"] == directory.as_uri())

    def test_without_directory_reports(self):
        first = self.root / "unreported directory"
        second = self.root / "another directory"
        first.mkdir()
        second.mkdir()
        session_id, block_id = self.new_session(directory=first, report_directory=False)
        reported = json.loads(self.rex(arguments=["block", "call", "-s", session_id, "-b", block_id, "pwd"]))
        self.assertNotIn("pwd", reported)
        self.assert_label(session_id=session_id, expected=first.name)
        self.change_directory(session_id=session_id, block_id=block_id, directory=second, report_directory=False)
        self.assert_label(session_id=session_id, expected=second.name)
        self.change_directory(session_id=session_id, block_id=block_id, directory=pathlib.Path.home(), report_directory=False)
        self.assert_label(session_id=session_id, expected="~")

    def test_naming_and_restart(self):
        first = self.root / "first directory"
        second = self.root / "second"
        repository = self.root / "project"
        nested = repository / "nested" / "deeper"
        first.mkdir()
        second.mkdir()
        nested.mkdir(parents=True)
        subprocess.run(args=["git", "init", "-q", str(repository)], check=True, timeout=10)

        session_id, block_id = self.new_session(directory=first)
        self.assert_label(session_id=session_id, expected=first.name)
        self.change_directory(session_id=session_id, block_id=block_id, directory=second)
        self.assert_label(session_id=session_id, expected=second.name)
        self.change_directory(session_id=session_id, block_id=block_id, directory=nested)
        self.assert_label(session_id=session_id, expected=repository.name)
        self.change_directory(session_id=session_id, block_id=block_id, directory=pathlib.Path.home())
        self.assert_label(session_id=session_id, expected="~")

        self.rex(arguments=[
            "window", "new", "-s", session_id, "second-tab", "--shell=none", "--", "/bin/sh", "-c",
            self.shell_command(directory=second) + "; exec /bin/sh",
        ])
        self.change_directory(session_id=session_id, block_id=block_id, directory=first)
        self.assert_label(session_id=session_id, expected=first.name)

        self.stop_watcher()
        self.start_watcher()
        self.change_directory(session_id=session_id, block_id=block_id, directory=second)
        self.assert_label(session_id=session_id, expected=second.name)
        self.rex(arguments=["session", "rename", session_id, "Keep this"])
        self.stop_watcher()
        self.start_watcher()
        self.change_directory(session_id=session_id, block_id=block_id, directory=first)
        self.rex(arguments=["do", "--for", "1s", "-e", "rex.after(0.8, function() end)"])
        self.assertEqual(self.label(session_id=session_id), "Keep this")

        state_file = self.state / "session-names-local.json"
        self.assertIn(session_id, json.loads(state_file.read_text()))
        self.rex(arguments=["kill", session_id])
        self.sessions.remove(session_id)
        self.wait_for(predicate=lambda: session_id not in json.loads(state_file.read_text()))


if __name__ == "__main__":
    unittest.main()
