using Gtk;

public class MarkdownElementCodeBlock : MarkdownElement {
	public string language {get ; protected set; }
	private Gtk.Box box_code;

	public MarkdownElementCodeBlock (string content, MatchInfo info) {
		this.content = content;
		type = Type.CODEBLOCK;
		var lang = info.fetch_named ("lang") ?? "python";
		var code = info.fetch_named ("code") ?? """
print('Hello World')
""";
		
		print ("\n\n\n\n\033[32;1m%s\033[0m et %s\n\n\n\n\n", lang, code);
		box_code = append_textcode (lang, code);
	}

	public override Gtk.Widget? getwidget() {
		return box_code;
	}

	private Gtk.Box append_textcode (string lang, string code) throws Error {
		// BOX code
		var box_code = new Gtk.Box (Orientation.HORIZONTAL, 0) {
			css_classes = {"code_box"},
			halign = Align.START,
			valign = Align.FILL,
			hexpand = false,
			vexpand = false,
		};
		var buffer = new TextBuffer(null) {
			text = code,
		};
		var text = new Gtk.TextView.with_buffer (buffer) {
			halign = Align.START,
			valign = Align.START,
			hexpand=true,
			vexpand=true,
			can_focus = false,
			focusable = false,
		};

		// Count line
		var line_bar = new StringBuilder();
		int i = 1;
		int index = 0;
		while (true) {
			index = code.index_of_char ('\n', index + 1);
			if (index == -1)
				break;
			line_bar.append_printf ("%d\n", i);
			++i;
		}

		int max_size_line = 0;
		unowned string ptr = code;
		// count the max size of line
		while (true) {
			int max = ptr.index_of_char ('\n');
			if (max == -1)
				break;
			if (max > max_size_line)
				max_size_line = max;
			ptr = ptr.offset(max + 1);
		}

		text.set_size_request (max_size_line * 10, -1);

		box_code.append(new Gtk.Label (line_bar.str) {
			css_classes = {"line_bar"},
			halign = Align.START,
			valign = Align.START,
			vexpand = true,
			hexpand = true,
			justify = Justification.LEFT,
		});
		box_code.append(text);
		return box_code;
	}
}
