using Gtk;

// Blockquote container. CSS handles visuals (border-left, background, radius);
// inner content_box uses GTK4 margin properties for spacing so that wrapped-label
// height is measured against a plain (un-styled) box — avoiding the CSS-padding
// measurement issue that causes blockquotes to show at minimum height in GTK4.
public class BlockQuote : Gtk.Box {
	private Gtk.Box _content;

	construct {
		orientation = Gtk.Orientation.VERTICAL;
		css_classes = { "markdown-blockquote" };
		halign = Gtk.Align.FILL;
		hexpand = true;
		spacing = 0;

		_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
			halign = Gtk.Align.FILL,
			hexpand = true,
			vexpand = false,
			margin_top = 12,
			margin_bottom = 12,
			margin_start = 16,
			margin_end = 16,
		};
		((Gtk.Box) this).append (_content);
		_content.set_size_request (500, 200);
	}

	public BlockQuote () { }

	public unowned Gtk.Box content { get { return _content; } }
}
