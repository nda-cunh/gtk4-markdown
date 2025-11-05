
public class MarkdownElementImage : MarkdownElement {
	public string alt_text {get ; protected set; }
	public string url {get ; protected set; }
	public string title {get ; protected set; }

	public MarkdownElementImage (string content, MatchInfo info) {
		this.content = content;
		this.alt_text = info.fetch_named("name");
		this.url = info.fetch_named("url");
		this.title = info.fetch_named("title");
		type = Type.IMAGE;
	}

	public override void getwidget() {
	}
}
