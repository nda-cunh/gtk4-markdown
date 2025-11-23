public Gtk.Label parse_text (uint8[] str) {
	return parse(str);
}
/**
	* Returns the font size for a given header level.
	* @param level The header level (1-6).
	* @return The corresponding font size.
	*/
private int get_size_for_level(int level) {
	switch(level) {
		case 1: return 28;
		case 2: return 24;
		case 3: return 20;
		case 4: return 16;
		case 5: return 14;
		default: return 14;
	}
}


private void segment(StringBuilder sb, ref List<MarkdownEmphasis> list, MDNode node, out int begin, out int end) {
	begin = (int)sb.len;
	foreach (unowned var child in node.children)
		my_render_node(child, sb, ref list);
	end	= (int)sb.len;
}

/**
  * Transform the AST to a string and collect emphasis info.
  * @param node The current MDNode.
  * @param sb The StringBuilder to append text to.
  * @param list The list to collect emphasis information.
  */
private void my_render_node(MDNode node, StringBuilder sb, ref List<MarkdownEmphasis> list) {
	int begin;
	int end;

	if (node is MDText) {
		sb.append(node.text);
	}
	else if (node is MDParagraph) {
		// draw a new line after a paragraph but not if it's the end of paragraph
		foreach (unowned var child in node.children)
			my_render_node(child, sb, ref list);
		if (((MDParagraph)node).is_end == false)
			sb.append("\n");
	}
	else if (node is MDBold) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.BOLD, begin, (end - begin)) );
	}
	else if (node is MDItalic) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.ITALIC, begin, (end - begin)) );
	}
	else if (node is MDStrike) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.STRIKE, begin, (end - begin)) );
	}
	else if (node is MDInlineCode) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.BLOCK_CODE, begin, (end - begin)) );
	}
	else if (node is MDSuperscript) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.SUPERSCRIPT, begin, (end - begin)) );
	}
	else if (node is MDSubscript) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.SUBSCRIPT, begin, (end - begin)) );
	}
	else if (node is MDItalicBold) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.BOLD, begin, (end - begin)) );
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.ITALIC, begin, (end - begin)) );
	}
	else if (node is MDHeader) {
		sb.append("\n");
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasisHeader (begin, (end - begin), node.level));
		sb.append("\n");
	}
	else if (node is MDLineBreak) {
		sb.append("\n");
	}
	else if (node is MDhighlight) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.HIGHLIGHT, begin, (end - begin)) );
	}
	else if (node is MDListNode) {
		unowned MDListNode list_node = node as MDListNode;
		if (list_node.list_type == MDListNode.ListType.ORDERED)
			sb.append("1. ");
		else
			sb.append("• ");
		foreach (unowned var child in node.children)
			my_render_node(child, sb, ref list);
	}
    else if (node is MDDocument) {
        foreach (unowned var child in node.children)
            my_render_node(child, sb, ref list);
    }
}


private Gtk.Label parse (uint8[] str) {
	// Convert input bytes to UTF-8 string

	var parser = new MarkdownParser();
	MDDocument doc = parser.parse((string)str);
	doc.print();

    var list = new List<MarkdownEmphasis>();
	var mysb = new StringBuilder ();
	my_render_node(doc, mysb, ref list);


	var label = new Gtk.Label(mysb.str) {
		halign = Gtk.Align.START,
		selectable = true,
	};
	// Apply header styling from the collected list
    foreach (unowned var attr in list) {
        switch (attr.type) {
            case MarkdownEmphasis.Type.HEADER:
                var header_attr = (MarkdownEmphasisHeader) attr;
                int end_index = header_attr.start_index + header_attr.size;
                LabelExt.set_size (label, header_attr.start_index, end_index, get_size_for_level (header_attr.header_level));
                break;
			case MarkdownEmphasis.Type.BOLD:
				print ("Applying bold from %d to %d\n", attr.start_index, attr.size);
				LabelExt.add_bold(label, attr.start_index, attr.start_index + attr.size);
				break;
			case MarkdownEmphasis.Type.ITALIC:
				LabelExt.add_italic(label, attr.start_index, attr.start_index + attr.size);
				break;
			case MarkdownEmphasis.Type.STRIKE:
				LabelExt.add_strike(label, attr.start_index, attr.start_index + attr.size);
				break;
			case MarkdownEmphasis.Type.HIGHLIGHT:
				Gdk.RGBA color = { 0.7f, 0.7f, 0.1f, 0.3f }; // semi-transparent yellow
				LabelExt.add_highlight(label, attr.start_index, attr.start_index + attr.size, color);
				break;
			case MarkdownEmphasis.Type.SUPERSCRIPT:
				LabelExt.add_superscript(label, attr.start_index, attr.start_index + attr.size);
				LabelExt.set_size(label, attr.start_index, attr.start_index + attr.size, 7);
				break;
			case MarkdownEmphasis.Type.SUBSCRIPT:
				LabelExt.add_subscript(label, attr.start_index, attr.start_index + attr.size);
				LabelExt.set_size(label, attr.start_index, attr.start_index + attr.size, 7);
				break;
			case MarkdownEmphasis.Type.BLOCK_CODE:
				Gdk.RGBA colorbg = { 0.95f, 0.95f, 0.95f, 1.0f };
				Gdk.RGBA colorfg = { 0.2f, 0.2f, 0.2f, 1.0f };
				// TODO for light and dark themes
				// Gtk.StyleContext context = label.get_style_context();
				// context.lookup_color("theme_text_color", out colorfg);
				// context.lookup_color("theme_bg_color", out colorbg);
				var begin = attr.start_index;
				var end = begin + attr.size;

				LabelExt.apply_syntax_color(label, begin, end, colorfg);
				LabelExt.add_highlight(label, begin, end, colorbg);
				LabelExt.add_bold(label, begin, end);
				LabelExt.add_line_height(label, begin, end, 1.1f);
				LabelExt.set_monospace(label, begin, end);

				// LabelExt.add_letter_spacing(label, begin, begin, 81103);
				// LabelExt.add_letter_spacing(label, end - 1, end, 81103);
				break;
            default:
                break;
        }
    }


	return label;
}
