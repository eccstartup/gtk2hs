#include <glib.h>

#ifndef HSGTHREAD_H
#define HSGTHREAD_H

/* Initialize the threads system of Gdk and Gtk. */
void gtk2hs_threads_initialise (void);

/* Free an object within the Gtk+ main loop. */
void gtk2hs_g_object_unref_from_mainloop(gpointer object);

#endif HSGTHREAD_H

