project('markdown', ['c', 'vala'], default_options : ['warning_level=3', 'optimization=3'])

executable('markdown',
           'main.vala',
           'Markdown.vala',
           'Markdown_parse.vala',
           'Table.vala',
           'Gif.vala',
           c_args: '-w',
           vala_args: '--enable-experimental',
           dependencies : [
              dependency('gtk4'),
              dependency('gtksourceview-5')],
           install : true)
