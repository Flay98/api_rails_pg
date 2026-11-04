class Apply < ApplicationRecord
  BOOLEAN_VALUES = [ true, false, "true", "false", "1", "0", 1, 0 ].freeze

  belongs_to :job
  belongs_to :geek

  validates :job_id, :geek_id, numericality: { only_integer: true, greater_than: 0 }
  validates_associated :job, :geek
  validates :read, :invited, inclusion: { in: [ true, false ] }
  validate :boolean_values

  private

  def boolean_values
    %i[read invited].each do |attribute|
      unless BOOLEAN_VALUES.include?(read_attribute_before_type_cast(attribute))
        errors.add(attribute, "must be true or false")
      end
    end
  end
end
