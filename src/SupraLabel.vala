public class Link {
	public Link (int x, int y, string url) {
		this.begin = x;
		this.end = y;
		this.url = url;
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
	private Gtk.Label? label { private set; get; }
	private Pango.AttrList? base_attrs = null;

	public SupraLabel (string text) {
		links = new List<Link> ();
		hexpand = true;
		label = new Gtk.Label (text) {
			halign = Gtk.Align.START,
			selectable = true,
			wrap = true,
			hexpand = true,
		};

		gesture_click.pressed.connect (on_click);
		gesture_motion.motion.connect (on_motion);
		gesture_motion.leave.connect (on_leave);

		((Gtk.Widget) label).add_controller (gesture_click);
		((Gtk.Widget) label).add_controller (gesture_motion);
		append (label);
	}

	public Pango.AttrList get_attributes_list () {
		var attrs = label.get_attributes ();
		if (attrs == null)
			attrs = new Pango.AttrList ();
		label.set_attributes (attrs);
		return attrs;
	}

	public void add_link (int start_pos, int end_pos, string url) {
		apply_link_color (start_pos, end_pos);
		links.append (new Link (start_pos, end_pos, url));
	}

	private void apply_link_color (int start_pos, int end_pos) {
		Gdk.RGBA color;
		if (!label.get_style_context ().lookup_color ("accent_color", out color))
			color = Gdk.RGBA () { red = 0.2f, green = 0.5f, blue = 1.0f, alpha = 1.0f };
		LabelExt.apply_syntax_color (this, start_pos, end_pos, color);
	}

	private void ensure_base_attrs () {
		if (base_attrs != null) return;
		var cur = label.get_attributes ();
		base_attrs = cur != null ? cur.copy () : new Pango.AttrList ();
	}

	private void apply_hover_state () {
		ensure_base_attrs ();
		var attrs = base_attrs.copy ();

		bool any_hovered = false;
		foreach (unowned var link in links) {
			if (!link.is_hovered) continue;
			any_hovered = true;

			var c = Gdk.RGBA () { red = 0.18f, green = 0.36f, blue = 0.92f, alpha = 1.0f };
			var attr = Pango.attr_foreground_new (
				(uint16) (c.red   * 65535),
				(uint16) (c.green * 65535),
				(uint16) (c.blue  * 65535));
			attr.start_index = (uint) link.begin;
			attr.end_index   = (uint) link.end;
			attrs.change ((owned) attr);
		}

		label.set_attributes (attrs);
		label.set_cursor (any_hovered ? new Gdk.Cursor.from_name ("pointer", null) : null);
		label.queue_draw ();
	}

	private int xy_to_index (double x, double y) {
		unowned Pango.Layout layout = label.get_layout ();
		int x_off, y_off;
		label.get_layout_offsets (out x_off, out y_off);
		int pango_x = (int) ((x - x_off) * Pango.SCALE);
		int pango_y = (int) ((y - y_off) * Pango.SCALE);
		int index, trailing;
		layout.xy_to_index (pango_x, pango_y, out index, out trailing);
		return index + trailing;
	}

	private void on_click (int npress, double x, double y) {
		int pos = xy_to_index (x, y);
		foreach (unowned var link in links) {
			if (pos >= link.begin && pos <= link.end) {
				link_clicked.emit (link.url);
				break;
			}
		}
	}

	private void on_motion (double x, double y) {
		int pos = xy_to_index (x, y);
		bool changed = false;
		foreach (unowned var link in links) {
			bool over = pos >= link.begin && pos <= link.end;
			if (over != link.is_hovered) {
				link.is_hovered = over;
				changed = true;
			}
		}
		if (changed)
			apply_hover_state ();
	}

	private void on_leave () {
		bool changed = false;
		foreach (unowned var link in links) {
			if (link.is_hovered) { link.is_hovered = false; changed = true; }
		}
		if (changed)
			apply_hover_state ();
	}

	public signal void link_clicked (string url);
}
