#!/usr/bin/env python3
"""
download_stats.py — 聚合 DalamudPlugins 插件源各插件的 GitHub 下载量。

机制说明(为什么是"快照"而非"实时"):
  Dalamud 安装器只负责从 DownloadLinkInstall 拉 zip,不会回传任何遥测。
  下载数由 GitHub Release 资产的 download_count 字段天然记录。本脚本
  遍历 pluginmaster.json 每个条目,从 DownloadLinkInstall 解析
  github.com/<owner>/<repo>/releases/download/...,调 gh api 拉该仓库所有
  release 中 latest.zip 的 download_count 求和,写回条目顶层的 DownloadCount
  字段(安装器会忽略此未知字段,不影响安装)。

  注意:pluginmaster.json 是静态清单,本脚本写回的 DownloadCount 是运行
  时刻的快照。想保持新鲜,需定期跑本脚本(可配自动化/定时器)。

依赖: 已登录的 gh CLI(用 gh api 复用认证,避开裸调 GitHub API 的 60/h 限流)。
"""
import json
import os
import re
import subprocess
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
MASTER = os.path.join(HERE, "pluginmaster.json")
ASSET_NAME = "latest.zip"


def gh_api(path: str):
    r = subprocess.run(["gh", "api", path], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or f"gh api {path} failed")
    return json.loads(r.stdout)


def parse_repo(url: str):
    """从 github.com/<owner>/<repo>/releases/download/... 解析 owner/repo。"""
    m = re.search(r"github\.com/([^/]+)/([^/]+)/releases/download", url or "")
    return (m.group(1), m.group(2)) if m else None


def repo_downloads(owner: str, repo: str):
    """返回 (total, details), details=[(tag_name, count), ...]。"""
    releases = gh_api(f"repos/{owner}/{repo}/releases?per_page=100")
    total = 0
    details = []
    for rel in releases:
        for a in rel.get("assets", []):
            if a.get("name") == ASSET_NAME:
                c = a.get("download_count", 0)
                total += c
                details.append((rel.get("tag_name", "?"), c))
    return total, details


def main():
    with open(MASTER, encoding="utf-8") as f:
        master = json.load(f)

    print(f"拉取时间(UTC): {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}")
    grand = 0
    for entry in master:
        name = entry.get("InternalName") or entry.get("Name")
        url = entry.get("DownloadLinkInstall") or entry.get("DownloadLinkUpdate") or ""
        parsed = parse_repo(url)
        if not parsed:
            print(f"\n[{name}] 非 GitHub 托管,跳过")
            continue
        owner, repo = parsed
        try:
            total, details = repo_downloads(owner, repo)
        except Exception as e:  # noqa: BLE001
            print(f"\n[{name}] 查询失败: {e}")
            continue
        entry["DownloadCount"] = total
        grand += total
        print(f"\n[{name}] 总下载: {total}")
        for tag, c in details:
            print(f"  {tag}: {c}")

    print(f"\n=== 全部插件合计下载: {grand} ===")

    with open(MASTER, "w", encoding="utf-8") as f:
        json.dump(master, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"已写回 {MASTER}")


if __name__ == "__main__":
    main()
