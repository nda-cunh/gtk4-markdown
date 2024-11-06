using Gtk;

public class MarkDown : Gtk.Box {
	string markdown_text;

	// simple parsing replace HTML  <tag>text</tag>
	string parse_html(string regex_str, string balise_open, string balise_close) throws Error {
		string result = markdown_text;
		var regex = new Regex(regex_str, RegexCompileFlags.MULTILINE);
		MatchInfo match_info;

		if (regex.match (markdown_text, 0, out match_info)) {
			do {
				result = regex.replace_eval (result, -1, 0, 0, (info, bs) => {
					bs.append_printf("%s%s%s", balise_open, info.fetch (1), balise_close);
					return true;
				});
			} while (match_info.next ());
		}
		return result;
	}

	// Parse link    [name](url "title")
	string parse_link () throws Error {
		string result = markdown_text;
		MatchInfo match_info;
		var regex = new Regex("""\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""", RegexCompileFlags.MULTILINE);
		if (regex.match(markdown_text, 0, out match_info)) {
			do {
				result = regex.replace_eval (result, -1, 0, 0, (info, bs) => {
					var name = info.fetch_named("name");
					var url = info.fetch_named("url");
					var title = info.fetch_named("title")?.strip() ?? "\"none\""; 
					if (title == "")
						title = "\"none\"";

					// check if the link is an image
					int start_pos, end_pos;
					info.fetch_pos (0, out start_pos, out end_pos);
					if (result[start_pos - 1] == '!') {
						bs.append_printf("[%s](%s %s)", name, url, title);
						return false;
					}
					bs.append_printf("""<a href="%s" title=%s>%s</a>""", url, title, name);
					return false;
				});
			} while (match_info.next ());
		}
		return result;
	}

	private void simple_parse_html () throws Error {
		// BOLD/ITALIC/BOLD_ITALIC
		markdown_text = parse_html ("[*]{3}([^*]+)[*]{3}", "<b><i>", "</i></b>");
		markdown_text = parse_html ("[*]{2}([^*]+)[*]{2}", "<b>", "</b>");
		markdown_text = parse_html ("[*]{1}([^*]+)[*]{1}", "<i>", "</i>");
		// LINK
		markdown_text = parse_link();
		// HEADER
		markdown_text = parse_html("^[#]{1} (.*?)$$", """<span size="400%">""", "</span>");
		markdown_text = parse_html("^[#]{2} (.*?)$$", """<span size="350%">""", "</span>");
		markdown_text = parse_html("^[#]{3} (.*?)$$", """<span size="300%">""", "</span>");
		markdown_text = parse_html("^[#]{4} (.*?)$$", """<span size="250%">""", "</span>");
		markdown_text = parse_html("^[#]{5} (.*?)$$", """<span size="200%">""", "</span>");
		markdown_text = parse_html("^[#]{6} (.*?)$$", """<span size="150%">""", "</span>");
		// simple code 
		markdown_text = parse_html("^[`]([^*]+)[`]", """<span bgcolor="#292443">""", "</span>");
	}

