
public abstract class MarkdownElement {
	public enum Type {
		TEXT,
		CODEBLOCK,
		BLOCKQUOTE,
		TABLE,
		IMAGE,
		SEPARATOR
	}

	public string content {get ; protected set; }
	public Type type; 

	public abstract void getwidget();
}
