class CreateParts < ActiveRecord::Migration
  def change
    create_table :parts do |t|
      t.string :status
      t.string :sku
      t.string :name

      t.timestamps
    end
  end
end
