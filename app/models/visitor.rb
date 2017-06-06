class Visitor < ActiveRecord::Base
  include Person
  extend FreshnessCalculations

  attr_accessor :validate_contact_list_matching

  belongs_to :visit

  validates :visit, :sort_index, presence: true
  validate :contact_list_processed

  default_scope do
    order(sort_index: :asc)
  end

  scope :banned,   -> { where(banned: true) }
  scope :unlisted, -> { where(not_on_list: true) }
  scope :allowed,  -> { where(banned: false, not_on_list: false) }

  def validate_contact_list_matching
    # TODO: Changes in Rails 5 to `ActiveRecord::Type::Boolean.new.cast(string)`
    ActiveRecord::Type::Boolean.
      new.
      type_cast_from_database(@validate_contact_list_matching)
  end

  def validate_contact_list_matching?
    validate_contact_list_matching
  end

  def allowed?
    !(banned || not_on_list)
  end

  def status
    return 'banned' if banned?
    return 'not on list' if not_on_list?
    'allowed'
  end

  def contact_list_processed
    if validate_contact_list_matching? && (nomis_id.present? == not_on_list?)
      errors.add :base, :unprocessed_contact_list
    end
  end
end
