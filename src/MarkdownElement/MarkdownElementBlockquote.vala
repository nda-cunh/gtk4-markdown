
public class MarkdownElementBlockquote : MarkdownElement {
	public MarkdownElementBlockquote (string content) {
		this.content = content;
		type = Type.BLOCKQUOTE;
	}

	public Gtk.Box append_blockquote() {
		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			halign = Gtk.Align.FILL,
			css_classes = { "markdown-blockquote" },
		};

		var regex = new Regex ("""^>\s?""", RegexCompileFlags.MULTILINE | RegexCompileFlags.OPTIMIZE);
		content = regex.replace (content, -1, 0, "");
		print ("Blockquote content: \n" + content + "\n");

		var lst = Markdown.cut_content(content, ""); // TODO basepath
		foreach (unowned var i in lst) {
			var? w = i.getwidget ();
			if (w != null) {
				// TODO
				// if (w is SupraLabel) {
					// w.link_clicked.connect ((uri) => {
						// activate_link (uri);
					// });
				// }
				box.append(w);
			}
		}
		return box;
	}

	public override Gtk.Widget? getwidget() {
		return append_blockquote();
	}
}
