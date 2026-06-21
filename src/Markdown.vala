using Gtk;

[CCode (cname = "tree_sitter_markdown")]
extern TreeSitter.Language ts_md_lang ();

public class MarkDown : Gtk.Box {
	private unowned Gtk.Box box;
	private Box general_box;
	private TreeSitter.Parser ts_parser;
	private InlineRenderer inline_renderer;
	private string file_dir = Environment.get_current_dir ();

	construct {
		anchor = new HashTable<string, Gtk.Widget> (str_hash, str_equal);
		general_box = new Gtk.Box (Orientation.VERTICAL, 12) {
			hexpand = true,
			halign = Align.FILL
		};

		box = general_box;
		var provider = new Gtk.CssProvider ();
		provider.load_from_resource ("/style.css");
		StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		base.append (general_box);
		ts_parser = new TreeSitter.Parser ();
		ts_parser.set_language (ts_md_lang ());
		inline_renderer = new InlineRenderer ();
		hexpand = true;
		vexpand = true;
	}

	public MarkDown () {
	}

	public MarkDown.from_file (string file) throws Error {
		load_file (file);
	}

	public MarkDown.from_string (string text) throws Error {
		parse (text);
	}

	public void load_string (string text) throws Error {
		parse (text.replace ("\r", ""));
	}

	Label END;
	public void load_file (owned string file, owned string? tag = null) throws Error {
		string uri = Path.get_basename (file);
		string markdown_path = uri;
		if (markdown_path.index_of_char ('#') != -1) {
			markdown_path = markdown_path[0:markdown_path.index_of_char ('#')];
			tag = uri[uri.index_of_char ('#') + 1:];
			if (file.has_suffix (".md"))
				file = file[0:file.index_of_char ('#')] + ".md";
			else
				file = file[0:file.index_of_char ('#')];
		}
		// resolve to absolute so relative-path callers work correctly
		if (!GLib.Path.is_absolute (file))
			file = Environment.get_current_dir () + "/" + file;
		file_dir = Path.get_dirname (file);
		string markdown_text;
		FileUtils.get_contents (file, out markdown_text);
		markdown_text = markdown_text.replace ("\r", "");
		parse (markdown_text);

		END = new Gtk.Label ("") {
			can_focus = true,
			focusable = true,
			selectable = true,
		};
		box.append (END);

		if (tag != null) {
			Idle.add (() => {
				var tmp = Gtk.Settings.get_default ().gtk_enable_animations;
				var tmp2 = Gtk.Settings.get_default ().gtk_overlay_scrolling;
				Gtk.Settings.get_default ().gtk_enable_animations = false;
				Gtk.Settings.get_default ().gtk_overlay_scrolling = false;
				END.focus (DirectionType.DOWN);
				Timeout.add (100, () => {
					debug ("b: Jump to tag: %s\n", tag);
					if (anchor.contains (tag)) {
						anchor[tag].focus (DirectionType.UP);
						anchor[tag].grab_focus ();
					}
					return false;
				});
				Gtk.Settings.get_default ().gtk_enable_animations = tmp;
				Gtk.Settings.get_default ().gtk_overlay_scrolling = tmp2;
				return false;
			});
		}
	}

	public HashTable<string, Gtk.Widget> anchor;

	public void clear () {
		base.remove (general_box);
		general_box = null;
		general_box = new Gtk.Box (Orientation.VERTICAL, 12) {
			hexpand = true,
			halign = Align.FILL
		};
		box = general_box;
		base.append (general_box);
	}

	// ── Tree-sitter block parsing ────────────────────────────────────────────

	private void parse (string text_md) throws Error {
		var tree = ts_parser.parse_string (null, text_md, (uint32) text_md.length);
		if (tree == null) return;
		walk_node (tree.get_root_node (), text_md);
	}

