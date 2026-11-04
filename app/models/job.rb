class Job < ApplicationRecord
  belongs_to :company
  has_many :applies, dependent: :destroy
  has_many :geeks, -> { distinct }, through: :applies

  validates :name, :place, presence: true, length: { maximum: 255 }
  validates :company_id, numericality: { only_integer: true, greater_than: 0 }
  validates_associated :company
  validates :deleted, inclusion: { in: [ true, false ] }

  def delete_job
    update(deleted: true)
  end
end
