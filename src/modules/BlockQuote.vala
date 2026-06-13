using Gtk;

// Blockquote rendered as a horizontal box:
//   [4 px accent bar] [background area > content box with margins]
//
// Separating the bar and background into two widgets avoids the GTK4 CSS-padding
// measurement issue: wrapped Gtk.Labels measure their height against the
// un-styled content box, so they get the right width before wrapping.
public class BlockQuote : Gtk.Box {
	private Gtk.Box _content;

	construct {
		orientation = Gtk.Orientation.HORIZONTAL;
		halign = Gtk.Align.FILL;
		hexpand = true;
		vexpand = false;
		spacing = 0;

		var bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			css_classes = { "markdown-blockquote-bar" },
			hexpand = false,
			vexpand = true,
		};

		var bg = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			css_classes = { "markdown-blockquote-bg" },
			hexpand = true,
			vexpand = false,
		};

		_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
			halign = Gtk.Align.FILL,
			hexpand = true,
			vexpand = false,
			margin_top = 10,
			margin_bottom = 10,
			margin_start = 14,
			margin_end = 12,
		};

		bg.append (_content);
		((Gtk.Box) this).append (bar);
		((Gtk.Box) this).append (bg);
	}

	public BlockQuote () { }

	public unowned Gtk.Box content { get { return _content; } }
}
