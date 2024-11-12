using Gtk;


public class MarkDown : Gtk.Box {
	/** Private members */
	private unowned Gtk.Box box;
	private Regex		regex_image;
	private Regex		regex_table;
	private Regex		regex_code;
	private Regex		regex_task;
	private Regex		regex_blockquotes;
	private Regex		regex_link;
	private Regex		regex_blockquotes_replace;
	private Box			general_box;

	public string path_dir {get; set;}

	/** Constructor */
	construct {
		path_dir = Environment.get_current_dir ();
		general_box = new Gtk.Box (Orientation.VERTICAL, 0);
		box = general_box;
		var provider = new Gtk.CssProvider ();
		provider.load_from_resource ("/style.css");
		StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		base.append(general_box);
		try {
			regex_image = new Regex("""[!]\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""", RegexCompileFlags.OPTIMIZE);
			regex_table = new Regex("""^\|.*\|.*\|\n(\|.*\|.*\|\n)*""", RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
			regex_code = new Regex("""^```(?P<lang>\S*)?\n(?P<code>.*?)```""", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
			regex_link = new Regex("""^\[(?P<name>[^\]]+)\]\s*\((?P<url>[^ ""\)]+)(?P<title>[^\)]+)?\)""", RegexCompileFlags.OPTIMIZE);
			regex_task = new Regex("""^-\s\[(X|x| )\]\s*(?<name>.*)""", RegexCompileFlags.OPTIMIZE);
			regex_blockquotes = new Regex("(^>.*?\n)+(\n|$)", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
			regex_blockquotes_replace = new Regex("^>[ ]?", MULTILINE | OPTIMIZE);
		}
		catch (Error e) {
			error ("Error: %s\n", e.message);
		}
		hexpand = true;
		vexpand = true;
	}

	/* Markdown Constructor */
	public MarkDown () {

	}

	public MarkDown.from_file (string file) throws Error {
		load_file (file);
	}

	public MarkDown.from_string (string text) throws Error {
		parse (text);
	}

	public void load_string (string text) throws Error {
		// Timer timer = new Timer ();
		// timer.reset ();
		parse (text.replace("\r", ""));
		// print ("Time string: %f\n", timer.elapsed());
	}

	public void load_file (string file) throws Error {
		// Timer timer = new Timer ();
		// timer.reset ();
		string markdown_text;
		FileUtils.get_contents (file, out markdown_text);
		markdown_text = markdown_text.replace ("\r", "");
		parse (markdown_text);
		// print ("Time file: %f\n", timer.elapsed());
	}

	public void clear () {
		base.remove (general_box);
		general_box = null;
		general_box = new Gtk.Box (Orientation.VERTICAL, 0);
		box = general_box;
		base.append(general_box);
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
			else if (text_md[i] == '!') {
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
					start = i ;
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

			else if (text_md[i] == '>') {
				if (regex_blockquotes.match(text_md.offset(i), 0, out match_info)) {
					match_info.fetch_pos (0, out start_pos, out end_pos);
					if (start != i)
						append_text (text_md[start:i]);
					var blockquotes = match_info.fetch (0);
					append_blockquotes(blockquotes);
					i += end_pos - 2;
					start = i;
				}
			}

			else if (text_md[i] == '`' && text_md[i + 1] == '`' && text_md[i + 2] == '`') {
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
		var parse_me = regex_blockquotes_replace.replace (content, -1, 0, "");
		parse (parse_me);
		box = general_box;
	}

	private void append_table (string content) throws Error {
		content = label_parsing (content, true);
		var table = new Table.from_content (content) {
			halign = Align.START,
			valign = Align.FILL,
			hexpand= true,
			vexpand=true,
		};
		box.append (table);
	}

	private void append_img (string name, string url, string title) throws Error {
		string _url = path_dir + "/" + url; 
		try {
			if (_url.has_suffix (".gif") || _url.has_suffix (".webp")) {
				var img = new Gif (_url);
				box.append (img);
				return ;
			}
			else {
				if (FileUtils.test (_url, FileTest.EXISTS) == false) {
					throw new FileError.EXIST("Image [%s] not found", _url);
				}
				Picture img = new Gtk.Picture.for_filename (_url) {
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
		catch (Error e) {
			try {
				append_text (@"Error: $(e.message)");
			}
			catch (Error e) {
				throw e;
			}
		}
	}

		
	public signal bool activate_link (string uri);

	private void append_text (string text) throws Error {
		text = label_parsing (text);
		var label = new Gtk.Label (text) {
			halign = Align.START,
			use_markup = true,
			selectable = true,
			hexpand = true,
			vexpand = false,
			wrap = true,
			can_focus = false
		};
		label.activate_link.connect ((uri) => {
			if (this.activate_link(uri) == false) {
				try {
					if (FileUtils.test (path_dir + "/" + uri + ".md", FileTest.EXISTS)) {
						this.clear();
						this.load_file (path_dir + "/" + uri + ".md");
					}
					else
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


	/** Simple parsing for Label */
	private string label_parsing (owned string text, bool is_table = false) throws Error {
		StringBuilder result = new StringBuilder();
		MatchInfo info;
		bool is_newline = true;
		bool is_header = false;
		bool is_bold = false;
		bool is_italic = false;
		bool is_bolditalic = false;
		bool is_code1 = false;
		bool is_code2 = false;
		bool is_highlight = false;
		bool is_strike = false;
		bool is_underline = false;
		bool is_sub = false;
		bool is_sup = false;
		bool is_quote = false;
		bool is_escaped = false;
		var regex_automatic_link = new Regex("""^http[s]?://[^\s"']*""", RegexCompileFlags.OPTIMIZE);

		for (int i = 0; text[i] != '\0'; ++i) {
			// check newline
			if (i == 0 || text[i - 1] == '\n') {
				is_newline = true;
				if (is_header) {
					result.append("</span>");
					is_header = false;
				}
				is_quote = false;
			}
			else
				is_newline = false;	

			if (i != 0 && text[i - 1] == '\\')
				is_escaped = true;
			else
				is_escaped = false;


			// escape me !
			if (text[i] == '<') {
				result.append("&lt;");
				continue;
			}
			else if (text[i] == '>') {
				result.append("&gt;");
				continue;
			}
			if (text[i] == '\\') {
				if (text[i + 1] == '<') {
					result.append("&lt;");
					++i;
				}
				else if (text[i + 1] == '>') {
					result.append("&gt;");
					++i;
				}
				continue ;
			}



			if (is_newline == true) {
				
				if (is_table == false && text[i] == '-' && text[i + 1] == ' ') {
					result.append("• ");
					i += 2;
				}

				// HEADER 
				if (text[i] == '#') {
					int n = 0;
					while (text[i + n] == '#')
						++n;
					if (text[i + n] == ' ') {
						is_header = true;
						switch (n) {
							case 1:
								result.append("<span size=\"300%\">");
								break;
							case 2:
								result.append("<span size=\"200%\">");
								break;
							case 3:
								result.append("<span size=\"150%\">");
								break;
							case 4:
								result.append("<span size=\"125%\">");
								break;
							case 5:
								result.append("<span size=\"110%\">");
								break;
							case 6:
								result.append("<span size=\"85%\">");
								break;
						}
						i += n + 1;
					}
				}
			}

			if (regex_link.match(text.offset(i), RegexMatchFlags.NOTEOL, out info)) {
				int start_pos, end_pos;
				info.fetch_pos (0, out start_pos, out end_pos);
				
				var name = info.fetch_named("name");
				var url = info.fetch_named("url");
				var? title = info.fetch_named("title")?.strip();
				if (title == null || title == "")
					result.append_printf ("<a href=\"%s\">%s</a>", url, name);
				else
					result.append_printf ("<a href=\"%s\" title=%s>%s</a>", url, title, name);
				i += end_pos - 1;
				continue;
			}
				// CODE
			else if (text[i] == '`' && is_escaped == false) {
				int n = 0;
				while (text[i + n] == '`')
					++n;
				switch (n) {
					case 1:
						if (is_code1)
							result.append("</span>");
						else
							result.append("<span bgcolor=\"#292443\">");
						is_code1 = !is_code1;
						continue;
					case 2:
						if (is_code2)
							result.append("</span>");
						else
							result.append("<span bgcolor=\"#292959\">");
						is_code2 = !is_code2;
						i += 1;
						continue;
				}
			}

			if (is_code1 == false && is_code2 == false && is_escaped == false) {
				// AUTOMATIC LINK
				if (regex_automatic_link.match(text.offset(i), RegexMatchFlags.NOTEOL, out info)) {
					int quote_found = 0;
					int n = 0;
					while (text[i + n] != '\0' && text[i + n] != '\n')
					{
						if (text[i + n] == '\'')
							++quote_found;
						++n;
					}
					if (quote_found % 2 == 0 && is_quote == false || is_quote == true && quote_found == 0) 
					{
						int start_pos, end_pos;
						info.fetch_pos (0, out start_pos, out end_pos);
						var url = info.fetch (0);
						result.append_printf ("<a href=\"%s\">%s</a>", url, url);
						i += end_pos - 1;
						continue;
					}
				}

				// BOLD/ITALIC/BOLD_ITALIC
				if (text[i] == '*') {
					int n = 0;
					while (text[i + n] == '*')
						++n;
					if (n <= 3) {
						switch (n) {
							case 1:
								if (is_italic)
									result.append("</i>");
								else
									result.append("<i>");
								is_italic = !is_italic;
								i += n - 1;
								continue;
							case 2:
								if (is_bold)
									result.append("</b>");
								else
									result.append("<b>");
								is_bold = !is_bold;
								i += n - 1;
								continue;
							case 3:
								if (is_bolditalic)
									result.append("</i></b>");
								else
									result.append("<b><i>");
								is_bolditalic = !is_bolditalic;
								i += n - 1;
								continue;
						}
					}
				}

				else if (text[i] == '=' && text[i + 1] == '=' && is_escaped == false) {
					if (is_highlight)
						result.append("</span>");
					else
						result.append("<span bgcolor=\"#594939\">");
					is_highlight = !is_highlight;
					i += 1;
					continue;
				}

				else if (text[i] == '~' && is_escaped == false) {
					int n = 0;
					while (text[i + n] == '~')
						++n;
					switch (n) {
						case 1:
							if (is_sub)
								result.append("</sub>");
							else
								result.append("<sub>");
							is_sub = !is_sub;
							continue;
						case 2:
							if (is_strike)
								result.append("</s>");
							else
								result.append("<s>");
							is_strike = !is_strike;
							++i;
							continue;
					}
				}

				else if (text[i] == '^' && text[i + 1] != '^' && is_escaped == false) {
					if (is_sup)
						result.append("</sup>");
					else
						result.append("<sup>");
					is_sup = !is_sup;
					continue;
				}

				else if (text[i] == '_' && text[i + 1] == '_' && is_escaped == false) {
					if (is_underline)
						result.append("</u>");
					else
						result.append("<u>");
					is_underline = !is_underline;
					++i;
					continue;
				}

			}


			if (text[i] == '\'' && is_escaped == false) {
				is_quote = !is_quote;
			}


			result.append_c (text[i]);
		}
		if (is_header) {
			result.append("</span>");
			is_header = false;
		}


		return (owned)result.str;
	}
}
