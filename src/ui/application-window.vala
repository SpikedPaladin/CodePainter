using Gee;

namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/window.ui")]
    public class ApplicationWindow : Gtk.ApplicationWindow {
        private Gtk.SourceStyleSchemeManager scheme_manager;
        private Gtk.SourceLanguageManager language_manager;
        private Gtk.SourceStyleScheme current_scheme;
        private Gtk.SourceBuffer source_buffer;
        private HashMap<string, Style> styles;
        private Gtk.CssProvider provider;
        
        private string current_language;
        private string current_style_id;
        private Settings settings;
        private Samples samples;
        
        private string temp_scheme_id;
        private string temp_scheme_file;
        
        private ulong toggle_bold_handler;
        private ulong toggle_italic_handler;
        private ulong toggle_underline_handler;
        private ulong toggle_strikethrough_handler;
        private ulong check_foreground_handler;
        private ulong check_background_handler;
        
        private string? original_file;
        
        [GtkChild]
        private unowned Gtk.MenuButton gears;
        
        [GtkChild]
        private unowned Gtk.SourceView source_view;
        
        [GtkChild]
        private unowned Gtk.ListStore style_store;
        [GtkChild]
        private unowned Gtk.ListStore language_store;
        [GtkChild]
        private unowned Gtk.TreeView tree_view_styles;
        
        [GtkChild]
        private unowned Gtk.Popover language_popover;
        [GtkChild]
        private unowned Gtk.TreeModelFilter language_filter;
        [GtkChild]
        private unowned Gtk.SearchEntry language_search;
        [GtkChild]
        private unowned Gtk.TreeView language_list;
        [GtkChild]
        private unowned Gtk.Label language_name;
        
        [GtkChild]
        private unowned Gtk.Entry entry_name;
        [GtkChild]
        private unowned Gtk.Entry entry_id;
        [GtkChild]
        private unowned Gtk.Entry entry_description;
        [GtkChild]
        private unowned Gtk.Entry entry_author;
        
        [GtkChild]
        private unowned Gtk.Button button_clear;
        [GtkChild]
        private unowned Gtk.ToggleButton toggle_bold;
        [GtkChild]
        private unowned Gtk.ToggleButton toggle_italic;
        [GtkChild]
        private unowned Gtk.ToggleButton toggle_underline;
        [GtkChild]
        private unowned Gtk.ToggleButton toggle_strikethrough;
        [GtkChild]
        private unowned Gtk.ColorButton color_foreground;
        [GtkChild]
        private unowned Gtk.CheckButton check_foreground;
        [GtkChild]
        private unowned Gtk.ColorButton color_background;
        [GtkChild]
        private unowned Gtk.CheckButton check_background;
        
        public ApplicationWindow(Gtk.Application application) {
            Object(application: application);
            
            // Fix 'Invalid object type GtkSourceView' error
            typeof(Gtk.SourceView).ensure();
            
            provider = new Gtk.CssProvider();
            settings = new Settings("me.paladin.SchemeEditor");
            settings.changed["font"].connect(() => FontUtil.update_font(provider, settings.get_string("font")));
            
            source_buffer = new Gtk.SourceBuffer(null);
            source_buffer.set_max_undo_levels(0);
            source_view.set_buffer(source_buffer);
            source_view.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            FontUtil.update_font(provider, settings.get_string("font"));
            
            styles = new HashMap<string, Style>();
            samples = new Samples();
            
            scheme_manager = new Gtk.SourceStyleSchemeManager();
            language_manager = new Gtk.SourceLanguageManager();
            
            scheme_manager.append_search_path(Environment.get_tmp_dir());
            
            load_scheme();
            
            toggle_bold_handler = toggle_bold.toggled.connect(on_style_changed);
            toggle_italic_handler = toggle_italic.toggled.connect(on_style_changed);
            toggle_underline_handler = toggle_underline.toggled.connect(on_style_changed);
            toggle_strikethrough_handler = toggle_strikethrough.toggled.connect(on_style_changed);
            
            color_foreground.color_set.connect(on_style_changed);
            color_background.color_set.connect(on_style_changed);
            
            check_foreground_handler = check_foreground.toggled.connect(on_foreground_toggled);
            check_background_handler = check_background.toggled.connect(on_background_toggled);
            
            language_search.search_changed.connect(() => language_filter.refilter());
            language_filter.set_visible_func((model, iter) => {
                string language_name;
                
                model.get(iter, 0, out language_name);
                
                if (language_search.text == "")
                    return true;
                
                if (language_name.down().index_of(language_search.text.down()) > -1)
                    return true;
                
                return false;
            });
            
            Gtk.TreeIter iter;
            language_store.append(out iter);
            language_store.set(iter, 0, "def");
            language_store.set(iter, 1, "Defaults");
            foreach (var language in language_manager.get_language_ids()) {
                if (language == "def") continue;
                
                language_store.append(out iter);
                language_store.set(iter, 0, language);
                language_store.set(iter, 1, language_manager.get_language(language).get_name());
            }
            
            language_list.get_model().get_iter_first(out iter);
            language_list.get_selection().select_iter(iter);
            language_list.row_activated.connect(on_language_selected);
            tree_view_styles.get_selection().changed.connect(on_style_selected);
            on_language_selected();
            
            var builder = new Gtk.Builder.from_resource("/me/paladin/SchemeEditor/ui/gears-menu.ui");
            var menu = builder.get_object("menu") as MenuModel;
            
            var action = new SimpleAction("save-as", null);
            action.activate.connect(save_as);
            add_action(action);
            
            action = new SimpleAction("preferences", null);
            action.activate.connect(() => new ApplicationPreferences(this).present());
            add_action(action);
            
            action = new SimpleAction("inspector", null);
            action.activate.connect(() => Gtk.Window.set_interactive_debugging(true));
            add_action(action);
            
            gears.set_menu_model(menu);
        }
        
        [GtkCallback]
        private void on_save_clicked() {
            if (original_file == null)
                save_as();
            else
                write_scheme(original_file);
        }
        
        private void save_as() {
            var file_chooser = new Gtk.FileChooserDialog(
                "Save",
                this,
                Gtk.FileChooserAction.SAVE,
                "_Cancel",
                Gtk.ResponseType.CANCEL,
                "_Save",
                Gtk.ResponseType.OK
            );
            
            file_chooser.response.connect((dialog, response) => {
                var save_dialog = dialog as Gtk.FileChooserDialog;
                
                if (response == Gtk.ResponseType.OK)
                    write_scheme(original_file = save_dialog.get_file().get_path());
                
                dialog.destroy();
            });
            file_chooser.show();
        }
        
        [GtkCallback]
        private void on_open_clicked() {
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
                    load_scheme(open_dialog.get_file().get_path());
                
                dialog.destroy();
            });
            file_chooser.show();
        }
        
        private void on_foreground_toggled() {
            if (check_foreground.get_active()) {
                color_foreground.set_sensitive(true);
                color_foreground.activate();
                
                button_clear.set_sensitive(true);
            } else {
                color_foreground.set_rgba({ 0, 0, 0, 1 });
                color_foreground.set_sensitive(false);
                styles[current_style_id].foreground = null;
                clear_style_if_empty(current_style_id);
                update_preview();
            }
        }
        
        private void on_background_toggled() {
            if (check_background.get_active()) {
                color_background.set_sensitive(true);
                color_background.activate();
                
                button_clear.set_sensitive(true);
            } else {
                color_background.set_rgba({ 0, 0, 0, 1 });
                color_background.set_sensitive(false);
                styles[current_style_id].background = null;
                clear_style_if_empty(current_style_id);
                update_preview();
            }
        }
        
        [GtkCallback]
        private void on_clear_clicked() {
            if (current_style_id in styles.keys) {
                clear_style_buttons();
            }
        }
        
        private void on_style_changed(Gtk.Widget widget) {
            if (!(current_style_id in styles.keys))
                styles.set(current_style_id, new Style());
            
            if (widget == color_foreground) {
                var color = get_color_from_rgba(color_foreground.get_rgba());
                styles[current_style_id].foreground = color;
            } else if (widget == color_background) {
                var color = get_color_from_rgba(color_background.get_rgba());
                styles[current_style_id].background = color;
            } else if (widget == toggle_bold)
                styles[current_style_id].bold = toggle_bold.get_active();
            else if (widget == toggle_italic)
                styles[current_style_id].italic = toggle_italic.get_active();
            else if (widget == toggle_underline)
                styles[current_style_id].underline = toggle_underline.get_active();
            else if (widget == toggle_strikethrough)
                styles[current_style_id].strikethrough = toggle_strikethrough.get_active();
            
            var toggle_button = widget as Gtk.ToggleButton;
            if (toggle_button != null) {
                if (toggle_button.get_active()) {
                    button_clear.set_sensitive(true);
                }
            }
            
            clear_style_if_empty(current_style_id);
            update_preview();
        }
        
        private bool load_scheme(string scheme = "cobalt") {
            Gtk.SourceStyleScheme style_scheme = null;
            
            if (scheme.contains("/")) {
                var file = File.new_for_path(scheme);
                var directory = file.get_parent().get_path();
                if (!(directory in scheme_manager.get_search_path()))
                    scheme_manager.prepend_search_path(directory);
                
                string scheme_id = get_scheme_id(file.get_path());
                
                if (scheme_id == null)
                    return false;
                
                original_file = file.get_path();
                style_scheme = scheme_manager.get_scheme(scheme_id);
            } else {
                style_scheme = scheme_manager.get_scheme(scheme);
                if (style_scheme == null)
                    return false;
            }
            
            current_scheme = style_scheme;
            
            styles.clear();
            load_styles(current_scheme.get_filename());
            
            entry_name.set_text(current_scheme.get_name());
            entry_id.set_text(current_scheme.get_id());
            entry_description.set_text(current_scheme.get_description());
            entry_author.set_text(string.joinv(", ", current_scheme.get_authors()));
            
            source_buffer.set_style_scheme(current_scheme);
            
            temp_scheme_id = current_scheme.get_id() + "_temp";
            temp_scheme_file = @"$(Environment.get_tmp_dir())/$temp_scheme_id.xml";
            
            return true;
        }
        
        private void load_styles(string path) {
            Xml.Parser.init();
            
            Xml.Doc* doc = Xml.Parser.parse_file(path);
            
            for (Xml.Node* iter = doc->get_root_element()->children; iter != null; iter = iter->next) {
                if (iter->type != Xml.ElementType.ELEMENT_NODE || iter->name != "style")
                    continue;
                
                for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next) {
                    if (prop->name == "name") {
                        var style_name = prop->children->content;
                        
                        styles.set(style_name, new Style.from_source_style(current_scheme.get_style(style_name)));
                        break;
                    }
                }
            }
            
            Xml.Parser.cleanup();
        }
        
        // TODO rewrite with libxml
        private bool write_scheme(string path, string? scheme_id = null) {
            var output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
            output += @"<style-scheme id=\"$(scheme_id ?? entry_id.get_text())\" name=\"$(entry_name.get_text())\" version=\"1.0\">\n";
            output += @"    <author>$(entry_author.get_text())</author>\n";
            output += @"    <description>$(entry_description.get_text())</description>\n    \n";
            
            foreach (var entry in styles.entries) {
                output += @"    <style name=\"$(entry.key)\"";
                
                if (entry.value.foreground != null)
                    output += @" foreground=\"$(entry.value.foreground)\"";
                if (entry.value.background != null)
                    output += @" background=\"$(entry.value.background)\"";
                if (entry.value.italic)
                    output += " italic=\"true\"";
                if (entry.value.bold)
                    output += " bold=\"true\"";
                if (entry.value.underline)
                    output += " underline=\"true\"";
                if (entry.value.strikethrough)
                    output += " strikethrough=\"true\"";
                
                output += "/>\n";
            }
            
            output += "</style-scheme>";
            
            try {
                FileUtils.set_contents(path, output);
                return true;
            } catch (FileError er) {
                print(er.message);
                return false;
            }
        }
        
        private void on_style_selected(Gtk.TreeSelection selection) {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            
            if (selection.get_selected(out model, out iter)) {
                model.get(iter, 0, out current_style_id);
                current_style_id = @"$current_language:$current_style_id";
                
                if (!(current_style_id in styles.keys) && current_language == "def") {
                    model.get(iter, 0, out current_style_id);
                }
                
                SignalHandler.block(toggle_bold, toggle_bold_handler);
                SignalHandler.block(toggle_italic, toggle_italic_handler);
                SignalHandler.block(toggle_underline, toggle_underline_handler);
                SignalHandler.block(toggle_strikethrough, toggle_strikethrough_handler);
                SignalHandler.block(check_foreground, check_foreground_handler);
                SignalHandler.block(check_background, check_background_handler);
                
                if (current_style_id in styles.keys) {
                    var style = styles[current_style_id];
                    
                    if (style.foreground != null) {
                        var foreground = Gdk.RGBA();
                        foreground.parse(style.foreground);
                        
                        color_foreground.set_rgba(foreground);
                        color_foreground.set_sensitive(true);
                        check_foreground.set_active(true);
                    } else {
                        color_foreground.set_rgba({ 0, 0, 0, 1 });
                        color_foreground.set_sensitive(false);
                        check_foreground.set_active(false);
                    }
                    
                    if (style.background != null) {
                        var background = Gdk.RGBA();
                        background.parse(style.background);
                        
                        color_background.set_rgba(background);
                        color_background.set_sensitive(true);
                        check_background.set_active(true);
                    } else {
                        color_background.set_rgba({ 0, 0, 0, 1 });
                        color_background.set_sensitive(false);
                        check_background.set_active(false);
                    }
                    
                    toggle_italic.set_active(style.italic);
                    toggle_bold.set_active(style.bold);
                    toggle_underline.set_active(style.underline);
                    toggle_strikethrough.set_active(style.strikethrough);
                    button_clear.set_sensitive(true);
                } else
                    clear_style_buttons();
                
                SignalHandler.unblock(toggle_bold, toggle_bold_handler);
                SignalHandler.unblock(toggle_italic, toggle_italic_handler);
                SignalHandler.unblock(toggle_underline, toggle_underline_handler);
                SignalHandler.unblock(toggle_strikethrough, toggle_strikethrough_handler);
                SignalHandler.unblock(check_foreground, check_foreground_handler);
                SignalHandler.unblock(check_background, check_background_handler);
            }
        }
        
        private void on_language_selected() {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            
            if (language_list.get_selection().get_selected(out model, out iter)) {
                model.get(iter, 0, out current_language);
                
                style_store.clear();
                
                var language = language_manager.get_language(current_language);
                
                ArrayList<string> style_ids = new ArrayList<string>.wrap(language.get_style_ids());
                style_ids.sort((a, b) => a.collate(b));
                
                if (current_language == "def") {
                    string[] gui_style_ids = {
                            "text",
                            "selection",
                            "selection-unfocused",
                            "cursor",
                            "secondary-cursor",
                            "current-line",
                            "line-numbers",
                            "current-line-number",
                            "bracket-match",
                            "bracket-mismatch",
                            "right-margin",
                            "draw-spaces",
                            "background-pattern"
                    };
                    
                    foreach (var style in gui_style_ids) {
                        style_store.append(out iter);
                        
                        style_store.set(iter, 0, style);
                    }
                }
                
                foreach (var style in style_ids) {
                    style_store.append(out iter);
                    
                    style_store.set(iter, 0, style.substring(style.last_index_of(":") + 1));
                }
                
                if (style_ids != null && style_ids.size > 0) {
                    tree_view_styles.get_model().get_iter_first(out iter);
                    tree_view_styles.get_selection().select_iter(iter);
                }
                
                if (current_language in samples.list.keys) {
                    source_buffer.set_language(language_manager.get_language(current_language));
                    source_buffer.set_text(samples.list[current_language]);
                } else {
                    var default_language = settings.get_string("default-language");
                    source_buffer.set_language(language_manager.get_language(default_language));
                    source_buffer.set_text(samples.list[default_language]);
                }
                
                language_name.set_text(language.get_name());
                language_popover.popdown();
            }
        }
        
        private void clear_style_buttons() {
            color_foreground.set_rgba({ 0, 0, 0, 1 });
            color_background.set_rgba({ 0, 0, 0, 1 });
            
            color_foreground.set_sensitive(false);
            color_background.set_sensitive(false);
            
            check_foreground.set_active(false);
            check_background.set_active(false);
            
            toggle_bold.set_active(false);
            toggle_italic.set_active(false);
            toggle_underline.set_active(false);
            toggle_strikethrough.set_active(false);
            
            button_clear.set_sensitive(false);
        }
        
        private void clear_style_if_empty(string style_id) {
            if (!(style_id in styles.keys))
                return;
            
            if (styles[style_id].is_empty()) {
                styles.unset(style_id);
                clear_style_buttons();
            }
        }
        
        private void update_preview() {
            write_scheme(temp_scheme_file, temp_scheme_id);
            
            scheme_manager.force_rescan();
            
            source_buffer.set_style_scheme(scheme_manager.get_scheme(temp_scheme_id));
        }
        
        private string? get_scheme_id(string path) {
            Xml.Parser.init();
            
            Xml.Doc* doc = Xml.Parser.parse_file(path);
            if (doc == null) {
                Xml.Parser.cleanup();
                print(@"File $path not found or permissions missing");
                return null;
            }
            
            Xml.Node* root = doc->get_root_element();
            if (root == null) {
                delete doc;
                Xml.Parser.cleanup();
                print(@"The xml file '$path' is empty");
                return null;
            }
            
            if (root->name != "style-scheme") {
                delete doc;
                Xml.Parser.cleanup();
                print(@"The xml file '$path' is not a style scheme");
                return null;
            }
            
            string scheme_id = root->get_prop("id");
            if (scheme_id == null) {
                delete doc;
                Xml.Parser.cleanup();
                print(@"ID not found in file '$path'");
                return null;
            }
            
            delete doc;
            
            Xml.Parser.cleanup();
            
            return scheme_id;
        }
        
        private string get_color_from_rgba(Gdk.RGBA rgba) {
            return "#%02X%02X%02X".printf(
                    (int)(0.5 + rgba.red * 255),
                    (int)(0.5 + rgba.green * 255),
                    (int)(0.5 + rgba.blue * 255)
            );
        }
    }
}
