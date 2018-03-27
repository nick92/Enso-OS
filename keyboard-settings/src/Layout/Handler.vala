public class Pantheon.Keyboard.LayoutPage.LayoutHandler : GLib.Object {
    public HashTable<string, string> languages { public get; private set; }

    public LayoutHandler () {
        parse_layouts ();
    }

    construct {
        languages = new HashTable<string, string> (str_hash, str_equal);
    }

    private void parse_layouts () {
        Xml.Doc* doc = Xml.Parser.parse_file ("/usr/share/X11/xkb/rules/evdev.xml");
        if (doc == null) {
            critical ("'evdev.xml' not found or permissions missing\n");
            return;
        }

        Xml.XPath.Context cntx = new Xml.XPath.Context (doc);
        Xml.XPath.Object* res = cntx.eval_expression ("/xkbConfigRegistry/layoutList/layout/configItem");

        if (res == null) {
            delete doc;
            critical ("Unable to parse 'evdev.xml'");
            return;
        }

        if (res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null) {
            delete res;
            delete doc;
            critical ("No layouts found in 'evdev.xml'");
            return;
        }

        for (int i = 0; i < res->nodesetval->length (); i++) {
            Xml.Node* node = res->nodesetval->item (i);
            string? name = null;
            string? description = null;
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                    if (iter->name == "name") {
                        name = iter->get_content ();
                    } else if (iter->name == "description") {
                        description = dgettext ("xkeyboard-config", iter->get_content ());
                    }
                }
            }
            if (name != null && description != null) {
                languages.set (name, description);
            }
        }

        delete res;
        delete doc;
    }

    public HashTable<string, string> get_variants_for_language (string language) {
        var returned_table = new HashTable<string, string> (str_hash, str_equal);
        returned_table.set ("", _("Default"));
        Xml.Doc* doc = Xml.Parser.parse_file ("/usr/share/X11/xkb/rules/evdev.xml");
        if (doc == null) {
            critical ("'evdev.xml' not found or permissions incorrect\n");
            return returned_table;
        }

        Xml.XPath.Context cntx = new Xml.XPath.Context (doc);
        var xpath = @"/xkbConfigRegistry/layoutList/layout/configItem/name[text()='$language']/../../variantList/variant/configItem";
        Xml.XPath.Object* res = cntx.eval_expression (xpath);

        if (res == null) {
            delete doc;
            critical ("Unable to parse 'evdev.xml'");
            return returned_table;
        }

        if (res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null) {
            delete res;
            delete doc;
            warning (@"No variants for $language found in 'evdev.xml'");
            return returned_table;
        }

        for (int i = 0; i < res->nodesetval->length (); i++) {
            Xml.Node* node = res->nodesetval->item (i);

            string? name = null;
            string? description = null;
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                    if (iter->name == "name") {
                        name = iter->get_content ();
                    } else if (iter->name == "description") {
                        description = dgettext ("xkeyboard-config", iter->get_content ());
                    }
                }
            }
            if (name != null && description != null) {
                returned_table.set (name, description);
            }
        }

        delete res;
        delete doc;

        return returned_table;
    }

    public string get_display_name (string variant) {
        if ("+" in variant) {
            var parts = variant.split ("+", 2);
            return get_variants_for_language (parts[0]).get (parts[1]);
        } else {
            return languages.get (variant);
        }
    }
}
