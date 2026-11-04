class AddDeletedToJobs < ActiveRecord::Migration[7.2]
  def change
    add_column :jobs, :deleted, :boolean, null: false, default: false
  end
end
