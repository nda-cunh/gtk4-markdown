public class Link {
	public Link (int x, int y, string url) {
		this.begin = x;
		this.end = y;
		this.url = url;
		this.is_hovered = false;
	}
	public bool is_hovered = false;
	public int begin;
	public int end;
	public string url;
}

public class SupraLabel : Gtk.Box {
	private List<Link> links;
	private Gtk.GestureClick gesture_click = new Gtk.GestureClick ();
	private Gtk.EventControllerMotion gesture_motion = new Gtk.EventControllerMotion ();
	private Gtk.Label? label {private set; get;}

	/* Constructor */
	public SupraLabel (string text) {
		links = new List<Link> ();
		label = new Gtk.Label (text) {
			halign = Gtk.Align.START,
			selectable = true,
		};

		gesture_click.pressed.connect(onClick);
		gesture_motion.motion.connect(onMotion);

		((Gtk.Widget)label).add_controller (gesture_click);
		((Gtk.Widget)label).add_controller (gesture_motion);
		append (label);
	}

	/* Methods */
	public Pango.AttrList get_attributes_list () {
		var attrs = label.get_attributes ();
		if (attrs == null)
			attrs = new Pango.AttrList ();
		label.set_attributes (attrs);
		return attrs;
	}

	public void add_link (int start_pos, int end_pos, string url) {
		add_color_link(start_pos, end_pos);
		links.append(new Link (start_pos, end_pos, url));
	}

	private void add_color_link (int start_pos, int end_pos) {
		Gdk.RGBA link_color;
		Gtk.StyleContext context = label.get_style_context();
		if (context.lookup_color("accent_color", out link_color) == false)
			link_color = Gdk.RGBA() { red = 0.0f, green = 0.0f, blue = 1.0f, alpha = 1.0f };
		LabelExt.apply_syntax_color(this, start_pos, end_pos, link_color);
		LabelExt.add_underline(this, start_pos, end_pos);
	}

	public void add_color_hover (int start_pos, int end_pos) {
		Gdk.RGBA hover_color;
		Gtk.StyleContext context = label.get_style_context();
		if (context.lookup_color("accent_color_hover", out hover_color) == false)
			hover_color = Gdk.RGBA() { red = 0.5f, green = 0.0f, blue = 0.5f, alpha = 1.0f };
		LabelExt.apply_syntax_color(this, start_pos, end_pos, hover_color);
	}

	/* Callbacks */
	private void onClick (int npress, double x, double y) {
		unowned Pango.Layout layout = label.get_layout ();
		int x_offset, y_offset;
		label.get_layout_offsets (out x_offset, out y_offset);
		int pango_x = (int)((x - x_offset) * Pango.SCALE);
		int pango_y = (int)((y - y_offset) * Pango.SCALE);
		int index, trailing;
		layout.xy_to_index (pango_x, pango_y, out index, out trailing);
		int cursor_pos = index + trailing;

		foreach (unowned var link in links) {
			if (cursor_pos >= link.begin && cursor_pos <= link.end) {
				link_clicked.emit (link.url);
				break;
			}
		}
	}

	private void onMotion(double x, double y) {
		unowned Pango.Layout layout = label.get_layout ();
		int x_offset, y_offset;
		label.get_layout_offsets (out x_offset, out y_offset);
		int pango_x = (int)((x - x_offset) * Pango.SCALE);
		int pango_y = (int)((y - y_offset) * Pango.SCALE);
		int index, trailing;
		layout.xy_to_index (pango_x, pango_y, out index, out trailing);
		int cursor_pos = index + trailing;

		foreach (unowned var link in links) {
			if (cursor_pos >= link.begin && cursor_pos <= link.end) {
				if (link.is_hovered)
					break; // already hovered
				add_color_hover(link.begin, link.end);
				link.is_hovered = true;
				label.queue_draw ();
				break;
			}
			else {
				if (!link.is_hovered)
					continue;
				var attrs = get_attributes_list();
				attrs.filter ((attr) => {
					if (attr.klass.type == Pango.AttrType.FOREGROUND &&
							attr.start_index == link.begin &&
						attr.end_index == link.end) {
						return true; 
					}
					return false;
				});
				add_color_link(link.begin, link.end);
				
				label.queue_draw ();
				link.is_hovered = false;
			}
		}
	}

	/* Signals */
	public signal void link_clicked (string url);
}
