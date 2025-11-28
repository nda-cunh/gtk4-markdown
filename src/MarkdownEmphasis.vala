public class MarkdownEmphasis {
	public enum Type {
		BOLD,
		ITALIC,
		UNDERLINE,
		STRIKE,
		BLOCK_CODE,
		LINK,
		HIGHLIGHT,
		SUBSCRIPT,
		SUPERSCRIPT,
		HEADER
	}

	public Type type;
	public int start_index {get; private set;}
	public int end_index {get; private set;}

	public MarkdownEmphasis (Type type, int start_index, int size) {
		this.type = type;
		this.start_index = start_index;
		this.end_index = size;
	}
}

public class MarkdownEmphasisLink : MarkdownEmphasis {
	public string url {get; private set;}

	public MarkdownEmphasisLink (int start_index, int size, string url) {
		base (Type.LINK, start_index, size);
		this.url = url;
	}
}

public class MarkdownEmphasisHeader : MarkdownEmphasis {
	public int header_level {get; private set;}

	public MarkdownEmphasisHeader (int start_index, int size, int header_level) {
		base (Type.HEADER, start_index, size);
		this.header_level = header_level;
	}
}
