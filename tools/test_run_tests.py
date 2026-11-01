"""Failure, deadline and coverage contracts for the parallel test launcher."""
import io
import sys
import unittest

from run_tests import checks, run_jobs


class RunnerTests(unittest.TestCase):
    def test_failures_do_not_hide_later_results(self):
        out = io.StringIO()
        jobs = [("bad", [sys.executable, "-c", "raise SystemExit(7)"]),
                ("good", [sys.executable, "-c", "print('finished')"])]
        self.assertEqual(run_jobs(jobs, 2, output=out), 1)
        self.assertIn("exit 7", out.getvalue())
        self.assertIn("finished", out.getvalue())

    def test_shared_deadline_is_a_failure(self):
        out = io.StringIO()
        job = ("slow", [sys.executable, "-c", "import time; time.sleep(10)"])
        self.assertEqual(run_jobs([job, job], .1, workers=1, output=out), 1)
        self.assertIn("Exceeded the shared test budget", out.getvalue())
        self.assertIn("Budget exhausted", out.getvalue())

    def test_missing_tool_is_reported(self):
        out = io.StringIO()
        self.assertEqual(run_jobs([("missing", ["/nonexistent-test-tool"])], 1, output=out), 1)
        self.assertIn("exit 127", out.getvalue())

    def test_all_suites_once_and_renderer_checks_are_default(self):
        jobs = checks(arguments=["rules", "--extended"])
        games = [command for _, command in jobs if command[0].startswith("./build/test/")]
        self.assertEqual(len(games), 6)
        self.assertEqual(len({command[0] for command in games}), 6)
        self.assertTrue(all(command[1:] == ["--check", "rules", "--extended"] for command in games))
        self.assertNotIn("clayfight", [arg for command in games for arg in command[1:]])
        self.assertTrue(all(command[1] == "--fast" for _, command in checks(True)
                            if command[0].startswith("./build/test/")))


if __name__ == "__main__":
    unittest.main()