	// Extract text from an inline node, skipping block_continuation children ("> " markers).
	private string inline_text (TreeSitter.Node node, string src) {
		uint32 n = TreeSitter.node_get_child_count (node);
		if (n == 0) return node_text (node, src);
		var sb = new StringBuilder ();
		uint32 pos = node.start_byte;
		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			if (TreeSitter.node_get_type (child) == "block_continuation") {
				if (child.start_byte > pos)
					append_bytes (sb, src, pos, child.start_byte);
				pos = child.end_byte;
			}
		}
		if (pos < node.end_byte)
			append_bytes (sb, src, pos, node.end_byte);
		return sb.str;
	}

	private void append_bytes (StringBuilder sb, string src, uint32 start, uint32 end_pos) {
		if (end_pos <= start) return;
		uint32 len = end_pos - start;
		uint8[] buf = new uint8[len + 1];
		Memory.copy (buf, ((uint8*) src) + start, (size_t) len);
		sb.append (((string) buf).dup ());
	}

	private string node_text (TreeSitter.Node node, string src) {
		uint32 len = node.end_byte - node.start_byte;
		uint8[] buf = new uint8[len + 1];
		Memory.copy (buf, ((uint8*) src) + node.start_byte, (size_t) len);
		return ((string) buf).dup();
	}

	private void walk_node (TreeSitter.Node node, string src) throws Error {
		unowned string? type = TreeSitter.node_get_type (node);
		if (type == null) return;

		switch (type) {
		case "document":
		case "section":
			walk_children (node, src);
			break;
		case "atx_heading":
			render_atx_heading (node, src);
			break;
		case "setext_heading":
			render_setext_heading (node, src);
			break;
		case "paragraph":
			render_paragraph (node, src);
			break;
		case "fenced_code_block":
			render_fenced_code (node, src);
			break;
		case "indented_code_block":
			render_indented_code (node, src);
			break;
		case "block_quote":
			render_block_quote (node, src);
			break;
		case "list":
		case "tight_list":
		case "loose_list":
			walk_children (node, src);
			break;
		case "list_item":
			render_list_item (node, src);
			break;
		case "thematic_break":
			append_separator ();
			break;
		case "pipe_table":
			render_pipe_table (node, src);
			break;
		case "block_continuation":
			break;
		default:
			break;
		}
	}

	private void walk_children (TreeSitter.Node node, string src) throws Error {
		uint32 n = TreeSitter.node_get_child_count (node);
		for (uint32 i = 0; i < n; i++)
			walk_node (TreeSitter.node_get_child (node, i), src);
	}

	private void render_atx_heading (TreeSitter.Node node, string src) throws Error {
		int level = 1;
		string content = "";
		uint32 n = TreeSitter.node_get_child_count (node);
		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			unowned string? ct = TreeSitter.node_get_type (child);
			if (ct == null) continue;
			switch (ct) {
			case "atx_h1_marker": level = 1; break;
			case "atx_h2_marker": level = 2; break;
			case "atx_h3_marker": level = 3; break;
			case "atx_h4_marker": level = 4; break;
			case "atx_h5_marker": level = 5; break;
			case "atx_h6_marker": level = 6; break;
			case "inline":
				content = node_text (child, src);
				break;
			}
		}
		int[] top_margins = { 24, 20, 16, 12, 10, 10 };
		var label = create_supra_label (content, level);
		label.can_focus = true;
		label.focusable = true;
		label.margin_top = top_margins[level - 1];
		label.margin_bottom = 4;
		box.append (label);
		anchor[content._strip ()] = label;
	}

	private void render_setext_heading (TreeSitter.Node node, string src) throws Error {
		int level = 1;
		string content = "";
		uint32 n = TreeSitter.node_get_child_count (node);
		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			unowned string? ct = TreeSitter.node_get_type (child);
			if (ct == null) continue;
			switch (ct) {
			case "setext_h1_underline": level = 1; break;
			case "setext_h2_underline": level = 2; break;
			case "paragraph":
				uint32 pn = TreeSitter.node_get_child_count (child);
				for (uint32 j = 0; j < pn; j++) {
					var pc = TreeSitter.node_get_child (child, j);
					if (TreeSitter.node_get_type (pc) == "inline") {
						content = node_text (pc, src)._strip ();
						break;
					}
				}
				if (content == "")
					content = node_text (child, src)._strip ();
				break;
			case "inline":
				content = node_text (child, src)._strip ();
				break;
			}
		}
		int[] top_margins = { 24, 20, 16, 12, 10, 10 };
		var label = create_supra_label (content, level);
		label.can_focus = true;
		label.focusable = true;
		label.margin_top = top_margins[level - 1];
		label.margin_bottom = 4;
		box.append (label);
		anchor[content._strip ()] = label;
	}

	private void render_paragraph (TreeSitter.Node node, string src) throws Error {
		uint32 n = TreeSitter.node_get_child_count (node);
		var sb = new StringBuilder ();
		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			unowned string? ct = TreeSitter.node_get_type (child);
			if (ct == "inline") {
				if (sb.len > 0) sb.append_c ('\n');
				sb.append (inline_text (child, src));
			}
		}
		string text = sb.len > 0 ? sb.str : node_text (node, src);
		if (!parse_image_from_text (text))
			append_text (text);
	}

	// Byte-level scan for standalone image syntax ![alt](url){width=N height=N}.
	// All delimiters are ASCII so byte offsets equal character offsets for them.
	private bool parse_image_from_text (string raw) throws Error {
		int len = raw.length;
		int i = 0;
		while (i < len && (raw[i] == ' ' || raw[i] == '\n' || raw[i] == '\r' || raw[i] == '\t'))
			i++;
		if (i + 3 >= len || raw[i] != '!' || raw[i + 1] != '[') return false;

		int alt_start = i + 2;
		int bracket_end = -1;
		int depth = 0;
		for (int j = alt_start; j < len; j++) {
			if (raw[j] == '[') depth++;
			else if (raw[j] == ']') {
				if (depth > 0) { depth--; continue; }
				if (j + 1 < len && raw[j + 1] == '(') { bracket_end = j; break; }
			}
		}
		if (bracket_end < 0) return false;

		int url_start = bracket_end + 2;
		int paren_end = -1;
		for (int j = url_start; j < len; j++) {
			if (raw[j] == ')') { paren_end = j; break; }
		}
		if (paren_end < 0) return false;

		uint8[] alt_buf = new uint8[bracket_end - alt_start + 1];
		Memory.copy (alt_buf, ((uint8*) raw) + alt_start, bracket_end - alt_start);
		string alt = (string) alt_buf;

		int url_end = url_start;
		while (url_end < paren_end && raw[url_end] != ' ' && raw[url_end] != '\t')
			url_end++;
		if (url_start == url_end) return false;
		uint8[] url_buf = new uint8[url_end - url_start + 1];
		Memory.copy (url_buf, ((uint8*) raw) + url_start, url_end - url_start);
		string url = (string) url_buf;

		string title = "";
		if (url_end < paren_end) {
			int t = url_end;
			while (t < paren_end && (raw[t] == ' ' || raw[t] == '\t')) t++;
			int t_end = paren_end;
			while (t_end > t && (raw[t_end - 1] == ' ' || raw[t_end - 1] == '\t')) t_end--;
			if (t_end > t) {
				uint8[] title_buf = new uint8[t_end - t + 1];
				Memory.copy (title_buf, ((uint8*) raw) + t, t_end - t);
				title = (string) title_buf;
			}
		}

		// Parse optional {width=N height=N} after the closing ).
		int img_width = -1;
		int img_height = -1;
		int k = paren_end + 1;
		while (k < len && (raw[k] == ' ' || raw[k] == '\t')) k++;
		if (k < len && raw[k] == '{') {
			int attr_end = raw.index_of ("}", k + 1);
			if (attr_end > k) {
				string attrs = raw.substring (k + 1, attr_end - k - 1);
				img_width  = parse_img_attr_int (attrs, "width");
				img_height = parse_img_attr_int (attrs, "height");
				k = attr_end + 1;
			}
		}
		// Reject if anything other than whitespace remains.
		for (; k < len; k++) {
			if (raw[k] != ' ' && raw[k] != '\n' && raw[k] != '\r' && raw[k] != '\t')
				return false;
		}

		append_img (alt, url, title, img_width, img_height);
		return true;
	}

	private int parse_img_attr_int (string attrs, string key) {
		string pattern = key + "=";
		int pos = attrs.index_of (pattern);
		if (pos < 0) return -1;
		int val_start = pos + pattern.length;
		int val_end = val_start;
		while (val_end < attrs.length && attrs[val_end].isdigit ()) val_end++;
		if (val_end == val_start) return -1;
		return int.parse (attrs.substring (val_start, val_end - val_start));
	}

	private void render_fenced_code (TreeSitter.Node node, string src) throws Error {
		string lang = "none";
		string code = "";
		uint32 n = TreeSitter.node_get_child_count (node);
		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			unowned string? ct = TreeSitter.node_get_type (child);
			if (ct == null) continue;
			switch (ct) {
			case "info_string":
				lang = node_text (child, src).strip ();
				if (lang == "") lang = "none";
				break;
			case "code_fence_content":
				code = node_text (child, src);
				break;
			}
		}
		append_textcode (lang, code);
	}

	private void render_indented_code (TreeSitter.Node node, string src) throws Error {
		var raw = node_text (node, src);
		var sb = new StringBuilder ();
		foreach (var line in raw.split ("\n")) {
			if (line.has_prefix ("    "))
				sb.append (line[4:]);
			else
				sb.append (line);
			sb.append_c ('\n');
		}
		append_textcode ("none", sb.str);
	}

	private void render_block_quote (TreeSitter.Node node, string src) throws Error {
		var bq = new BlockQuote () {
			margin_top = 6,
			margin_bottom = 6,
			hexpand = false,
			halign = Gtk.Align.START,
		};
		bq.set_size_request (500, -1);
		var old_box = box;
		box.append (bq);
		box = bq.content;
		try {
			uint32 n = TreeSitter.node_get_child_count (node);
			for (uint32 i = 0; i < n; i++) {
				var child = TreeSitter.node_get_child (node, i);
				unowned string? ct = TreeSitter.node_get_type (child);
				if (ct != "block_quote_marker" && ct != "block_continuation")
					walk_node (child, src);
			}
		} finally {
			box = old_box;
		}
	}

	private void render_list_item (TreeSitter.Node node, string src) throws Error {
		bool is_task = false;
		bool is_checked = false;
		string marker = "•";
		uint32 n = TreeSitter.node_get_child_count (node);

		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			unowned string? ct = TreeSitter.node_get_type (child);
			if (ct == null) continue;
			if (ct == "task_list_marker_checked") { is_task = true; is_checked = true; }
			else if (ct == "task_list_marker_unchecked") { is_task = true; }
			else if (ct.has_prefix ("list_marker")) {
				var m = node_text (child, src).strip ();
				if (m != "-" && m != "+" && m != "*")
					marker = m;
			}
		}

		if (is_task) {
			string para_text = "";
			for (uint32 i = 0; i < n; i++) {
				var child = TreeSitter.node_get_child (node, i);
				if (TreeSitter.node_get_type (child) == "paragraph")
					para_text = node_text (child, src)._strip ();
			}
			append_checkbox (is_checked ? 'x' : ' ', para_text);
			return;
		}

		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			unowned string? ct = TreeSitter.node_get_type (child);
			if (ct == null) continue;
			if (ct.has_prefix ("list_marker") || ct.has_prefix ("task_list_marker"))
				continue;
			if (ct == "paragraph") {
				bool rendered_image = false;
				uint32 pn = TreeSitter.node_get_child_count (child);
				for (uint32 pi = 0; pi < pn; pi++) {
					var pc = TreeSitter.node_get_child (child, pi);
					if (TreeSitter.node_get_type (pc) == "inline") {
						rendered_image = parse_image_from_text (node_text (pc, src));
						break;
					}
				}
				if (!rendered_image)
					append_list_item (marker, node_text (child, src)._strip ());
			} else {
				walk_node (child, src);
			}
		}
	}

	private void render_pipe_table (TreeSitter.Node node, string src) throws Error {
		append_table (node_text (node, src) + "\n");
	}

	// ── Widget factories ─────────────────────────────────────────────────────

	private void append_checkbox (char c, string text) {
		var row = new Gtk.Box (Orientation.HORIZONTAL, 8) {
			halign = Align.START,
			valign = Align.CENTER,
			hexpand = false,
			margin_top = 2,
		};
		var check = new Gtk.CheckButton () {
			halign = Align.START,
			valign = Align.CENTER,
			can_focus = false,
			active = (c == 'x' || c == 'X'),
		};
		var label = create_supra_label (text);
		row.append (check);
		row.append (label);
		box.append (row);
	}

	private void append_list_item (string marker, string text) {
		var row = new Gtk.Box (Orientation.HORIZONTAL, 6) {
			halign = Align.START,
			valign = Align.START,
			hexpand = true,
			margin_top = 1,
		};
		var bullet = new Gtk.Label (marker) {
			halign = Align.START,
			valign = Align.START,
			hexpand = false,
		};
		var label = create_supra_label (text);
		row.append (bullet);
		row.append (label);
		box.append (row);
	}

	private void append_separator () {
		var separator = new Gtk.Separator (Orientation.HORIZONTAL) {
			halign = Align.FILL,
			valign = Align.FILL,
			hexpand = true,
			vexpand = false,
			margin_top = 8,
			margin_bottom = 8,
		};
		box.append (separator);
	}

	private Gtk.Widget make_table_label (string text, bool is_table) throws Error {
		return create_supra_label (text);
	}

	private void append_table (string content) throws Error {
		var table = new Table.from_content (content, make_table_label) {
			halign = Align.START,
			valign = Align.FILL,
			hexpand = true,
			vexpand = true,
			margin_top = 4,
			margin_bottom = 4,
		};
		box.append (table);
	}

	private void append_img (string name, string url, string title, int req_width = -1, int req_height = -1) throws Error {
		string _url = GLib.Path.is_absolute (url) ? url : file_dir + "/" + url;
		try {
			if (_url.has_suffix (".gif") || _url.has_suffix (".webp")) {
				var img = new Gif (_url) {
					valign = Align.START,
					halign = Align.START,
					hexpand = false,
					vexpand = false,
					can_focus = false,
					focusable = false,
				};
				int w = req_width  > 0 ? req_width  : img.width;
				int h = req_height > 0 ? req_height : img.height;
				img.set_size_request (w, h);
				box.append (img);
			} else {
				var texture = Gdk.Texture.from_filename (_url);
				int w = req_width  > 0 ? req_width  : texture.get_width ();
				int h = req_height > 0 ? req_height : texture.get_height ();
				Picture img = new Gtk.Picture.for_paintable (texture) {
					valign = Align.START,
					halign = Align.START,
					hexpand = false,
					vexpand = false,
					can_focus = false,
					focusable = false,
					alternative_text = title,
					can_shrink = false,
				};
				img.set_size_request (w, h);
				box.append (img);
			}
		} catch (Error e) {
			printerr ("Error loading image: %s\n", e.message);
			var vbox = new Gtk.Box (Orientation.VERTICAL, 2);
			var icon = new Gtk.Image.from_icon_name ("image-missing-symbolic") {
				valign = Align.START,
				halign = Align.START,
			};
			string safe_url = url.validate () ? url : "(invalid path)";
			var err_label = new Gtk.Label ("Image not found: " + safe_url) {
				valign = Align.START,
				halign = Align.START,
				css_classes = { "markdown-image-error" },
			};
			vbox.append (icon);
			vbox.append (err_label);
			box.append (vbox);
		}
	}

	public signal bool activate_link (string uri);

	private void append_text (string text) throws Error {
		var label = create_supra_label (text);
		box.append (label);
	}

	private void append_textcode (string lang, string code) throws Error {
		box.append (new CodeBlock (lang, code));
	}

	// ── SupraLabel inline renderer ───────────────────────────────────────────

	private int get_inline_size_for_level (int level) {
		switch (level) {
		case 1: return 28;
		case 2: return 24;
		case 3: return 20;
		case 4: return 16;
		case 5: return 14;
		default: return 14;
		}
	}

	public SupraLabel create_label_markdown (string text, bool is_table) {
		return create_supra_label (text);
	}

	private SupraLabel create_supra_label (string text, int heading_level = 0) {
		string plain_text;
		List<MarkdownEmphasis> emph_list;
		inline_renderer.parse (text, out plain_text, out emph_list);

		var label = new SupraLabel (plain_text);

		if (heading_level > 0)
			LabelExt.set_size (label, 0, int.MAX, get_inline_size_for_level (heading_level));

		foreach (unowned var attr in emph_list) {
			switch (attr.type) {
			case MarkdownEmphasis.Type.BOLD:
				LabelExt.add_bold (label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.ITALIC:
				LabelExt.add_italic (label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.STRIKE:
				LabelExt.add_strike (label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.UNDERLINE:
				LabelExt.add_underline (label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.HIGHLIGHT:
				Gdk.RGBA hl_color = { 0.7f, 0.7f, 0.1f, 0.3f };
				LabelExt.add_highlight (label, attr.start_index, attr.end_index, hl_color);
				break;
			case MarkdownEmphasis.Type.SUPERSCRIPT:
				LabelExt.add_superscript (label, attr.start_index, attr.end_index);
				LabelExt.set_size (label, attr.start_index, attr.end_index, 7);
				break;
			case MarkdownEmphasis.Type.SUBSCRIPT:
				LabelExt.add_subscript (label, attr.start_index, attr.end_index);
				LabelExt.set_size (label, attr.start_index, attr.end_index, 7);
				break;
			case MarkdownEmphasis.Type.BLOCK_CODE:
				Gdk.RGBA code_bg;
				Gdk.RGBA code_fg;
				Gtk.StyleContext ctx = label.get_style_context ();
				if (!ctx.lookup_color ("theme_text_color", out code_fg))
					code_fg = Gdk.RGBA () { red = 0.9f, green = 0.9f, blue = 0.9f, alpha = 0.8f };
				if (!ctx.lookup_color ("theme_bg_color", out code_bg))
					code_bg = Gdk.RGBA () { red = 0.16f, green = 0.14f, blue = 0.26f, alpha = 0.9f };
				else {
					code_bg.red += 0.09f;
					code_bg.green += 0.09f;
					code_bg.blue += 0.09f;
					code_bg.alpha = 0.4f;
					code_fg.alpha = 0.9f;
				}
				LabelExt.apply_syntax_color (label, attr.start_index, attr.end_index, code_fg);
				LabelExt.add_highlight (label, attr.start_index, attr.end_index, code_bg);
				LabelExt.set_monospace (label, attr.start_index, attr.end_index);
				LabelExt.add_line_height (label, attr.start_index, attr.end_index, 1.1f);
				break;
			case MarkdownEmphasis.Type.LINK:
				var link_attr = (MarkdownEmphasisLink) attr;
				label.add_link (attr.start_index, attr.end_index, link_attr.url);
				break;
			default:
				break;
			}
		}

		label.link_clicked.connect ((url) => {
			if (this.activate_link (url) == false) {
				try {
					string md_path = url;
					string? tag = null;
					if (md_path.index_of_char ('#') != -1) {
						md_path = md_path[0:md_path.index_of_char ('#')];
						tag = url[url.index_of_char ('#') + 1:];
					}
					if (FileUtils.test (file_dir + "/" + md_path + ".md", FileTest.EXISTS)) {
						this.clear ();
						this.load_file (file_dir + "/" + md_path + ".md", tag);
					} else {
						Process.spawn_command_line_async ("xdg-open " + url);
					}
				} catch (Error e) {
					print ("Error: %s\n", e.message);
				}
			}
		});

		return label;
	}
}
