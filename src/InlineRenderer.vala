[CCode (cname = "tree_sitter_markdown_inline")]
extern TreeSitter.Language ts_md_inline_lang ();

public class InlineRenderer {
	private TreeSitter.Parser parser;

	public InlineRenderer () {
		parser = new TreeSitter.Parser ();
		parser.set_language (ts_md_inline_lang ());
	}

	private string node_text (TreeSitter.Node node, string src) {
		uint32 len = node.end_byte - node.start_byte;
		uint8[] buf = new uint8[len + 1];
		Memory.copy (buf, ((uint8*) src) + node.start_byte, (size_t) len);
		return ((string) buf).dup ();
	}

	private void append_bytes (string src, uint32 start, uint32 end_pos, StringBuilder sb) {
		if (end_pos <= start) return;
		uint32 len = end_pos - start;
		uint8[] buf = new uint8[len + 1];
		Memory.copy (buf, ((uint8*) src) + start, (size_t) len);
		sb.append (((string) buf).dup ());
	}

	public void parse (string text, out string plain_text, out List<MarkdownEmphasis> emphases) {
		var sb = new StringBuilder ();
		emphases = new List<MarkdownEmphasis> ();
		var tree = parser.parse_string (null, text, (uint32) text.length);
		if (tree != null)
			walk_node (tree.get_root_node (), text, sb, ref emphases);
		plain_text = sb.str;
	}

	private void walk_node (TreeSitter.Node node, string src, StringBuilder sb, ref List<MarkdownEmphasis> emphases) {
		unowned string? type = TreeSitter.node_get_type (node);
		if (type == null) return;

		switch (type) {
		case "markdown_inline":
		case "inline":
			// Plain text lives in byte gaps between children — must fill them.
			walk_gap (node, node.start_byte, node.end_byte, src, sb, ref emphases);
			break;
		case "strong_emphasis":
			wrap_delimited (node, src, sb, ref emphases, MarkdownEmphasis.Type.BOLD, "emphasis_delimiter");
			break;
		case "emphasis":
			wrap_delimited (node, src, sb, ref emphases, MarkdownEmphasis.Type.ITALIC, "emphasis_delimiter");
			break;
		case "strikethrough":
			// ~~ markers are hidden nodes — strip 2 bytes on each side.
			{
				int begin = (int) sb.len;
				walk_gap (node, node.start_byte + 2, node.end_byte - 2, src, sb, ref emphases);
				int end = (int) sb.len;
				if (end > begin)
					emphases.append (new MarkdownEmphasis (MarkdownEmphasis.Type.STRIKE, begin, end));
			}
			break;
		case "code_span":
			render_code_span (node, src, sb, ref emphases);
			break;
		case "link":
		case "inline_link":
		case "shortcut_link":
		case "full_reference_link":
		case "collapsed_reference_link":
			render_link (node, src, sb, ref emphases);
			break;
		case "image":
			// Block-level image handling covers standalone images; skip inline.
			break;
		case "uri_autolink":
		case "email_autolink":
			render_autolink (node, src, sb, ref emphases);
			break;
		case "hard_line_break":
			sb.append_c ('\n');
			break;
		case "backslash_escape":
			// child 0 = '\', child 1 = escaped char
			{
				uint32 nc = TreeSitter.node_get_child_count (node);
				if (nc > 1)
					sb.append (node_text (TreeSitter.node_get_child (node, 1), src));
				else if (node.end_byte > node.start_byte + 1)
					append_bytes (src, node.start_byte + 1, node.end_byte, sb);
			}
			break;
		case "entity_reference":
		case "numeric_character_reference":
		case "html_tag":
			sb.append (node_text (node, src));
			break;
		default:
			{
				uint32 n = TreeSitter.node_get_child_count (node);
				if (n > 0)
					walk_gap (node, node.start_byte, node.end_byte, src, sb, ref emphases);
				else
					sb.append (node_text (node, src));
			}
			break;
		}
	}

