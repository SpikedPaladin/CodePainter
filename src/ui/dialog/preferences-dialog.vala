namespace CodePainter {
    
    [GtkTemplate (ui = "/me/paladin/CodePainter/ui/dialog-preferences.ui")]
    public class PreferencesDialog : Gtk.Dialog {
        [GtkChild]
        private unowned Gtk.FontButton font;
        
        [GtkChild]
        private unowned Gtk.Switch night_mode;
        
        [GtkChild]
        private unowned Gtk.ComboBoxText default_language;
        
        public PreferencesDialog(Gtk.Window window) {
            Object(
                    transient_for: window,
                    use_header_bar: 1
            );
            
            Application.settings.bind("font", font, "font", SettingsBindFlags.DEFAULT);
            Application.settings.bind("night-mode", night_mode, "active", SettingsBindFlags.DEFAULT);
            Application.settings.bind("default-language", default_language, "active-id", SettingsBindFlags.DEFAULT);
        }
    }
}
