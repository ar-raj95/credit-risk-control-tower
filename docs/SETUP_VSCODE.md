# Step-by-step guide: build the Credit Risk Control Tower in VS Code

This guide takes you from an empty laptop to a public GitHub repo with a working dbt pipeline, a Power BI report, a docs site and a demo. Follow it in order. Each phase ends with a check, so you always know whether you're on track before moving on.

**Assumes Windows**, because Power BI Desktop only runs on Windows. All commands are for the PowerShell terminal inside VS Code.

**Three things that cause most problems:**

1. **Wrong Python version.** Use Python 3.12. Newer versions (3.15) can't install dbt yet.
2. **Wrong folder in the terminal.** Look at the path before the `>` in the prompt. Python scripts (`python ingest/...`) and `git` run from the **project root**. `dbt` commands run from the **`dbt` folder**. Use `cd dbt` to go in and `cd ..` to come back out.
3. **Environment not active.** The prompt must start with `(.venv)`. If not, run `.venv\Scripts\Activate.ps1` from the project root.

| Phase | What you finish with | Time |
|---|---|---|
| 1. Install tools | Python, Git, VS Code, Power BI ready | 45 min |
| 2. Open the project | Project open in VS Code with extensions | 15 min |
| 3. Python environment | dbt installed and working | 15 min |
| 4. Synthetic run | Pipeline passing on fake data | 15 min |
| 5. Real data run | Pipeline passing on 2.26M real loans | 1 hour |
| 6. Lint and check | Clean SQL, reconciled numbers | 30 min |
| 7. GitHub | Public repo, CI green, docs site live | 1 hour |
| 8. Power BI model | Tables, relationships, measures | 1 evening |
| 9. Report pages | 7 pages built in 2 releases | 3 to 4 evenings |
| 10. Governance features | RLS, field parameter, bookmarks | 1 evening |
| 11. Publish and polish | Screenshots, PDF, demo, findings | 1 evening |
| 12. Send | Email to Pavleen | 15 min |

---

## Phase 1: Install the tools (one time)

### 1.1 Python 3.12
1. Go to python.org > Downloads > Windows and download **Python 3.12** (the latest 3.12.x installer). **Don't use the newest Python version** shown on the front page: the project is tested on 3.12, and newer versions such as 3.15 fail because one of dbt's dependencies doesn't support them yet.
2. Run the installer. On the first screen, **tick "Add python.exe to PATH"**. This is the step people most often miss.
3. Click **Install Now**.

Python 3.12 installs alongside any other version you already have. It doesn't replace or break it.

### 1.2 Git
1. Download **Git for Windows** from git-scm.com.
2. Run the installer and accept the defaults.

### 1.3 VS Code
1. Download from code.visualstudio.com and install.
2. On the "Select Additional Tasks" screen, tick **"Add 'Open with Code' action"** for both files and folders. It saves time later.

### 1.4 Power BI Desktop
Install **Power BI Desktop** from the Microsoft Store. The Store version updates itself.

### 1.5 Accounts
- **GitHub** (github.com): pick a professional username, since it will be in your link to the team.
- **Kaggle** (kaggle.com): needed to download the data.

### Check
Open a new PowerShell window (Start > PowerShell) and run:

```powershell
python --version
git --version
```

You should see `Python 3.12.x` and a Git version. If you have more than one Python installed, run `py --list` to see them all; you need 3.12 in the list. If `python` opens the Microsoft Store instead, reinstall Python with "Add to PATH" ticked, then open a **new** PowerShell window.

---

## Phase 2: Open the project in VS Code

### 2.1 Unzip
Unzip `credit-risk-control-tower.zip` to a simple path, for example `C:\projects\credit-risk-control-tower` or `C:\Users\<you>\Downloads\credit-risk-control-tower`.

Avoid folders that sync to OneDrive (often Desktop and Documents). Syncing can lock the database file in the middle of a build. Downloads is usually fine.

**Use only the latest zip from the chat.** If you downloaded files more than once, Windows names the copies `SETUP_VSCODE (1).md` and so on. Delete the extras so you never edit the wrong file.

### 2.2 Show file extensions in File Explorer
Windows hides extensions by default, so `data.csv` and `data.csv.gz` look the same. In File Explorer: **View > Show > File name extensions**. You'll need this in Phase 5.

### 2.3 Open the folder
1. Open VS Code.
2. **File > Open Folder** and choose `credit-risk-control-tower` (the folder that contains `README.md`, not its parent).
3. If asked "Do you trust the authors?", click **Yes**.

### 2.4 Install the extensions
The project includes a list of recommended extensions. VS Code shows a pop-up at the bottom right: click **Install All**.

If you miss the pop-up, open Extensions (**Ctrl+Shift+X**), type `@recommended`, and install:

