# 📘 CEDT 2110413 Computer Security - Assignment Repository

This repository contains my cedt computer security activity solutions, written as **Jupyter notebooks** (Python) and, where a written proof or derivation is needed, in **LaTeX**.
It is structured for clarity, reproducibility, and ease of compilation.

---

## 📂 Repository Structure

```
.
├── activity-01/
│   ├── activity-01.tex         # LaTeX write-up (uses CEDT-Assignment-style)
│   ├── activity-01.pdf         # Compiled/exported assignment
│   ├── code/
│   │   └── activity-01.ipynb   # Jupyter notebook (circuits, code)
│   └── images/                 # Diagrams / figures (if any)
├── activity-02/ ...            # Later activities, same layout (notebook and/or LaTeX)
├── vendor/template/            # Git submodule: shared style + scaffolding (see below)
├── course-config.tex           # This subject's values (course code/name, student info)
├── Makefile                    # Thin wrapper that includes vendor/template/Makefile.include
├── .gitmodules
├── .gitignore
└── README.md
```

- **`activity-xx/`** → Each activity, as a Jupyter notebook and/or LaTeX source, with its compiled PDF and (for LaTeX ones) a per-folder `.latexmkrc`.
- **`images/`** → Supporting figures, TikZ diagrams, plots, or circuit screenshots.

### Shared template (`vendor/template/`)

`CEDT-Assignment-style.sty`, `templates/assignment-template.tex`, `new-assignment.sh`,
`.latexindent.yaml`, and the Makefile build rules all live in a separate repo,
[`cedt-latex-template`](../../../cedt-latex-template), vendored here as a git submodule at
`vendor/template/` rather than copy-pasted per subject. This repo (and any other CEDT subject
repo) only owns `course-config.tex`, which sets the subject-specific values
(`\CourseCode`, `\CourseName`, `\StudentID`, `\StudentName`, `\DefaultCollaborators`) that the
shared style/template read.

To pull in template updates:

```bash
git submodule update --remote --merge vendor/template
git add vendor/template && git commit -m "Update template submodule"
```

To bootstrap a *new* subject repo the same way:

```bash
git submodule add <template-repo-url> vendor/template
cp vendor/template/course-config.tex.example course-config.tex
# edit course-config.tex, then:
git add vendor/template .gitmodules course-config.tex
```

---

## 🛠️ Requirements

For notebook-based assignments (e.g. IBM Quantum Experience / Qiskit circuits), you'll need:

- **Python 3** with `jupyter`, plus whatever quantum SDK the assignment calls for (e.g. `qiskit`) — see `.venv/` for the local environment used here.
- To export a notebook to a *styled* PDF (see "Notebook → Styled PDF" below), `nbconvert` also needs a working `xelatex` from your TeX distribution — it's the only engine `nbconvert`'s PDF exporter shells out to, regardless of which LaTeX engine you use elsewhere in this repo.

To compile the `.tex` files into PDF, you'll need:

