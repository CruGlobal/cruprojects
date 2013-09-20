module ApplicationHelper
  def amount_to_color(amount)
    case
    when amount < 4.0
      'red'
    when amount >= 6.0
      'green'
    else
      'yellow'
    end
  end
end