| Extension | What it does for you |
|---|---|
| Python (Microsoft) | Runs Python and uses the project environment |
| Power User for dbt | Lineage graph, compiled SQL preview, run buttons |
| sqlfluff | Underlines SQL style issues as you type |
| Rainbow CSV | Colours columns in the seed files so they're easy to edit |

Power User may show an item in the **Problems** tab, or a red dot on the `dbt` folder, until Phase 3 is done. That's expected. Phase 3.5 clears it.

### 2.5 Get to know the layout
Open the Explorer (**Ctrl+Shift+E**) and look at:

- `ingest/`: loads the raw file into the database
- `dbt/models/`: the SQL pipeline (staging, intermediate, marts)
- `dbt/seeds/`: business rules as CSV files (thresholds, mappings, DQ rules)
- `docs/`: product owner documents and the Power BI guide

### Check
Open `requirements.txt`. The first line must start with `# Use Python 3.12`, and the file must list `dbt-duckdb`. If it lists `dbt-snowflake` or `pandas`, you have an old copy of the project: unzip the latest zip from the chat and start Phase 2 again.

---

## Phase 3: Create the Python environment

### 3.1 Open the terminal
Press **Ctrl+`** (the key above Tab). A PowerShell terminal opens in the project folder.

### 3.2 Confirm Python 3.12 is available

```powershell
py --list
```

You need a line containing `3.12`. Other versions in the list (for example 3.15) are fine; they stay installed and this project won't use them. If 3.12 is missing, go back to step 1.1, then close and reopen VS Code.

### 3.3 Create and activate the environment

```powershell
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
python --version
```

**The last line must print `Python 3.12.x`.** If it shows anything else, stop: delete the environment with `deactivate` then `Remove-Item -Recurse -Force .venv`, and repeat this step.

**If you see "running scripts is disabled on this system"**, run this once, answer Y, then run the activate line again:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

When it works, the prompt starts with `(.venv)`.

### 3.4 Install the packages

```powershell
python -m pip install --upgrade pip
pip install -r requirements.txt
```

The command is **`pip install`**, not `python install`. This one line installs dbt, the DuckDB adapter and SQLFluff.

### 3.5 Point VS Code at the environment
1. Press **Ctrl+Shift+P**, type **Python: Select Interpreter**, and choose the one that shows `.venv`.
2. Press **Ctrl+Shift+P** again and run **Developer: Reload Window**. This clears the Power User warning from Phase 2.

### Check

```powershell
dbt --version
Get-Command dbt
```

You should see:
- `Core: installed: 1.12.6`
- Under **Plugins**: `duckdb: 1.11.1`. If it says `snowflake` instead, you installed from an old `requirements.txt`. See the Troubleshooting table.
- A path ending in `.venv\Scripts\dbt.exe` from `Get-Command dbt`

The message "dbt v2 is available, and is the default for new installations" is only a notice. This project uses dbt Core v1 on purpose; ignore it.

**Habit to build now:** every time you open a new terminal, look for `(.venv)` at the start of the prompt. If it's missing, run `.venv\Scripts\Activate.ps1`. Most "not recognized" errors come from skipping this.

---

## Phase 4: First run on synthetic data

This proves your setup works in 2 minutes, before you download 1.6 GB.

### 4.1 Create and load fake data
From the project root:

```powershell
python ingest/make_fixture.py
python ingest/load_raw.py --input data/fixture.csv
```

You should see `Wrote 5,001 synthetic rows` and `Loaded 5,001 raw rows`.

### 4.2 Build the pipeline

```powershell
cd dbt
dbt build
```

### Check
The last line should read:

```
Done. PASS=77 WARN=1 ERROR=0 SKIP=0 NO-OP=1 ...
```

The 1 warning is deliberate: the fake data contains 15 impossible DTI values, and the test catches them. This proves the test works. You'll also see `Exported ... .parquet` lines just before it, and a `data\marts` folder appears.

### 4.3 Explore the lineage
From the `dbt` folder:

```powershell
dbt docs generate
dbt docs serve
```

**What to expect:**
- The terminal prints `Serving docs at 8080` and then **keeps running with no prompt**. That's normal: it's acting as a small web server until you stop it.
- If no browser window opens, open Chrome or Edge and go to **http://localhost:8080**.
- Lines ending in `200` are successful requests. A few lines with `404` mentioning `getIcon` or `favicon.ico` are harmless and appear for everyone.

In the browser:
1. Click the **green circle icon** at the bottom right to see the lineage graph, from the raw source to the Power BI exposure.
2. Click `fct_kri_quarterly` in the left panel to see its description and tests.
3. Open **Project > seeds > risk_appetite** to see where thresholds are documented.

When you're done, click in the terminal, press **Ctrl+C** to stop the server, then go back to the project root:

```powershell
cd ..
```

To keep the docs open while you work, leave that terminal running and open a second one with the **+** at the top right of the terminal panel. Activate the environment in the new terminal first.

### 4.4 Try the Power User extension
Open `dbt/models/marts/monitoring/fct_psi.sql`. Use the Power User panel (dbt icon in the left bar) to view lineage and compiled SQL for the open file. This is a good thing to show in your demo.

---

## Phase 5: Run on the real data

### 5.1 Download
1. On Kaggle, search **lending club** and open the dataset by **wordsforthewise**.
2. Click **Download**. You get a large zip file, often named `archive.zip`.
3. Right-click it in File Explorer, choose **Extract All**.
4. Inside, find the accepted-loans file. Depending on how it was extracted, it's either:
   - `accepted_2007_to_2018Q4.csv.gz` (about 375 MB), or
   - `accepted_2007_to_2018Q4.csv` (about 1.6 GB). Windows may show its type as "Microsoft Excel Comma Separated Values File".

   Either works. Note which one you have.
5. Move that one file into the project's `data` folder. The `rejected_...` file isn't needed.

**Don't open the CSV in Excel.** Excel stops at about 1 million rows (this file has over 2 million), and saving it would cut the data.

**If you can't find the file**, search your Downloads folder from the terminal:

```powershell
Get-ChildItem $HOME\Downloads -Recurse -Filter "accepted_2007_to_2018*" -ErrorAction SilentlyContinue | Select-Object FullName, Length
```

Then move it, pasting the full path from the result:

```powershell
Move-Item "PASTE-FULL-PATH-HERE" .\data\
```

Note: `cd` only works on folders. You never need to `cd` into the data file; the loader reads it from the path you give it.

### 5.2 Load the data
From the **project root** (not the `dbt` folder), with `(.venv)` active. Use the line that matches your file:

```powershell
python ingest/load_raw.py --input data/accepted_2007_to_2018Q4.csv
```

or

```powershell
python ingest/load_raw.py --input data/accepted_2007_to_2018Q4.csv.gz
```

The terminal may look idle for a few minutes. Wait for:

```
Loaded 2,260,701 raw rows from accepted_2007_to_2018Q4.csv into data/warehouse.duckdb (raw.lendingclub_loans)
```

The loader replaces the fake data with the real data. If it says `Input not found`, run `dir data` and copy the exact file name.

### 5.3 Build

```powershell
cd dbt
dbt build
```

### Check
On the full Kaggle file, the expected result is:

```
Done. PASS=77 WARN=1 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=79
```

with the build taking around 20 seconds to a minute, and 15 `Exported ... .parquet` lines before it.

The 1 warning is a **real data quality finding**: about 2,563 loans have a DTI below 0 or above 100. It warns rather than blocks because it only affects DTI bands, and rule DQ06 tracks it on the scorecard. Missing DTI values aren't counted here; those are DQ02.

### 5.4 Investigate the warning
This makes a good interview story ("the pipeline flagged 2,563 implausible DTI values; here's what I found"). From the `dbt` folder:

```powershell
dbt show --inline "select case when dti < 0 then 'negative' when dti <= 200 then '100 to 200' when dti < 999 then '200 to 999' else '999 or more' end as dti_range, count(*) as loans, min(dti) as min_dti, max(dti) as max_dti from {{ ref('stg_lendingclub__loans') }} where dti < 0 or dti > 100 group by 1 order by 2 desc"
```

How to read it:
- **A spike at one exact value** (like -1 or 999) usually means a placeholder code from the source system, not a real ratio. The remediation is upstream: ask the data owner what the code means.
- **A spread between 100 and 200** is more likely genuine, very indebted borrowers. These may be valid but worth a policy question.

Write down what you found. You'll use it in step 5.6 and in Key findings.

### 5.5 If something fails
The output names the failing test. Common cases on real data:

| Message mentions | What it means | What to do |
|---|---|---|
| `relationships_..._loan_status` | The source has a status not in the mapping | Find it (query below), add a row to `dbt/seeds/loan_status_map.csv` with the right flags, rerun `dbt build` |
| `accepted_values_..._grade` | A grade other than A to G | Find it with a similar query and decide whether to map or exclude it |
| `assert_fct_loans_reconciles_to_source` | Totals differ by more than 0.1% | Paste the error into a chat with Claude for help |
| `Database is locked` | Another program has the database open | Stop any `dbt docs serve` or other terminal using it, then rerun |
| Contract error on `fct_loans` | A column type changed | Read the table in the error; it names the column and both types |
| `Export skipped` | A test failed, so nothing was exported | Fix the failing test; this is the safety feature working |

To look at the data behind a failure, from the `dbt` folder:

```powershell
dbt show --inline "select loan_status, count(*) as loans from {{ ref('stg_lendingclub__loans') }} group by 1 order by 2 desc"
```

Each failure you fix is a real example for your interview ("the pipeline stopped because the source sent an unmapped status; I mapped it through a reviewed change").

### 5.6 Record the run
1. In `docs/05_uat_and_reconciliation.md`, update **Last automated run** to: today's date, "full Kaggle file, 2,260,701 raw rows, PASS=77 WARN=1 ERROR=0". Use your actual numbers if they differ.
2. In `docs/06_raid_log.md`:
   - Close issue **I1** (change Status to Closed, and note the date and result).
   - Add **I2**: "2,563 loans with DTI outside 0 to 100 (DQ06)", with what step 5.4 showed and the action, for example "Confirm meaning of value X with origination data owner".

---

## Phase 6: Lint and reconcile

### 6.1 Lint the SQL
From the project root:

```powershell
$env:DUCKDB_PATH = "$PWD\data\warehouse.duckdb"
sqlfluff lint dbt/models dbt/tests
```

You want `All Finished!` with no `FAIL` lines. If you edit SQL and get style issues, run `sqlfluff fix dbt/models dbt/tests`, then rerun `dbt build` to confirm nothing broke.

### 6.2 Check three numbers by hand
Pick three cuts and record them, because you'll compare them with Power BI later. From the `dbt` folder:

```powershell
dbt show --inline "select count(*) as loans, sum(loan_amount) as funded, sum(is_default) * 1.0 / nullif(sum(is_closed), 0) as default_rate from {{ ref('fct_loans') }} where grade = 'C' and year(issue_date) = 2016"
```

Change the filter for your other two cuts, for example `purpose = 'small_business'` or `fico_band = '<660'`. Paste the results into the spot-check table in `docs/05_uat_and_reconciliation.md`.

---

## Phase 7: Put it on GitHub

### 7.1 Personalize the files
1. Press **Ctrl+Shift+H** (search and replace across all files).
2. Search ar-raj95, replace with your GitHub username, click **Replace All**.
3. Search Abhishek Raj and https://www.linkedin.com/in/ar-abhishek-raj/ and fill them in.
4. Search ar.rajabhishek@gmail.com and replace it with a contact email you're happy to show publicly, or leave it.

### 7.2 Create the empty repo on GitHub
1. On github.com, click **+ > New repository**.
2. Name: `credit-risk-control-tower`. Visibility: **Public**.
3. Leave **every** "Add a README / .gitignore / licence" box **unticked**.
4. Click **Create repository** and keep the page open.

### 7.3 Make the first commit
In the VS Code terminal, from the project root:

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git init
git add .
git status
```

