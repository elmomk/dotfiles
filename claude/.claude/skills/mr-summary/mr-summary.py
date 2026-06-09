import sys, json

d = json.load(sys.stdin)
hp = d.get("head_pipeline") or {}

fields = {
    "iid":       d.get("iid"),
    "title":     d.get("title"),
    "state":     d.get("state") + (" (DRAFT)" if d.get("draft") else ""),
    "source":    f"{d.get('source_branch')} -> {d.get('target_branch')}",
    "merge":     d.get("detailed_merge_status") or d.get("merge_status"),
    "head_sha":  (d.get("sha") or "")[:10],
    "pipeline":  f"{hp.get('status','none')} (id={hp.get('id','n/a')})",
    "conflicts": d.get("has_conflicts"),
    "updated":   d.get("updated_at"),
    "web_url":   d.get("web_url"),
}

if "--tsv" in sys.argv:
    print("\t".join(str(v) for v in fields.values()))
else:
    for k, v in fields.items():
        print(f"{k:9} {v}")
