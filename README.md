# HMAC Hardware Design

A project implementing a 64-bit HMAC-style digest module in SystemVerilog. The design follows a finite-state-machine and datapath architecture and uses the AES inverse S-box as its byte substitution operation.

The project follows the VLSI development flow from a Python high-level reference model, through RTL and ModelSim verification, to FPGA synthesis, fitting, and static timing analysis with Quartus Prime. The algorithm is described in chapter 1 of [`doc/Report_Mennuni_Palumbo.pdf`](doc/Report_Mennuni_Palumbo.pdf); this implementation is a course project and is not a general-purpose cryptographic library.

## Design and Development Flow

### 1. Python reference model

[`model/HMAC.py`](model/HMAC.py) implements the high-level model used to calculate expected digests. It applies 36 rounds of byte-state updates for every message byte, then processes the eight bytes of the 64-bit key. It reads messages and keys from [`modelsim/tv/`](modelsim/tv/) and writes expected-digest files there: [`digests_1.txt`](modelsim/tv/digests_1.txt), [`digests_2.txt`](modelsim/tv/digests_2.txt), [`digests_3.txt`](modelsim/tv/digests_3.txt), [`digests_4.txt`](modelsim/tv/digests_4.txt), and [`digests_5.txt`](modelsim/tv/digests_5.txt).

The model uses Python's standard library only.

### 2. SystemVerilog RTL

The RTL is in [`db/`](db/):

- [`HMAC.sv`](db/HMAC.sv) contains the five-state FSM, the 64-bit internal hash state, message-byte counter, round counter, and ready/valid control signals. It has an asynchronous active-low reset. Each message byte is processed through 36 rounds; after the final byte, the key is processed and the 64-bit digest is presented.
- [`inverse_S_box.sv`](db/inverse_S_box.sv) implements the 256-entry AES inverse S-box lookup table as a separate combinational module. The HMAC datapath instantiates eight copies to transform the eight bytes of its internal state.
- [`HMAC_wrapper.sv`](db/HMAC_wrapper.sv) registers the HMAC inputs and outputs to provide a registered outer interface.

### 3. ModelSim verification

The testbenches are in [`tb/`](tb/):

- [`tb_HMAC.sv`](tb/tb_HMAC.sv) reads message lines and expected digests, sends the message bytes using the valid/ready and start/last signals, and compares the RTL digest with the reference vector.
- [`tb_inverse_S_box.sv`](tb/tb_inverse_S_box.sv) checks the inverse S-box module.

The test vectors are in [`modelsim/tv/`](modelsim/tv/): [`messages.txt`](modelsim/tv/messages.txt), [`keys.txt`](modelsim/tv/keys.txt), and the generated digest files listed above. The HMAC testbench uses the corresponding expected-digest file for its selected key.

### 4. Quartus FPGA implementation and results

The Quartus project in [`quartus/`](quartus/) targets an Intel Cyclone V FPGA, device `5CGXFC9D6F27C7`. The build flow can use either `HMAC` or `HMAC_wrapper` as the top-level entity. The timing constraints in [`quartus/constr/time_constr_template.sdc`](quartus/constr/time_constr_template.sdc) define a 6.93 ns clock period.

See [`doc/Report_Mennuni_Palumbo.pdf`](doc/Report_Mennuni_Palumbo.pdf) for the full analysis. These are the values reported for the stated target and constraints; results may differ with a different Quartus version, device, top-level entity, or constraint set.

## Working Environment

### Tools and setup

- **SystemVerilog** for the RTL and testbenches.
- **Python 3** for the high-level model and project helper scripts.
- **ModelSim Intel FPGA Edition** for compilation and simulation.
- **Intel Quartus Prime** for synthesis, fitting, and static timing analysis on the Cyclone V target.
- **Tcl and SDC** for Quartus project automation and timing constraints.

Add the folders containing the Quartus and ModelSim executables to the system `PATH`, or configure the paths to `quartus.exe` and `vsim.exe`. The project scripts use Python 3 and only the Python standard library, including modules such as `shutil`, `glob`, and `pathlib`; no third-party packages or requirements file are needed.

### Directory structure

| Folder | Purpose |
| --- | --- |
| [`doc/`](doc/) | Project documentation, including the project report. |
| [`db/`](db/) | SystemVerilog RTL design modules. |
| [`tb/`](tb/) | SystemVerilog testbenches. |
| [`model/`](model/) | Python high-level reference model. |
| [`modelsim/`](modelsim/) | ModelSim project helper scripts, test vectors in [`tv/`](modelsim/tv/), and waveform files in [`wave/`](modelsim/wave/). |
| [`quartus/`](quartus/) | Quartus project helper scripts and timing/device constraints in [`constr/`](quartus/constr/). |

The ModelSim build script [`modelsim/build.py`](modelsim/build.py) collects SystemVerilog files from [`db/`](db/) and [`tb/`](tb/). The Quartus build script [`quartus/build.py`](quartus/build.py) includes the RTL files and files from [`quartus/constr/`](quartus/constr/), selects the target FPGA, and prompts for the top-level module. The [`automatic_virtual_pin.tcl`](quartus/constr/automatic_virtual_pin.tcl) script assigns virtual pins to top-level ports other than the clock, which must be named `clk`.

### Running the project scripts

Run each helper script from its own folder because the scripts use relative paths.

Generate the reference digests with [`model/HMAC.py`](model/HMAC.py):

```powershell
cd model
python HMAC.py
```

Create the ModelSim project with [`modelsim/build.py`](modelsim/build.py):

```powershell
cd modelsim
python build.py
```

Then open the generated ModelSim project, compile the design and testbench, select `tb_HMAC_file`, and run the simulation. Select `tb_inverse_S_box` to run the S-box testbench.

Create the Quartus project with [`quartus/build.py`](quartus/build.py):

```powershell
cd quartus
python build.py
```

Enter `HMAC` or `HMAC_wrapper` when prompted, then run Analysis & Synthesis and the Fitter. Run the Timing Analyzer for static timing analysis. To compare the core and wrapper implementations, create separate Quartus runs with each module as the top-level entity.

The clean scripts remove generated tool files and must be run from their own folders because their paths are relative:

- [`modelsim/clean.py`](modelsim/clean.py) removes generated ModelSim files and folders while keeping [`modelsim/tv/`](modelsim/tv/), [`modelsim/wave/`](modelsim/wave/), [`modelsim/build.py`](modelsim/build.py), and [`modelsim/clean.py`](modelsim/clean.py); it also removes the ModelSim `transcript` file.
- [`quartus/clean.py`](quartus/clean.py) removes generated Quartus files and folders while keeping [`quartus/constr/`](quartus/constr/), [`quartus/build.py`](quartus/build.py), [`quartus/quartus.build`](quartus/quartus.build), and [`quartus/clean.py`](quartus/clean.py).

Run these scripts from [`modelsim/`](modelsim/) or [`quartus/`](quartus/).

## Authors

- [AntonioMennuni](https://github.com/AntonioMennuni)
- [danpalu2](https://github.com/danpalu2)