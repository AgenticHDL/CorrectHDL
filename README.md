# /vsplit — C++ → Verilog Modular Conversion Scripts

This package provides a set of **n+5** Python scripts (where n scripts are auto‑generated in stage S1 for submodules aes1..aesn). These scripts drive the LLM to convert C++ submodules into Verilog, generate testbenches, run simulation (Questasim/ModelSim or VCS supported), and finally perform top‑level concatenation and full‑system testing.

## Directory Structure
```
/vsplit/
  config.py                 # Path and LLM configuration
  llm_utils.py              # LLM invocation, logging, code extraction utilities
  cpp_utils.py              # C/C++ prototype parsing and bit‑width mapping
  s1_interface_setup.py     # Count modules, create aesvX directories, generate interface .sv/.md, generate n s4_aesX.py scripts
  s2_generate_specs.py      # Generate specX.md for each submodule
  s3_prepare_sim.py         # Copy and edit simulation scripts (sim.py) and VCS helper (compileh.py) for each aesvX
  s5_concat_and_test.py     # Concatenate aes1..aesn into aes_concat.v and test_concat.v, then run system‑level test
  run_all.py                # Top‑level orchestrator; can run a single stage or a single submodule

  /templates/
    compileh.py             # Template for VCS compilation/run script
    sim.py                  # Questasim/ModelSim simulation script
    verilog_module_skeleton.v.j2
    testbench_template.v.j2
    s4_template.py          # Template for generating each s4_aesX.py
  /logs/                    # Time‑stamped log files of all LLM prompts/outputs
```

## Dependencies
- Python 3.8+
- Optional: `openai` Python package (for LLM calls). Install: `pip install openai`
- Optional: Questasim/ModelSim (`vlog`/`vsim`) or Synopsys VCS (`vcs`/`simv`)
- Environment variable: `OPENAI_API_KEY` (or configure it inside `config.py`)

## Usage
1. Place your inputs:
   - For each submodule: `/aesX/aesX.h`, `/aesX/aesX.cpp`, `/aesX/testX.cpp`
   - Output from previous stage: `/csplit/module_decomposition.txt`
   - (Optional) Full C++ version: `/aes_concat/aes_concat.cpp`, `/aes_concat/test_concat.cpp`

2. Configure the LLM: edit `config.py` (MODEL, etc.) or set environment variables.

3. Run:
   - Full workflow:  
     `python /vsplit/run_all.py`
   - Run only one stage:  
     `python run_all.py --only-s 1`  
     `python run_all.py --only-s 2`  
     `python run_all.py --only-s 3`  
     `python run_all.py --only-s 5`
   - Run only round K (Verilog generation and simulation for aesK):  
     `python run_all.py --round K`
   - Run a range of rounds (e.g., 2 through 4):  
     `python run_all.py --start-round 2 --end-round 4`

4. Outputs:
   - `standard_stream_if.sv`, `interface_spec.md` (Unified interface + mapping rules)
   - `aesvX/specX.md`, `aesvX/aesX.v`, `aesvX/testX.v`, `aesvX/sim.py`, `aesvX/report.txt`
   - Top-level results: `/aes_concat/aes_concat.v`, `test_concat.v`, `concat_check.txt`

> Logging: All LLM prompts and outputs are saved in `/vsplit/logs/`.
