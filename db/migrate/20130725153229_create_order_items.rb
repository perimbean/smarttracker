class CreateOrderItems < ActiveRecord::Migration
  def change
    create_table :order_items do |t|
      t.references :order
      t.references :part
      t.integer :count

      t.timestamps
    end
    add_index :order_items, :order_id
    add_index :order_items, :part_id
  end
end
