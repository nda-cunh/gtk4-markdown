public class MarkdownEmphasis {
	public enum Type {
		BOLD,
		ITALIC,
		UNDERLINE,
		STRIKE,
		BLOCK_CODE,
	}

	public Type type;
	public int start_index {get; private set;}
	public int size {get; private set;}

	public MarkdownEmphasis (Type type, int start_index, int size) {
		this.type = type;
		this.start_index = start_index;
		this.size = size;
	}
}
