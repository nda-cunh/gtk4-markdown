
public class MarkdownElementSeparator : MarkdownElement {
	Gtk.Separator separator;

	public MarkdownElementSeparator () {
		this.content = "---";
		type = Type.SEPARATOR;
		separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
	}

	public override Gtk.Widget? getwidget() {
		return separator;
	}
}
