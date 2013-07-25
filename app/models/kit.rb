class Kit < ActiveRecord::Base
  attr_accessible :name, :parts

  serialize :parts, Array
end
