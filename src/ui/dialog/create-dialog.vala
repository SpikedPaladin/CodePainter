using Gee;

namespace CodePainter {
    
    [GtkTemplate (ui = "/me/paladin/CodePainter/ui/dialog-create.ui")]
    public class CreateDialog : Gtk.Dialog {
        private unowned UpdateFunc update_func;
        private string[] scheme_ids;
        
        [GtkChild]
        private unowned Gtk.Button button_save;
        
        [GtkChild]
        private unowned Gtk.Entry entry_id;
        [GtkChild]
        private unowned Gtk.Entry entry_name;
        [GtkChild]
        private unowned Gtk.Revealer error_revealer;
        [GtkChild]
        private unowned Gtk.Revealer add_revealer;
        [GtkChild]
        private unowned Gtk.CheckButton add_check;
        [GtkChild]
        private unowned Gtk.ComboBox add_scheme;
        [GtkChild]
        private unowned Gtk.ListStore scheme_store;
        
        public CreateDialog(Gtk.Window window, owned UpdateFunc? update_func = null) {
            Object(
                    transient_for: window,
                    use_header_bar: 1
            );
            this.update_func = update_func;
            
            scheme_ids = Application.scheme_manager.get_scheme_ids();
            
            Gtk.TreeIter iter;
            foreach (var id in scheme_ids) {
                scheme_store.append(out iter);
                scheme_store.set(iter, 0, id);
            }
            
            add_check.bind_property("active", add_revealer, "reveal-child", BindingFlags.DEFAULT);
        }
        
        [GtkCallback]
        private void update_button() {
            if (entry_id.text != "") {
                if (!(entry_id.text in scheme_ids)) {
                    entry_id.get_style_context().remove_class("error");
                    error_revealer.reveal_child = false;
                    
                    if (entry_name.text != "")
                        button_save.set_sensitive(true);
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
                HashMap<string, Style>? styles = null;
                if (add_check.active && add_scheme.get_active() > -1) {
                    var scheme = Application.scheme_manager.get_scheme(scheme_ids[add_scheme.get_active()]);
                    styles = new HashMap<string, Style>();
                    XmlUtil.load_styles(ref scheme, ref styles);
                }
                XmlUtil.write_scheme(Application.scheme_path + @"/$(entry_id.text).xml", entry_id.text, entry_name.text, "", "", styles);
                update_func();
            }
            close();
        }
        
        public delegate void UpdateFunc();
    }
}
