
public class MarkdownElementText : MarkdownElement {
	public MarkdownElementText (string content) {
		this.content = content;
		type = Type.TEXT;
	}

	public override void getwidget() {
	}
}
