using Gee;

namespace CodePainter {
    
    public class XmlUtil {
        
        public static void load_styles(
            ref Gtk.SourceStyleScheme scheme,
            ref HashMap<string, Style> styles
        ) {
            styles.clear();
            Xml.Parser.init();
            
            Xml.Doc* doc = Xml.Parser.parse_file(scheme.get_filename());
            
            for (Xml.Node* iter = doc->get_root_element()->children; iter != null; iter = iter->next) {
                if (iter->type != Xml.ElementType.ELEMENT_NODE || iter->name != "style")
                    continue;
                
                for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next) {
                    if (prop->name == "name") {
                        var style_name = prop->children->content;
                        
                        styles.set(style_name, new Style.from_source_style(scheme.get_style(style_name)));
                        break;
                    }
                }
            }
            
            delete doc;
            
            Xml.Parser.cleanup();
        }
        
        public static void write_scheme(
            string path,
            string id,
            string name,
            string author,
            string description,
            HashMap<string, Style>? styles = null
        ) {
            var writer = new Xml.TextWriter.filename(path);
            writer.set_indent(true);
            writer.set_indent_string("  ");
            
            writer.start_document("1.0", "UTF-8");
            writer.start_element("style-scheme");
            writer.write_attribute("id", id);
            writer.write_attribute("name", name);
            writer.write_attribute("version", "1.0");
            
            if (author != "")
                writer.write_element("author", author);
            
            if (description != "")
                writer.write_element("description", description);
            
            if (styles != null) {
                foreach (var entry in styles.entries) {
                    writer.start_element("style");
                    writer.write_attribute("name", entry.key);
                    
                    if (entry.value.foreground != null)
                        writer.write_attribute("foreground", entry.value.foreground);
                    if (entry.value.background != null)
                        writer.write_attribute("background", entry.value.background);
                    if (entry.value.bold)
                        writer.write_attribute("bold", "true");
                    if (entry.value.italic)
                        writer.write_attribute("italic", "true");
                    if (entry.value.underline)
                        writer.write_attribute("underline", "true");
                    if (entry.value.strikethrough)
                        writer.write_attribute("strikethrough", "true");
                    
                    writer.end_element();
                }
            }
            
            writer.end_element();
            writer.end_document();
            
            writer.flush();
        }
        
        public static string? get_scheme_id(string path) {
            Xml.Parser.init();
            
            Xml.Doc* doc = Xml.Parser.parse_file(path);
            if (doc == null) {
                Xml.Parser.cleanup();
                print(@"File $path not found or permissions missing\n");
                return null;
            }
            
            Xml.Node* root = doc->get_root_element();
            if (root == null) {
                delete doc;
                Xml.Parser.cleanup();
                print(@"The xml file '$path' is empty\n");
                return null;
            }
            
            if (root->name != "style-scheme") {
                delete doc;
                Xml.Parser.cleanup();
                print(@"The xml file '$path' is not a style scheme\n");
                return null;
            }
            
            string scheme_id = root->get_prop("id");
            if (scheme_id == null) {
                delete doc;
                Xml.Parser.cleanup();
                print(@"ID not found in file '$path'\n");
                return null;
            }
            
            delete doc;
            
            Xml.Parser.cleanup();
            
            return scheme_id;
        }
    }
}
