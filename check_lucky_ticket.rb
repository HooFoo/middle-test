require 'scanf'

result = false

if ARGV[0] && ARGV[0].length == 6
  digits = ARGV[0].scanf("%1d"*6)
  left = right = 0
  for i in 0..2
    left += digits[i]
    right += digits[5-i]
  end
  result = left == right
end

puts result