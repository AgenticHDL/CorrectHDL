# Decomposition Pipeline Script 

-   **Each submodule `aes{id}.cpp` must define a unique top-level
    function `aes{id}_top(...)`, with `#pragma hls_design top` inserted
    on the preceding line** (generated in Round 2 by LLM; Round 4 also
    validates/inserts if missing).
-   Round 1 JSON now includes each module's `top_function.signature`,
    which Round 2 must strictly follow.
-   Round 3 testbench **invokes `aes{id}_top(...)`**, ensuring a
    consistent top-level function for Catapult HLS.
-   The Round 5 generated `aes_concat.cpp` top-level function is
    **`aes_concat_top(...)` with pragma**; compilation scripts no longer
    replace `aes.h`, only `.cpp` and `test.cpp`.

## File List

-   `step1_decompose.py`: outputs `module_decomposition.txt` (including
    top_function.signature).
-   `step2_generate_modules.py`: generates `aes1..N/aesX.h|.cpp`, each
    `.cpp` containing `#pragma hls_design top` + `aesX_top(...)`.
-   `step3_generate_testbenches.py`: generates `testX.cpp` for each
    `aesX`, calling `aesX_top(...)` and producing a 6-line `report.txt`.
-   `step4_compile_submodules.py`: copies/fixes `compileh.py` into each
    `aesX`, validates or auto-inserts pragma before running; executes
    submodules sequentially.
-   `step5_concat_and_test.py`: generates `aes_concat/aes_concat.cpp`
    (with `#pragma hls_design top` + `aes_concat_top(...)`) and
    `test_concat.cpp`; compiles and tests.
-   `run_pipeline.py`: top-level orchestration script.

## Environment/Dependencies

Requires `OPENAI_API_KEY`; Python 3.8+; `openai` SDK (optional) or
`requests`; your `compileh.py` must be executable within subdirectories.

## Usage Example

``` bash
python3 run_pipeline.py                # Run pre 1..5
python3 run_pipeline.py --pre 2      # Only pre 2 (module generation with HLS top)
python3 run_pipeline.py --pre 3 4    # Only testbench generation and submodule compilation
```
