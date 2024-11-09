using Gtk;


public class MarkDown : Gtk.Box {
	/** Private members */
	private unowned Gtk.Box box;
	private Regex		regex_image;
	private Regex		regex_table;
	private Regex		regex_code;
	private Regex		regex_task;
	private Regex		regex_blockquotes;
	private Box			general_box;

	/** Constructor */
	construct {
		general_box = new Gtk.Box (Orientation.VERTICAL, 0);
		box = general_box;
		var provider = new Gtk.CssProvider ();
		provider.load_from_resource ("/style.css");
		StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		base.append(general_box);
		try {
			regex_image = new Regex("""[!]\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""");
			regex_table = new Regex("""^\|.*\|.*\|\n(\|.*\|.*\|\n)*""", RegexCompileFlags.MULTILINE);
			regex_code = new Regex("""^```(?P<lang>\S*)?\n(?P<code>.*?)```""", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE);

			regex_task = new Regex("""^-\s\[(X|x| )\]\s*(?<name>.*)""");
			regex_blockquotes = new Regex("(^>.*?\n)+(\n|$)", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE);
		}
		catch (Error e) {
			error ("Error: %s\n", e.message);
		}
	}

	/* Markdown Constructor */
	public MarkDown () throws Error {

	}

	public MarkDown.from_file (string file) throws Error {
		load_from_file (file);
	}

	public MarkDown.from_string (string text) throws Error {
		parse (text);
	}

	public void load_from_string (string text) throws Error {
		parse (text.replace("\r", ""));
	}

	public void load_from_file (string file) throws Error {
		string markdown_text;
		FileUtils.get_contents (file, out markdown_text);
		markdown_text = markdown_text.replace ("\r", "");
		parse (markdown_text);
	}

	public void clear () {
		general_box = new Gtk.Box (Orientation.VERTICAL, 0);
		box = general_box;
	}


