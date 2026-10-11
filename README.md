# BruBotics — sEMG tip-force modelling (Hyser baseline)

**Research collaboration** · BruBotics / R&MM · Vrije Universiteit Brussel (VUB)  
**Collaborators:** Rossana Lovecchio · Prof. Tom Verstraten  
**Contributor:** Ronald Tatchemo Guiafaing (IMESS, Grenoble INP–Esisar)

Portfolio: https://ronald-tatchemo-guiafaing.github.io/

---

## What this repository is

Public code snapshot for the **October 2026** progress on estimating finger /
tool-related forces from forearm **high-density surface EMG (HD-sEMG)** using
the open **Hyser** benchmark (Jiang et al., IEEE TNSRE 2021).

Focus of this release:

| Track | Script | Status (Oct 2026) |
|--------|--------|-------------------|
| One-DoF force regression | `scripts/demo_one_dof_force.m` | Working demo (example RMSE ≈ 0.063) |
| N-DoF multi-finger regression | `scripts/demo_n_dof_force.m` | Working demo + finger-wise RMSE |
| Motor-unit decomposition (SIL) | `scripts/demo_emg_decomposition.m` | Working demo (mean SIL ≈ 0.85) |
| Table V reproduction | `scripts/reproduce_table_v.m` | Subject-01 ready; scale to 20 subjects |

Example figures from this release are in [`results/figures/`](results/figures/).

**Next public update:** end of **November 2026**.

---

## What this repository is not

- Not a Master’s thesis repository (collaboration status only).
- Not a dump of private supervisor notes or internal PDFs.
- Not a mirror of the full Hyser dataset (download it yourself — see below).

---

## Scientific context (short)

Hand-held laparoscopy often lacks a tip force sensor. Vision / robot-state
cues used in RMIS papers are not always available. This project studies
**forearm HD-sEMG → force** as a sensorless modelling path, starting from the
reproducible Hyser pipeline (features → PCA → SIFiR lag regression), then
building towards the BruBotics application setting.

Please cite the dataset paper if you use these methods:

> Jiang X. et al., “Open Access Dataset, Toolbox and Benchmark Processing Results of High-Density Surface Electromyogram Recordings,” *IEEE Trans. Neural Syst. Rehabil. Eng.*, 2021.  
> DOI: [10.1109/TNSRE.2021.3082551](https://doi.org/10.1109/TNSRE.2021.3082551) · Data: [10.13026/ym7v-bh53](https://doi.org/10.13026/ym7v-bh53)

---

## Repository layout

```text
BruBotics-sEMG-Force-Modelling/
├── README.md
├── LICENSE
├── config/
│   └── paths_example.m      ← copy to paths.m (git-ignored)
├── scripts/                 ← commented driver scripts (start here)
├── toolbox/function/        ← Hyser open MATLAB helpers (+ NOTICE.md)
└── results/figures/         ← example plots from the Oct 2026 snapshot
```

---

## Quick start

1. Install **MATLAB** (tested with a recent release; Statistics toolbox useful).
2. Download the **Hyser** dataset from PhysioNet and unzip it so you see folders
   such as `1dof_dataset/`, `ndof_dataset/`, `mvc_dataset/`.
3. Configure paths:

```matlab
% In MATLAB, from the repo root:
copyfile('config/paths_example.m', 'config/paths.m');
edit config/paths.m   % set DATASET_ROOT to your Hyser folder
```

4. Run a demo:

```matlab
cd scripts
demo_one_dof_force          % fastest sanity check
% demo_n_dof_force
% demo_emg_decomposition
% reproduce_table_v         % defaults to subject 01 only
```

Outputs (figures / logs) go to `OUTPUT_ROOT` defined in `config/paths.m`
(by default `Desktop/BruBotics_Results`).

---

## Notes on code comments

Driver scripts in `scripts/` are written to be readable if you are new to the
pipeline: each block states **what** it does and **why**. Low-level numeric
routines live under `toolbox/function/` and keep the original toolbox structure
(see `toolbox/NOTICE.md`).

---

## Release cadence

| Release | When | Content |
|---------|------|---------|
| **v0.1.0-oct2026** | October 2026 | Baseline demos + Table V subject-01 path + figures |
| **v0.2.x** | End of November 2026 | Planned next public push |

---

## Contact

Ronald Tatchemo Guiafaing · `Ronald.Tatchemo-Guiafaing@grenoble-inp.org`  
https://ronald-tatchemo-guiafaing.github.io/
