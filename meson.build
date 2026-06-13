project('markdown', ['c', 'vala'], default_options : ['warning_level=3', 'optimization=2'])

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

# Add Gressource file (style.css)
gnome = import('gnome')
asresources = gnome.compile_resources(
  'gtk4_markdown_resources', 'gresource.xml',
  source_dir: '.',
  c_name: 'gtk4_markdown_resource')

# Dependencies for the library
markdown_dep = [
  dependency('gtk4'),
  dependency('tree-sitter', static: true),
]

sources = files(
  'tree-sitter-markdown/src/parser.c',
  'tree-sitter-markdown/src/scanner.c',
  'tree-sitter-markdown-inline/src/parser.c',
  'tree-sitter-markdown-inline/src/scanner.c',
  'src/Markdown.vala',
  'src/InlineRenderer.vala',
  'src/SupraLabel.vala',
  'src/LabelExt.vala',
  'src/MarkdownEmphasis.vala',
  'src/modules/BlockQuote.vala',
  'src/modules/CodeBlock.vala',
  'src/modules/Gif.vala',
  'src/modules/Table.vala',
)

# Library gtk4 markdown
lib_gtk4markdown = static_library('markdown',
  sources,
  asresources,
  dependencies: markdown_dep,
  c_args: '-w',
  vala_args: '--pkg=tree-sitter',
  install_dir: [true, true, true],
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
