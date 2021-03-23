project_deps = [
    dependency('gio-2.0', version: '>= 2.50'),
    dependency('gtk+-3.0', version: '>= 3.22'),
    dependency('gee-0.8', version: '>= 0.20'),
    dependency('gtksourceview-4'),
    dependency('libxml-2.0')
]

project_sources = files(
    'main.vala',
    
    'util/style.vala',
    'util/samples.vala',
    'util/xml-util.vala',
    'util/font-util.vala',
    
    'core/application.vala',
    
    'ui/main-window.vala',
    
    'ui/dialog/create-dialog.vala',
    'ui/dialog/preferences-dialog.vala',
    
    'ui/widget/list-box.vala',
    'ui/widget/home-page.vala',
    'ui/widget/editor-page.vala'
)

executable('scheme-editor',
    project_resources,
    project_sources,
    vala_args: '--target-glib=2.50',
    dependencies: project_deps,
    install: true,
)
