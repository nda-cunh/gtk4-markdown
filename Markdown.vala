using Gtk;

public partial class MarkDown : Gtk.Box {
	string markdown_text;

	// simple parsing replace HTML  <tag>text</tag>
	string parse_html(string regex_str, string balise_open, string balise_close, string text) throws Error {
		string result = text;
		var regex = new Regex(regex_str, RegexCompileFlags.MULTILINE);
		MatchInfo match_info;

		if (regex.match (text, 0, out match_info)) {
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
	string parse_link (string text) throws Error {
		string result = text;
		MatchInfo match_info;
		var regex = new Regex("""\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""", RegexCompileFlags.MULTILINE);
		if (regex.match(text, 0, out match_info)) {
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

	private string simple_parse_html (string text) throws Error {
		// BOLD/ITALIC/BOLD_ITALIC

		text = parse_html ("[*]{3}([^*]+)[*]{3}", "<b><i>", "</i></b>", text);
		text = parse_html ("[*]{2}([^*]+)[*]{2}", "<b>", "</b>", text);
		text = parse_html ("[*]{1}([^*]+)[*]{1}", "<i>", "</i>", text);
		// LINK
		text = parse_link(text);
		// HEADER
		text = parse_html("^[#]{1} (.*?)$$", """<span size="400%">""", "</span>", text);
		text = parse_html("^[#]{2} (.*?)$$", """<span size="350%">""", "</span>", text);
		text = parse_html("^[#]{3} (.*?)$$", """<span size="300%">""", "</span>", text);
		text = parse_html("^[#]{4} (.*?)$$", """<span size="250%">""", "</span>", text);
		text = parse_html("^[#]{5} (.*?)$$", """<span size="200%">""", "</span>", text);
		text = parse_html("^[#]{6} (.*?)$$", """<span size="150%">""", "</span>", text);
		// simple code 
		text = parse_html("[`]([^*]+)[`][^`]", """<span bgcolor="#292443">""", "</span>", text);
		return text;
	}
	void parse () throws Error {
		// markdown_text = simple_parse_html (markdown_text);
		int start = 0;
		MatchInfo match_info;

		var regex_image = new Regex("""[!]\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""");
		var regex_table = new Regex("""^\|.*\|.*\|\n(\|.*\|.*\|\n)*""", RegexCompileFlags.MULTILINE);
		var regex_code = new Regex("```(?P<lang>[a-zA-Z0-9]*)?\n(?P<code>.+?)?```", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE);


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
				markdown_text = "%s%s%s".printf(markdown_text[0:i], "•", markdown_text.offset(i+1)); 
			}
			
			if (markdown_text[i - 1] == '\n' && markdown_text[i] == '`' && markdown_text[i + 1] == '`' && markdown_text[i + 2] == '`') {
				print ("code block %s\n", markdown_text.offset(i));
				if (regex_code.match(markdown_text.offset(i), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					append_text (markdown_text[start:i]);
					print ("code block\n\nWWW\n\n");
					var lang = match_info.fetch_named("lang") ?? "none";
					var code = match_info.fetch_named("code");

					print (@"\033[32;1mlanguage\033[0;32m [$lang]\033[0m\n");
					print (@"\033[1;93mcode\033[0;93m\n[$code]\033[0m\n");
					append_textcode(lang, code);
					i += end_pos;
					start = i;
				}
			}
			++i;
		}
		append_text (markdown_text.offset(start));
	}

	private void append_table (string content) throws Error {
		content = simple_parse_html (content);
		var table = new Table.from_content (content) {
			halign = Align.START,
			valign = Align.FILL,
			hexpand= true,
			vexpand=true,
		};
		box.append (table);
	}

	private void append_img (string name, string url, string title) {
		if (url.has_suffix (".gif") || url.has_suffix (".webp")) {
			var img = new Gif (url);
			box.append (img);
			return ;
		}
		else {
			Picture img = new Gtk.Picture.for_filename (url) {
				halign = Align.START,
				valign = Align.FILL,
				hexpand= true,
				vexpand=true,
				can_focus = false,
				alternative_text = title	
			};
			img.set_size_request (-1, img.paintable.get_intrinsic_height ());
			box.append (img);
			return ;
		}
	}

	private void append_text (string text) throws Error {
		text = simple_parse_html (text);
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
	
	private void append_textcode (string lang, string code) throws Error {
		// BOX code
		var _box = new Gtk.Box (Orientation.HORIZONTAL, 0) {
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


		text.set_size_request (300, -1);
		
		_box.append(new Gtk.Label (line_bar.str) {
			css_classes = {"line_bar"},
			halign = Align.START,
			valign = Align.START,
			vexpand = true,
			hexpand = true,
			justify = Justification.LEFT,
		});
		_box.append(text);
		box.append (_box);
	}


	Box box = new Gtk.Box (Orientation.VERTICAL, 0);
	ScrolledWindow scrolled = new ScrolledWindow () {
		hexpand = true,
		vexpand = true,
	};
	Viewport viewport = new Viewport (null, null);

	/* Markdown Constructor */
	public MarkDown() {
		try {
			var provider = new Gtk.CssProvider ();
		provider.load_from_data ("""
.code_box {
	background-color: #292929;
	border : solid 1px #787063;
}
.code_box textview {
	background-color: #292929;
	padding-top: 6px;
	padding-left : 10px;
}
.line_bar {
	background-color: #292443;
	color: white;
	padding-right: 10px;
	padding-left: 10px;
	padding-top: 5px;
	padding-bottom: 5px;
	border: 0px;
}

""".data);
	Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
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