	void parse () throws Error {
		simple_parse_html ();
		int start = 0;
		MatchInfo match_info;

		var regex_image = new Regex("""[!]\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""");
		var regex_table = new Regex("""^\|.*\|.*\|\n(\|.*\|.*\|\n)*""", RegexCompileFlags.MULTILINE);

		int i = 0;
		while (markdown_text[i] != '\0') {
			int start_pos, end_pos;
			// image parsing
			if (markdown_text[i - 1] == '\n' && markdown_text[i] == '!') {
				if (regex_image.match(markdown_text.offset(i), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					append_text (markdown_text[start:i]);

					var name = match_info.fetch_named("name");
					var url = match_info.fetch_named("url");
					var title = match_info.fetch_named("title")?.strip() ?? "\"none\"";
					if (title == "")
						title = "\"none\"";
					append_img (name, url, title);
					i += end_pos;
					start = i + 1;
				}
			}
			// table parsing
			else if (markdown_text[i - 1] == '\n' && markdown_text[i] == '|') {
				if (regex_table.match(markdown_text.offset(i - 1), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					append_text (markdown_text[start:i]);
					string table = markdown_text.offset(i)[0:end_pos - 1];
					append_table (table);
					i += end_pos - 1;
					start = i;
				}
			}
			// le truc des tiret
			if (markdown_text[i - 1] == '\n' && markdown_text[i] == '-') {
				markdown_text = markdown_text[0:i] + "•" + markdown_text.offset(i+1); 
			}
			++i;
		}
		append_text (markdown_text.offset(start));
	}

	public void append_table (string content) {
		var table = new Table.from_content (content) {
			halign = Align.START,
			valign = Align.FILL,
			hexpand= true,
			vexpand=true,
		};
		box.append (table);
	}

	public void append_img (string name, string url, string title) {
		var img = new Gtk.Picture.for_filename (url) {
			halign = Align.START,
			valign = Align.FILL,
			hexpand= true,
			vexpand=true,
			can_focus = false,
			alternative_text = title	
		};
		img.set_size_request (-1, img.paintable.get_intrinsic_height ());
		box.append (img);
	}

	public void append_text (string text) {
		var label = new Gtk.Label (text) {
			halign = Align.START,
			use_markup = true,
			selectable = true,
			hexpand = false,
			vexpand = false,
			can_focus = false
		};

		box.append (label);
	}


	Box box = new Gtk.Box (Orientation.VERTICAL, 0);
	ScrolledWindow scrolled = new ScrolledWindow ();
	Viewport viewport = new Viewport (null, null);

	/* Markdown Constructor */
	public MarkDown() {
		try {
			FileUtils.get_contents ("text.md", out markdown_text);
			base.append(scrolled);
			scrolled.child = (viewport);
			scrolled.min_content_width = 500;
			scrolled.min_content_height = 800;
			viewport.child = box;
			parse ();
		}
		catch (Error e) {
			print ("Error: %s\n", e.message);
		}
	}
}

public class ExampleApp : Gtk.Application {
	construct {
		application_id = "org.example.app";
		flags = ApplicationFlags.FLAGS_NONE;
	}

  public override void activate () {
	var win = new Gtk.ApplicationWindow (this);
			var provider = new Gtk.CssProvider ();
		provider.load_from_data ("""
.table {
	border: solid 1px #787063;
}

.table .table_label {
	padding-right: 10px;
	padding-left: 10px;
	padding-top: 5px;
	padding-bottom: 5px;
	background-color: #202224;
	border: solid 0.5px #787063;
}

.table .header_table {
	background-color: #404040;
	color: white;
	font-weight: bold;
	padding-right: 20px;
	padding-left: 20px;
	padding-top: 10px;
	padding-bottom: 10px;
	border: solid 1px #787063;
}

""".data);
	Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);


	win.child = new MarkDown() {
		margin_start = 15,
		margin_top = 15,
	};
	win.present ();
  }

  public static int main (string[] args) {
    var app = new ExampleApp ();
    return app.run (args);
  }
}




public class Table : Gtk.Grid {
	construct {
		css_classes = {"table"};
	}

	public Table () {

	}

	public Table.from_content (string content) {
		foreach (unowned var line in content.split("\n")) {
			if (is_table(line))
				this.add_line(line);
			else if (!this.is_empty()) {
				generate_table();
				break;
			}
		}
	}

	private bool is_table(string line) {
		MatchInfo match_info;
		var reg = /^[|]{1}(.*[|]{1})+\s*$/;
		if (reg.match(line, 0, out match_info))
			return true;
		return false;
	}

	public void add_line(string line) {
		content += line;
	}

	public void generate_table() {
		bool is_header = true;
		for (int i = 0; i < content.length; i++) {
			var elems = content[i].split("|");
			elems = elems[1:elems.length - 1];

			if (/^[|]([- :]+[|])+\s*$/.match(content[i])) {
				is_header = false;
				continue;
			}

			for (int j = 0; j < elems.length; j++) {
				var elem = elems[j]._strip();

				if (is_header)
					attach(new Gtk.Label(elem){css_classes={"header_table"}, use_markup=true}, j, i);
				else
					attach(new Gtk.Label(elem){css_classes={"table_label"}, use_markup=true, selectable=true, vexpand=true, hexpand=true, halign=Gtk.Align.FILL}, j, i);
			}
		}
	}

	public bool is_empty() {
		return content.length == 0;
	}

	private string []content;
}
