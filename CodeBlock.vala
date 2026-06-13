using Gtk;

public class CodeBlock : Gtk.Box {
	construct {
		orientation = Gtk.Orientation.HORIZONTAL;
		css_classes = { "markdown-code_box" };
		
		halign = Gtk.Align.START; 
		valign = Gtk.Align.START;
		hexpand = false;
		vexpand = false;
		
		margin_top = 4;
		margin_bottom = 4;
	}

	public CodeBlock (string lang, string code) {
		code._strip();
		var line_bar = new StringBuilder ();
		string[] lines = code.split ("\n");
		int line_num = 1;
		foreach (var line in lines) {
			line_bar.append_printf ("%d\n", line_num);
			++line_num;
		}

		append (new Gtk.Label (line_bar.str) {
			css_classes = { "markdown-line_bar" },
			halign = Gtk.Align.START,
			valign = Gtk.Align.FILL,
			vexpand = true,
			hexpand = false,
			justify = Justification.RIGHT,
		});

		var buffer = new TextBuffer (null) { text = code };
		
		var text_view = new Gtk.TextView.with_buffer (buffer) {
			halign = Gtk.Align.FILL,
			valign = Gtk.Align.FILL,
			can_focus = false,
			focusable = false,
			wrap_mode = Gtk.WrapMode.NONE,
		};

		var pango_context = text_view.get_pango_context ();
		var layout = new Pango.Layout (pango_context);
		layout.set_text (code, -1);
		int text_width = 0;
		int text_height = 0;
		layout.get_pixel_size (out text_width, out text_height);
		
		text_view.set_size_request (final_width, text_height);
		
		append (text_view);
	}
}
