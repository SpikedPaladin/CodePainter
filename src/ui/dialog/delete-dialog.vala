namespace CodePainter {
    
    [GtkTemplate (ui = "/me/paladin/CodePainter/ui/dialog-delete.ui")]
    public class DeleteDialog : Gtk.Dialog {
        private unowned UpdateFunc update_func;
        private File[] files;
        
        [GtkChild]
        private unowned Gtk.Button button_delete;
        
        [GtkChild]
        private unowned Gtk.Revealer revealer;
        [GtkChild]
        private unowned Gtk.Label label_ids;
        
        public DeleteDialog(Gtk.Window window, string[] ids, owned UpdateFunc update_func) {
            Object(
                    transient_for: window,
                    use_header_bar: 1
            );
            this.update_func = update_func;
            
            foreach (var id in ids)
                files += File.new_for_path(scheme_manager.get_scheme(id).get_filename());
            
            label_ids.set_text(string.joinv("\n", ids));
        }
        
        [GtkCallback]
        private void toggle_delete(Gtk.ToggleButton button) {
            revealer.reveal_child = button.active;
            button_delete.label = button.active ? "_Delete" : "_Trash";
        }
        
        public override void response(int response_id) {
            if (response_id == Gtk.ResponseType.OK) {
                try {
                    foreach (var file in files) {
                        if (revealer.reveal_child) {
                            file.delete();
                        } else {
                            file.trash();
                        }
                    }
                } catch (Error e) {
                    warning(e.message);
                }
                update_func();
            }
            close();
        }
        
        public delegate void UpdateFunc();
    }
}
