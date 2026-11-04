class CreateApplies < ActiveRecord::Migration[7.2]
  def change
    create_table :applies do |t|
      t.references :job, null: false, foreign_key: true
      t.references :geek, null: false, foreign_key: true
      t.boolean :read, null: false, default: false
      t.boolean :invited, null: false, default: false
      t.timestamps
    end
  end
end
