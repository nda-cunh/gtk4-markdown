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
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.BOLD, begin, end) );
	}
	else if (node is MDItalic) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.ITALIC, begin, end) );
	}
	else if (node is MDStrike) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.STRIKE, begin, end) );
	}
	else if (node is MDInlineCode) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.BLOCK_CODE, begin, end) );
	}
	else if (node is MDSuperscript) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.SUPERSCRIPT, begin, end) );
	}
	else if (node is MDSubscript) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.SUBSCRIPT, begin, end) );
	}
	else if (node is MDItalicBold) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.BOLD, begin, end) );
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.ITALIC, begin, end) );
	}
	else if (node is MDLink) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasisLink (begin, end, ((MDLink)node).url) );
	}
	else if (node is MDHeader) {
		sb.append("\n");
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasisHeader (begin, end, node.level));
		sb.append("\n");
	}
	else if (node is MDLineBreak) {
		sb.append("\n");
	}
	else if (node is MDhighlight) {
		segment(sb, ref list, node, out begin, out end);
		list.append( new MarkdownEmphasis (MarkdownEmphasis.Type.HIGHLIGHT, begin, end) );
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

private SupraLabel parse_text (uint8[] str) {
	// Convert input bytes to UTF-8 string

	var parser = new MarkdownParser();
	MDDocument doc = parser.parse((string)str);
	// doc.print();

    var list = new List<MarkdownEmphasis>();
	var mysb = new StringBuilder ();
	my_render_node(doc, mysb, ref list);


	var label = new SupraLabel(mysb.str);
	// var label = new Gtk.Label(mysb.str) {
		// halign = Gtk.Align.START,
		// selectable = true,
	// };
	// remove focus
	// label.set_can_focus (true);
	// Apply header styling from the collected list
    foreach (unowned var attr in list) {
        switch (attr.type) {
            case MarkdownEmphasis.Type.HEADER:
                var header = (MarkdownEmphasisHeader) attr;
                LabelExt.set_size (label, attr.start_index, attr.end_index, get_size_for_level (header.header_level));
                break;
			case MarkdownEmphasis.Type.BOLD:
				LabelExt.add_bold(label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.ITALIC:
				LabelExt.add_italic(label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.STRIKE:
				LabelExt.add_strike(label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.HIGHLIGHT:
				Gdk.RGBA color = { 0.7f, 0.7f, 0.1f, 0.3f }; // semi-transparent yellow
				LabelExt.add_highlight(label, attr.start_index, attr.end_index, color);
				break;
			case MarkdownEmphasis.Type.UNDERLINE:
				LabelExt.add_underline(label, attr.start_index, attr.end_index);
				break;
			case MarkdownEmphasis.Type.SUPERSCRIPT:
				LabelExt.add_superscript(label, attr.start_index, attr.end_index);
				LabelExt.set_size(label, attr.start_index, attr.end_index, 7);
				break;
			case MarkdownEmphasis.Type.LINK:
				var link_attr = (MarkdownEmphasisLink) attr;
				label.add_link(attr.start_index, attr.end_index, link_attr.url);
				break;
			case MarkdownEmphasis.Type.SUBSCRIPT:
				LabelExt.add_subscript(label, attr.start_index, attr.end_index);
				LabelExt.set_size(label, attr.start_index, attr.end_index, 7);
				break;
			case MarkdownEmphasis.Type.BLOCK_CODE:
				Gdk.RGBA colorbg;
				Gdk.RGBA colorfg;
				Gtk.StyleContext context = label.get_style_context();
				context.lookup_color("theme_text_color", out colorfg);
				context.lookup_color("theme_bg_color", out colorbg);
				colorbg.red += 0.09f;
				colorbg.green += 0.09f;
				colorbg.blue += 0.09f;
				colorbg.alpha = 0.3f;
				colorfg.alpha = 0.7f;

				var begin = attr.start_index;
				var end = attr.end_index;

				LabelExt.apply_syntax_color(label, begin, end, colorfg);
				LabelExt.add_highlight(label, begin, end, colorbg);
				LabelExt.add_bold(label, begin, end);
				LabelExt.add_line_height(label, begin, end, 1.1f);
				LabelExt.set_monospace(label, begin, end);
				break;
            default:
                break;
        }
    }


	return label;
}
