public abstract class MDNode {
	public List<MDNode> children = new List<MDNode> ();
	public abstract unowned string get_type_name ();

	public static MDNode new_from_type (string type) {
		switch (type) {
		case "___": return new MDItalicBold ();
		case "***": return new MDItalicBold ();
		case "**": return new MDBold ();
		case "~~": return new MDStrike ();
		case "`": return new MDInlineCode ();
		case "*": return new MDItalic ();
		case "_": return new MDItalic ();
		case "==": return new MDhighlight ();
		case "~": return new MDSubscript ();
		case "^": return new MDSuperscript ();
		case "strong": return new MDBold ();
		case "b": return new MDBold ();
		case "em": return new MDItalic ();
		case "i": return new MDItalic ();
		case "u": return new MDUnderline ();
		case "s": return new MDStrike ();
		case "h1": return new MDHeader (1);
		case "h2": return new MDHeader (2);
		case "h3": return new MDHeader (3);
		case "h4": return new MDHeader (4);
		case "h5": return new MDHeader (5);
		case "h6": return new MDHeader (6);
		default:
			return new MDText ("<unknown:" + type + ">");
		}
	}
}

public class MDHeader : MDNode {
	public override unowned string get_type_name () { return "Header"; }
	public int level;
	public MDHeader (int level) { this.level = level; }
}

public class MDText : MDNode {
	public override unowned string get_type_name () { return "Text"; }
	public string text;
	public MDText (owned string text) { this.text = text; }
}

public class MDDocument : MDNode {
	public override unowned string get_type_name () { return "Document"; }
}

public class MDParagraph : MDNode {
	public override unowned string get_type_name () { return "Paragraph"; }
	public bool is_end = false;
}

public class MDBold : MDNode {
	public override unowned string get_type_name () { return "Bold"; }
}

public class MDItalicBold : MDNode {
	public override unowned string get_type_name () { return "ItalicBold"; }
}

public class MDItalic : MDNode {
	public override unowned string get_type_name () { return "Italic"; }
}

public class MDStrike : MDNode {
	public override unowned string get_type_name () { return "Strike"; }
}

public class MDUnderline : MDNode {
	public override unowned string get_type_name () { return "Underline"; }
}

public class MDInlineCode : MDNode {
	public override unowned string get_type_name () { return "InlineCode"; }
}

public class MDhighlight : MDNode {
	public override unowned string get_type_name () { return "Highlight"; }
}

public class MDSubscript : MDNode {
	public override unowned string get_type_name () { return "Subscript"; }
}

public class MDSuperscript : MDNode {
	public override unowned string get_type_name () { return "Superscript"; }
}

public class MDLineBreak : MDNode {
	public override unowned string get_type_name () { return "LineBreak"; }
}

public class MDListNode : MDNode {
	public override unowned string get_type_name () { return "List"; }
	public enum ListType { UNORDERED, ORDERED }
	public ListType list_type;
	public MDListNode (ListType type) { this.list_type = type; }
}

public class MDLink : MDNode {
	public override unowned string get_type_name () { return "Link"; }
	public string url;
	public string name;
	public string title;
	public MDLink (owned string name, owned string url, owned string title) {
		this.url = url;
		this.title = title;
		this.name = name;
	}
}
