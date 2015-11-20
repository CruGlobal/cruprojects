class MonitorsController < ApplicationController
  def lb
    Team.first
    render text: 'OK'
  end
end
