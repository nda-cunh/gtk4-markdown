
public class MarkdownElementText : MarkdownElement {
	private Gtk.Label label;

	public MarkdownElementText (string content) {
		this.content = content;
		type = Type.TEXT;
		print ("Created TEXT element: %s\n", content);
		label = parse_text(content.data);
		// label = new Gtk.Label (content) {
			// halign = Gtk.Align.START,
			// valign = Gtk.Align.START,
			// hexpand = true,
			// vexpand = false,
			// wrap = true,
			// justify = Gtk.Justification.FILL,
		// };
	}

	public override Gtk.Widget? getwidget() {
		return label;
	}
}
