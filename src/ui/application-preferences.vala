namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/prefs.ui")]
    public class ApplicationPreferences : Gtk.Dialog {
        private Settings settings;
        
        [GtkChild]
        private unowned Gtk.FontButton font;
        
        [GtkChild]
        private unowned Gtk.ComboBoxText default_language;
        
        public ApplicationPreferences(ApplicationWindow window) {
            Object(
                    transient_for: window,
                    use_header_bar: 1
            );
            
            settings = new Settings("me.paladin.SchemeEditor");
            
            settings.bind("font", font, "font", SettingsBindFlags.DEFAULT);
            settings.bind("default-language", default_language, "active-id", SettingsBindFlags.DEFAULT);
        }
    }
}
