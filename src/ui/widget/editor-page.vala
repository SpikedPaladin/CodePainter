using Gee;

namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/ui/editor-page.ui")]
    public class EditorPage : Gtk.Box {
        public unowned Gtk.SourceLanguageManager language_manager {
            get {
                return Gtk.SourceLanguageManager.get_default();
            }
        }
        
        public unowned Gtk.SourceStyleSchemeManager scheme_manager {
            get {
                return Gtk.SourceStyleSchemeManager.get_default();
            }
        }
        
        private Samples samples = new Samples();
        private HashMap<string, Style> styles;
        private Settings settings;
        
        private string current_language;
        private string current_scheme;
        private string current_style;
        
        private string temp_path;
        
        private ulong toggle_bold_handler;
        private ulong toggle_italic_handler;
        private ulong toggle_underline_handler;
        private ulong toggle_strikethrough_handler;
        private ulong check_foreground_handler;
        private ulong check_background_handler;
        
        [GtkChild]
        private unowned Gtk.Popover language_popover;
        [GtkChild]
        private unowned Gtk.TreeModelFilter language_filter;
        [GtkChild]
        private unowned Gtk.SearchEntry language_search;
        [GtkChild]
        private unowned Gtk.ListStore language_store;
        [GtkChild]
        private unowned Gtk.TreeView language_list;
        [GtkChild]
        private unowned Gtk.Label language_name;
        
        [GtkChild]
        private unowned Gtk.ListStore style_store;
        [GtkChild]
        private unowned Gtk.TreeView style_list;
        
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
        [GtkChild]
        private unowned Gtk.Button button_clear;
        
        [GtkChild]
        private unowned Gtk.Entry entry_name;
        [GtkChild]
        private unowned Gtk.Entry entry_id;
        [GtkChild]
        private unowned Gtk.Entry entry_description;
        [GtkChild]
        private unowned Gtk.Entry entry_author;
        
        [GtkChild]
        private unowned Gtk.SourceView preview;
        private Gtk.SourceBuffer buffer;
        
        construct {
            settings = new Settings("me.paladin.SchemeEditor");
            var provider = new Gtk.CssProvider();
            
            settings.changed["font"].connect(() =>
                    FontUtil.update_font(provider, settings.get_string("font"))
            );
            
            preview.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            FontUtil.update_font(provider, settings.get_string("font"));
            
            buffer = new Gtk.SourceBuffer(null);
            buffer.set_max_undo_levels(0);
            preview.set_buffer(buffer);
            
            styles = new HashMap<string, Style>();
            
            temp_path = @"$(Environment.get_tmp_dir())/SchemeEditor";
            if (!FileUtils.test(temp_path, FileTest.EXISTS)) {
                try {
                    File dir = File.new_for_path(temp_path);
                    dir.make_directory();
                } catch (Error e) {
                    print("%s\n", e.message);
                }
            }
            
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
                if (language_search.text == "")
                    return true;
                
                string language_name;
                
                model.get(iter, 0, out language_name);
                
                if (language_name.down().index_of(language_search.text.down()) > -1)
                    return true;
                
                return false;
            });
            
            Gtk.TreeIter iter;
            language_store.append(out iter);
            language_store.set(iter, 0, "def", 1, "Defaults");
            foreach (var language in language_manager.get_language_ids()) {
                if (language == "def") continue;
                
                language_store.append(out iter);
                language_store.set(iter, 
                        0, language,
                        1, language_manager.get_language(language).get_name()
                );
            }
        }
        
        public override void destroy() {
            if (FileUtils.test(temp_path, FileTest.EXISTS)) {
                try {
                    File dir = File.new_for_path(temp_path);
                    if (current_scheme != null && FileUtils.test(temp_path + @"/$(current_scheme)_temp.xml", FileTest.EXISTS)) {
                        File file = File.new_for_path(temp_path + @"/$(current_scheme)_temp.xml");
                        file.delete();
                    }
                    dir.delete();
                } catch (Error e) {
                    print("%s\n", e.message);
                }
            }
        }
        
        public void load_scheme(string id) {
            Gtk.SourceStyleScheme scheme = scheme_manager.get_scheme(id);
            current_scheme = id;
            
            XmlUtil.load_styles(ref scheme, ref styles);
            
            entry_name.set_text(scheme.get_name());
            entry_id.set_text(id);
            entry_description.set_text(scheme.get_description() ?? "");
            entry_author.set_text(string.joinv(", ", scheme.get_authors()) ?? "");
            
            buffer.set_style_scheme(scheme);
            
            scheme_manager.append_search_path(temp_path);
            
            Gtk.TreeIter iter;
            language_list.get_model().get_iter_first(out iter);
            language_list.get_selection().select_iter(iter);
            on_language_selected();
        }
        
        public void save_scheme() {
            if (current_scheme != null)
                write_scheme(scheme_manager.get_scheme(current_scheme).get_filename());
        }
        
        public void close_scheme() {
            File file = File.new_for_path(temp_path + @"/$(current_scheme)_temp.xml");
            file.delete_async.begin();
            
            current_scheme = null;
            
            scheme_manager.set_search_path(null);
        }
        
        [GtkCallback]
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
                        
                        style_store.set(iter, 0, style, 1, style);
                    }
                }
                
                foreach (var style in style_ids) {
                    style_store.append(out iter);
                    
                    style_store.set(iter, 0, style, 1, style.substring(style.last_index_of(":") + 1));
                }
                
                if (style_ids.size > 0) {
                    style_store.get_iter_first(out iter);
                    style_list.get_selection().select_iter(iter);
                }
                
                if (current_language in samples.list.keys) {
                    buffer.set_language(language_manager.get_language(current_language));
                    buffer.text = samples.list[current_language];
                } else {
                    var default_language = settings.get_string("default-language");
                    buffer.set_language(language_manager.get_language(default_language));
                    buffer.text = samples.list[default_language];
                }
                
                language_name.set_text(language.get_name());
                language_popover.popdown();
            }
        }
        
        [GtkCallback]
        private void on_style_selected(Gtk.TreeSelection selection) {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            
            if (selection.get_selected(out model, out iter)) {
                model.get(iter, 0, out current_style);
                
                SignalHandler.block(toggle_bold, toggle_bold_handler);
                SignalHandler.block(toggle_italic, toggle_italic_handler);
                SignalHandler.block(toggle_underline, toggle_underline_handler);
                SignalHandler.block(toggle_strikethrough, toggle_strikethrough_handler);
                SignalHandler.block(check_foreground, check_foreground_handler);
                SignalHandler.block(check_background, check_background_handler);
                
                if (current_style in styles.keys) {
                    var style = styles[current_style];
                    
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
        
        private void on_style_changed(Gtk.Widget widget) {
            if (!(current_style in styles.keys))
                styles.set(current_style, new Style());
            
            if (widget == color_foreground) {
                var color = get_color_from_rgba(color_foreground.get_rgba());
                styles[current_style].foreground = color;
            } else if (widget == color_background) {
                var color = get_color_from_rgba(color_background.get_rgba());
                styles[current_style].background = color;
            } else if (widget == toggle_bold)
                styles[current_style].bold = toggle_bold.get_active();
            else if (widget == toggle_italic)
                styles[current_style].italic = toggle_italic.get_active();
            else if (widget == toggle_underline)
                styles[current_style].underline = toggle_underline.get_active();
            else if (widget == toggle_strikethrough)
                styles[current_style].strikethrough = toggle_strikethrough.get_active();
            
            var toggle_button = widget as Gtk.ToggleButton;
            if (toggle_button != null) {
                if (toggle_button.get_active()) {
                    button_clear.set_sensitive(true);
                }
            }
            
            clear_style_if_empty(current_style);
            update_preview();
        }
        
        private void on_foreground_toggled() {
            if (check_foreground.get_active()) {
                color_foreground.set_sensitive(true);
                color_foreground.activate();
                
                button_clear.set_sensitive(true);
            } else {
                color_foreground.set_rgba({ 0, 0, 0, 1 });
                color_foreground.set_sensitive(false);
                styles[current_style].foreground = null;
                clear_style_if_empty(current_style);
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
                styles[current_style].background = null;
                clear_style_if_empty(current_style);
                update_preview();
            }
        }
        
        [GtkCallback]
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
        
        private void write_scheme(string path, string? id = null) {
            XmlUtil.write_scheme(
                path,
                id ?? entry_id.get_text(),
                entry_name.get_text(),
                entry_author.get_text(),
                entry_description.get_text(),
                styles
            );
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
            var temp_id = current_scheme + "_temp";
            write_scheme(temp_path + @"/$(current_scheme)_temp.xml", temp_id);
            
            scheme_manager.force_rescan();
            
            buffer.set_style_scheme(scheme_manager.get_scheme(temp_id));
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
