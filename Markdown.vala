using Gtk;

public class Markdown : Gtk.Box {
	private string file_path;
	private string dir_name;
	private string filename;
	private Regex regex_image;
	private Regex regex_link;
	private Regex regex_table;
	private Regex regex_code;
	private Regex regex_blockquote;

	construct {
		orientation = Gtk.Orientation.VERTICAL;
		try {
			regex_image = new Regex("""[!]\[(?P<name>.*)\]\((?P<url>[^\s]*)?(?P<title>.*?)?\)""", RegexCompileFlags.OPTIMIZE);
			regex_link = new Regex("""^\[(?P<name>[^\]]+)\]\s*\((?P<url>[^ ""\)]+)(?P<title>[^\)]+)?\)""", RegexCompileFlags.OPTIMIZE);
			regex_table = new Regex("""(?:\|[^\n]*\n)+""", RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
			regex_code = new Regex("""```.*?```""", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
			regex_blockquote = new Regex("""([>]\s+.+?\n)+""", RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);


		}
		catch (Error e) {
			printerr ("Error compiling regex: %s\n", e.message);
		}
	}

	public Markdown (string file_path) throws Error {
		string contents;
		FileUtils.get_contents (file_path, out contents);

		this.filename = Path.get_basename(file_path);
		this.file_path = file_path;
		this.dir_name = Path.get_dirname(file_path);

	
		// append( new Gtk.Label(contents) );

		var provider = new Gtk.CssProvider ();
		provider.load_from_resource ("/style.css");
		Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		// parser(contents);
		var lst = cut_content(contents);

		print ("---- CUT CONTENT RESULT ----\n");
		foreach (var i in lst) {
			if (i.type == MarkdownElement.Type.TEXT)
				print ("Block type: [TEXT]>>>\033[35m\n%s\033[0m\n", i.content);
			if (i.type == MarkdownElement.Type.IMAGE)
				print ("Block type: [IMAGE]>>>\033[34m\n%s\033[0m\n", i.content);
			if (i.type == MarkdownElement.Type.CODEBLOCK)
				print ("Block type: [CODEBLOCK]>>>\033[32m\n%s\033[0m\n", i.content);
			if (i.type == MarkdownElement.Type.TABLE)
				print ("Block type: [TABLE]>>>\033[33m\n%s\033[0m\n", i.content);
			if (i.type == MarkdownElement.Type.BLOCKQUOTE)
				print ("Block type: [BLOCKQUOTE]>>>\033[36m\n%s\033[0m\n", i.content);
			if (i.type == MarkdownElement.Type.SEPARATOR)
				print ("Block type: [SEPARATOR]>>>\033[31m\n%s\033[0m\n", i.content);
		}
	}



		public SList<MarkdownElement> cut_content (string contents) {
		var result = new SList<MarkdownElement>();
		unowned string str = (string)contents;
		int len = str.length;

		int segment_start = 0;
		int i = 0;

		while (i < len) {
			bool line_start = (i == 0) || (str[i - 1] == '\n');

			// NOTE Horizontal Rule ---
			if (line_start && i + 2 < len && str[i] == '-' && str[i + 1] == '-' && str[i + 2] == '-') {

				if (i > segment_start)
					result.append(new MarkdownElementText(str[segment_start: i]));

				result.append(new MarkdownElementSeparator());
				i += 3;
				segment_start = i;
				continue;
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
					result.append(new MarkdownElementCodeBlock(str[i: i + end_pos]));

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
					print ("\n\n\n\n\n\nTable found at positions %d to %d\n", start_pos, end_pos);

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

					result.append(new MarkdownElementImage(str[i: i + end_pos], info));
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

	void parse_special_text(string test, uint8[] line, ref List<MarkdownEmphasis> list, ref StringBuilder sb, ref int j, MarkdownEmphasis.Type type, int max)
	{
		unowned string ptr = (string)&line[j];
		int start = j;
		int test_length = test.length;
		j += test_length; // Move past the '**'
		while (line[j] != '\0' && j < max) {
			ptr = (string)&line[j];
			if (ptr.has_prefix (test)) {
				// End of bold
				// Remove the '**' from the string builder
				sb.erase(start, test_length);
				sb.erase(j - test_length, test_length);
				// Add attribute to list
				list.append( new MarkdownEmphasis(type, start, j - start - test_length) );
				j -= test_length * 2; // Adjust j due to removed characters
				break;
			}
			j++;
		}
		j = start + test_length;
	}

	Gtk.Label parse_text (uint8[] str, ref int i) {
		unowned string begin_text_ptr = (string)&str[i];
		int nl = begin_text_ptr.index_of_char ('\n');
		if (nl == -1)
			nl = begin_text_ptr.length;
		// MatchInfo match_info;
		// if (regex_image.match(begin_text_ptr, 0, out match_info)) {
			// int end_pos, start_pos;
			// match_info.fetch_pos (0, out start_pos, out end_pos);
			// print ("Image found in text: %d and %d\n", start_pos, end_pos);
			// nl = start_pos;
			// print ("Adjusted nl to: %d\n", nl);
		// }
		var list = new List<MarkdownEmphasis>();
		// print ("Parsing line: [%s]\n", begin_text_ptr[0 : nl - 1]);
		
		int header_level = 0;
		while (str[i + header_level] == '#') {
			++header_level;
		}
		StringBuilder sb;
		if (header_level != 0) {
			print ("Header level detected: %d\n", header_level);
			print ("%s\n", begin_text_ptr[0 : nl]);
			if (begin_text_ptr[header_level] == ' ') {
				print ("Valid header with space after #'s\n");
				sb = new StringBuilder(begin_text_ptr[header_level + 1: nl]);
			}
			else {
				header_level = 0; // Not a header
				sb = new StringBuilder(begin_text_ptr[0: nl]);
			}
		}
		else {
			sb = new StringBuilder(begin_text_ptr[0: nl]);
		}

		unowned uint8[] line = sb.data;
		int j = 0;

		while (line[j] != '\0' && j < nl) {
			unowned string ptr = (string)&line[j];
			if (ptr.has_prefix ("**"))
				parse_special_text("**", line, ref list, ref sb, ref j, MarkdownEmphasis.Type.BOLD, nl);
			else if (ptr.has_prefix ("~~"))
				parse_special_text("~~", line, ref list, ref sb, ref j, MarkdownEmphasis.Type.STRIKE, nl);
			else if (ptr.has_prefix ("`"))
				parse_special_text("`", line, ref list, ref sb, ref j, MarkdownEmphasis.Type.BLOCK_CODE, nl);
			else if (ptr.has_prefix ("__"))
				parse_special_text("__", line, ref list, ref sb, ref j, MarkdownEmphasis.Type.UNDERLINE, nl);
			else if (ptr.has_prefix ("*"))
				parse_special_text("*", line, ref list, ref sb, ref j, MarkdownEmphasis.Type.ITALIC, nl);
			else
				++j;
		}

		var label = new Gtk.Label(sb.str) {
			use_markup = false,
		};
 		// Apply attributes to label
		foreach (unowned var attr in list) {
			switch (attr.type) {
				case MarkdownEmphasis.Type.BOLD:
					LabelExt.add_bold(label, attr.start_index, attr.size + attr.start_index);
					break;
				case MarkdownEmphasis.Type.STRIKE:
					LabelExt.add_strike(label, attr.start_index, attr.size + attr.start_index);
					break;
				case MarkdownEmphasis.Type.ITALIC:
					LabelExt.add_italic(label, attr.start_index, attr.size + attr.start_index);
					break;
				case MarkdownEmphasis.Type.UNDERLINE:
					LabelExt.add_underline(label, attr.start_index, attr.size + attr.start_index);
					break;
				case MarkdownEmphasis.Type.BLOCK_CODE:
					LabelExt.add_highlight(label, attr.start_index,  attr.size + attr.start_index, {0.1f, 0.1f, 0.1f, 0.2f});
					break;
				default:
					break;
			}					
		}

		switch (header_level) {
			case 0:
				// Normal text
				break;
			case 1:
				LabelExt.set_size(label, 0, nl, 28);
				LabelExt.add_bold(label, 0, nl);
				break;
			case 2:
				LabelExt.set_size(label, 0, nl, 20);
				LabelExt.add_bold(label, 0, nl);
				break;
			case 3:
				LabelExt.set_size(label, 0, nl, 16);
				LabelExt.add_bold(label, 0, nl);
				break;
			default:
				LabelExt.set_size(label, 0, nl, 14);
				break;
		}

		label.selectable = true;
		label.set_halign (Gtk.Align.START);
		i += nl;
		return label;
	}



	void append_table (uint8[] str, ref int i) {
		unowned string begin_text_ptr = (string)&str[i];
		int nl = begin_text_ptr.index_of_char ('\n');
		if (nl == -1) {
			nl = begin_text_ptr.length;
		}
		StringBuilder sb = new StringBuilder();
		while (true) {
			begin_text_ptr = (string)&str[i];
			nl = begin_text_ptr.index_of_char ('\n');
			if (nl == -1) {
				nl = begin_text_ptr.length;
			}
			sb.append(begin_text_ptr[0 : nl] + "\n");
			i += nl + 1;
			begin_text_ptr = (string)&str[i];
			if (!begin_text_ptr.has_prefix ("|"))
				break;
		}
		var table = new Table.from_content(sb.str, (text, is_table) => {
			int _index = 0;
			return parse_text((uint8[])text.data, ref _index);
		});
		append(table);
		i -= 1; // Adjust i since the main loop will increment it
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
		append (box_code);
	}

	private void append_img (string name, string url, string title) throws Error {
		string _url = dir_name + "/" + url;
		try {
			if (_url.has_suffix (".gif") || _url.has_suffix (".webp")) {
				var img = new Gif (_url) {
					valign = Align.START,
					halign = Align.START,
					hexpand=false,
					vexpand=false,
					can_focus = false,
					focusable = false,
				};
				append (img);
				return ;
			}
			else {
				if (FileUtils.test (_url, FileTest.EXISTS) == false) {
					throw new FileError.EXIST("Image [%s] not found", _url);
				}
				Picture img = new Gtk.Picture.for_filename (_url) {
					valign = Align.START,
					halign = Align.START,
					hexpand=false,
					vexpand=false,
					can_focus = false,
					focusable = false,
					alternative_text = title
				};
				img.set_size_request (-1, img.paintable.get_intrinsic_height ());
				append (img);
				return ;
			}
		}
		catch (Error e) {
			throw e;
		}
	}



	void parser (string content) {
		int i = 0;
		uint8[] str = content.data;
		int len_max = str.length;

		bool is_begin = true;
		while (i < len_max) {
			MatchInfo info;

			print (@"\033[35m$is_begin >>> [%s]\033[0m\n", ((string)&str[i])[0:10]);
				
			// if (regex_image.match((string)&str[i], RegexMatchFlags.ANCHORED, out info)) {
				// // Image ![alt](url "title")
				// int start_pos, end_pos;
				// info.fetch_pos (1, out start_pos, out end_pos);
				// var url = info.fetch_named("url");
				// var title = info.fetch_named("title");
				// var name = info.fetch_named("name");
				// print ("Image found: %s\n", ((string)&str[i])[start_pos:end_pos]);
				// append_img(name, url, title);
				// i += end_pos;
				// is_begin = true;
				// // continue;
			// }

			if (str[i] == '-' && str[i+1] == '-' && str[i+2] == '-') {
				print ("Horizontal Rule found\n");
				append( new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
				unowned string begin_text_ptr = (string)&str[i];
				int nl = begin_text_ptr.index_of_char ('\n');
				i += nl == -1 ? begin_text_ptr.length : nl;
				continue;
			}


			// Code block  ```lang text```
			// NOTE rework it
			if (is_begin && str[i] == '`' && str[i + 1] == '`' && str[i + 2] == '`') {
				// Code block
				i += 3; // Move past the opening ```
				unowned string begin_text_ptr = (string)&str[i];
				int nl = begin_text_ptr.index_of_char ('\n');
				if (nl == -1) {
					nl = begin_text_ptr.length;
				}
				// Extract language (if any)
				string lang = begin_text_ptr[0 : nl]._strip();
				i += nl + 1; // Move to the next line after language

				// Now extract code until closing ```
				begin_text_ptr = (string)&str[i];
				int end_code_index = begin_text_ptr.index_of("```");
				if (end_code_index == -1) {
					end_code_index = begin_text_ptr.length;
				}
				string code = begin_text_ptr[0 : end_code_index];
				append_textcode(lang, code);
				i += end_code_index + 3; // Move past the closing ```
				continue; // Skip the i++ at the end
			}

			// Table  | Foo | Bar |
			// NOTE add a is_table function
			if (is_begin && str[i] == '|') {
				append_table(str, ref i);
				continue;
			}

			// Unordered list - '- '
			if (is_begin && str[i] == '-' && str[i+1] == ' ') {
				// Unordered list
				// print ("Unordered List\n");
				var ul_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
					halign = Gtk.Align.START,
				};
				while (i < len_max && str[i] == '-' && str[i+1] == ' ') {
					i += 2; // Move past '- '
					var item_label = parse_text(str, ref i);
					var item_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5) {
						halign = Gtk.Align.START,
					};
					var bullet_label = new Gtk.Label("• ") {
						halign = Gtk.Align.START,
						valign = Gtk.Align.END
					};
					LabelExt.set_size (bullet_label, 0, 3, 20);
					item_box.append(bullet_label);
					item_box.append(item_label);
					ul_box.append(item_box);
					// Move to the next line
					if (i < len_max && str[i] == '\n') {
						i++;
					}
				}
				append(ul_box);
				continue;
			}

			append(parse_text(str, ref i));
			
			i++;
		}
	}

}
