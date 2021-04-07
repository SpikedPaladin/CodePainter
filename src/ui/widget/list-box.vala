namespace SchemeEditor {
    
    public class ListBox : Gtk.ListBox {
        public bool selecting;
        
        construct {
            set_header_func((row, before) => {
                row.set_header(before != null ? new Gtk.Separator(Gtk.Orientation.HORIZONTAL) : null);
            });
        }
        
        public override void row_activated(Gtk.ListBoxRow list_row) {
            var row = list_row as Row;
            
            if (selecting)
                row.selected = !row.selected;
            else
                open_scheme(row.id);
        }
        
        public override bool button_press_event(Gdk.EventButton event) {
            Gdk.Event* ev = (Gdk.Event*) event;
            if (!selecting && ev->triggers_context_menu()) {
                var row = get_row_at_y((int) event.y) as Row;
                
                if (row != null) {
                    row.selected = true;
                    return true;
                }
            }
            return base.button_press_event(event);
        }
        
        public void clear() {
            @foreach((element) => remove(element));
        }
        
        public void toggle_selection(bool selecting) {
            foreach (var row in get_children()) {
                row.select(selecting);
            }
            this.selecting = selecting;
        }
        
        public string[] get_selected() {
            string[] result = {};
            foreach (var row in get_children()) {
                if (row.selected) {
                    result += row.id;
                }
            }
            return result;
        }
        
        public new List<weak Row> get_children() {
            return (List<weak Row>) base.get_children();
        }
        
        public void add_scheme(Gtk.SourceStyleScheme scheme) {
            var row = new Row.from_scheme(scheme);
            row.notify["selected"].connect(() => selected(get_selected().length));
            insert(row, -1);
        }
        
        public signal void selected(int count);
        public signal void open_scheme(string id);
        
        [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/scheme-row.ui")]
        public class Row : Gtk.ListBoxRow {
            public string id { get; construct set; }
            public bool selected { get; set; }
            [GtkChild]
            private unowned Gtk.Label row_title;
            [GtkChild]
            private unowned Gtk.Label row_subtitle;
            
            [GtkChild]
            private unowned Gtk.Revealer revealer;
            [GtkChild]
            private unowned Gtk.CheckButton check_selected;
            [GtkChild]
            private unowned Gtk.Revealer open_revealer;
            
            public Row.from_scheme(Gtk.SourceStyleScheme scheme) {
                id = scheme.get_id();
                row_title.set_text(scheme.get_name());
                row_subtitle.set_text("ID: " + id);
                check_selected.bind_property("active", this, "selected", BindingFlags.BIDIRECTIONAL);
                revealer.bind_property("reveal-child", open_revealer, "reveal-child", BindingFlags.INVERT_BOOLEAN);
            }
            
            public void select(bool selecting) {
                revealer.reveal_child = selecting;
                
                if (!selecting)
                    check_selected.active = false;
            }
        }
    }
}
