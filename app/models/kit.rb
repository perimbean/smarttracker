class Kit < ActiveRecord::Base
  attr_accessible :name, :parts

  serialize :parts, Array

  def important_parts
    parts - ["USB Host Cable"]
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
