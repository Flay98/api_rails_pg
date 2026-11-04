class AddDeletedToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :deleted, :boolean, null: false, default: false
  end
end
