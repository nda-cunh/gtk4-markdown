using Gtk;

public class ExampleApp : Gtk.Application {
	construct {
		application_id = "org.example.app";
		flags = ApplicationFlags.FLAGS_NONE;
	}

	public override void activate () {
		var win = new Gtk.ApplicationWindow (this);

		win.child = new MarkDown() {
			margin_start = 15,
			margin_top = 15,
		};
		win.present ();
	}

	public static int main (string[] args) {
		var app = new ExampleApp ();
		return app.run (args);
	}
}
