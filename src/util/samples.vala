using Gee;

namespace SchemeEditor {
    
    public class Samples {
        public HashMap<string, string> list { get; private set; }
        
        public Samples() {
            list = new HashMap<string, string>();
            
            load_samples();
        }
        
        private void load_samples() {
            list.set("c",
"""#include <gtk/gtk.h>
#include <curl/curl.h>

#include "dependency.h"
#include "dependency-row.h"
#include "androidprojectwizard.h"
#include "androidprojectwizard-window.h"

struct _WizardAppWindow {
    GtkApplicationWindow parent;
};

typedef struct _WizardAppWindowPrivate WizardAppWindowPrivate;

struct _WizardAppWindowPrivate {
    GSettings *settings;
    
    GtkListBox *dependencies;
    GtkRevealer *sidebar;
    
    GtkWidget *gears;
};

G_DEFINE_TYPE_WITH_PRIVATE(WizardAppWindow, wizard_app_window, GTK_TYPE_APPLICATION_WINDOW);

struct url_data {
    size_t size;
    char* data;
};

size_t write_data(void *ptr, size_t size, size_t nmemb, struct url_data *data) {
    size_t index = data->size;
    size_t n = (size * nmemb);
    char* tmp;

    data->size += (size * nmemb);

#ifdef DEBUG
    fprintf(stderr, "data at %p size=%ld nmemb=%ld\n", ptr, size, nmemb);
#endif
    tmp = realloc(data->data, data->size + 1); /* +1 for '\0' */

    if(tmp) {
        data->data = tmp;
    } else {
        if(data->data) {
            free(data->data);
        }
        fprintf(stderr, "Failed to allocate memory.\n");
        return 0;
    }

    memcpy((data->data + index), ptr, n);
    data->data[data->size] = '\0';

    return size * nmemb;
}

char *handle_url(char* url) {
    CURL *curl;

    struct url_data data;
    data.size = 0;
    data.data = malloc(4096); /* reasonable size initial buffer */
    if(NULL == data.data) {
        fprintf(stderr, "Failed to allocate memory.\n");
        return NULL;
    }

    data.data[0] = '\0';

    CURLcode res;

    curl = curl_easy_init();
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &data);
        res = curl_easy_perform(curl);
        if(res != CURLE_OK) {
                fprintf(stderr, "curl_easy_perform() failed: %s\n",  
                        curl_easy_strerror(res));
        }

        curl_easy_cleanup(curl);

    }
    return data.data;
}

void button_action(GtkWidget *widget, gpointer *data) {
    WizardAppWindowPrivate *priv;
    
    priv = (WizardAppWindowPrivate *) data;
    
    /*if (widget == priv->clear) {
        gtk_label_set_text (priv->output, "");
        gtk_entry_set_text(priv->input, "");
    } else if (widget == priv->save) {
        g_settings_set_value(priv->settings, "test-string", g_variant_new("s", gtk_entry_get_text (priv->input)));
    } else if (widget == priv->load) {
        gchar *result;
        g_variant_get(g_settings_get_value(priv->settings, "test-string"), "s", &result);
        gtk_label_set_text (priv->output, result);
        g_free(result);
    } else if (widget == priv->execute) {
        g_print("Get button\n");
        gchar *result;
        
        result = handle_url ("https://dl.google.com/android/maven2/androidx/recyclerview/group-index.xml");
        gtk_label_set_text (priv->response, result);
        g_free(result);
    }*/
}

static void activate_about(GSimpleAction *action, GVariant *parameter, gpointer user_data) {
    GtkWidget *win = user_data;
    
    gtk_show_about_dialog (GTK_WINDOW (win), "program-name", "Wizard", NULL);
}

static void wizard_app_window_init(WizardAppWindow *win) {
    WizardAppWindowPrivate *priv;
    GtkBuilder *builder;
    GMenuModel *menu;
    GAction *action;
    
    ProjectDependencyRow *row;
    ProjectDependency *dep;
    
    priv = wizard_app_window_get_instance_private(win);
    gtk_widget_init_template(GTK_WIDGET(win));
    priv->settings = g_settings_new("me.paladin.APW");
    
    g_settings_bind(
            priv->settings, "show-dependencies",
            priv->sidebar, "reveal-child",
            G_SETTINGS_BIND_DEFAULT
    );
    
    for (int i = 0; i < 10; i++) {
        dep = project_dependency_new("androidx.recyclerview", "recyclerview", "1.2.0-beta01", "enabled");
        row = project_dependency_row_new(dep);
        gtk_widget_show(GTK_WIDGET(row));
        gtk_container_add(GTK_CONTAINER(priv->dependencies), GTK_WIDGET(row));
    }
    
    //g_signal_connect(GTK_BUTTON (priv->clear), "clicked", G_CALLBACK(button_action), priv);
    //g_signal_connect(GTK_BUTTON (priv->load), "clicked", G_CALLBACK(button_action), priv);
    //g_signal_connect(GTK_BUTTON (priv->save), "clicked", G_CALLBACK(button_action), priv);
    //g_signal_connect(GTK_BUTTON (priv->execute), "clicked", G_CALLBACK(button_action), priv);
    
    builder = gtk_builder_new_from_resource("/me/paladin/APW/androidprojectwizard-gears-menu.ui");
    menu = G_MENU_MODEL (gtk_builder_get_object(builder, "menu"));
    gtk_menu_button_set_menu_model(GTK_MENU_BUTTON(priv->gears), menu);
    g_object_unref(builder);
    
    action = g_settings_create_action(priv->settings, "show-dependencies");
    g_action_map_add_action(G_ACTION_MAP(win), action);
    g_object_unref(action);
    
    action = (GAction*) g_simple_action_new ("about", NULL);
    g_signal_connect (action, "activate", G_CALLBACK (activate_about), NULL);
    g_action_map_add_action (G_ACTION_MAP (win), action);
    g_object_unref (action);
}

static void wizard_app_window_dispose(GObject *object) {
    WizardAppWindow *win;
    WizardAppWindowPrivate *priv;
    
    win = WIZARD_APP_WINDOW(object);
    priv = wizard_app_window_get_instance_private(win);
    
    g_clear_object(&priv->settings);
    
    G_OBJECT_CLASS(wizard_app_window_parent_class)->dispose(object);
}

static void wizard_app_window_class_init(WizardAppWindowClass *class) {
    G_OBJECT_CLASS(class)->dispose = wizard_app_window_dispose;

    gtk_widget_class_set_template_from_resource(
            GTK_WIDGET_CLASS(class),
            "/me/paladin/APW/androidprojectwizard-window.ui"
    );
    
    gtk_widget_class_bind_template_child_private(GTK_WIDGET_CLASS(class), WizardAppWindow, dependencies);
    gtk_widget_class_bind_template_child_private(GTK_WIDGET_CLASS(class), WizardAppWindow, sidebar);
    
    gtk_widget_class_bind_template_child_private(GTK_WIDGET_CLASS(class), WizardAppWindow, gears);
}

WizardAppWindow *wizard_app_window_new(WizardApp *app) {
  return g_object_new(WIZARD_APP_WINDOW_TYPE, "application", app, NULL);
}
""");
            list.set("java",
"""/* Block comment */
import java.util.Date;
import static AnInterface.CONSTANT;
import static java.util.Date.parse;
import static SomeClass.staticField;
/**
 * Doc comment here for <code>SomeClass</code>
 * @param T type parameter
 * @see Math#sin(double)
 */
@Annotation (name=value)
public class SomeClass<T extends Runnable> { // some comment
  private T field = null;
  private double unusedField = 12345.67890;
  private UnknownType anotherString = "Another\nStrin\g";
  public static int staticField = 0;
  public final int instanceFinalField = 0;

  /**
   * Semantic highlighting:
   * Generated spectrum to pick colors for local variables and parameters:
   *  Color#1 SC1.1 SC1.2 SC1.3 SC1.4 Color#2 SC2.1 SC2.2 SC2.3 SC2.4 Color#3
   *  Color#3 SC3.1 SC3.2 SC3.3 SC3.4 Color#4 SC4.1 SC4.2 SC4.3 SC4.4 Color#5
   * @param param1
   * @param reassignedParam
   * @param param2
   * @param param3
   */
  public SomeClass(AnInterface param1, int[] reassignedParam,
                  int param2
                  int param3) {
    int reassignedValue = this.staticField + param2 + param3;
    long localVar1, localVar2, localVar3, localVar4;
    int localVar = "IntelliJ"; // Error, incompatible types
    System.out.println(anotherString + toString() + localVar);
    long time = parse("1.2.3"); // Method is deprecated
    new Thread().countStackFrames(); // Method is deprecated and marked for removal
    reassignedValue ++; 
    field.run(); 
    new SomeClass() {
      {
        int a = localVar;
      }
    };
    reassignedParam = new ArrayList<String>().toArray(new int[CONSTANT]);
  }
}
enum AnEnum { CONST1, CONST2 }
interface AnInterface {
  int CONSTANT = 2;
  void method();
}
abstract class SomeAbstractClass {
  protected int instanceField = staticField;
}

class SomeClass extends BaseClass {
  private static final field = null;
  protected final otherField;

  public SomeClass(AnInterface param1, int[] reassignedParam,
                  int param2
                  int param3) {
    super(param1);
    this.field = param1;
    this.unused = null;
    return true || false;
  }
 }""");
            list.set("vala",
"""namespace SchemeEditor {
    
    [GtkTemplate (ui = "/me/paladin/SchemeEditor/prefs.ui")]
    public class ApplicationPreferences : Gtk.Dialog {
        private GLib.Settings settings;
        
        [GtkChild]
        private Gtk.FontButton font;
        
        [GtkChild]
        private Gtk.ComboBoxText transition;
        
        // App preferences
        public ApplicationPreferences(ApplicationWindow window) {
            GLib.Object(
                    transient_for: window,
                    use_header_bar: 1
            );
            
            settings = new GLib.Settings("me.paladin.SchemeEditor");
            
            settings.bind("font", font, "font", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("transition", transition, "active-id", GLib.SettingsBindFlags.DEFAULT);
            var str = "String";
            var bl = true;
            print(@"Hello from $str $bl\n");
        }
    }
}""");
            list.set("sh",
"""#!/usr/bin/env sh

#Sample comment
let "a=16 << 2";
b="Sample text";

function foo() {
  if [ $string1 == $string2 ]; then
    for url in `cat example.txt`; do
      curl $url > result.html
    done
  fi
}

rm -f $(find / -name core) &> /dev/null
mkdir -p "${AGENT_USER_HOME_${PLATFORM}}"

multiline='first line
           second line
           third line'
cat << EOF
 Sample text
EOF""");
            list.set("xml",
"""<?xml version='1.0' encoding='ISO-8859-1'  ?>
<!DOCTYPE index>
<!-- Some xml example -->
<index version="1.0" xmlns:pf="http://test">
   <name>Main Index</name>
   <indexitem text="rename" target="refactoring.rename"/>
   <indexitem text="move" target="refactoring.move"/>
   <indexitem text="migrate" target="refactoring.migrate"/>
   <indexitem text="usage search" target="find.findUsages"/>
   <indexitem>Matched tag name</indexitem>
   <someTextWithEntityRefs>&amp; &#x00B7;</someTextWithEntityRefs>
   <withCData><![CDATA[
          <object class="MyClass" key="constant">
          </object>
        ]]>
   </withCData>
   <indexitem text="project" target="project.management"/>
   <pf:foo pf:bar="bar"/>
</index>""");
            list.set("html",
"""<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<!--
*        Sample comment
-->
<HTML>
<head>
<title>Android Studio</title>
</head>
<body>
<h1>Android Studio</h1>
<p><br><b><IMG border=0 height=12 src="images/hg.gif" width=18 >
What is Android&nbsp;Studio? &#x00B7; &Alpha; </b><br><br>
</body>
</html>""");
            list.set("glsl",
"""#version 120
precision lowp int;
uniform vec3 normal; // surface normal
const vec3 light = vec3(5.0, 0.5, 1.0);

void shade(in vec3 light, in vec3 normal, out vec4 color);

struct PointLight{
    vec3 position;
    float intensity;
};

/* Fragment shader */
void main() {
#ifdef TEXTURED
    vec2 tex = gl_TexCoord[0].xy;
#endif
    float diffuse = dot(normal, light);
    if(diffuse < 0) {
        diffuse = -diffuse;
    }
    gl_FragColor = vec4(diffuse, diffuse, diffuse, 1.0);
}""");
            list.set("cpp",
"""/*
 * Block comment 
 */
#include <vector>

using namespace std;  // line comment
namespace foo {

  typedef struct Struct {
    int field;
  } Typedef;
  enum Enum {Foo = 1, Bar = 2};

  Typedef *globalVar;
  extern Typedef *externVar;

  template <typename T>
  concept Concept = requires (T t) {
    t.field;
  };

  template<typename T, int N>
  class Class {
    T n;
  public:
    /**
     * Semantic highlighting:
     * Generated spectrum to pick colors for local variables and parameters:
     *  Color#1 SC1.1 SC1.2 SC1.3 SC1.4 Color#2 SC2.1 SC2.2 SC2.3 SC2.4 Color#3
     *  Color#3 SC3.1 SC3.2 SC3.3 SC3.4 Color#4 SC4.1 SC4.2 SC4.3 SC4.4 Color#5
     */
    void function(int param1, int param2, int param3) {
      int localVar1, localVar2, localVar3;
      int *localVar = new int[1];
      this->n = N;
      localVar1 = param1 + param2 + localVar3;

    label:
      printf("Formatted string %d\n\g", localVar[0]);
      printf(R"**(Formatted raw-string %d\n)**", 1);
      std::cout << (1 << 2) << std::endl;  

    #define FOO(A) A
    #ifdef DEBUG
      printf("debug");
    #endif
    }
  };
}
""");
        }
    }
}
