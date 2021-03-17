desktop_file = i18n.merge_file(
    input: 'me.paladin.SchemeEditor.desktop.in',
    output: 'me.paladin.SchemeEditor.desktop',
    type: 'desktop',
    po_dir: '../po',
    install: true,
    install_dir: join_paths(datadir, 'applications')
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
    test('Validate desktop file', desktop_utils,
        args: [desktop_file]
    )
endif

appstream_file = i18n.merge_file(
    input: 'me.paladin.SchemeEditor.appdata.xml.in',
    output: 'me.paladin.SchemeEditor.appdata.xml',
    po_dir: '../po',
    install: true,
    install_dir: join_paths(datadir, 'appdata')
)

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
    test('Validate appstream file', appstream_util,
        args: ['validate', appstream_file]
    )
endif

install_data('me.paladin.SchemeEditor.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas')
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test('Validate schema file', compile_schemas,
        args: ['--strict', '--dry-run', meson.current_source_dir()]
    )
endif

gnome = import('gnome')

project_resources = gnome.compile_resources(
    'resources',
    'me.paladin.SchemeEditor.gresource.xml',
    c_name: 'resources'
)
