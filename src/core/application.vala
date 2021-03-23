namespace SchemeEditor {
    
    public class Application : Gtk.Application {
        private MainWindow window;
        
        public Application() {
            application_id = "me.paladin.SchemeEditor";
        }
        
        public override void activate() {
            window = new MainWindow(this);
            window.present();
        }
    }
}
