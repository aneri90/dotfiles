"""Tests for localbin/.local/bin/glflow against a fake glab.

Run: python3 -m unittest discover -s .tests/glflow -v   (from the repo root)
"""
import base64
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
GLFLOW = os.path.join(HERE, "..", "..", "localbin", ".local", "bin", "glflow")
FAKE = os.path.join(HERE, "fake_glab.py")
MR = r"projects/g%2Fr/merge_requests/7$"
PIPES = r"projects/g%2Fr/merge_requests/7/pipelines"


def mr(sha="aaa", state="opened", draft=False, merge_status="mergeable", merge_commit=None):
    return {"iid": 7, "sha": sha, "state": state, "draft": draft,
            "detailed_merge_status": merge_status, "merge_commit_sha": merge_commit}


class GlflowTest(unittest.TestCase):
    def run_glflow(self, routes, *argv):
        tmp = tempfile.mkdtemp()
        scenario = os.path.join(tmp, "scenario.json")
        with open(scenario, "w") as f:
            json.dump(routes, f)
        env = dict(os.environ, GLFLOW_GLAB=FAKE, FAKE_SCENARIO=scenario)
        proc = subprocess.run([sys.executable, GLFLOW] + list(argv) + ["--repo", "g/r", "--interval", "0"],
                              capture_output=True, text=True, env=env, timeout=60)
        lines = proc.stdout.strip().splitlines()
        self.assertEqual(len(lines), 1, proc.stdout + proc.stderr)
        calls = []
        if os.path.exists(scenario + ".log"):
            with open(scenario + ".log") as f:
                calls = [json.loads(line) for line in f]
        return proc.returncode, json.loads(lines[0]), calls

    def test_green_pipeline_on_head_exits_0(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr()}]},
            {"match": PIPES, "responses": [{"body": [{"id": 1, "sha": "aaa", "status": "running"}]},
                                           {"body": [{"id": 1, "sha": "aaa", "status": "success"}]}]},
        ], "mr-wait", "7")
        self.assertEqual((code, out["status"], out["pipeline_id"]), (0, "success", 1))

    def test_failed_pipeline_exits_1_and_names_jobs(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr()}]},
            {"match": PIPES, "responses": [{"body": [{"id": 9, "sha": "aaa", "status": "failed"}]}]},
            {"match": r"pipelines/9/jobs", "responses": [{"body": [{"name": "test"}]}]},
        ], "mr-wait", "7")
        self.assertEqual((code, out["status"], out["failed_jobs"]), (1, "pipeline_failed", ["test"]))

    def test_pipeline_on_an_older_sha_is_not_the_head(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr(sha="new")}]},
            {"match": PIPES, "responses": [{"body": [{"id": 1, "sha": "old", "status": "success"}]}]},
        ], "mr-wait", "7", "--no-pipeline-grace", "0")
        self.assertEqual((code, out["status"]), (5, "no_pipeline"))

    def test_head_moved_while_waiting_exits_4(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr(sha="aaa")}, {"body": mr(sha="bbb")}]},
            {"match": PIPES, "responses": [{"body": [{"id": 1, "sha": "aaa", "status": "running"}]}]},
        ], "mr-wait", "7")
        self.assertEqual((code, out["status"], out["sha"]), (4, "head_moved", "bbb"))

    def test_no_pipeline_exits_5(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr(draft=True)}]},
            {"match": PIPES, "responses": [{"body": []}]},
        ], "mr-wait", "7", "--no-pipeline-grace", "0")
        self.assertEqual((code, out["status"]), (5, "no_pipeline"))

    def test_still_pending_exits_3(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr()}]},
            {"match": PIPES, "responses": [{"body": [{"id": 1, "sha": "aaa", "status": "running"}]}]},
        ], "mr-wait", "7", "--timeout", "0")
        self.assertEqual((code, out["status"]), (3, "timeout"))

    def test_already_merged_exits_0_without_merging(self):
        code, out, calls = self.run_glflow([
            {"match": MR, "responses": [{"body": mr(state="merged", merge_commit="mmm")}]},
        ], "mr-merge", "7")
        self.assertEqual((code, out["status"], out["merge_commit_sha"]), (0, "merged", "mmm"))
        self.assertFalse([c for c in calls if c["method"] == "PUT"])

    def test_merge_is_pinned_to_the_green_head(self):
        code, out, calls = self.run_glflow([
            {"match": MR, "responses": [{"body": mr()}]},
            {"match": PIPES, "responses": [{"body": [{"id": 1, "sha": "aaa", "status": "success"}]}]},
            {"method": "PUT", "match": r"merge_requests/7/merge$",
             "responses": [{"body": {"state": "merged", "merge_commit_sha": "mmm"}}]},
        ], "mr-merge", "7")
        self.assertEqual((code, out["merge_commit_sha"]), (0, "mmm"))
        puts = [c for c in calls if c["method"] == "PUT"]
        self.assertEqual(puts[0]["fields"], ["sha=aaa"])

    def test_merge_refused_on_sha_conflict_exits_4(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr()}]},
            {"match": PIPES, "responses": [{"body": [{"id": 1, "sha": "aaa", "status": "success"}]}]},
            {"method": "PUT", "match": r"merge_requests/7/merge$", "responses": [{"status": 409}]},
        ], "mr-merge", "7")
        self.assertEqual((code, out["status"], out["http"]), (4, "merge_refused", 409))

    def test_draft_is_not_merged(self):
        code, out, calls = self.run_glflow([
            {"match": MR, "responses": [{"body": mr(draft=True)}]},
        ], "mr-merge", "7")
        self.assertEqual((code, out["status"]), (2, "draft"))
        self.assertFalse([c for c in calls if c["method"] == "PUT"])

    def test_wait_tag_takes_the_lowest_release_containing_the_commit(self):
        code, out, _ = self.run_glflow([
            {"match": MR, "responses": [{"body": mr(state="merged", merge_commit="mmm")}]},
            {"match": r"commits/mmm/refs", "responses": [{"body": [{"name": "v2.1.0"}, {"name": "v2.0.10"}]}]},
        ], "wait-tag", "--mr", "7")
        self.assertEqual((code, out["tag"]), (0, "v2.0.10"))

    def test_wait_tag_with_no_release_exits_5(self):
        code, out, _ = self.run_glflow([
            {"match": r"commits/sss/refs", "responses": [{"body": []}]},
            {"match": r"pipelines\?sha=sss", "responses": [{"body": [{"id": 3, "status": "success"}]}]},
        ], "wait-tag", "--sha", "sss", "--release-grace", "0")
        self.assertEqual((code, out["status"]), (5, "no_release"))

    def file_routes(self, content):
        body = {"content": base64.b64encode(content.encode()).decode(), "last_commit_id": "c0"}
        return [{"match": r"repository/files/", "responses": [{"body": body}]}]

    def test_deploy_bump_refuses_an_ambiguous_pattern(self):
        code, out, calls = self.run_glflow(
            self.file_routes("    version: 1.0.0\n    version: 2.0.0\n"),
            "deploy-bump", "--branch", "test", "--file", "helmfile.yaml",
            "--pattern", r"version: (?P<v>\S+)", "--version", "3.0.0")
        self.assertEqual((code, out["status"], out["matches"]), (2, "ambiguous_pattern", 2))
        self.assertFalse([c for c in calls if c["method"] == "POST"])

    def test_deploy_bump_already_at_version_exits_0(self):
        code, out, _ = self.run_glflow(
            self.file_routes("chart: x\n    version: 3.0.0\n"),
            "deploy-bump", "--branch", "test", "--file", "helmfile.yaml",
            "--pattern", r"version: (?P<v>\S+)", "--version", "3.0.0")
        self.assertEqual((code, out["status"]), (0, "already"))


if __name__ == "__main__":
    unittest.main()
