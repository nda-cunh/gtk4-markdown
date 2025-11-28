
public class MarkdownElementText : MarkdownElement {
	private SupraLabel label;

	public MarkdownElementText (string content) {
		this.content = content;
		type = Type.TEXT;
		label = parse_text(content.data);
	}

	public signal bool activate_link (string uri);

	public override Gtk.Widget? getwidget() {
		return label;
	}
}
