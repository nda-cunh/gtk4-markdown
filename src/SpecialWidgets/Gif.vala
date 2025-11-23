using Gtk;
using Gdk;
using Cairo;

public class Gif : DrawingArea {
	construct {
		hexpand = true;
		vexpand = true;
	}
	
	private Pixbuf pixbuf;
	private PixbufAnimation anim;
	private PixbufAnimationIter iter;

	public int width {private set; get;}
	public int height {private set; get;}

	public Gif (string location) throws Error {
		anim = new PixbufAnimation.from_file (location);
		pixbuf = anim.get_static_image ();
		width = anim.get_width ();
		height = anim.get_height ();
		set_size_request (width, height);
		set_draw_func (drawing);
		iter = anim.get_iter(null);
		
		var idle_id = Timeout.add (10, () => {
			iter.advance (null);
			pixbuf = iter.get_pixbuf ();
			queue_draw ();
			return true;
		});

		GLib.Application.get_default ().shutdown.connect (()=> {
			Source.remove (idle_id);
		});

	}

	private void drawing (DrawingArea drawing_area, Context ctx, int width, int height)
	{
		Gdk.cairo_set_source_pixbuf (ctx, pixbuf, 0, 0); 
		ctx.paint();
	}
}
