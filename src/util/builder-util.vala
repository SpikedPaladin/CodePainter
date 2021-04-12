namespace SchemeEditor.BuilderUtil {
    
    public static T? load_object<T>(string resource, string object) {
        var builder = new Gtk.Builder.from_resource(@"/me/paladin/SchemeEditor/$resource");
        
        var ret = builder.get_object(object);
        
        return (T?) ret;
    }
}
