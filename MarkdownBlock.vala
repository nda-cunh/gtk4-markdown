public class MarkdownElement {
	public enum Type {
		TEXT,
		CODEBLOCK,
		BLOCKQUOTE,
		TABLE,
		IMAGE,
		SEPARATOR
	}


	public string content {get ; private set; }
	public Type type; 

	public MarkdownElement (string content, Type type) {
		this.content = content;
		this.type = type;
	}
}

