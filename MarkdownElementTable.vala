
public class MarkdownElementTable : MarkdownElement {
	public MarkdownElementTable (string content) {
		this.content = content;
		type = Type.TABLE;
	}

	public override void getwidget() {
	}
}
