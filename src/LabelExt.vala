namespace LabelExt {

	public void add_bold(SupraLabel label, int start_index, int end_index) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_weight_new(Pango.Weight.BOLD);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_italic(SupraLabel label, int start_index, int end_index) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_style_new(Pango.Style.ITALIC);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}
	
	public void add_line_height(SupraLabel label, int start_index, int end_index, float scale) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_line_height_new(scale);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_letter_spacing(SupraLabel label, int start_index, int end_index, int spacing) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_letter_spacing_new(spacing);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_underline(SupraLabel label, int start_index, int end_index) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_underline_new(Pango.Underline.SINGLE);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_strike(SupraLabel label, int start_index, int end_index) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_strikethrough_new(true);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void apply_syntax_color(SupraLabel label, int start, int end, Gdk.RGBA color) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_foreground_new(
			(uint16)(color.red * 65535),
			(uint16)(color.green * 65535),
			(uint16)(color.blue * 65535)
		);
		attr.start_index = start;
		attr.end_index = end;
		attrs.insert ((owned)attr);
	}

	public void add_highlight(SupraLabel label, int start_index, int end_index, Gdk.RGBA color) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_background_new(
			(uint16)(color.red * 65535),
			(uint16)(color.green * 65535),
			(uint16)(color.blue * 65535)
		);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	// set monospace
	public void set_monospace(SupraLabel label, int start_index, int end_index) {
		var attrs = label.get_attributes_list();
		var font_desc = new Pango.FontDescription();
		font_desc.set_family("monospace");
		var attr = new Pango.AttrFontDesc(font_desc); 
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_superscript(SupraLabel label, int start_index, int end_index) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_baseline_shift_new( Pango.BaselineShift.SUPERSCRIPT);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_subscript(SupraLabel label, int start_index, int end_index) {
		var attrs = label.get_attributes_list();
		var attr = Pango.attr_baseline_shift_new( Pango.BaselineShift.SUBSCRIPT);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void set_size(SupraLabel label, int start_index, int end_index, int size) {
		var attrs = label.get_attributes_list();
		var font_desc = new Pango.FontDescription();
		font_desc.set_size(size * Pango.SCALE);
		var attr = new Pango.AttrFontDesc(font_desc); 
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}
}
