
public class MarkdownElementSeparator : MarkdownElement {
	public MarkdownElementSeparator () {
		this.content = "---";
		type = Type.SEPARATOR;
	}

	public override void getwidget() {
	}
}