**Before committing, read the `git status` list.** It must not include:
- anything inside `data\` except `data/.gitkeep`
- any `.duckdb` file
- the `.venv` folder

If any of those appear, stop and check `.gitignore` is in the project root.

```powershell
git commit -m "Add dbt pipeline, tests, CI and product documents"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/credit-risk-control-tower.git
git push -u origin main
```

The first push opens a browser to sign in to GitHub. Approve it.

### 7.4 Turn on the docs site
1. In your repo on GitHub: **Settings > Pages**.
2. Under **Build and deployment > Source**, choose **GitHub Actions**.

### 7.5 Watch CI run
1. Open the **Actions** tab. A run called **dbt CI** starts.
2. It builds the pipeline on synthetic data, runs every test, lints the SQL and publishes the docs site. It takes a few minutes.

### Check
- The Actions run shows a green tick.
- The README badge shows **passing**.
- Your docs site loads at `https://YOUR-USERNAME.github.io/credit-risk-control-tower`.

If a step is red, click it to see the log and the failing command.

### 7.6 Pin and tag the repo
1. On your GitHub profile, click **Customize your pins** and pin this repo.
2. On the repo page, click the gear next to **About**, add a one-line description, and add topics: `power-bi`, `dbt`, `credit-risk`, `data-quality`, `product-owner`, `duckdb`.

