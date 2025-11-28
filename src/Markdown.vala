using Gtk;

public class Markdown : Gtk.Box {
	private string file_path;
	private string dir_name;
	private string filename;
	private static Regex regex_image;
	private static Regex regex_table;
	private static Regex regex_code;
	private static Regex regex_blockquote;

	public signal bool activate_link (string uri);
	public HashTable<string, Gtk.Widget> anchor;

	construct {
		orientation = Gtk.Orientation.VERTICAL;
		hexpand = true;
		vexpand = true;
		try {
			regex_image = new Regex("""[!]\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""", RegexCompileFlags.OPTIMIZE);
			regex_table = new Regex("""(?:\|[^\n]*\n)+""", RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
			regex_code = new Regex("""[`]{3}(?P<lang>[^\s\n]*)?\n(?P<code>.*?)[`]{3}""", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
			regex_blockquote = new Regex("""([>]\s+.+?\n)+""", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
		}
		catch (Error e) {
			printerr ("Error compiling regex: %s\n", e.message);
		}
	}

	public Markdown (string file_path) throws Error {
		string contents;
		FileUtils.get_contents (file_path, out contents);

		contents = contents.replace ("\r\n", "\n"); // Normalize line endings
		contents = contents._delimit("\r", '\n');

		this.filename = Path.get_basename(file_path);
		this.file_path = file_path;
		this.dir_name = Path.get_dirname(file_path);

		var provider = new Gtk.CssProvider ();
		provider.load_from_resource ("/style.css");
		Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


		var lst = cut_content(contents, this.dir_name);

		foreach (unowned var i in lst) {
			var? w = i.getwidget ();
			if (w != null) {
				if (w is SupraLabel) {
					w.link_clicked.connect ((uri) => {
						activate_link (uri);
					});
				}
				append(w);
			}
		}
	}



	public static SList<MarkdownElement> cut_content (string contents, string base_path) {
		var result = new SList<MarkdownElement>();
		unowned string str = (string)contents;
		int len = str.length;

		int segment_start = 0;
		int i = 0;

		while (i < len) {
			bool line_start = (i == 0) || (str[i - 1] == '\n');

			// NOTE Horizontal Rule ---
			if (line_start && str[i] == '-' || str[i] == '*' || str[i] == '_') {
				char c = str[i];
				int dash_count = 0;
				while (i < len && str[i] == c) {
					dash_count++;
					i++;
				}
				if (dash_count >= 3 && (i == len || str[i] == '\n')) {
					if (segment_start < i - dash_count) {
						result.append(new MarkdownElementText(str[segment_start: i - dash_count]));
					}

					result.append(new MarkdownElementSeparator());
					segment_start = i;
					continue;
				} else {
					i -= dash_count;
				}
			}


			// NOTE Blockquote > text
			if (line_start && str[i] == '>' && (i + 1 < len && (str[i + 1] == ' ' || str[i + 1] != '\n'))) {
				MatchInfo info;
				if (regex_blockquote.match(str.offset(i), RegexMatchFlags.ANCHORED, out info)) {
					int start_pos, end_pos;
					info.fetch_pos(0, out start_pos, out end_pos);

					if (i > segment_start)
						result.append(new MarkdownElementText(str[segment_start: i]));
					result.append(new MarkdownElementBlockquote(str[i: i + end_pos]));
					i += end_pos;
					segment_start = i;
					continue;
				}
			}

			// NOTE Code block  ```lang text```
			if (line_start && i + 2 < len && str[i] == '`' && str[i + 1] == '`' && str[i + 2] == '`') {
				MatchInfo info;
				if (regex_code.match(str.offset(i), RegexMatchFlags.ANCHORED, out info)) {
					int start_pos, end_pos;
					info.fetch_pos(0, out start_pos, out end_pos);

					if (i > segment_start)
						result.append(new MarkdownElementText(str[segment_start: i]));
					result.append(new MarkdownElementCodeBlock(str[i: i + end_pos], info));

					i += end_pos;
					segment_start = i;
					continue;
				}
			}

			// NOTE table | Foo | Bar |
			if (line_start && str[i] == '|') {
				MatchInfo info;
				if (regex_table.match(str.offset(i), RegexMatchFlags.ANCHORED, out info)) {
					int start_pos, end_pos;
					info.fetch_pos(0, out start_pos, out end_pos);

					if (i > segment_start)
						result.append(new MarkdownElementText(str[segment_start: i]));

					result.append(new MarkdownElementTable(str[i: i + end_pos]));
					i += end_pos;
					segment_start = i;
					continue;
				}
			}

			// NOTE Image ![alt](url "title")
			if (str[i] == '!') {
				MatchInfo info;
				if (regex_image.match(str.offset(i), RegexMatchFlags.ANCHORED, out info)) {
					int start_pos, end_pos;
					info.fetch_pos(0, out start_pos, out end_pos);

					if (i > segment_start)
						result.append(new MarkdownElementText(str[segment_start: i]));

					result.append(new MarkdownElementImage(str[i: i + end_pos], info, base_path));
					i += end_pos;
					segment_start = i;
					continue;
				}
			}


			++i;
		}

		if (segment_start < len)
			result.append(new MarkdownElementText(str[segment_start: len]));

		return result;
	}
}
