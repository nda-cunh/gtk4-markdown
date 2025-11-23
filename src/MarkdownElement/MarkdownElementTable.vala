
public class MarkdownElementTable : MarkdownElement {
	Table table;
	public MarkdownElementTable (string content) {
		this.content = content;
		type = Type.TABLE;
		table = new Table.from_content(content, (text, is_table) => {
			return parse_text((uint8[])text.data);
		});

	}

	public override Gtk.Widget? getwidget() {
		return table;
	}
}
