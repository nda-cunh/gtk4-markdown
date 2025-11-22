public class MarkdownParser {

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
	 * Parses inline markdown elements in the given line and appends them to the parent node.
	 * Supports **bold**, *italic*, ~~strikethrough~~, and `inline code`.
	 * @param line The line to parse.
	 * @param parent The parent MDNode to append parsed elements to.
	 */
    private void parse_inline (string line, MDNode parent) {
        int i = 0;
        int len = line.length;

        while (i < len) {
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
			if (process_inline_token("`", line, parent, ref i))
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
        const string[] tokens = {"**", "~~", "*", "`", "_", "___", "***", "=="};
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
