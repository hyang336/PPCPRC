for i=1:16
    version(i).v_num=version_table.version_num(i);
    version(i).set_cb=version_table.set_cb(i);
    version(i).run_cb=version_table.run_cb{i};
    version(i).hand_cb=version_table.hand_cb{i};
end