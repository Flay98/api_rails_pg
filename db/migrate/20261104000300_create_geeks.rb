class CreateGeeks < ActiveRecord::Migration[7.2]
  def change
    create_table :geeks do |t|
      t.string :name, null: false
      t.string :stack, null: false
      t.text :resume
      t.timestamps
    end
  end
end
