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
		int		nb_cols = 0;
		bool	is_header = true;
		var		aligns = new float[0];

		for (int i = 0; i < content.length; i++) {
			// Store each line cells in array 
			var elems = content[i].split("|");
			elems = elems[1:elems.length - 1];
			var nb_elems = elems.length;

			if (!is_header && nb_elems > nb_cols)
				nb_elems = nb_cols;

			// Check if line is a separator title <-> content
			if (/^[|]([- :]+[|])+\s*$/.match(content[i])) {
				is_header = false;
				for (int ia = 0; ia < nb_cols; ia++) {
					var s = elems[ia]._strip();
					if (s.has_prefix(":") && s.has_suffix(":"))
						aligns[ia] = 0.5f;
					else if (s.has_suffix(":"))
						aligns[ia] = 1.0f;
					else
						aligns[ia] = 0.0f;
				}
				continue;
			} else if (is_header) {
				nb_cols = elems.length;
				aligns = new float[nb_cols];
			}

			for (int j = 0; j < nb_elems; j++) {
				var elem = elems[j]._strip();

				if (is_header)
					attach(new Gtk.Label(elem){css_classes={"header_table"}, use_markup=true}, j, i);
				else
					attach(new Gtk.Label(elem){css_classes={"table_label"}, use_markup=true,
							selectable=true, vexpand=true, hexpand=true, xalign=aligns[j]}, j, i);
			}
		}
	}

	public bool is_empty() {
		return content.length == 0;
	}

	private string []content;
}
