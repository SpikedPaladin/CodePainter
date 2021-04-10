namespace SchemeEditor {
    
    public class Application : Gtk.Application {
        public static Gtk.SourceStyleSchemeManager scheme_manager;
        public static Settings settings;
        private MainWindow window;
        
        public Application() {
            application_id = "me.paladin.SchemeEditor";
            
            scheme_manager = Gtk.SourceStyleSchemeManager.get_default();
            settings = new Settings("me.paladin.SchemeEditor");
        }
        
        public override void activate() {
            window = new MainWindow(this);
            window.present();
            
            setup_accels();
        }
        
        public void setup_accels() {
            // Main menu
            set_accels_for_action("win.preferences", { "<Primary>comma" });
            set_accels_for_action("win.inspector", { "<Primary><Shift>I" });
            
            // Create menu
            set_accels_for_action("win.create", { "<Primary>N" });
            set_accels_for_action("win.import", { "<Primary>I" });
        }
    }
}
