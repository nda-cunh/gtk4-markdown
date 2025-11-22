using Gtk;

public class MarkdownElementImage : MarkdownElement {
	public string alt_text {get ; protected set; }
	public string url {get ; protected set; }
	public string title {get ; protected set; }
	public string dir_name {get ; protected set; }

	public MarkdownElementImage (string content, MatchInfo info, string dir_name) {
		this.dir_name = dir_name;
		this.content = content;
		this.alt_text = info.fetch_named("name");
		this.url = info.fetch_named("url");
		this.title = info.fetch_named("title");
		type = Type.IMAGE;
	}

	private Gtk.Widget get_simple_image_widget() throws Error {
		Gtk.Widget img;
		string _url = this.dir_name + "/" + this.url;
		if (_url.has_suffix (".gif") || _url.has_suffix (".webp")) {
			img = new Gif (_url) {
				valign = Align.START,
				halign = Align.START,
				hexpand=false,
				vexpand=false,
				can_focus = false,
				focusable = false,
			};
			return img;
		}
		else {
			if (FileUtils.test (_url, FileTest.EXISTS) == false) {
				throw new FileError.EXIST("Image [%s] not found", _url);
			}
			img = new Gtk.Picture.for_filename (_url) {
				valign = Align.START,
				halign = Align.START,
				hexpand=false,
				vexpand=false,
				can_focus = false,
				focusable = false,
				alternative_text = title
			};
			img.set_size_request (0, ((Gtk.Picture)img).paintable.get_intrinsic_height ());
		}
		return img;
	}

	private Gtk.Widget get_image_widget() {
		try {
			return get_simple_image_widget();
		}
		catch (Error e) {
			Gtk.Box vbox = new Gtk.Box (Orientation.VERTICAL, 2);
			Gtk.Image icon = new Gtk.Image.from_icon_name ("image-missing-symbolic") {
				valign = Align.START,
				halign = Align.START,
				can_focus = false,
				focusable = false,
			};
			// print in label the error message in red color
			Gtk.Label label = new Gtk.Label ("<span foreground='red'>Image not found: " + this.url + "</span>") {
				valign = Align.START,
				halign = Align.START,
				use_markup = true,
			};
			vbox.append (icon);
			vbox.append (label);
			return vbox;
		}
	}


	public override Gtk.Widget? getwidget() {
		return get_image_widget();
	}
}
