
public class MarkdownElementCodeBlock : MarkdownElement {
	public string language {get ; protected set; }

	public MarkdownElementCodeBlock (string content) {
		this.content = content;
		type = Type.CODEBLOCK;
	}

	public override void getwidget() {
	}
}
