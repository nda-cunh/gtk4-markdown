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
				min_height = 800,
				min_width = 800,
			};

			foreach (var cmd in cmds[1:]) {
				markdown.load_from_file (cmd);
			}

			win.child = markdown;

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
