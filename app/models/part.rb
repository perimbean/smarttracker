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
      part = (scope.first || scope.new)
      part.update_attributes!(status: status)

      @parts[name] = part
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

      ss_parts = []
      kit_parts.each do |kit_part_name|
        s = kit_part_name.downcase.
          sub('extension', 'replicator').sub('2mm', '').
          split(/\s/).reject(&:empty?).map(&:downcase)
        
        db_part = 
          parts.values.detect{|pt| pt.name.downcase == kit_part_name.downcase} ||
          parts.values.detect{|pt| s.all?{|ps| pt.name.downcase.include?(ps) }}

        if db_part
          ss_parts << db_part.name
        else
          puts("Missing part: #{kit_part_name}")
        end
      end

      scope = Kit.where({ name: name })
      kit = scope.first || scope.new
      kit.update_attributes(parts: ss_parts)
      @kits[name] = kit
    end

    nil
  end
end
