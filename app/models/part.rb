require 'csv'
require 'open-uri'

class Part < ActiveRecord::Base
  STATUSES = {
    "ww"          => "In stock worldwide",
    "cn"          => "Production completed, in stock China",
    "running"     => "Production running",
    "approved"    => "Design completed and approved, waiting for production run",
    "prototyped"  => "Design completed and final prototype made waiting final approval",
    "designed"    => "Design completed, sample PCB made, final prototype not ready",
    "designing"   => "Design not completed",
    "standby"     => "In standby",
  }

  COLORS = {
    "ww"          => "green",
    "cn"          => "lime",
    "running"     => "blue",
    "approved"    => "cyan",
    "prototyped"  => "yellow",
    "designed"    => "orange",
    "designing"   => "red",
    "standby"     => "grey",
  }

  FIELD = {
    :sku=>0,               # SKU of the product
    :name=>1,              # Name of the part
    :kk1=>2,  :kk1qt=>3,   # Kits 1-8
    :kk2=>4,  :kk2qt=>5,
    :kk3=>6,  :kk3qt=>7,
    :kk4=>8,  :kk4qt=>9,
    :kk5=>10, :kk5qt=>11,
    :kk6=>12, :kk6qt=>13,
    :kk7=>14, :kk7qt=>15,
    :kk8=>16, :kk8qt=>17,
    :kits=>18,             # Number of components from kits
    :additional=>19,       # Number of additional components from ks / website
    :total=>20,            # Total number of ordered components
    :to_make=>21,          # Number of comonents to make ( > total ordered)
    :made=>22,             # Number of kits already made
    :bal=>23,              # made - to make
    :receptacle=>24,       # ?
    :header=>25,           # ?
    :total_recept=>26,     # to make * receptacle
    :total_head=>27,       # to make * head
    :status=>28            # textual status of the order, see STATUSES
  }

  validates :status, :inclusion => STATUSES.keys

  attr_accessible :status, :sku, :name, :kits, :additional, :total, :to_make, :made

  class << self
    def import
      content = File.read(File.join(Rails.root, 'doc', 'TOTAL_PRODUCT_QUANTITIES.csv'))
      @parts = {}

      @kits = Kit.all.inject({}){|hash, kit| hash[kit.index] = kit; hash }
      @kits.values.each{|kit| kit.parts = [] }

      CSV.parse(content).each_with_index do |row, i|
        next if i == 0
        sku, name, _ = *row
        next unless sku.present?

        scope = Part.where({ sku: sku, name: name })
        @parts[name] = part = (scope.first || scope.new)

        attrs = {}
        [ :kits, :additional, :total, :to_make, :made, :status ].each do |k|
          attrs[k] = row[FIELD[k]]
        end
        p attrs
        part.update_attributes!(attrs)

        (1..8).each do |kit_i|
          kit = @kits[kit_i]

          qty    = row[FIELD[:"kk#{kit_i}qt"]]
          in_kit = row[FIELD[:"kk#{kit_i}"]].to_i
          
          kit.parts << name if in_kit > 0
          kit.qty = qty.to_i unless qty.nil? || qty.empty?
        end
      end

      @kits.values.each{|kit| kit.save }

      nil
    end
  end

  def percent_made
    made && to_make > 0 ? (100 * made / to_make) : 0
  end

  def human_status
    STATUSES[status] || "Unknown"
  end

  def color
    COLORS[status]
  end
end
