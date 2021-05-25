namespace CodePainter {
    
    public class Style {
        public string? foreground;
        public string? background;
        public bool bold;
        public bool italic;
        public bool underline;
        public bool strikethrough;
        
        public Style.from_source_style(Gtk.SourceStyle style) {
            foreground = style.foreground;
            background = style.background;
            bold = style.bold;
            italic = style.italic;
            underline = style.underline_set;
            strikethrough = style.strikethrough;
            
            if (foreground != null && foreground.get_char(0) != '#')
                foreground = "#" + foreground;
            
            if (background != null && background.get_char(0) != '#')
                background = "#" + background;
        }
        
        public bool is_empty() {
            return
                    foreground == null &&
                    background == null &&
                    !bold &&
                    !italic &&
                    !underline &&
                    !strikethrough;
        }
    }
}
