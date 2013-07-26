class AddQtyToKit < ActiveRecord::Migration
  def change
    add_column :kits, :qty, :integer
    add_column :kits, :pieces, :integer
    add_column :kits, :index, :integer
  end
end
