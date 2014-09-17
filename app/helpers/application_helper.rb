module ApplicationHelper
  def amount_to_color(amount)
    case
    when round(amount) < 4.0
      'gray'
    when round(amount) >= 4.0 && round(amount) < 5.0
      'yellow'
    when round(amount) >= 5.0 && round(amount) < 6.0
      'green'
    when round(amount) >= 6.0 && round(amount) < 7.0
      'orange'
    else
      'red'
    end
  end

  def round(num, precision = 1)
    number_with_precision(num, precision: precision).to_f
  end
end
