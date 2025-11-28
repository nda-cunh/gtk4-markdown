public class MarkdownParser {

	Regex regex_url;
	Regex regex_link;
	public MarkdownParser() {
		try {
			regex_url = new Regex("""(?P<url>https?://[^\s<]+)""", RegexCompileFlags.OPTIMIZE);
			regex_link = new Regex("""\[(?P<name>[^\]]+)\]\s*\((?P<url>[^ ""\)]+)(?P<title>[^\)]+)?\)""", RegexCompileFlags.OPTIMIZE);
		}
		catch (Error e) {
			printerr ("Error compiling regex: %s\n", e.message);
		}
	}
	/**
	 * Parses the input markdown string and returns the root MDDocument node.
	 * @param input The markdown input string.
	 * @return The parsed MDDocument.
	 */
    public MDDocument parse (string input) {
        var doc = new MDDocument();

        int pos = 0;
        int len = input.length;

        while (pos < len) {
            int line_start = pos;
            int nl = input.index_of("\n", pos);
            bool has_newline = (nl != -1);
            if (!has_newline)
                nl = len;

            string line = input.substring(line_start, nl - line_start);
            pos = has_newline ? (nl + 1) : len;

            int h = count_header_prefix(line);
            if (h > 0) {
                string content = extract_header_text(line, h);
                var node = new MDHeader(h);
                parse_inline(content, node);
                doc.children.append(node);
                continue;
            }

            var p = new MDParagraph();
			// if it's the last paragrap set it to p.is_end = true
			if (pos >= len)
				p.is_end = true;
            parse_inline(line, p);
            doc.children.append(p);
        }

        return doc;
    }

	/**
	 * Counts the number of '#' characters at the start of the line to determine header level.
	 * Returns 0 if the line is not a valid header.
	 * @param line The line to check.
	 * @return The header level (1-6) or 0 if not a header.
	 */
    private int count_header_prefix (string line) {
        int i = 0;
        int count = 0;
        while (i < line.length && line.get_char(i) == '#') {
            count++;
            i++;
            if (count >= 6) break;
        }
        if (count == 0) return 0;
        if (i < line.length && line.get_char(i).isspace())
            return count;
        return 0;
    }

	/**
	 * Extracts the header text from the line after the '#' characters and any following whitespace.
	 * @param line The line containing the header.
	 * @param h The number of '#' characters at the start of the line.
	 * @return The extracted header text.
	 */
    private string extract_header_text (string line, int h) {
        int i = h;
        while (i < line.length && line.get_char(i).isspace()) i++;
        return line.substring(i, line.length - i);
    }

	private bool process_inline_token (string type, string line, MDNode parent, ref int i) {
		if (starts_with(line, i, type)) {
			var len_type = type.length;
			int close = find_closing(line, i + len_type, type);
			if (close >= 0) {
				string inside = line.substring(i + len_type, close - (i + len_type));
				var node = MDNode.new_from_type(type);
				parse_inline((owned)inside, node);
				parent.children.append(node);
				i = close + len_type;
			}
			else {
				// Pas de fermeture trouvée : on traite les '**' comme du texte
				parent.children.append(new MDText(type));
				i += len_type; 
			}
			return true;
		}
		return false;
	}


	/**
	 * Processes HTML-like inline tags such as <i>, <b>, <u>, <s>, <strong>, <em>, <h1>-<h6>.
	 * @param line The line to parse.
	 * @param parent The parent MDNode to append parsed elements to.
	 * @param tag The HTML-like tag to process (e.g., "i", "b", "u", etc.).
	 * @param i The current index in the line (passed by reference).
	 * @return True if the tag was processed, false otherwise.
	 */
	private bool process_html_inline_tag (string line, MDNode parent, string tag, ref int i) {
		string open_tag = "<" + tag + ">";
		string close_tag = "</" + tag + ">";
		if (starts_with(line, i, open_tag)) {
			int close = find_closing(line, i + open_tag.length, close_tag);
			if (close >= 0) {
				string inside = line.substring(i + open_tag.length, close - (i + open_tag.length));
				var node = MDNode.new_from_type(tag);
				parse_inline((owned)inside, node);
				parent.children.append(node);
				i = close + close_tag.length;
			}
			else {
				parent.children.append(new MDText(open_tag));
				i += open_tag.length; 
			}
			return true;
		}
		return false;
	}

	/**
	 * Parses inline markdown elements in the given line and appends them to the parent node.
	 * Supports **bold**, *italic*, ~~strikethrough~~, and `inline code`.
	 * @param line The line to parse.
	 * @param parent The parent MDNode to append parsed elements to.
	 */
    private void parse_inline (string line, MDNode parent) {
        int i = 0;
        int len = line.length;

        while (i < len) {
			// add line break support
			if (starts_with(line, i, "<br>")) {
				parent.children.append(new MDLineBreak());
				i += 4;
				continue;
			}

			if (line[i] == '\\' && i + 1 < len) {
				const char []lst_allowed = {'\\', '`', '*', '_', '{', '}', '[', ']', '<', '>', '#', '+', '-', '.', '!', '|', 'h'};
				if (line[i + 1] in lst_allowed) {
					parent.children.append(new MDText(line[i + 1].to_string()));
					i += 2;
					continue;
				}
			}

			if (starts_with(line, i, "`")) {
				int find_close = find_closing(line, i + 1, "`");
				if (find_close >= 0) {
					string code_text = line.offset(i)[1 : find_close - (i)];
					var code_node = new MDInlineCode ();
					code_node.children.append(new MDText(code_text));
					parent.children.append(code_node);
					i = find_close + 1;
					continue;
				} else {
					// No closing backtick found, treat as text
					parent.children.append(new MDText("`"));
					i += 1;
					continue;
				}		
			}

			// NOTE urls
			if (starts_with (line, i, "http://") || starts_with (line, i, "https://")) {
				MatchInfo info;
				if (regex_url.match(line.offset(i), RegexMatchFlags.ANCHORED, out info)) {
					string link_url = info.fetch_named("url");
					int start_pos, end_pos;
					info.fetch_pos (0, out start_pos, out end_pos);
					var link_node = new MDLink(link_url, link_url, "");
					link_node.children.append(new MDText(link_url));
					parent.children.append(link_node);
					i += end_pos;
					continue;
				}
				else {
					// No valid URL found, treat as text
					parent.children.append(new MDText(line[i].to_string()));
					i += 1;
					continue;
				}
			}
			if (starts_with(line, i, "[")) {
				MatchInfo info;
				if (regex_link.match(line.offset(i), RegexMatchFlags.ANCHORED, out info)) {
					string link_name = info.fetch_named ("name");
					string link_url = info.fetch_named("url");
					string link_title = info.fetch_named("title");
					int start_pos, end_pos;
					info.fetch_pos (0, out start_pos, out end_pos);
					var link_node = new MDLink(link_name, link_url, link_title);
					parse_inline(link_name, link_node);
					parent.children.append(link_node);
					i += end_pos;
					continue;
				} else {
					// No valid link found, treat as text
					parent.children.append(new MDText("["));
					i += 1;
					continue;
				}

			}

			// HTML-like inline tags
			if (line[i] == '<') {
				if (process_html_inline_tag(line, parent, "i", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "b", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "u", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "s", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "strong", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "em", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "h1", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "h2", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "h3", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "h4", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "h5", ref i))
					continue;
				if (process_html_inline_tag(line, parent, "h6", ref i))
					continue;
			}


			if (process_inline_token("==", line, parent, ref i))
				continue;
			if (process_inline_token("___", line, parent, ref i))
				continue;
			if (process_inline_token("***", line, parent, ref i))
				continue;
			if (process_inline_token("**", line, parent, ref i))
				continue;
			if (process_inline_token("~~", line, parent, ref i))
				continue;
			if (process_inline_token("*", line, parent, ref i))
				continue;
			if (process_inline_token("_", line, parent, ref i))
				continue;
			if (process_inline_token("~", line, parent, ref i))
				continue;
			if (process_inline_token("^", line, parent, ref i))
				continue;


			// List unonordered
			if ( i == 0
					&& starts_with(line, i, "- ")
					|| starts_with(line, i, "* ")
					|| starts_with(line, i, "+ "))
				{
				i += 2; // Skip "- "
				var list_node = new MDListNode(MDListNode.ListType.UNORDERED);
				int next = next_markup_pos(line, i);
				if (next == -1) {
					string t = line.substring(i, len - i);
					list_node.children.append(new MDText(t));
					parent.children.append(list_node);
					break;
				} else {
					if (next > i) {
						string t = line.substring(i, next - i);
						list_node.children.append(new MDText(t));
					}
					parent.children.append(list_node);
					i = next;
					continue;
				}
			}

			// No markup found, treat as text
            int next = next_markup_pos(line, i);
            if (next == -1) {
                string t = line.substring(i, len - i);
                parent.children.append(new MDText(t));
                break;
            } else {
                if (next > i) {
                    string t = line.substring(i, next - i);
                    parent.children.append(new MDText(t));
                }
                i = next;
                continue;
            }
        }
    }

	/**
	 * Returns the position of the next markup token in the line starting from 'start'.
	 * If none found, returns -1.
	 * @param line The line to search.
	 * @param start The starting index for the search.
	 * @return The index of the next markup token, or -1 if none found.
	 */
    private int next_markup_pos (string line, int start) {
        int best = -1;
        const string[] tokens = {"**", "~~", "*", "`", "_", "___", "***", "==", "~", "^", "<br>", "\\", "<i>", "</i>", "<b>", "</b>", "<u>", "</u>", "<s>", "</s>", "<strong>", "</strong>", "<em>", "</em>", "<h1>", "</h1>", "<h2>", "</h2>", "<h3>", "</h3>", "<h4>", "</h4>", "<h5>", "</h5>", "<h6>", "</h6>", "[", "http://", "https://"};
		// print ("Searching for next markup in line: '%s' starting at %d\n", line, start);
        foreach (unowned var tok in tokens) {
            int p = line.index_of(tok, start);
            if (p == -1) continue;
            if (best == -1 || p < best) best = p;
        }
        return best;
    }

	/**
	 * Checks if the line starts with the given token at position i.
	 * @param line The line to check.
	 * @param i The position to check from.
	 * @param token The token to check for.
	 * @return True if the line starts with the token at position i, false otherwise.
	 */
    private bool starts_with (string line, int i, string token) {
        int toklen = token.length;
        if (i + toklen > line.length) return false;
        int p = line.index_of(token, i);
        return (p == i);
    }

	/**
	 * Finds the closing token in the line starting from 'start'.
	 * Returns the index of the closing token, or -1 if not found.
	 * @param line The line to search.
	 * @param start The starting index for the search.
	 * @param token The closing token to find.
	 * @return The index of the closing token, or -1 if not found.
	 */
	private int find_closing (string line, int start, string token) {
        return line.index_of(token, start);
    }
}
