begin
  stack = []
  ARGV.each do |element|
    if element =~ /\d+/
      stack << element.to_f
    elsif element =~/[\+\-\*\/\^]/
      element = '**' if element == '^' # not cool, but ruby has no ^ operation
      left, right = stack.pop(2)
      if left.nil? || right.nil?
        raise 'To many operands.'
      else
        stack << left.method(element).call(right)
      end
    else
      raise 'Invalid operation. Check your arguments'
    end
  end
  if stack.length > 1
    raise 'Invalid notation'
  end

  # format for autotest
  if stack[0].modulo(1) == 0
    stack[0] = stack[0].to_i
  end

  puts stack[0] || 0
rescue  Exception => e
  puts e.message
end
