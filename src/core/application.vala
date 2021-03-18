namespace SchemeEditor {
    
    public class Application : Gtk.Application {
        private ApplicationWindow window;
        
        public Application() {
            application_id = "me.paladin.SchemeEditor";
        }
        
        public override void activate() {
            window = new ApplicationWindow(this);
            window.present();
        }
        
        public override void startup() {
            base.startup();
        }
    }
}
