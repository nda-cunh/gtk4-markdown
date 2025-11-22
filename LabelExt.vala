namespace LabelExt {

	internal Pango.AttrList get_attributes_list (Gtk.Label label) {
		var attrs = label.get_attributes ();
		if (attrs == null)
			attrs = new Pango.AttrList ();
		label.set_attributes (attrs);
		return attrs;
	}

	public void add_bold(Gtk.Label label, int start_index, int end_index) {
		var attrs = get_attributes_list (label);
		var attr = Pango.attr_weight_new(Pango.Weight.BOLD);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_italic(Gtk.Label label, int start_index, int end_index) {
		var attrs = get_attributes_list (label);
		var attr = Pango.attr_style_new(Pango.Style.ITALIC);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}
	
	public void add_line_height(Gtk.Label label, int start_index, int end_index, float scale) {
		var attrs = get_attributes_list (label);
		var attr = Pango.attr_line_height_new(scale);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_letter_spacing(Gtk.Label label, int start_index, int end_index, int spacing) {
		var attrs = get_attributes_list (label);
		var attr = Pango.attr_letter_spacing_new(spacing);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_underline(Gtk.Label label, int start_index, int end_index) {
		var attrs = get_attributes_list (label);
		var attr = Pango.attr_underline_new(Pango.Underline.SINGLE);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void add_strike(Gtk.Label label, int start_index, int end_index) {
		var attrs = get_attributes_list (label);
		var attr = Pango.attr_strikethrough_new(true);
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void apply_syntax_color(Gtk.Label label, int start, int end, Gdk.RGBA color) {
		var attrs = label.get_attributes();
		var attr = Pango.attr_foreground_new(
			(uint16)(color.red * 65535),
			(uint16)(color.green * 65535),
			(uint16)(color.blue * 65535)
		);
		attr.start_index = start;
		attr.end_index = end;
		
		// Assurez-vous d'utiliser set_attributes si vous modifiez la liste existante
		// ou si vous créez une nouvelle Pango.AttrList
		if (attrs == null) {
			attrs = new Pango.AttrList();
		}
		attrs.insert ((owned)attr);
		label.set_attributes(attrs);
	}

	public void add_highlight(Gtk.Label label, int start_index, int end_index, Gdk.RGBA color) {
		var attrs = get_attributes_list (label);
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
	public void set_monospace(Gtk.Label label, int start_index, int end_index) {
		var attrs = get_attributes_list (label);
		var font_desc = new Pango.FontDescription();
		font_desc.set_family("monospace");
		var attr = new Pango.AttrFontDesc(font_desc); 
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}

	public void set_size(Gtk.Label label, int start_index, int end_index, int size) {
		var attrs = get_attributes_list (label);
		var font_desc = new Pango.FontDescription();
		font_desc.set_size(size * Pango.SCALE);
		var attr = new Pango.AttrFontDesc(font_desc); 
		attr.start_index = start_index;
		attr.end_index = end_index;
		attrs.insert ((owned)attr);
	}
}
