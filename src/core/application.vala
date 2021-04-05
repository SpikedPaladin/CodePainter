namespace SchemeEditor {
    
    public class Application : Gtk.Application {
        public static Settings settings;
        private MainWindow window;
        
        public Application() {
            application_id = "me.paladin.SchemeEditor";
            settings = new Settings("me.paladin.SchemeEditor");
        }
        
        public override void activate() {
            window = new MainWindow(this);
            window.present();
        }
    }
}
