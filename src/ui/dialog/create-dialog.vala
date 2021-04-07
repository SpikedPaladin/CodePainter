namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/dialog-create.ui")]
    public class CreateDialog : Gtk.Dialog {
        private unowned UpdateFunc update_func;
        private string[] scheme_ids;
        private string save_path;
        
        [GtkChild]
        private unowned Gtk.Button button_save;
        
        [GtkChild]
        private unowned Gtk.Entry entry_id;
        [GtkChild]
        private unowned Gtk.Entry entry_name;
        [GtkChild]
        private unowned Gtk.Revealer error_revealer;
        
        public CreateDialog(Gtk.Window window, owned UpdateFunc? update_func = null) {
            Object(
                    transient_for: window,
                    use_header_bar: 1
            );
            
            this.update_func = update_func;
            scheme_ids = Gtk.SourceStyleSchemeManager.get_default().get_scheme_ids();
            
            // Find save path
            save_path = Gtk.SourceStyleSchemeManager.get_default().get_search_path()[0];
        }
        
        [GtkCallback]
        private void update_button() {
            if (entry_id.text != "") {
                if (!(entry_id.text in scheme_ids)) {
                    entry_id.get_style_context().remove_class("error");
                    error_revealer.reveal_child = false;
                    if (entry_name.text != "") {
                        button_save.set_sensitive(true);
                    }
                } else {
                    entry_id.get_style_context().add_class("error");
                    error_revealer.reveal_child = true;
                    button_save.set_sensitive(false);
                }
            } else {
                button_save.set_sensitive(false);
            }
        }
        
        public override void response(int response_id) {
            if (response_id == Gtk.ResponseType.OK) {
                XmlUtil.write_scheme(save_path + @"/$(entry_id.text).xml", entry_id.text, entry_name.text, "", "");
                update_func();
            }
            destroy();
        }
        
        public delegate void UpdateFunc();
    }
}
