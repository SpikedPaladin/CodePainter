namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/home-page.ui")]
    public class HomePage : Gtk.Box {
        
        [GtkChild]
        private unowned ListBox list;
        
        [GtkChild]
        private unowned Gtk.Revealer revealer;
        [GtkChild]
        private unowned Gtk.Button button_trash;
        
        construct {
            list.selected.connect((count) => {
                if (!list.selecting) {
                    toggle_selection(true);
                }
                button_trash.set_sensitive(count > 0);
            });
            list.open_scheme.connect((id) => scheme_selected(id));
            load_schemes();
        }
        
        private void load_schemes() {
            var manager = Gtk.SourceStyleSchemeManager.get_default();
            
            foreach (var id in manager.get_scheme_ids()) {
                var scheme = manager.get_scheme(id);
                if (scheme.get_filename().index_of(manager.search_path[0]) != 0)
                    continue;
                
                list.add_scheme(scheme);
            }
        }
        
        [GtkCallback]
        public void create_scheme() {
            new CreateDialog(get_toplevel() as Gtk.Window, update_page).present();
        }
        
        public void update_page() {
            toggle_selection(false);
            Gtk.SourceStyleSchemeManager.get_default().force_rescan();
            
            list.clear();
            load_schemes();
        }
        
        public signal void toggle_selection(bool selecting) {
            if (!selecting) {
                button_trash.set_sensitive(false);
            }
            revealer.reveal_child = selecting;
            list.toggle_selection(selecting);
        }
        
        public bool is_empty() {
            return list.get_children().is_empty();
        }
        
        [GtkCallback]
        private void trash_clicked() {
            if (get_window() != null) {
                new DeleteDialog(
                        get_toplevel() as Gtk.Window,
                        list.get_selected(),
                        () => update_page()
                ).present();
            }
        }
        
        public signal void scheme_selected(string id);
    }
}
