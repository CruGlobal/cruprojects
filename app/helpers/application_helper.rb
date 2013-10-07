module ApplicationHelper
  def amount_to_color(amount)
    case
    when round(amount) < 4.0
      'red'
    when round(amount) >= 6.0
      'green'
    else
      'yellow'
    end
  end

  def round(num)
    number_with_precision(num, precision: 1).to_f
  end
end
