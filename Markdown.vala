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

	void change_token (StringBuilder new_line, int i, string token, string open, string close, string? escape = null) {
		int len_open = open.length;
		int len_token = token.length;

		while (i < new_line.len)
		{
			if (new_line.str.offset(i).has_prefix(token) && new_line.str[i + len_token] != token[0])
			{
				// Skip if token is escaped
				if (i != 0 && new_line.str[i - 1] == '\\')
				{
					// new_line.erase(i - 1, 1);
					++i;
					continue;
				}
				// find closing tag and replace
				int j = i + len_token;
				do {
					j = new_line.str.index_of(token, j + 1);
				} while (new_line.str[j - 1] == '\\');
				// escape all character 'escape' between token ``**`` -> <code>**</code>
				// insert backslash before escape character
				if (escape != null) {
					for (int k = i; k < j; ++k)
					{
						if (escape.index_of_char(new_line.str[k]) != -1)
						{
							new_line.insert(k, "\\");
							++k;
							++j;
						}
					}
				}
				// check if there is a closing tag in line (\0 or \n)
				if (j != -1)
				{
					new_line.erase(i, len_token);
					new_line.insert(i, open);
					new_line.erase(j+len_open - len_token, len_token);
					new_line.insert(j - len_token + len_open, close);
					i = j + 1;
				}

			}
			++i;
		}
	}

int append_line (StringBuilder new_line, string line) {
	var start = (int)new_line.len;
	new_line.append (line);

	change_token (new_line, start, "```", "<span bgcolor=\"#292959\">", "</span>", "*=_^~!");
	change_token (new_line, start, "``", "<span bgcolor=\"#292959\">", "</span>", "*=_^~!");
	change_token (new_line, start, "`", "<span bgcolor=\"#292959\">", "</span>", "*=_^~!");
	change_token (new_line, start, "^", "<sup>", "</sup>");
	change_token (new_line, start, "==", "<span bgcolor=\"#594939\">", "</span>");
	change_token (new_line, start, "~~", "<s>", "</s>");
	change_token (new_line, start, "~", "<sub>", "</sub>");
	change_token (new_line, start, "__", "<b>", "</b>");
	change_token (new_line, start, "_", "<u>", "</u>");
	change_token (new_line, start, "***", "<b><i>", "</i></b>");
	change_token (new_line, start, "**", "<b>", "</b>");
	change_token (new_line, start, "*", "<i>", "</i>");
	new_line.append ("\n");
	return line.length;
}


	/** Simple parsing for Label */
	private string label_parsing (owned string text, bool is_table = false) throws Error {
		StringBuilder result = new StringBuilder();


		text = text.replace (">", "&gt;");
		text = text.replace ("<", "&lt;");

		int i = 0;
		int len_text = text.length;
		while (i < len_text) {
			int n = 0;
			int nl = text.index_of_char ('\n', i);

			if (text.offset(i).has_prefix("# ")) {
				unowned string begin = text.offset(i);
				if (begin.has_prefix("## "))
					result.append("<span size=\"xx-large\">");
				// else if (begin.has_prefix("## "))
					// result.append("<span size=\"x-large\">");
				// else if (begin.has_prefix("### "))
					// result.append("<span size=\"large\">");
				// else if (begin.has_prefix("#### "))
					// result.append("<span size=\"medium\">");
				// else if (begin.has_prefix("##### "))
					// result.append("<span size=\"small\">");
				// else if (begin.has_prefix("###### "))
					// result.append("<span size=\"x-small\">");
				result.append_len (text.offset(i + begin.index_of_char (' ')), nl);
				result.append("</span>\n");
				i += nl + 1;
				continue ;
			}
			if (nl != -1) {
				text.data[nl] = '\0';
				n = append_line(result, text.offset(i));
				text.data[nl] = '\n';
			}
			i += n + 1;
		}


		return (owned)result.str;
	}
}
