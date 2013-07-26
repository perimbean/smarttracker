class AddFieldsToPart < ActiveRecord::Migration
  def change
    add_column :parts, :kits, :integer
    add_column :parts, :additional, :integer
    add_column :parts, :total, :integer
    add_column :parts, :to_make, :integer
    add_column :parts, :made, :integer
  end
end
