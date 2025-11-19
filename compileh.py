import os
import sys

def create_catapult_tcl_script():
    tcl_script_path = '/nas'
    

    main_c_file = 'aes.cpp'
    test_c_file = 'test.cpp'

    with open(tcl_script_path, 'w') as f:
        f.write(f'''
solution new -state initial
solution options defaults
solution options set /OnTheFly/VthAttributeType cell_lib
flow package require /SCVerify
flow package option set /SCVerify/USE_CCS_BLOCK true
solution file add {main_c_file} -type C++
solution file add {test_c_file} -type C++
go new
go analyze
go compile
flow run /SCVerify/launch_make ./scverify/Verify_orig_cxx_osci.mk {{}} SIMTOOL=osci sim
solution library add nangate-45nm_beh -- -rtlsyntool DesignCompiler -vendor Nangate -technology 045nm
go libraries
directive set -CLOCKS {{clk {{-CLOCK_PERIOD n -CLOCK_EDGE rising -CLOCK_UNCERTAINTY 0.0 -CLOCK_HIGH_TIME 0.5 -RESET_SYNC_NAME rst -RESET_ASYNC_NAME arst_n -RESET_KIND sync -RESET_SYNC_ACTIVE high -RESET_ASYNC_ACTIVE low -ENABLE_ACTIVE high}}}}
go assembly
go architect
go allocate
go extract
flow run /SCVerify/launch_make ./scverify/Verify_rtl_v_msim.mk {{}} SIMTOOL=qsim sim
quit
''')
    return tcl_script_path



def run_tcl_script(tcl_script_path, catapult_bin):
    """
    Executes the generated Tcl script using the Catapult HLS tool.
    Configures environment so Catapult/SCVerify can find QuestaSim.
    """
    print(f"Running Catapult with script: {tcl_script_path}")
    

    questasim_root = '/usr/local/tools/mentor/questasim/.../questasim'
    questasim_ini_path = f'{questasim_root}/modelsim.ini'
    questasim_bin_path = f'{questasim_root}/bin'
    questasim_arch_bin = f'{questasim_root}/linux_x86_64'  

    os.environ['MODELSIM_INI'] = questasim_ini_path
    original_path = os.environ.get('PATH', '')

    os.environ['PATH'] = questasim_bin_path + os.pathsep + questasim_arch_bin + os.pathsep + original_path

    os.environ.setdefault('MTI_HOME', questasim_root)
    os.environ.setdefault('QUESTA_HOME', questasim_root)

    print(f"Temporarily set MODELSIM_INI to: {os.environ['MODELSIM_INI']}")
    print(f"Temporarily updated PATH to start with: {questasim_bin_path} and {questasim_arch_bin}")
    command = f'{catapult_bin}/catapult -shell -f {tcl_script_path}'
    os.system(command)
    print("Catapult execution finished.")

def main(catapult_bin):
    tcl_script_path = create_catapult_tcl_script()
    run_tcl_script(tcl_script_path, catapult_bin)

if __name__ == "__main__":
    # Path to the Catapult bin directory
    catapult_bin_path = '/mentor/catapult/.../Mgc_home/bin'
    main(catapult_bin_path)