### Commit habit from here on
Commit after each meaningful piece of work, with a clear message. Reviewers read commit history. You can use the **Source Control** panel (**Ctrl+Shift+G**): type a message, click **Commit**, then **Sync Changes**. Or in the terminal:

```powershell
git add .
git commit -m "Add Executive Summary page"
git push
```

---

## Phase 8: Build the Power BI model

`docs/POWERBI_GUIDE.md` has the full DAX. This phase walks through the clicks.

### 8.1 Turn on the project format
1. Open Power BI Desktop.
2. **File > Options and settings > Options > Preview features**. If you see **Power BI Project (.pbip) save option**, tick it and restart Power BI. If it isn't listed, the feature is already on in your version.

### 8.2 Create the folder parameter
1. **Home > Transform data** to open Power Query.
2. **Manage Parameters > New Parameter**.
3. Name `MartsFolder`, type **Text**, current value: your full path, for example `C:\projects\credit-risk-control-tower\data\marts`.
4. Click **OK**.

### 8.3 Load each table
For each Parquet file:
1. **New Source > Blank Query**.
2. **Advanced Editor**, replace everything with (changing the file name each time):

```
let
    Source = Parquet.Document(File.Contents(MartsFolder & "\fct_loans.parquet"))
in
    Source
```

3. Rename the query (right panel, Name) to the business name below.

