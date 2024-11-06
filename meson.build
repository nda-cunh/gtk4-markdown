project('markdown', ['c', 'vala'], default_options : ['warning_level=3'])

executable('markdown',
           'main.vala',
           c_args: '-w',
           dependencies : [
              dependency('gtk4')],
           install : true)
