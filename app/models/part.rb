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

  attr_accessible :name, :sku, :status

  validates :status, :inclusion => STATUSES.keys

  def self.parts
    @parts ||= Part.all.inject({}){|h, part| h[part.name] = part; h}
  end

  def self.import_parts
    content = File.read(File.join(Rails.root, 'doc', 'TOTAL_PRODUCT_QUANTITIES.csv'))
    @parts = {}

    CSV.parse(content).each_with_index do |row, i|
      next if i == 0
      status, sku, name, _ = *row
      next unless sku.present?

      scope = Part.where({ sku: sku, name: name })
      @parts[name] = part = (scope.first || scope.new)
      part.update_attributes!(status: status)
    end

    nil
  end

  def self.import_kits
    ks   = open("http://www.kickstarter.com/projects/fairduino/smartduino-open-system-by-former-arduinos-manufact")
    page = ks.read
    doc  = Nokogiri::HTML(page)
    @kits = {}
    
    kits = doc.
      css('#what-you-get').css('li .desc').
      map{|n| n.text}.
      select{|t| t.include?("KIT")}

    kits.each do |t| 
      name, rest = t.split("-", 2)

      name = name.strip[11..-1]

      kit_parts = rest.
        split(/inc?lude:/, 2).last.strip.
        split(/,\s/).
        map{|pr| pr.sub(/[,.]$/, '')}

      # Kit part names adjustments. Kickstarter name => Spreadsheet name.
      ss_parts = [] # Spreadshit part name
      kit_parts.each do |kit_part_name|
        kit_part_name = kit_part_name.downcase.
          sub('extension', 'replicator').
          sub('2mm', '')

        split_kit_part_name = kit_part_name.split(/\s/).reject(&:empty?).map(&:downcase)
        
        db_part = 
          # First try to directly match name.
          parts.values.detect{|pt| pt.name.downcase == kit_part_name} ||
          # Then try to match every word from original name to spreadsheet name.
          parts.values.detect{|pt| split_kit_part_name.all?{|ps| pt.name.downcase.include?(ps) }}

        if db_part
          ss_parts << db_part.name
        else
          puts("Missing part: #{kit_part_name}")
        end
      end

      scope = Kit.where({ name: name })
      @kits[name] = kit = scope.first || scope.new
      kit.update_attributes(parts: ss_parts)
    end

    nil
  end

  def human_status
    STATUSES[status] || "Unknown"
  end

  def color
    COLORS[status]
  end
end