| File | Query name |
|---|---|
| fct_loans | FactLoans |
| fct_kri_quarterly | FactKRI |
| fct_psi | FactPSI |
| fct_psi_bins | FactPSIBins |
| fct_dq_results | FactDQ |
| dim_date | DimDate |
| dim_quarter | DimQuarter |
| dim_grade | DimGrade |
| dim_purpose | DimPurpose |
| dim_state | DimState |
| dim_fico_band | DimFICOBand |
| dim_dti_band | DimDTIBand |
| risk_appetite | RiskAppetite |
| metric_dictionary | MetricDictionary |
| dq_rule_catalog | DQRules |

Shortcut: after the first one, right-click the query > **Duplicate**, then edit the file name in the Advanced Editor.

4. Check the column types look right (dates as dates, amounts as decimal numbers). Then **Close & Apply**.

### 8.4 Save as a project
**File > Save as**, choose the `powerbi` folder in the repo, set **Save as type** to **Power BI project files (\*.pbip)**, name it `CreditRiskControlTower`.

### 8.5 Create the relationships
Go to **Model view** (third icon on the left). Drag each key onto its match, or use **Manage relationships > New**. All are **one to many** with **single** cross-filter direction:

| From (one side) | To (many side) |
|---|---|
| DimQuarter[quarter_key] | DimDate[quarter_key] |
| DimDate[date_day] | FactLoans[issue_date] |
| DimGrade[grade] | FactLoans[grade] |
| DimPurpose[purpose] | FactLoans[purpose] |
| DimState[state_code] | FactLoans[state_code] |
| DimFICOBand[fico_band] | FactLoans[fico_band] |
| DimDTIBand[dti_band] | FactLoans[dti_band] |
| DimQuarter[quarter_key] | FactKRI[period_key] |
| DimQuarter[quarter_key] | FactPSI[period_key] |
| DimQuarter[quarter_key] | FactPSIBins[period_key] |
| DimQuarter[quarter_key] | FactDQ[period_key] |
| DQRules[rule_id] | FactDQ[rule_id] |

Leave **RiskAppetite** and **MetricDictionary** unconnected.

Delete any relationship Power BI created automatically that isn't in this table.

### 8.6 Set up the date table and sort orders
1. Select **DimDate** > **Table tools > Mark as date table** > choose `date_day`.
2. Select `DimQuarter[quarter_label]` > **Column tools > Sort by column** > `quarter_key`.
3. Do the same for `DimFICOBand[fico_band]`, `DimDTIBand[dti_band]` and `DimGrade[grade]`, sorting by `sort_order`.
4. Select `DimDate[month_label]` and sort by `month_key`.

### 8.7 Create the measures table
1. **Home > Enter data**, name the table `_Measures`, click **Load**.
2. Add each measure from `docs/POWERBI_GUIDE.md` section 3: select `_Measures`, **New measure**, paste one measure at a time.
3. When all measures exist, delete the default `Column1` in `_Measures`.
4. Select each measure and set its **Display folder** (Properties pane): Exposure, Performance, Credit quality, Stability, Data quality, RAG.
5. Format rates as **Percentage, 1 decimal**, and amounts as **Currency, 0 decimals**.

### 8.8 Tidy the model
1. Hide all key columns on fact tables (right-click > **Hide in report view**).
2. Hide raw numeric columns that now have measures (`loan_amount`, `loss_amount`, flags).
3. Set **Summarization: Don't summarize** on `loan_id` and all key columns.

### Check
Put a card with `[Default Rate]` and a slicer on `DimQuarter[quarter_label]` on a blank page. The card should change when you pick a quarter. Commit:

```powershell
git add .
git commit -m "Add Power BI semantic model"
git push
```

Before pushing, check `git status` doesn't list `cache.abf`.

---

## Phase 9: Build the report pages

### 9.1 Set the theme first
1. **View > Themes > Customize current theme**.
2. Pick one neutral palette (greys and one accent), plus RAG colours used only for status: Red `#C0392B`, Amber `#E6A23C`, Green `#2E8B57`.
3. Set one font (Segoe UI) for everything.

