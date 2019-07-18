# Configure sensitive parameters which will be filtered from the log file.
# Be sure to restart the server if you modify this file.
#
Rails.application.config.filter_parameters += [
  :card_type,
  :card_number,
  :card_cvv,
  :card_to,
  :card_from,
  :card_issue
]