	/*
	* principal parsing function
	* it parse the markdown text and append the result to the actual box
	*/
	private void parse (owned string text_md) throws Error {
		MatchInfo match_info;
		int start_pos, end_pos;
		int start = 0;


		for (int i = 0; text_md[i] != '\0'; ++i) {
			bool is_nl;
			if (i == 0)
				is_nl = true;
			else
				is_nl = (text_md[i - 1] == '\n');
			if (is_nl == false)
				continue;

			// Task checkbox parsing
			if (text_md[i] == '-') {
				if (regex_task.match(text_md.offset(i), 0, out match_info))
				{
					match_info.fetch_pos (0, out start_pos, out end_pos);
					if (start != i)
						append_text (text_md[start:i]);
					var name = match_info.fetch_named("name");
					append_checkbox (text_md[i + 3], name);
					i += end_pos;
					start = i + 1;
					continue;
				}
			}
			// Horizontal line
			if (text_md[i] == '*' || text_md[i] == '-' || text_md[i] == '_') {
				char c = text_md[i];
				int n = 0;
				while (text_md[n + i] == c)
					++n;
				if (n >= 3 && text_md[i + n] == '\n') {
					append_text (text_md[start:i]);
					append_separator();
					i += n;
					start = i;
				}
			}
			// image parsing
			if (text_md[i] == '!') {
				if (regex_image.match(text_md.offset(i), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					if (start != i)
						append_text (text_md[start:i]);

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
			else if (text_md[i] == '|') {
				if (regex_table.match(text_md.offset(i - 1), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					if (start != i)
						append_text (text_md[start:i]);
					string table = text_md.offset(i)[0:end_pos - 1];
					append_table (table);
					i += end_pos - 1;
					start = i;
				}
			}
			// - to bullet list
			if (text_md[i] == '-' && text_md[i + 1] == ' ') {
				if (start == 0)
					append_text (text_md[start:i]);
				else if (start != i)
					append_text (text_md[start+1:i]);
				int nl = text_md.offset(i).index_of_char ('\n');
				var str = "• " + simple_parse_html(text_md.offset(i)[2:nl]);
				append_text (str);
				start = i + 0 + nl;
				i = start;
			}

			if (text_md[i] == '>') {
				if (regex_blockquotes.match(text_md.offset(i), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					if (start != i)
						append_text (text_md[start:i]);
					var blockquotes = match_info.fetch (0);
					append_blockquotes(blockquotes);
					i += end_pos;
					start = i;
				}
			}

			if (text_md[i] == '`' && text_md[i + 1] == '`' && text_md[i + 2] == '`') {
				if (regex_code.match(text_md.offset(i), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					if (start != i)
						append_text (text_md[start:i]);
					var lang = match_info.fetch_named("lang") ?? "none";
					var code = match_info.fetch_named("code");
					append_textcode(lang, code);
					i += end_pos;
					start = i;
				}
			}
		}

		append_text (text_md.offset(start));
	}

	private void append_checkbox (char c, string name) {
		var check = new Gtk.CheckButton.with_label (name) {
			halign = Align.START,
			valign = Align.FILL,
			hexpand = false,
			vexpand = false,
			can_focus = false,
		};
		if (c == 'x' || c == 'X')
			check.active = true;
		box.append (check);
	}

	private void append_separator () {
		var separator = new Gtk.Separator (Orientation.HORIZONTAL) {
			halign = Align.FILL,
			valign = Align.FILL,
			hexpand = true,
			vexpand = false,
		};
		box.append (separator);
	}

	private void append_blockquotes (string content) throws Error {
		var block_quotes = new Gtk.Box (Orientation.VERTICAL, 0) {
			css_classes = {"blockquotes"},
			halign = Align.START,
			valign = Align.FILL,
			hexpand = false,
			vexpand = false,
		};
		box.append(block_quotes);
		box = block_quotes;
		var regex = new Regex("^>[ ]?", MULTILINE);
		var parse_me = regex.replace (content, -1, 0, "");
		parse (parse_me);
		box = general_box;
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
			try {
				var img = new Gif (url);
				box.append (img);
			}
			catch (Error e) {
				print ("Error: %s\n", e.message);
			}
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

		
	public signal bool activate_link (string uri);

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
		label.activate_link.connect ((uri) => {
			if (this.activate_link(uri) == false) {
				try {
					Process.spawn_command_line_async("xdg-open " + uri);
				}
				catch (Error e) {
					print ("Error: %s\n", e.message);
				}
			}
			return true;
		});

		box.append (label);
	}

	private void append_textcode (string lang, string code) throws Error {
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

		box_code.append(new Gtk.Label (line_bar.str) {
			css_classes = {"line_bar"},
			halign = Align.START,
			valign = Align.START,
			vexpand = true,
			hexpand = true,
			justify = Justification.LEFT,
		});
		box_code.append(text);
		box.append (box_code);
	}
}






/**
* Simple function to parse markdown text HTML
*/

// simple parsing replace HTML  <tag>text</tag>
private string parse_html(string regex_str, string balise_open, string balise_close, string text) throws Error {
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
private string parse_link (string text) throws Error {
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

private string simple_parse_html (owned string text) throws Error {
	// BOLD/ITALIC/BOLD_ITALIC
	text = text.replace("<", "&lt;");
	text = text.replace(">", "&gt;");

	text = parse_html ("[*]{3}([^*]+)[*]{3}", "<b><i>", "</i></b>", text);
	text = parse_html ("[*]{2}([^*]+)[*]{2}", "<b>", "</b>", text);
	text = parse_html ("[*]{1}([^*]+)[*]{1}", "<i>", "</i>", text);
	text = parse_html("[=]{2}([^=]+)[=]{2}", """<span bgcolor="#383006">""", "</span>", text);
	// LINK
	text = parse_link(text);
	// HEADER
	text = parse_html("^[#]{1} (.*?)$$", """<span size="300%">""", "</span>", text);
	text = parse_html("^[#]{2} (.*?)$$", """<span size="200%">""", "</span>", text);
	text = parse_html("^[#]{3} (.*?)$$", """<span size="150%">""", "</span>", text);
	text = parse_html("^[#]{4} (.*?)$$", """<span size="125%">""", "</span>", text);
	text = parse_html("^[#]{5} (.*?)$$", """<span size="110%">""", "</span>", text);
	text = parse_html("^[#]{6} (.*?)$$", """<span size="85%">""", "</span>", text);
	// simple code
	text = parse_html("[`]([^`]+)[`]", """<span bgcolor="#292443">""", "</span>", text);
	return text;
}
