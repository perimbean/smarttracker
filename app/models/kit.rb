class Kit < ActiveRecord::Base
  NAMES = [
    "STARTER KIT - 6PCS",
    "TINKERER KIT - 10PCS",
    "ANDROID KIT - 12PCS",
    "ADVANCED KIT - 18PCS",
    "HACKER KIT - 23PCS",
    "MAKER KIT - 26PCS",
    "PROFESSIONAL KIT - 35PCS",
    "ALL IN ONE KIT - 40PCS"
  ]

  serialize :parts, Array

  attr_accessible :name, :pieces, :qty, :parts, :index

  def self.import
    NAMES.each_with_index do |full_name, i|
      name, pieces = full_name.split(" - ")

      scope = Kit.where(name: name)
      kit = (scope.first || scope.new)
      kit.update_attributes!(pieces: pieces.to_i, qty: 0, index: i+1)
    end
  end

  def important_parts
    read_attribute(:parts) - ["USB Host Cable"]
  end

  def db_parts
    @db_parts ||= important_parts.map{|n| Part.find_by_name(n) }
  end

  def status
    @status ||= begin
      part_statuses = db_parts.map{|pr| pr.status }.uniq
      Part::STATUSES.keys.reverse.detect{|st| part_statuses.include?(st) }
    end
  end

  def human_status
    Part::STATUSES[status]
  end

  def color
    Part::COLORS[status]
  end
end
