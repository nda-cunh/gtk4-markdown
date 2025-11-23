project( 'markdown', 'vala', meson_version : '>= 1.0.0', version : '0.1',)
gnome = import('gnome')
asresources = gnome.compile_resources(
  'gtk4_markdown_resources', 'gresource.xml',
  source_dir: '.',
  c_name: 'gtk4_markdown_resource')

# Declare dependencies
dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk4'),
  dependency('libadwaita-1'),
]

# Source files
srcs_lib_markdown = []

subdir('src')


markdown_lib = shared_library('markdownlib',
  srcs_lib_markdown,
  asresources,
  c_args: '-w',
  dependencies : dependencies,
)

markdown_dep = declare_dependency(
  link_with : markdown_lib,
  dependencies : dependencies,
  include_directories : include_directories('.')
)

meson.override_dependency('gtk-markdown', markdown_dep)

# Build the executable
executable('markdown-app',
  'main.vala',
  dependencies : [markdown_dep],
  install : true,
)
