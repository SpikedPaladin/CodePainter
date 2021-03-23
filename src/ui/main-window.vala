using Gee;

namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/window-main.ui")]
    public class MainWindow : Gtk.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.Button button_close;
        [GtkChild]
        private unowned Gtk.Button button_create;
        [GtkChild]
        private unowned Gtk.Button button_save;
        [GtkChild]
        private unowned Gtk.MenuButton button_menu;
        
        [GtkChild]
        private unowned Gtk.Stack stack;
        [GtkChild]
        private unowned HomePage home_page;
        [GtkChild]
        private unowned EditorPage editor_page;
        
        public MainWindow(Gtk.Application application) {
            Object(application: application);
            
            home_page.scheme_selected.connect(id => switch_page(id));
            
            button_create.clicked.connect(() =>
                new CreateDialog(this, home_page.update_page).present()
            );
            button_save.clicked.connect(() => editor_page.save_scheme());
            button_close.clicked.connect(() => switch_page());
            setup_menu();
        }
        
        private void setup_menu() {
            var builder = new Gtk.Builder.from_resource("/me/paladin/SchemeEditor/ui/menu-main.ui");
            var menu = builder.get_object("menu") as MenuModel;
            
            var action = new SimpleAction("preferences", null);
            action.activate.connect(() => new PreferencesDialog(this).present());
            add_action(action);
            
            action = new SimpleAction("inspector", null);
            action.activate.connect(() => Gtk.Window.set_interactive_debugging(true));
            add_action(action);
            
            button_menu.set_menu_model(menu);
        }
        
        public void switch_page(string? id = null) {
            if (id != null) {
                stack.set_visible_child(editor_page);
                
                button_close.set_visible(true);
                button_create.set_visible(false);
                button_save.set_visible(true);
                editor_page.load_scheme(id);
                
                set_title(editor_page.scheme_manager.get_scheme(id).get_name());
            } else {
                stack.set_visible_child(home_page);
                
                button_close.set_visible(false);
                button_create.set_visible(true);
                button_save.set_visible(false);
                editor_page.close_scheme();
                home_page.update_page();
                
                set_title("Scheme Editor");
            }
        }
    }
}
