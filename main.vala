using Gtk;

public class ExampleApp : Gtk.Application {
	construct {
		application_id = "org.markdown.app";
		flags = ApplicationFlags.FLAGS_NONE;
	}

	MarkDown markdown;
	public override void activate () {
		try {
			var win = new Gtk.ApplicationWindow (this);
			markdown = new MarkDown() {
				margin_start = 15,
				margin_top = 15,
			};

			markdown.path_dir = "/nfs/homes/nda-cunh/.local/share/supravim-gui/";
			if (cmds.length == 1) {
				markdown.load_file ("Readme.md");
			}
			else {
				foreach (var cmd in cmds[1:]) {
					markdown.load_file (cmd);
				}
			}
			// markdown.load_from_file ("/nfs/homes/nda-cunh/.local/share/supravim-gui/Compilation.md");
			// markdown.clear();
			// markdown.load_file ("Readme.md");


			Viewport viewport = new Viewport (null, null) {
				child = markdown,
			};
			ScrolledWindow scrolled_window = new ScrolledWindow () {
				min_content_height = 600,
				min_content_width = 800,
				child = viewport,
			};

			win.child = scrolled_window;


			win.present ();
		}
		catch (Error e) {
			error ("Error: %s\n", e.message);
		}
	}
	static unowned string []cmds;

	public static int main (string[] args) {
		cmds = args;
		var app = new ExampleApp ();
		return app.run ({args[0]});
	}
}
