namespace CodePainter {
    
    public class FontUtil {
        
        public static void update_font(Gtk.CssProvider provider, string font) {
            try {
                provider.load_from_data(css_from_font(font));
            } catch (Error e) {
                print("Error while updating font: " + e.message);
            }
        }
        
        private static string css_from_font(string font) {
            Pango.FontDescription desc = Pango.FontDescription.from_string(font);
            Pango.FontMask mask;
            string css = "* { ";
            
            mask = desc.get_set_fields();
            
            if (Pango.FontMask.FAMILY in mask) {
                css += "font-family: ";
                css += desc.get_family();
                css += "; ";
            }
            if (Pango.FontMask.STYLE in mask) {
                switch (desc.get_style()) {
                    case Pango.Style.NORMAL:
                        css += "font-style: normal; ";
                        break;
                    case Pango.Style.OBLIQUE:
                        css += "font-style: oblique; ";
                        break;
                    case Pango.Style.ITALIC:
                        css += "font-style: italic; ";
                        break;
                }
            }
            if (Pango.FontMask.VARIANT in mask) {
                switch (desc.get_variant()) {
                    case Pango.Variant.NORMAL:
                        css += "font-variant: normal; ";
                        break;
                    case Pango.Variant.SMALL_CAPS:
                        css += "font-variant: small-caps; ";
                        break;
                }
            }
            if (Pango.FontMask.WEIGHT in mask) {
                switch (desc.get_weight()) {
                    case Pango.Weight.THIN:
                        css += "font-weight: 100; ";
                        break;
                    case Pango.Weight.ULTRALIGHT:
                        css += "font-weight: 200; ";
                        break;
                    case Pango.Weight.LIGHT, Pango.Weight.SEMILIGHT:
                        css += "font-weight: 300; ";
                        break;
                    case Pango.Weight.BOOK, Pango.Weight.NORMAL:
                        css += "font-weight: 400; ";
                        break;
                    case Pango.Weight.MEDIUM:
                        css += "font-weight: 500; ";
                        break;
                    case Pango.Weight.SEMIBOLD:
                        css += "font-weight: 600; ";
                        break;
                    case Pango.Weight.BOLD:
                        css += "font-weight: 700; ";
                        break;
                    case Pango.Weight.ULTRABOLD:
                        css += "font-weight: 800; ";
                        break;
                    case Pango.Weight.HEAVY, Pango.Weight.ULTRAHEAVY:
                        css += "font-weight: 900; ";
                        break;
                }
            }
            if (Pango.FontMask.STRETCH in mask) {
                switch (desc.get_stretch()) {
                    case Pango.Stretch.ULTRA_CONDENSED:
                        css += "font-stretch: ultra-condensed; ";
                        break;
                    case Pango.Stretch.EXTRA_CONDENSED:
                        css += "font-stretch: extra-condensed; ";
                        break;
                    case Pango.Stretch.CONDENSED:
                        css += "font-stretch: condensed; ";
                        break;
                    case Pango.Stretch.SEMI_CONDENSED:
                        css += "font-stretch: semi-condensed; ";
                        break;
                    case Pango.Stretch.NORMAL:
                        css += "font-stretch: normal; ";
                        break;
                    case Pango.Stretch.SEMI_EXPANDED:
                        css += "font-stretch: semi-expanded; ";
                        break;
                    case Pango.Stretch.EXPANDED:
                        css += "font-stretch: expanded; ";
                        break;
                    case Pango.Stretch.EXTRA_EXPANDED:
                        css += "font-stretch: extra-expanded; ";
                        break;
                    case Pango.Stretch.ULTRA_EXPANDED:
                        css += "font-stretch: ultra-expanded; ";
                        break;
                }
            }
            
            if (Pango.FontMask.SIZE in mask) {
                var size = desc.get_size() / Pango.SCALE;
                css += @"font-size: $(size)pt";
            }
            
            css += "}";
            
            return css;
        }
    }
}
