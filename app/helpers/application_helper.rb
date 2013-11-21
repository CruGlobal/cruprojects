module ApplicationHelper
  def amount_to_color(amount)
    case
    when round(amount) < 4.0
      'white'
    when round(amount) >= 4.0 && round(amount) < 5.0
      'blue'
    when round(amount) >= 5.0 && round(amount) < 6.0
      'green'
    when round(amount) >= 6.0 && round(amount) < 7.0
      'yellow'
    else
      'red'
    end
  end

  def round(num)
    number_with_precision(num, precision: 1).to_f
  end
end
