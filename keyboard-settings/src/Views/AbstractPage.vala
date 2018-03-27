// a common class for all pages
public abstract class Pantheon.Keyboard.AbstractPage : Gtk.Grid {
    public AbstractPage () {
        Object (
            column_homogeneous: false,
            row_homogeneous: false,
            column_spacing: 12,
            row_spacing: 12,
            margin_bottom: 12,
            margin_top: 12
        );
    }

    // every page must provide a class to reset all settings to default
    public abstract void reset ();
}
