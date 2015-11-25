class RenameOverrideSpamOrBounceAndSpamOrBounce < ActiveRecord::Migration
  def change
    rename_column :visits, :override_spam_or_bounce, :override_delivery_error
    rename_column :visits, :spam_or_bounce, :delivery_error_type
  end
end
