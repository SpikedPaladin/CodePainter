namespace SchemeEditor {
    
    public class ListBox : Gtk.ListBox {
        
        construct {
            set_header_func((row, before) => {
                row.set_header(before != null ? new Gtk.Separator(Gtk.Orientation.HORIZONTAL) : null);
            });
        }
        
        public override void row_activated(Gtk.ListBoxRow row) {
            if (row is Row) {
                open_scheme(row.id);
            }
        }
        
        public void clear() {
            foreach (var child in get_children()) {
                child.destroy();
            }
        }
        
        public new List<weak Row> get_children() {
            return (List<weak Row>) base.get_children();
        }
        
        public signal void open_scheme(string id);
        
        public void add_scheme(Gtk.SourceStyleScheme scheme) {
            insert(new Row.from_scheme(scheme), -1);
        }
        
        [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/scheme-row.ui")]
        public class Row : Gtk.ListBoxRow {
            public string id { get; construct set; }
            [GtkChild]
            private unowned Gtk.Label row_title;
            [GtkChild]
            private unowned Gtk.Label row_subtitle;
            
            public Row.from_scheme(Gtk.SourceStyleScheme scheme) {
                id = scheme.get_id();
                row_title.set_text(scheme.get_name());
                row_subtitle.set_text("ID: " + id);
            }
        }
    }
}
