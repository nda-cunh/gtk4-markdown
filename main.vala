
public class ExampleApp : Adw.Application {
	public ExampleApp () {
		Object (application_id: "com.example.App");
	}

	public override void activate () {
		try {
			var win = new Adw.ApplicationWindow (this);

			Intl.setlocale ();
			var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			var winscroll = new Gtk.ScrolledWindow ();
			var markdown = new Markdown ("/home/nda-cunh/.local/share/supravim-gui/Customisation.md") {
				margin_top = 12,
				margin_bottom = 12,
				margin_start = 12,
				margin_end = 12,
			};

			winscroll.set_child (markdown);
			winscroll.width_request = 600;
			winscroll.height_request = 800;

			box.append (new Adw.HeaderBar () {
			});
			box.append (winscroll);

			win.content = box;
			win.present ();
		}
		catch (Error e) {
			printerr ("Error: %s\n", e.message);
			base.quit ();
		}
	}

	public static int main (string[] args) {
		var app = new ExampleApp ();
		return app.run (args);
	}
}
