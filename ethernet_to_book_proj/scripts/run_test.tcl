proc run_test {tb_name} {
    set_property top $tb_name [get_filesets sim_1]
    launch_simulation
}