using Gtk;

public class Table : Gtk.Grid {
	construct {
		css_classes = { "markdown-table" };
		func = (text, is_table) => new Gtk.Label (text);
	}

	public Table () {
	}

	public Table.from_content (string content, LabelFactory? func = null) {
		if (func == null)
			func = (text, is_table) => new Gtk.Label (text);
		else
			this.func = func;
		foreach (unowned var line in content.split ("\n")) {
			if (is_table (line))
				this.add_line (line);
			else if (!this.is_empty ()) {
				generate_table ();
				break;
			}
		}
	}

	public delegate Gtk.Widget LabelFactory (string text, bool is_table) throws Error;
	public LabelFactory func;

	private bool is_table (string line) {
		MatchInfo match_info;
		var reg = /^[|]{1}(.*[|]{1})+\s*$/;
		if (reg.match (line, 0, out match_info))
			return true;
		return false;
	}

	public void add_line (string line) {
		content += line;
	}

	public void generate_table () {
		bool is_header = true;
		int data_row = 0;
		for (int i = 0; i < content.length; i++) {
			var elems = content[i].split ("|");
			elems = elems[1:elems.length - 1];

			if (/^[|]([- :]+[|])+\s*$/.match (content[i])) {
				is_header = false;
				continue;
			}

			bool is_even = (data_row % 2 == 0);

			for (int j = 0; j < elems.length; j++) {
				var elem = elems[j]._strip ();

				if (is_header) {
					try {
						var widget = func (elem, true);
						widget.css_classes = { "markdown-header_table" };
						widget.halign = Gtk.Align.FILL;
						widget.vexpand = true;
						widget.hexpand = true;
						attach (widget, j, i);
					} catch (Error e) {
						printerr (e.message);
					}
				} else {
					try {
						var widget = func (elem, true);
						widget.css_classes = { is_even ? "markdown-table_label" : "markdown-table_label_alt" };
						widget.vexpand = true;
						widget.hexpand = true;
						widget.halign = Gtk.Align.FILL;
						attach (widget, j, i);
					} catch (Error e) {
						printerr (e.message);
					}
				}
			}

			if (!is_header)
				data_row++;
		}
	}

	public bool is_empty () {
		return content.length == 0;
	}

	private string[] content;
}
