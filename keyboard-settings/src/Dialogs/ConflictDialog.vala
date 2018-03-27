public class ConflictDialog : Gtk.MessageDialog {

    public signal void reassign ();

    public ConflictDialog (string shortcut, string conflict_action, string this_action) {
        modal = true;
        message_type = Gtk.MessageType.WARNING;
        text = _("%s is already used for %s!").printf (shortcut, conflict_action);
        secondary_text = _("If you reassign the shortcut to %s, %s will be disabled").printf (this_action, conflict_action);

        add_button (_("Cancel"), 0);
        add_button (_("Reassign"), 1);

        response.connect ((response_id) => {
            if (response_id == 1) {
                reassign ();
            }

            destroy();
        });
    }
}
