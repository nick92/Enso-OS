gnome = import ('gnome')

greeter_resources = gnome.compile_resources ('greeter_resources', 'gresource.xml', source_dir: '.', c_name: 'greeter')

install_data('greeter.desktop',
    install_dir : join_paths('share', 'xgreeters'))


