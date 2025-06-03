require_relative 'polynomial'

puts "Введите любой многочлен, например: 3x^2 + 2x - 5 + 6y^3 "
print "Введите Ваш многочлен: "
p = gets.chomp
poly = Polynomial.from(p)
print "Введите символ по которому будете дифференцировать: "
difname = gets.chomp.strip.downcase.to_sym
print "Дифференцированный многочлен по #{difname}: "
dp_dx = poly.diff(difname)
#puts do_dx = dp_dx
puts dp_dx