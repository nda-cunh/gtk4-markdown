
public class MarkdownElementBlockquote : MarkdownElement {
	public MarkdownElementBlockquote (string content) {
		this.content = content;
		type = Type.BLOCKQUOTE;
	}

	public override Gtk.Widget? getwidget() {
		return null;
	}
}