### 9.2 Page layout rules
- A slicer panel on the left of every page: Quarter, Grade, Purpose, Region.
- No more than 6 to 7 visuals per page.
- Every axis labelled; every chart titled with the question it answers.
- Alt text on each visual (Format > General > Alt text).

### Release 1: Pages 1 to 3

**Page 1, Executive Summary**
1. Cards: Default Rate, Delinquency Rate, Net Loss Rate, Funded Amount, DQ Pass Rate, Max PSI.
2. For each card: **Format > Callout value > Colour > fx > Format style: Field value**, using the matching RAG measure. Build the RAG measures by wrapping `[KRI RAG]` as shown in the Power BI guide, plus a colour measure that returns the hex code for each status.
3. A line chart of `[Default Rate]` by `DimQuarter[quarter_label]`.
4. A table of `FactKRI` filtered to `rag` = Red or Amber for the latest quarter: the "breaches" list.
5. A text box with the `[Exec Title]` measure as the page title (Insert > Text box > + Value).
6. **View > Mobile layout**: arrange the cards for phone.

**Page 2, Composition and Concentration**
1. Bar chart: `[Funded Amount]` by `DimGrade[grade]`.
2. Bar chart: `[Funded Amount]` by `DimPurpose[purpose_label]`.
3. Filled map: `[Funded Amount]` by `DimState[state_name]`.
4. Table: Purpose, `[Funded Amount]`, `[Exposure Share]`, `[Default Rate]`, with conditional formatting on Exposure Share above 20%.

**Page 3, Vintage Performance**
1. Line chart: `[Default Rate]` and `[Delinquency Rate]` by `DimQuarter[quarter_label]`.
2. Column chart: `[Funded Amount]` by quarter.
3. Shade immature quarters: add `FactKRI[is_right_censored]` to the tooltip and as a legend or background rule.
4. Text box: "Quarters marked immature have under half their loans at full term. Their default rates are understated and will rise."

**Hidden reconciliation page**
1. New page, name it `Reconciliation`, right-click the tab > **Hide page**.
2. Table: `DimQuarter[quarter_label]`, `[Default Rate]`, a measure for the KRI value (`CALCULATE ( SUM ( FactKRI[kri_value] ), FactKRI[kri] = "default_rate" )`), and a difference measure.
3. Every difference should be 0.

### Check for Release 1
- Compare your 3 hand-checked cuts from Phase 6.2 with the report. Record both values in the UAT file.
- Run UAT-01 to UAT-06 in `docs/05_uat_and_reconciliation.md` and fill in the Result and Date columns.
- Commit with the message "Release 1: Pages 1-3".

### Release 2: Pages 4 to 7

**Page 4, Segment Drill-down**
1. Matrix: rows `DimFICOBand[fico_band]`, columns `DimDTIBand[dti_band]`, values `[Default Rate]`. Turn on **Background colour** conditional formatting (gradient).
2. Table of the top 10 segments by `[Loss Amount]` (use **Top N** filter).
3. **Decomposition tree** on `[Loss Amount]`, explained by grade, purpose, FICO band, DTI band.
4. **Drill-through page**: a new page with a loan-level table from `FactLoans`. Add `DimGrade[grade]` and `DimFICOBand[fico_band]` to its drill-through field well.

**Page 5, Population Stability**
1. Matrix: rows `FactPSI[feature]`, columns `DimQuarter[quarter_label]`, values `[Max PSI]`, background colour by `FactPSI[rag]`.
2. Line chart: `[Max PSI]` by quarter, legend `feature`, with constant lines at 0.10 and 0.25 (Analytics pane).
3. Drill-through page using `FactPSIBins`: clustered columns of `baseline_share` and `current_share` by `bin_no`.
4. Tooltip text: "Below 0.10 stable, 0.10 to 0.25 moderate shift, 0.25 and above significant shift."

**Page 6, Data Quality Scorecard**
1. Cards: `[DQ Pass Rate]` for each dimension (use a card per dimension with a visual-level filter, or a multi-row card).
2. Matrix: rows `FactDQ[rule_id]` and `description`, columns quarter, values `[DQ Pass Rate]` with conditional formatting.
3. Line chart: failing records `SUM ( FactDQ[failed] )` by quarter.
4. Table: rule, severity, owner from `DQRules`.

**Page 7, Metric Dictionary**
1. Table visual on `MetricDictionary` with all columns, word wrap on.
2. On every other page: **Insert > Buttons > Information**, set **Action > Page navigation** to Page 7.

### Check for Release 2
Run UAT-07 to UAT-09, fill in results, commit "Release 2: Pages 4-7".

---

## Phase 10: Governance features

