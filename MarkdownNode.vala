/**
 * Base class for all Markdown AST nodes.
 * Each node can have multiple children forming a tree structure.
 */
public abstract class MDNode {
	public List<MDNode> children = new List<MDNode>();
	public abstract unowned string get_type_name();

	public static MDNode new_from_type(string type) {
		switch (type) {
			case "___": return new MDItalicBold();
			case "***": return new MDItalicBold();
			case "**": return new MDBold();
			case "~~": return new MDStrike();
			case "`": return new MDInlineCode();
			case "*": return new MDItalic();
			case "_": return new MDItalic();
			case "==": return new MDhighlight();
			default:
				error("Unknown MDNode type: %s", type);
		}
	}

	/**
	 * Prints the AST starting from this node.
	 */
	public void print () {
		this.print_ast("", true);
	}
	/**
	 * Prints the AST starting from this node.
	 * @param prefix The prefix string for indentation.
	 * @param is_tail Whether this node is the last child of its parent.
	 */
	private void print_ast(string prefix, bool is_tail) {
		string name = this.get_type_name();
		string content = "";

		if (this is MDHeader) {
			var h = this as MDHeader;
			content = " (level " + h.level.to_string() + ")";
		} else if (this is MDText) {
			var t = this as MDText;
			content = " : \"" + t.text.replace("\n", "\\n") + "\"";
		}
		stdout.printf("%s%s%s%s\n", prefix, (is_tail ? "└── " : "├── "), name, content);
		
		string child_prefix = prefix + (is_tail ? "    " : "│   ");
		
		for (int i = 0; i < this.children.length(); ++i) {
			unowned var child = this.children.nth_data(i);
			bool child_is_tail = (i == this.children.length() - 1);
			child.print_ast(child_prefix, child_is_tail);
		}
	}
}
// Represents a header node with a specific level (1-6)
public class MDHeader : MDNode {
	public override unowned string get_type_name() {
		return "Header";
	}
	public int level;
	public MDHeader(int level) {
		this.level = level;
	}
}

// Represents plain text
public class MDText : MDNode {
	public override unowned string get_type_name() {
		return "Text";
	}
	public string text;
	public MDText(owned string text) {
		this.text = text;
	}
}

// Represents the root document node
public class MDDocument : MDNode { 
	public override unowned string get_type_name() { return "Document"; }
}
// Represents a paragraph node
public class MDParagraph : MDNode {
	public override unowned string get_type_name() { return "Paragraph"; }
}
// Represents bold text: **
public class MDBold : MDNode {
	public override unowned string get_type_name() { return "Bold"; }
}
// Represents italic and bold text: ***
public class MDItalicBold : MDNode {
	public override unowned string get_type_name() { return "ItalicBold"; }
}
// Represents italic text: *
public class MDItalic : MDNode {
	public override unowned string get_type_name() { return "Italic"; }
}
// Represents strikethrough text: ~~
public class MDStrike : MDNode {
	public override unowned string get_type_name() { return "Strike"; }
}
// Represents inline code text: `
public class MDInlineCode : MDNode {
	public override unowned string get_type_name() { return "InlineCode"; }
}

public class MDhighlight : MDNode {
	public override unowned string get_type_name() { return "Highlight"; }
}

// Represents a list node (ordered or unordered)
public class MDListNode : MDNode {
	public override unowned string get_type_name() { return "List"; }
	public enum ListType {
		UNORDERED,
		ORDERED
	}
	public ListType list_type;
	public MDListNode(ListType type) {
		this.list_type = type;
	}
}