- **LaTeX distribution** with `latexmk` and `latexindent` (e.g., [TeX Live](https://tug.org/texlive/), [MikTeX](https://miktex.org/), or Overleaf online)
- Recommended packages:
  - `amsmath`, `amssymb` (math environments and symbols)
  - `enumitem` (custom lists)
  - `tcolorbox` (solution/problem boxes)
  - `tikz`, `pgfplots` (diagrams)
  - `graphicx`, `booktabs` (images and tables)

---

## ▶️ Compilation

Each LaTeX assignment folder has its own `.latexmkrc`, so builds are per-project. Use the root `Makefile`:

```bash
make build DIR=activity-06   # compile once
make watch DIR=activity-06   # rebuild automatically on save (latexmk -pvc)
make clean DIR=activity-06   # remove build artifacts for one project
make clean-all                 # remove build artifacts for every project
```

Or run `latexmk` directly from inside an assignment folder:

```bash
cd activity-06
latexmk
```

The compiled PDF will appear as `activity-06.pdf` next to the source.

If you're using VS Code, open the repo with the [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.LaTeX-Workshop) extension — it will build on save using the same `.latexmkrc`.

---

## 📓 Notebook → Styled PDF

For notebook-based assignments, `make nb-pdf` exports a `.ipynb` straight to PDF via `jupyter nbconvert`, styled with the same `CEDT-Assignment-style.sty` fonts/margins/header as the LaTeX write-ups (via a custom nbconvert template at `vendor/template/templates/nbconvert/cedt-assignment/`):

```bash
make nb-pdf NB=activity-01/code/activity-01-code.ipynb
```

The PDF is written next to the notebook, same as `jupyter nbconvert`'s default. Equivalent to running directly:

```bash
export TEXINPUTS="$(pwd):$(pwd)/vendor/template:$TEXINPUTS"
jupyter nbconvert --to pdf \
  --TemplateExporter.extra_template_basedirs=vendor/template/templates/nbconvert \
  --template=cedt-assignment \
  activity-01/code/activity-01-code.ipynb
```

`TEXINPUTS` is what lets the template find `CEDT-Assignment-style.sty` (in `vendor/template/`) and `course-config.tex` (at the repo root) — `nbconvert`'s PDF exporter always compiles in an isolated temp directory, so relative paths to either can never resolve there. `make nb-pdf` sets this up for you (via `JUPYTER := $(CURDIR)/.venv/bin/jupyter` in `vendor/template/Makefile.include`); only reach for the manual command if you need to run outside the repo root.

---

## 🧹 Formatting

[`latexindent`](https://github.com/cmhughes/latexindent.pl) (ships with TeX Live) reformats indentation only — it never touches wording, math, or numbers. Repo-specific rules live in `.latexindent.yaml` (keeps `codingbox` contents verbatim, indents `subproblems`/`subproblems_alpha` like normal lists).

```bash
make fmt DIR=activity-06   # format one project in place
make fmt-all                 # format every project in place
```

---

## 🆕 Starting a New Assignment

```bash
make new NAME=activity-07
```

This scaffolds `activity-07/` from the shared `assignment-template.tex`, pre-fills the activity number, and copies the shared `.latexmkrc`. The subject line and author block come from `course-config.tex` automatically. Fill in the week number and section/problem content, then build with `make build DIR=activity-07`.

---

## 🩹 Fixing Mistakes

If a mistake turns up in an already-submitted assignment — a wrong answer, a typo, a broken calculation — fix it in its own dedicated pull request, scoped to that assignment only. Don't bundle it with unrelated tooling or template changes.

- One mistake, one PR, e.g. `gh pr create --title "Assignment 05 | Fix wrong answer"`.
- Follow the existing commit style: `<Assignment/Scope> | <what changed>`.
- Keep the diff minimal — fix the mistake, don't rewrite the surrounding solution.

---

## 📑 Features

* Clean **problem/solution structure** using custom LaTeX environments.
* Highlighted **"To Submit"** sections via `tcolorbox`.
* **TikZ diagrams** for circuits, vectors, and geometry, with `positioning`, `arrows.meta`, `calc`, and `shapes.geometric` loaded.
* Configurable **assignment title page** with `\asgntitle{}` macro.
* `\fig[width]{path}{caption}{label}` for numbered, labelled figures.
* `simpletable` environment for `booktabs`-style tables with automatic caption/label.
* `\choices[num choices]{choice A, choice B, ...}` for multiple-choice options, auto-laid-out into 4 / 2 / 1 columns depending on how long the choices are (see `choices-check/` for a worked example of every case).

---

## 👤 Author

* Name: *Patthadon Phengpinij (CEDT02)*
* Course: (1/2026) *2110413 Computer Security* for CU CEDT
---

📌 *This repo is mainly for educational purposes. Please do not copy directly; use it as reference for your own work.*