### 10.1 Row-level security
1. **Modeling > Manage roles > New**.
2. Name the role `West`. Select table `DimState`, and set the filter to `[region] = "West"`.
3. Repeat for `Northeast`, `Midwest`, `South`.
4. **Modeling > View as** > tick `West` > OK. Confirm only West states appear.
5. Check the West totals against a query (from the `dbt` folder):

```powershell
dbt show --inline "select count(*) as loans, sum(f.loan_amount) as funded from {{ ref('fct_loans') }} f join {{ ref('dim_state') }} s using (state_code) where s.region = 'West'"
```

6. Record UAT-10.

### 10.2 Field parameter
1. **Modeling > New parameter > Fields**.
2. Add `[Default Rate]`, `[Delinquency Rate]`, `[Net Loss Rate]`. Name it `Metric Selector`.
3. Use the parameter on the Page 3 line chart and Page 4 matrix. Keep the slicer it creates.
4. Record UAT-11.

### 10.3 Bookmarks
1. **View > Bookmarks**.
2. Set up Page 1 with filters cleared and save the bookmark as **Executive view**.
3. Set up Page 4 with the slicer panel open and save as **Analyst view**.
4. Add two buttons on Page 1 linking to these bookmarks.

### 10.4 Performance check
1. **Optimize > Performance analyzer > Start recording > Refresh visuals**.
2. Take a screenshot of the results and save it to `screenshots/performance.png`.
3. Any visual over 1 second: reduce its fields or simplify its measure.

### 10.5 Test that the gate protects the report (UAT-05)
1. In `dbt/seeds/loan_status_map.csv`, temporarily delete the `Current` row and save.
2. Run `dbt build` from the `dbt` folder. It fails, and the log says **Export skipped**.
3. Refresh Power BI: the numbers don't change.
4. Undo the change (**Ctrl+Z**, save), run `dbt build` again. It passes.
5. Record the result.

Commit "Release 3: RLS, field parameter, bookmarks".

---

## Phase 11: Publish and polish

### 11.1 Screenshots
For each page, use **Win+Shift+S** to capture it. Save as `screenshots/01_executive.png`, `02_composition.png` and so on.

Add them to the README under section 5:

```markdown
![Executive Summary](screenshots/01_executive.png)
```

### 11.2 PDF export
**File > Export > Export to PDF**, save as `powerbi/report.pdf`.

### 11.3 Key findings
In README section 7, replace the placeholders with 3 to 5 findings from the real data. Rules:
- Each finding has a number.
- Each number matches a value you checked in Phase 6.2 or the UAT file.
- Only use matured vintages for default rate comparisons, or say clearly that a vintage is immature.

Example structure (fill in with your own numbers): "Grade X loans are N% of funded amount but M% of principal loss."

### 11.4 Demo video (2 minutes)
Record with **Clipchamp** (built into Windows) or Loom. A suggested script:

| Time | Show | Say |
|---|---|---|
| 0:00 | README | The problem and who it's for |
| 0:15 | Page 1 | KRIs against appetite; thresholds come from one reviewed file |
| 0:35 | Pages 3 and 4 | Where risk builds; immature vintages flagged |
| 0:55 | Page 5 | PSI drift and the bin drill-through |
| 1:10 | Page 6 | DQ rules with owners and trend |
| 1:25 | dbt docs lineage | Source to report, every model tested |
| 1:40 | Terminal | The gate test: unmapped status stops the refresh |
| 1:55 | docs folder | Backlog, release plan, decision log |

Upload it (Loom, or YouTube as Unlisted) and put the link at the top of the README.

### 11.5 Final review before sharing
Open your repo in a **private browser window** (logged out) and check:

- [ ] README shows the screenshots and the CI badge is green
- [ ] Docs site link works
- [ ] Demo video link plays
- [ ] No ar-raj95, Abhishek Raj or `add link` placeholders remain (search with Ctrl+Shift+F in VS Code)
- [ ] No TD logos, branding or wording that implies affiliation
- [ ] No data files committed (check the `data` folder on GitHub contains only `.gitkeep`)
- [ ] Every figure in Key findings matches your reconciliation records
- [ ] Disclaimer about public proxy data and illustrative thresholds is visible

Final commit: "Add screenshots, demo and key findings".

---

## Phase 12: Send it

Use one of the email drafts from the chat. Replace the placeholders with:
- your GitHub profile link (`https://github.com/YOUR-USERNAME`)
- the repo link
- the demo link

Send it only after the checklist in 11.5 is complete.

---

## Troubleshooting

