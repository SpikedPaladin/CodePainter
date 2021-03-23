namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/home-page.ui")]
    public class HomePage : Gtk.Box {
        
        [GtkChild]
        private unowned ListBox list;
        
        construct {
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
        
        public void update_page() {
            Gtk.SourceStyleSchemeManager.get_default().force_rescan();
            
            list.clear();
            load_schemes();
        }
        
        public signal void scheme_selected(string id);
    }
}
