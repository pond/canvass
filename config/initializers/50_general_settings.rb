########################################################################
# File::    50_general_settings.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Static Hub configuration which is invariant across different
#           environments (see also "config/environments/*.rb" and
#           "config/environment.rb").
# ----------------------------------------------------------------------
#           09-Mar-2009 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

# Notification e-mail messages are sent with a 'from' address specified below.

NOTIFICATION_EMAILS_COME_FROM = "info@riscosopen.org"

# Administrative copies of e-mail messages and the address given in a 'contact
# your site administrator' style error are sent to the e-mail address below.

ADMINISTRATOR_EMAIL_ADDRESS = NOTIFICATION_EMAILS_COME_FROM

# Maximum number of items to show per page in sortable list views.

MAXIMUM_LIST_ITEMS_PER_PAGE = 25

# ROOL specific change.

MATCHING_POT_CURRENCY = 'GBP'
MATCHING_POT_LOCATION = "/home/rool/shared/matching_pot.txt"
