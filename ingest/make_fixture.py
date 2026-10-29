"""
Generate a small synthetic file with the same columns as the Kaggle extract.

Used by CI and by anyone who wants to run the pipeline without downloading
the full dataset. It includes deliberate data-quality defects (missing
values, out-of-range DTI, a duplicated id, inverted FICO range) so every
DQ rule has something to find. The numbers are random, not real loans.

Usage:
    python ingest/make_fixture.py --rows 5000 --out data/fixture.csv
"""
import argparse
import csv
from datetime import date
from pathlib import Path

import numpy as np

GRADES = ["A", "B", "C", "D", "E", "F", "G"]
PURPOSES = ["debt_consolidation", "credit_card", "home_improvement", "other",
            "major_purchase", "medical", "small_business", "car"]
STATES = ["CA", "NY", "TX", "FL", "IL", "WA", "GA", "OH", "PA", "NJ", "MA", "ZZ"]
STATUSES = ["Fully Paid", "Charged Off", "Current", "Late (31-120 days)",
            "Late (16-30 days)", "In Grace Period", "Default"]
STATUS_P = [0.45, 0.12, 0.36, 0.03, 0.01, 0.02, 0.01]
MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rows", type=int, default=5000)
    ap.add_argument("--out", default="data/fixture.csv")
    ap.add_argument("--seed", type=int, default=7)
    a = ap.parse_args()
    rng = np.random.default_rng(a.seed)

    rows = []
    for i in range(a.rows):
        year = int(rng.choice([2014, 2015, 2016, 2017, 2018], p=[0.12, 0.2, 0.22, 0.23, 0.23]))
        drift = year - 2016                       # later vintages drift a little
        g = int(np.clip(rng.normal(2 + 0.2 * drift, 1.3), 0, 6))
        fico_low = int(np.clip(rng.normal(705 - 8 * g - 4 * drift, 25), 660, 845) // 5 * 5)
        amt = float(np.clip(rng.lognormal(9.4 + 0.05 * drift, 0.55), 1000, 40000) // 25 * 25)
        rate = round(6 + 3.2 * g + rng.normal(0, 1), 2)
        term = int(rng.choice([36, 60], p=[0.72, 0.28]))
        status = str(rng.choice(STATUSES, p=STATUS_P))
        if year <= 2015 and status in ("Current", "In Grace Period"):
            status = "Fully Paid"
        principal_paid = amt if status == "Fully Paid" else round(amt * rng.uniform(0.05, 0.7), 2)
        row = {
            "id": str(10_000_000 + i),
            "loan_amnt": f"{amt:.1f}",
            "term": f" {term} months",
            "int_rate": f"{rate}",
            "installment": f"{amt / term * 1.15:.2f}",
            "grade": GRADES[g],
            "sub_grade": f"{GRADES[g]}{rng.integers(1, 6)}",
            "emp_length": str(rng.choice(["< 1 year", "1 year", "5 years", "10+ years", ""])),
            "home_ownership": str(rng.choice(["RENT", "MORTGAGE", "OWN"])),
            "annual_inc": f"{rng.lognormal(11.1, 0.5):.0f}",
            "verification_status": str(rng.choice(["Verified", "Not Verified", "Source Verified"])),
            "issue_d": f"{MONTHS[rng.integers(0, 12)]}-{year}",
            "loan_status": status,
            "purpose": str(rng.choice(PURPOSES)),
            "addr_state": str(rng.choice(STATES, p=[0.0995] * 10 + [0.004, 0.001])),
            "dti": f"{np.clip(rng.normal(18 + drift, 8), 0, 60):.2f}",
            "delinq_2yrs": str(int(rng.poisson(0.3))),
            "fico_range_low": str(fico_low),
            "fico_range_high": str(fico_low + 4),
            "revol_util": f"{np.clip(rng.normal(50, 24), 0, 120):.1f}",
            "open_acc": str(int(rng.integers(2, 30))),
            "total_pymnt": f"{principal_paid * 1.12:.2f}",
            "total_rec_prncp": f"{principal_paid:.2f}",
            "recoveries": f"{(amt - principal_paid) * 0.08:.2f}" if status == "Charged Off" else "0.0",
        }
        rows.append(row)

    # Deliberate defects so each DQ rule has something to detect.
    for r in rng.choice(len(rows), 40, replace=False):
        rows[r]["annual_inc"] = ""
    for r in rng.choice(len(rows), 15, replace=False):
        rows[r]["dti"] = "999"
    for r in rng.choice(len(rows), 10, replace=False):
        rows[r]["fico_range_high"] = str(int(rows[r]["fico_range_low"]) - 5)
    rows[11]["revol_util"] = ""
    rows[-1]["id"] = rows[0]["id"]                # one duplicated loan id
    rows.append({k: "" for k in rows[0]} | {"id": "Total amount funded in policy code 1: 0"})

    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"Wrote {len(rows):,} synthetic rows to {out} (as of {date.today()})")


if __name__ == "__main__":
    main()
