namespace CodePainter {
    
    [GtkTemplate (ui = "/me/paladin/CodePainter/ui/home-page.ui")]
    public class HomePage : Gtk.Box {
        
        [GtkChild]
        private unowned ListBox list;
        
        [GtkChild]
        private unowned Gtk.Revealer revealer;
        [GtkChild]
        private unowned Gtk.Button button_trash;
        [GtkChild]
        private unowned Gtk.Button button_export;
        
        construct {
            list.selected.connect((count) => {
                if (!list.selecting) {
                    toggle_selection(true);
                }
                button_trash.set_sensitive(count > 0);
                button_export.set_sensitive(count > 0);
            });
            list.open_scheme.connect((id) => scheme_selected(id));
            load_schemes();
        }
        
        private void load_schemes() {
            var manager = scheme_manager;
            
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
            scheme_manager.force_rescan();
            
            list.clear();
            load_schemes();
        }
        
        public signal void toggle_selection(bool selecting) {
            if (!selecting) {
                button_trash.set_sensitive(false);
                button_export.set_sensitive(false);
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
        
        [GtkCallback]
        private void export_clicked() {
            var file_chooser = new Gtk.FileChooserDialog(
                "Save",
                get_toplevel() as Gtk.Window,
                Gtk.FileChooserAction.SELECT_FOLDER,
                "_Cancel",
                Gtk.ResponseType.CANCEL,
                "_Save",
                Gtk.ResponseType.OK
            );
            
            file_chooser.response.connect((dialog, response) => {
                var save_dialog = dialog as Gtk.FileChooserDialog;
                
                if (response == Gtk.ResponseType.OK)
                    export_selected(save_dialog.get_file().get_path());
                
                dialog.close();
            });
            file_chooser.show();
        }
        
        private void export_selected(string path) {
            foreach (var id in list.get_selected()) {
                var scheme_file = File.new_for_path(scheme_manager.get_scheme(id).get_filename());
                try {
                    scheme_file.copy(File.new_for_path(path + "/" + scheme_file.get_basename()), FileCopyFlags.NONE);
                } catch (Error e) {
                    warning(e.message);
                }
            }
        }
        
        public signal void scheme_selected(string id);
    }
}
