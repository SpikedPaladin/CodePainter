namespace SchemeEditor {
    
    public class Style {
        public string? foreground { get; set; }
        public string? background { get; set; }
        public bool bold { get; set; }
        public bool italic { get; set; }
        public bool underline { get; set; }
        public bool strikethrough { get; set; }
        
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
