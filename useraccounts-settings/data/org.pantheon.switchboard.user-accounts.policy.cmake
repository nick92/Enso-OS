<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
<policyconfig>
  <vendor>elementary</vendor>
  <vendor_url>http://elementaryos.org/</vendor_url>

  <action id="org.pantheon.switchboard.user-accounts.administration">
    <description gettext-domain="@GETTEXT_PACKAGE@">Manage user accounts</description>
    <message gettext-domain="@GETTEXT_PACKAGE@">Authentication is required to change user data</message>
    <icon_name>system-users</icon_name>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">@PKGDATADIR@/guest-session-toggle</annotate>
    <annotate key="org.freedesktop.policykit.imply">org.freedesktop.accounts.user-administration</annotate>
  </action>

</policyconfig>
