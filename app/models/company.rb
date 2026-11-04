class Company < ApplicationRecord
  has_many :jobs, dependent: :restrict_with_error
  has_many :applies, through: :jobs
  has_many :geeks, -> { distinct }, through: :applies

  validates :name, :location, presence: true, length: { maximum: 255 }
  validates :deleted, inclusion: { in: [ true, false ] }

  def delete_company
    update(deleted: true)
  end
end
