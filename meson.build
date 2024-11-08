project('markdown', ['c', 'vala'], default_options : ['warning_level=3', 'optimization=2'])


gnome = import('gnome')
asresources = gnome.compile_resources(
    'as-resources', 'gresource.xml',
    source_dir: '.',
    c_name: 'as'
)

executable('markdown',
           'main.vala',
           'Markdown.vala',
           'Table.vala',
           'Gif.vala',
           asresources,
           c_args: '-w',
           vala_args: '--enable-experimental',
           dependencies : [
              dependency('gtk4'),
              dependency('gtksourceview-5')],
           install : true)
