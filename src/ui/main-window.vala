using Gee;

namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/window-main.ui")]
    public class MainWindow : Gtk.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.HeaderBar header;
        [GtkChild]
        private unowned Gtk.Button button_close;
        [GtkChild]
        private unowned Gtk.MenuButton button_create;
        [GtkChild]
        private unowned Gtk.Button button_save;
        [GtkChild]
        private unowned Gtk.Button button_select;
        [GtkChild]
        private unowned Gtk.Button button_cancel;
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
            
            Application.settings.changed["night-mode"].connect(update_theme);
            update_theme();
            
            home_page.scheme_selected.connect(id => switch_page(id));
            home_page.toggle_selection.connect(toggle_selection);
            
            button_select.clicked.connect(() => {
                if (!home_page.is_empty())
                    home_page.toggle_selection(true);
            });
            button_cancel.clicked.connect(() => home_page.toggle_selection(false));
            button_save.clicked.connect(() => editor_page.save_scheme());
            button_close.clicked.connect(() => switch_page());
            
            header.bind_property("show-close-button", button_create, "visible");
            header.bind_property("show-close-button", button_select, "visible");
            header.bind_property("show-close-button", button_cancel, "visible", BindingFlags.INVERT_BOOLEAN);
            header.bind_property("show-close-button", button_menu, "visible");
            
            setup_menu();
        }
        
        private void setup_menu() {
            // Main button menu
            var builder = new Gtk.Builder.from_resource("/me/paladin/SchemeEditor/ui/menu-main.ui");
            var menu = builder.get_object("menu") as MenuModel;
            
            var action = new SimpleAction("preferences", null);
            action.activate.connect(() => new PreferencesDialog(this).present());
            add_action(action);
            
            action = new SimpleAction("inspector", null);
            action.activate.connect(() => Gtk.Window.set_interactive_debugging(true));
            add_action(action);
            
            button_menu.set_menu_model(menu);
            
            // Create button menu
            builder = new Gtk.Builder.from_resource("/me/paladin/SchemeEditor/ui/menu-add.ui");
            menu = builder.get_object("menu") as MenuModel;
            
            action = new SimpleAction("create", null);
            action.activate.connect(home_page.create_scheme);
            add_action(action);
            
            action = new SimpleAction("import", null);
            action.activate.connect(import_activated);
            add_action(action);
            
            button_create.set_menu_model(menu);
        }
        
        private void update_theme() {
            var night_mode = Application.settings.get_boolean("night-mode");
            Gtk.Settings.get_default().gtk_application_prefer_dark_theme = night_mode;
        }
        
        private void import_activated() {
            var file_chooser = new Gtk.FileChooserDialog(
                    "Open",
                    this,
                    Gtk.FileChooserAction.OPEN,
                    "_Cancel",
                    Gtk.ResponseType.CANCEL,
                    "_Open",
                    Gtk.ResponseType.OK
            );
            file_chooser.set_default_response(Gtk.ResponseType.OK);
            
            var file_filter = new Gtk.FileFilter();
            file_filter.set_name("XML files");
            file_filter.add_pattern("*.xml");
            file_chooser.add_filter(file_filter);
            
            file_filter = new Gtk.FileFilter();
            file_filter.set_name("All files");
            file_filter.add_pattern("*");
            file_chooser.add_filter(file_filter);
            
            file_chooser.response.connect((dialog, response) => {
                var open_dialog = dialog as Gtk.FileChooserDialog;
                
                if (response == Gtk.ResponseType.OK)
                    import_file(open_dialog.get_file());
                
                dialog.destroy();
            });
            file_chooser.show();
        }
        
        private void import_file(File file) {
            var dialog = new Gtk.MessageDialog(
                    this,
                    Gtk.DialogFlags.MODAL,
                    Gtk.MessageType.WARNING,
                    Gtk.ButtonsType.OK,
                    null
            );
            dialog.response.connect(() => dialog.destroy());
            // Don't import scheme from search path
            if (!(file.get_parent().get_path() in editor_page.scheme_manager.get_search_path())) {
                var scheme_id = XmlUtil.get_scheme_id(file.get_path());
                if (scheme_id != null) {
                    if (scheme_id in editor_page.scheme_manager.get_scheme_ids()) {
                        dialog.text = "Scheme with same ID exists";
                        dialog.present();
                        return;
                    }
                    
                    var file_name = editor_page.scheme_manager.get_search_path()[0] + "/" + file.get_basename();
                    if (FileUtils.test(file_name, FileTest.EXISTS)) {
                        dialog.text = "Scheme with same file name exists";
                        dialog.present();
                        return;
                    }
                    
                    try {
                        file.copy(File.new_for_path(file_name), FileCopyFlags.NONE);
                        home_page.update_page();
                    } catch (Error e) {
                        warning(e.message);
                        dialog.text = @"Error while importing scheme\n\n$(e.message)";
                        dialog.present();
                    }
                } else {
                    dialog.text = "Selected file is not style scheme";
                    dialog.present();
                }
            } else {
                dialog.text = "Scheme alreay imported";
                dialog.present();
            }
        }
        
        public void toggle_selection(bool selecting) {
            if (selecting) {
                header.get_style_context().add_class("selection-mode");
            } else {
                header.get_style_context().remove_class("selection-mode");
            }
            header.show_close_button = !selecting;
        }
        
        public void switch_page(string? id = null) {
            if (id != null) {
                stack.set_visible_child(editor_page);
                
                button_close.set_visible(true);
                button_create.set_visible(false);
                button_select.set_visible(false);
                button_save.set_visible(true);
                editor_page.load_scheme(id);
                
                set_title(editor_page.scheme_manager.get_scheme(id).get_name());
            } else {
                stack.set_visible_child(home_page);
                
                button_close.set_visible(false);
                button_create.set_visible(true);
                button_select.set_visible(true);
                button_save.set_visible(false);
                editor_page.close_scheme();
                home_page.update_page();
                
                set_title("Scheme Editor");
            }
        }
    }
}