	// Walk children while filling the byte gaps between them with raw text.
	// Tree-sitter-markdown-inline does NOT expose plain text as named children —
	// it lives in the intervals between child nodes.
	private void walk_gap (TreeSitter.Node parent, uint32 range_start, uint32 range_end,
	                        string src, StringBuilder sb, ref List<MarkdownEmphasis> emphases) {
		uint32 n = TreeSitter.node_get_child_count (parent);
		uint32 pos = range_start;

		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (parent, i);
			if (child.end_byte <= range_start) continue;
			if (child.start_byte >= range_end) break;

			// Gap before this child is plain text.
			if (child.start_byte > pos)
				append_bytes (src, pos, child.start_byte, sb);

			walk_node (child, src, sb, ref emphases);
			pos = child.end_byte;
		}

		// Trailing gap after the last child.
		if (pos < range_end)
			append_bytes (src, pos, range_end, sb);
	}

	// Wrap content between named delimiter nodes (e.g. emphasis_delimiter).
	private void wrap_delimited (TreeSitter.Node node, string src, StringBuilder sb,
	                              ref List<MarkdownEmphasis> emphases, MarkdownEmphasis.Type type,
	                              string delimiter_type) {
		uint32 n = TreeSitter.node_get_child_count (node);
		uint32 content_start = node.start_byte;
		uint32 content_end = node.end_byte;

		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			if (TreeSitter.node_get_type (child) == delimiter_type) {
				if (child.start_byte <= content_start) content_start = child.end_byte;
				else if (child.end_byte >= content_end)  content_end = child.start_byte;
			}
		}

		int begin = (int) sb.len;
		walk_gap (node, content_start, content_end, src, sb, ref emphases);
		int end = (int) sb.len;
		if (end > begin)
			emphases.append (new MarkdownEmphasis (type, begin, end));
	}

	private void render_code_span (TreeSitter.Node node, string src, StringBuilder sb, ref List<MarkdownEmphasis> emphases) {
		uint32 n = TreeSitter.node_get_child_count (node);
		uint32 content_start = node.start_byte;
		uint32 content_end = node.end_byte;

		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			if (TreeSitter.node_get_type (child) == "code_span_delimiter") {
				if (child.start_byte <= content_start) content_start = child.end_byte;
				else if (child.end_byte >= content_end)  content_end = child.start_byte;
			}
		}

		int begin = (int) sb.len;
		append_bytes (src, content_start, content_end, sb);
		int end = (int) sb.len;
		if (end > begin)
			emphases.append (new MarkdownEmphasis (MarkdownEmphasis.Type.BLOCK_CODE, begin, end));
	}

	private void render_link (TreeSitter.Node node, string src, StringBuilder sb, ref List<MarkdownEmphasis> emphases) {
		string url = "";
		int begin = (int) sb.len;
		uint32 n = TreeSitter.node_get_child_count (node);
		for (uint32 i = 0; i < n; i++) {
			var child = TreeSitter.node_get_child (node, i);
			unowned string? ct = TreeSitter.node_get_type (child);
			if (ct == "link_text" || ct == "link_label" || ct == "image_description")
				walk_gap (child, child.start_byte, child.end_byte, src, sb, ref emphases);
			else if (ct == "link_destination")
				url = node_text (child, src).strip ();
		}
		int end = (int) sb.len;
		if (end > begin)
			emphases.append (new MarkdownEmphasisLink (begin, end, url));
	}

	private void render_autolink (TreeSitter.Node node, string src, StringBuilder sb, ref List<MarkdownEmphasis> emphases) {
		string url = node_text (node, src);
		if (url.has_prefix ("<") && url.has_suffix (">"))
			url = url[1:url.length - 1];
		int begin = (int) sb.len;
		sb.append (url);
		int end = (int) sb.len;
		emphases.append (new MarkdownEmphasisLink (begin, end, url));
	}
}
