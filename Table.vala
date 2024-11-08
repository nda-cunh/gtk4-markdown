using Gtk;

public class Table : Gtk.Grid {
	construct {
		css_classes = {"table"};
	}

	public Table () {

	}

	public Table.from_content (string content) {
		foreach (unowned var line in content.split("\n")) {
			if (is_table(line))
				this.add_line(line);
			else if (!this.is_empty()) {
				generate_table();
				break;
			}
		}
	}

	private bool is_table(string line) {
		MatchInfo match_info;
		var reg = /^[|]{1}(.*[|]{1})+\s*$/;
		if (reg.match(line, 0, out match_info))
			return true;
		return false;
	}

	public void add_line(string line) {
		content += line;
	}

	public void generate_table() {
		bool is_header = true;
		for (int i = 0; i < content.length; i++) {
			var elems = content[i].split("|");
			elems = elems[1:elems.length - 1];

			if (/^[|]([- :]+[|])+\s*$/.match(content[i])) {
				is_header = false;
				continue;
			}

			for (int j = 0; j < elems.length; j++) {
				var elem = elems[j]._strip();

				if (is_header)
					attach(new Gtk.Label(elem){css_classes={"header_table"}, use_markup=true}, j, i);
				else
					attach(new Gtk.Label(elem){css_classes={"table_label"}, use_markup=true, selectable=true, vexpand=true, hexpand=true, halign=Gtk.Align.FILL}, j, i);
			}
		}
	}

	public bool is_empty() {
		return content.length == 0;
	}

	private string []content;
}
