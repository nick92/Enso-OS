include (Translations) # Replace plug-name with the correct name of your plug
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
)
