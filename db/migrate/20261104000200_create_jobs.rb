class CreateJobs < ActiveRecord::Migration[7.2]
  def change
    create_table :jobs do |t|
      t.string :name, null: false
      t.string :place, null: false
      t.references :company, null: false, foreign_key: true
      t.timestamps
    end
  end
end
