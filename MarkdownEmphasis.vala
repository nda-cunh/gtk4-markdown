public class MarkdownEmphasis {
	public enum Type {
		BOLD,
		ITALIC,
		UNDERLINE,
		STRIKE,
		BLOCK_CODE,
		HIGHLIGHT,
		HEADER
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

public class MarkdownEmphasisHeader : MarkdownEmphasis {
	public int header_level {get; private set;}

	public MarkdownEmphasisHeader (int start_index, int size, int header_level) {
		base (Type.HEADER, start_index, size);
		this.header_level = header_level;
	}
}