### Setup
| Problem | Cause | Fix |
|---|---|---|
| `python` opens the Microsoft Store | Python not on PATH | Reinstall 3.12 with "Add python.exe to PATH" ticked; open a new terminal |
| `python --version` in `.venv` shows 3.13, 3.14 or 3.15 | Environment created with the wrong Python | `deactivate`, `Remove-Item -Recurse -Force .venv`, then `py -3.12 -m venv .venv` |
| `No matching distribution found for metricflow`, or `cp315` in pip output | Environment on Python 3.15 | Same fix as above |
| `Could not find ... vswhere.exe` or "Preparing metadata ... error" | pip is trying to compile a package because there's no ready-made version for your Python | Use Python 3.12, where ready-made versions exist |
| `The term 'pyhton' is not recognized` | Typo | Check the spelling and rerun |
| `can't open file '...\install'` | Typed `python install` | The command is `pip install -r requirements.txt` |
| `dbt --version` shows `snowflake` under Plugins | Installed from an old `requirements.txt` | Replace `requirements.txt` with the latest version, then `pip uninstall -y dbt-snowflake snowflake-connector-python` and `pip install -r requirements.txt` |
| `dbt --version` shows `dbt 2.x` | A different dbt is being picked up | Rebuild `.venv` on 3.12 and reinstall; `Get-Command dbt` must point into `.venv` |
| `dbt` is not recognized | Environment not active | `.venv\Scripts\Activate.ps1` from the project root |
| `running scripts is disabled` | PowerShell policy | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Problems tab shows 1 item, red dot on `dbt` folder | Power User extension doesn't know the environment yet | **Python: Select Interpreter** > `.venv`, then **Developer: Reload Window** |

### Running the pipeline
| Problem | Cause | Fix |
|---|---|---|
| `Could not find profile` or `dbt_project.yml not found` | dbt run from the wrong folder | `cd dbt` first |
| `can't open file 'ingest/...'` | Python script run from the `dbt` folder | `cd ..` to the project root first |
| `cd : Cannot find path ...csv.gz` | `cd` used on a file | `cd` is only for folders; pass files to the loader with `--input` |
| `Input not found` from the loader | Wrong file name or extension | `dir data` and copy the exact name; it may be `.csv`, not `.csv.gz` |
| Terminal shows no prompt after `dbt docs serve` | The docs server is still running | Press Ctrl+C, or open a second terminal |
| `404` lines in the docs server output | Harmless icon requests | Ignore them |
| `Database is locked` | Another process has the database open | Stop `dbt docs serve` and other terminals using it, then rerun |
| `Cannot open file ... warehouse.duckdb` when linting | Lint needs the database path | From the project root: `$env:DUCKDB_PATH = "$PWD\data\warehouse.duckdb"` |
| `Export skipped` in the dbt log | A test failed, so nothing was exported | Fix the failing test; this is the safety feature working |

### Power BI and GitHub
| Problem | Cause | Fix |
|---|---|---|
| Power BI shows old numbers | Not refreshed, or export skipped | Check `dbt build` passed, then **Home > Refresh** |
| Power BI can't find a Parquet file | Wrong `MartsFolder` value | **Transform data > Manage parameters**, fix the path |
| `git push` rejected | Repo on GitHub isn't empty | Recreate the repo with all "Add" boxes unticked, or run `git pull origin main --allow-unrelated-histories` first |
| CI fails on GitHub but passes locally | Usually a lint issue or a seed change | Click the red step in Actions to read the log; run `sqlfluff lint` locally |

## Command cheat sheet

Run from the **project root** unless it says `dbt` folder.

| Task | Command |
|---|---|
| List installed Pythons | `py --list` |
| Create environment | `py -3.12 -m venv .venv` |
| Activate environment | `.venv\Scripts\Activate.ps1` |
| Install packages | `pip install -r requirements.txt` |
| Go into / out of the dbt folder | `cd dbt` / `cd ..` |
| Load fake data | `python ingest/make_fixture.py` then `python ingest/load_raw.py --input data/fixture.csv` |
| Load real data | `python ingest/load_raw.py --input data/accepted_2007_to_2018Q4.csv` (or `.csv.gz`) |
| Build and test everything (`dbt` folder) | `dbt build` |
| Build one model and its tests (`dbt` folder) | `dbt build --select fct_psi` |
| Build a model and everything after it (`dbt` folder) | `dbt build --select fct_loans+` |
| Run only unit tests (`dbt` folder) | `dbt test --select test_type:unit` |
| Query the data (`dbt` folder) | `dbt show --inline "select ..."` |
| Docs site (`dbt` folder) | `dbt docs generate` then `dbt docs serve`; Ctrl+C to stop |
| Lint | `$env:DUCKDB_PATH = "$PWD\data\warehouse.duckdb"` then `sqlfluff lint dbt/models dbt/tests` |
| Save work to GitHub | `git add .` then `git commit -m "message"` then `git push` |
