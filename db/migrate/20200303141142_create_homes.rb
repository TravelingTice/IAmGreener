class CreateHomes < ActiveRecord::Migration[5.2]
  def change
    create_table :homes do |t|
      t.string :location
      t.string :type
      t.string :isolation_type
      t.integer :inhabitants_size
      t.references :user
      t.integer :score

      t.timestamps
    end
  end
end
