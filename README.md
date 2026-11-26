## Authors

- [AntonioMennuni](https://github.com/AntonioMennuni)
- [danpalu2](https://github.com/danpalu2)



# HMAC Hardware Design

A project implementing a 64-bit HMAC-style digest module in SystemVerilog. The design follows a finite-state-machine and datapath architecture and uses the AES inverse S-box as its byte substitution operation.

The project follows the VLSI development flow from a Python high-level reference model, through RTL and ModelSim verification, to FPGA synthesis, fitting, and static timing analysis with Quartus Prime. The algorithm is described in chapter 1 of the file doc/Report_Mennuni_Palumbo.pdf; this implementation is just a project and is not a general-purpose cryptographic library.



## Design and Development Flow

### 1. Python reference model

[`model/HMAC.py`](model/HMAC.py) implements the high-level model used to calculate expected digests. It applies 36 rounds of byte-state updates for every message byte, then processes the eight bytes of the 64-bit key. It reads messages and keys from `modelsim/tv/` and writes one expected-digest file per valid key (`digests_1.txt`, `digests_2.txt`, and so on).
The model uses Python's standard library only.


### 2. SystemVerilog RTL

The RTL is in `db/`:

- [`HMAC.sv`](db/HMAC.sv) contains the five-state FSM, the 64-bit internal hash state, message-byte counter, round counter, and ready/valid control signals. It has an asynchronous active-low reset. Each message byte is processed through 36 rounds; after the final byte, the key is processed and the 64-bit digest is presented.
- [`inverse_S_box.sv`](db/inverse_S_box.sv) implements the 256-entry AES inverse S-box lookup table as a separate combinational module. The HMAC datapath instantiates eight copies to transform the eight bytes of its internal state.
- [`HMAC_wrapper.sv`](db/HMAC_wrapper.sv) registers the HMAC inputs and outputs to provide a registered outer interface.


### 3. ModelSim verification

The testbenches are in `tb/`:

- `tb_HMAC.sv` reads message lines and expected digests, sends the message bytes using the valid/ready and start/last signals, and compares the RTL digest with the reference vector.
- `tb_inverse_S_box.sv` checks the inverse S-box module.

The test vectors are in `modelsim/tv/`: `messages.txt`, `keys.txt`, and the generated `digests_N.txt` files. The HMAC testbench uses the corresponding expected-digest file for its selected key.


### 4. Quartus FPGA implementation and results

The Quartus project targets an Intel Cyclone V FPGA, device `5CGXFC9D6F27C7`. The build flow can use either `HMAC` or `HMAC_wrapper` as the top-level entity. The timing constraints define a 6.93 ns clock period.

See [`doc/Report_Mennuni_Palumbo.pdf`](doc/Report_Mennuni_Palumbo.pdf) for the full analysis.
These are the values reported for the stated target and constraints; results may differ with a different Quartus version, device, top-level entity, or constraint set. 



## Working Environment

### Tools and setup

- **SystemVerilog** for the RTL and testbenches.
- **Python 3** for the high-level model and project helper scripts.
- **ModelSim Intel FPGA Edition** for compilation and simulation.
- **Intel Quartus Prime** for synthesis, fitting, and static timing analysis on the Cyclone V target.
- **Tcl and SDC** for Quartus project automation and timing constraints.

Add the folders containing the Quartus and ModelSim executables to the system `PATH`, or configure the paths to `quartus.exe` and `vsim.exe`. The environment guide lists Python 2.x or 3.x and standard-library modules such as `shutil` and `glob`. The current reference model imports `pathlib`, so use Python 3. All scripts use only the Python standard library; no third-party packages are required and a `requirements.txt` is unnecessary.


### Directory structure

| Folder | Purpose |
| --- | --- |
| `doc/` | Project documentation, including the project report and this environment guide. |
| `db/` | SystemVerilog RTL design modules. |
| `tb/` | SystemVerilog testbenches. |
| `model/` | Python high-level reference model. |
| `modelsim/` | ModelSim project helper scripts, test vectors in `tv/`, and waveform files in `wave/`. |
| `quartus/` | Quartus project helper scripts and timing/device constraints in `constr/`. |

The ModelSim build script uses `modelsim/build.py` that collects SystemVerilog files from `db/` and `tb/`. The Quartus build script uses `quartus/build.py` that includes the RTL files and files from `quartus/constr/`, selects the target FPGA, and prompts for the top-level module. The `automatic_virtual_pin.tcl` script assigns virtual pins to top-level ports other than the clock, which must be named `clk`.


### Running the project scripts

Run each helper script from its own folder because the scripts use relative paths.

Generate the reference digests:
```
cd model
python HMAC.py
```

Create the ModelSim project:
```
cd modelsim
python build.py
```

Then open the generated ModelSim project, compile the design and testbench, select `tb_HMAC_file`, and run the simulation. Select `tb_inverse_S_box` to run the S-box testbench.

Create the Quartus project:

```powershell
cd quartus
python build.py
```

Enter `HMAC` or `HMAC_wrapper` when prompted, then run Analysis & Synthesis and the Fitter. Run the Timing Analyzer for static timing analysis. To compare the core and wrapper implementations, create separate Quartus runs with each module as the top-level entity.

The clean scripts remove generated tool files and must be run from their own folder because their paths are relative:

- `modelsim/clean.py` removes generated ModelSim files and folders while keeping `tv/`, `wave/`, `build.py`, and `clean.py`; it also removes the ModelSim `transcript` file.
- `quartus/clean.py` removes generated Quartus files and folders while keeping `constr/`, `build.py`, `quartus.build`, and `clean.py`.

Run them from `modelsim/` or `quartus/`
