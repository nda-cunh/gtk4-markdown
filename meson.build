project('markdown', ['c', 'vala'], default_options : ['warning_level=3', 'optimization=2'])

# Add Gressource file (style.css)
gnome = import('gnome')
asresources = gnome.compile_resources(
  'as-resources', 'gresource.xml',
  source_dir: '.',
  c_name: 'as')

# Dependencies for the library
markdown_dep = [
  dependency('gtk4'),
]

# Library gtk4 markdown
lib_gtk4markdown = library('markdown',
  'Markdown.vala',
  'Table.vala',
  'Gif.vala',
  asresources,
  dependencies: markdown_dep,
  c_args: '-w',
  install : true)

# Declare dependency for the library
dep_markdown = declare_dependency(link_with : lib_gtk4markdown, dependencies: markdown_dep, sources: asresources)
meson.override_dependency('gtk4-markdown', dep_markdown)

if get_option ('markdown_executable')
  executable('markdown',
    'main.vala',
    c_args: '-w',
    dependencies: dep_markdown,
    install : true)
endif
