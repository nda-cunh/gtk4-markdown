project( 'markdown', 'vala', meson_version : '>= 1.0.0', version : '0.1',)

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk4'),
  dependency('libadwaita-1'),
]

gnome = import('gnome')
asresources = gnome.compile_resources(
  'gtk4_markdown_resources', 'gresource.xml',
  source_dir: '.',
  c_name: 'gtk4_markdown_resource')


executable('markdown',
  files(
    'main.vala',
    'Markdown.vala',
    'LabelExt.vala',
    'MarkdownEmphasis.vala',
    'MarkdownElement.vala',
    'LabelFormatter.vala',
    'Table.vala',
    'Gif.vala',
    'MarkdownNode.vala',
    'MarkdownElementBlockquote.vala',
    'MarkdownElementCodeBlock.vala',
    'MarkdownElementImage.vala',
    'MarkdownElementSeparator.vala',
    'MarkdownElementTable.vala',
    'MarkdownElementText.vala',
    'MarkdownAstEmphasis.vala'
  ),
  asresources,
  dependencies : dependencies,
  install : true,
)
