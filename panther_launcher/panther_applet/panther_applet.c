#include <gtk/gtk.h>
#include <gtk/gtkbutton.h>
#include <panel-applet.h>
#include <unistd.h>
#include <stdlib.h>
#include <libintl.h>
#include "dbus.h"

#define _(String) gettext (String)
static char **environ;

static gboolean applet_fill_cb (PanelApplet * applet, const gchar * iid, gpointer data);

PANEL_APPLET_IN_PROCESS_FACTORY ("PantherAppletFactory", PANEL_TYPE_APPLET, applet_fill_cb, NULL);

static void launch(char silent) {

	GError *error = NULL;

    ComRastersoftPantherRemotecontrol *proxy;
    proxy = com_rastersoft_panther_remotecontrol_proxy_new_for_bus_sync (G_BUS_TYPE_SESSION,
                                                  G_DBUS_PROXY_FLAGS_NONE,
                                                  "com.rastersoft.panther.remotecontrol",
                                                  "/com/rastersoft/panther/remotecontrol",
                                                  NULL, /* GCancellable */
                                                  &error);
    if (proxy != NULL) {
        error = NULL;
        gboolean retval;
        
        if (silent == 0) {
            retval = com_rastersoft_panther_remotecontrol_call_do_show_sync(proxy,NULL,&error);
        } else {
            gint value;
            retval = com_rastersoft_panther_remotecontrol_call_do_ping_sync(proxy,0,&value,NULL,&error);
        }
        
        if (!retval) {
            printf("Failed to call panther launcher using DBus: %d; %s\n",error->code,error->message);
            int pid=fork();
            char *args[3];

            if (silent == 0) {
                args[1] = NULL;
            } else {
                args[1] = "-s";
                args[2] = NULL;
            }
            if (pid == 0) {
                // prelaunch panther launcher
                args[0]="/usr/bin/panther_launcher";
                execve(args[0],args,environ);
                args[0]="/usr/local/bin/panther_launcher";
                execve(args[0],args,environ);
                exit(0);
            }
        }
        g_object_unref(proxy);
    } else {
        printf("Error getting proxy to call panther launcher using DBus\n");
        launch(0);
    }
}

static void button_clicked(GtkWidget *widget, GdkEvent  *event, gpointer   user_data) {

    launch(0);
}

static gboolean applet_fill_cb (PanelApplet *applet, const gchar * iid, gpointer data) {

	gboolean retval = FALSE;
	static gboolean set_name = FALSE;
	GString *text;

	if (g_strcmp0 (iid, "PantherApplet") == 0) {
		if (!set_name) {
			g_set_application_name ("PantherLauncher");
			set_name=TRUE;
            launch(1);
		}
		gtk_container_set_border_width(GTK_CONTAINER (applet), 0);
		gtk_widget_show_all(GTK_WIDGET(applet));
		GtkWidget* main_button = gtk_label_new(NULL);
		gtk_widget_set_margin_start(main_button,3);
		gtk_widget_set_margin_end(main_button,3);

		text = g_string_new("");
		g_string_printf(text,"<b>%s</b>",_("Applications"));
		gtk_label_set_markup(GTK_LABEL(main_button),text->str);
		g_string_free(text,TRUE);
		GtkWidget* eventbox = gtk_event_box_new();
		gtk_container_add(GTK_CONTAINER(applet),eventbox);
		gtk_container_add(GTK_CONTAINER(eventbox),main_button);
		gtk_widget_show_all(GTK_WIDGET(applet));
		g_object_connect(G_OBJECT(eventbox),"signal::button_release_event",button_clicked,NULL,NULL);
		retval = TRUE;
	}

	return retval;
}
