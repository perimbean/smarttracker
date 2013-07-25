class PartsController < ApplicationController
  def index
    @parts = Part.all
    @kits = Kit.all
  end
end
