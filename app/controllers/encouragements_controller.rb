class EncouragementsController < InheritedResources::Base

  def index
    @locations = []
    render layout: false
  end

end
