class Symbol
  def *(other)
    Term.new({ self => 1 }) * other
  end

  def +(other)
    Term.new({ self => 1 }) + other
  end

  def -(other)
    Term.new({ self => 1 }) - other
  end

  def **(power)
    Term.new({ self => power })
  end

  def coerce(other)
    [Term.new({ self => 1 }), other]
  end

  def diff(sym)
    self == sym ? 1 : 0
  end
end

class Numeric
  def diff(sym)
    0
  end
end

class Term
  attr_reader :coefficient, :variables

  def initialize(variables = {}, coefficient = 1)
    @coefficient = coefficient
    @variables = variables.each_with_object({}) do |(var, power), h|
      h[var] = power if power != 0
    end
  end

  def *(other)
    if other.is_a?(Numeric)
      Term.new(@variables, @coefficient * other)
    elsif other.is_a?(Symbol)
      self * Term.new({ other => 1 })
    elsif other.is_a?(Term)
      new_vars = @variables.merge(other.variables) { |_, pow1, pow2| pow1 + pow2 }
      Term.new(new_vars, @coefficient * other.coefficient)
    else
      raise ArgumentError, "Unsupported type: #{other.class}"
    end
  end

  def coerce(other)
    if other.is_a?(Numeric)
      [Term.new({}, other), self]
    else
      raise TypeError, "#{other.class} can't be coerced into Term"
    end
  end

  def +(other)
    Polynomial.new(self) + other
  end

  def -(other)
    Polynomial.new(self) - other
  end

  def to_s
    parts = []
    parts << @coefficient.to_s unless @coefficient == 1 && !@variables.empty?

    @variables.each do |var, power|
      part = var.to_s
      part += "^#{power}" unless power == 1
      parts << part
    end

    parts.empty? ? '0' : parts.join('*')
  end

  def diff(sym)
    terms = []
    @variables.each do |var, power|
      if var == sym
        new_vars = @variables.dup
        if power == 1
          new_vars.delete(var)
        else
          new_vars[var] = power - 1
        end
        terms << Term.new(new_vars, @coefficient * power)
      end
    end
    terms.empty? ? 0 : terms.reduce(:+)
  end

  def ==(other)
    case other
    when Symbol
      @coefficient == 1 && @variables == { other => 1 }
    when Term
      @coefficient == other.coefficient && @variables == other.variables
    else
      false
    end
  end
end

class Polynomial
  attr_reader :terms

  def initialize(*terms)
    @terms = terms.map do |term|
      case term
      when Numeric then Term.new({}, term)
      when Symbol then Term.new({ term => 1 })
      when Term then term
      else raise ArgumentError, "Unsupported type: #{term.class}"
      end
    end
  end

  def +(other)
    other_terms = case other
                  when Numeric then [Term.new({}, other)]
                  when Symbol then [Term.new({ other => 1 })]
                  when Term then [other]
                  when Polynomial then other.terms
                  else raise ArgumentError, "Unsupported type: #{other.class}"
                  end
    Polynomial.new(*(@terms + other_terms))
  end

  def -(other)
    self + (other * -1)
  end

  def *(other)
    case other
    when Numeric
      Polynomial.new(*@terms.map { |term| term * other })
    when Symbol
      self * Term.new({ other => 1 })
    when Term
      Polynomial.new(*@terms.map { |term| term * other })
    when Polynomial
      terms = @terms.product(other.terms).map { |t1, t2| t1 * t2 }
      Polynomial.new(*terms)
    else
      raise ArgumentError, "Unsupported type: #{other.class}"
    end
  end

  def diff(sym)
    differentiated_terms = @terms.map { |term| term.diff(sym) }
    differentiated_terms = differentiated_terms.reject { |t| t == 0 }
    differentiated_terms.empty? ? 0 : differentiated_terms.reduce(:+)
  end

  def to_s
    @terms.empty? ? '0' : @terms.map(&:to_s).join(' + ').gsub('+ -', '- ')
  end

  def ==(other)
    case other
    when Numeric
      @terms.size == 1 && @terms.first == Term.new({}, other)
    when Symbol
      @terms.size == 1 && @terms.first == Term.new({ other => 1 })
    when Term
      @terms.size == 1 && @terms.first == other
    when Polynomial
      @terms.sort_by { |t| t.variables.to_s } == other.terms.sort_by { |t| t.variables.to_s }
    else
      false
    end
  end

  #!!!!!

  # Универсальный метод преобразования в Polynomial
  def self.from(value)
    case value
    when Polynomial then value
    when Numeric, Symbol, Term then new(value)
    when String then parse(value)
    else
      raise ArgumentError, "Cannot convert #{value.class} to Polynomial"
    end
  end

  # Метод parse остается без изменений
  #def self.parse(str)
  #str.gsub(/\s+/, "")
  #.split(/(?=[+-])/)
  #.reject(&:empty?)
  #.map { |term| parse_term(term) }
  #.then { |terms| new(*terms) }
  #end

  # Метод parse остается без изменений
  def self.parse(str)
    str.gsub(/\s+/, "")
       .split(/(?=[+-])/)
       .reject(&:empty?)
       .map { |term| parse_term(term) }
       .then { |terms| new(*terms) }
  end

  private

  def self.parse_term(term_str)
    # Разделяем коэффициент и переменные
    if term_str.include?("*")
      coeff_part, vars_part = term_str.split("*", 2)
    else
      # Если нет *, то ищем число в начале
      if term_str =~ /\A[+-]?\d+/
        coeff_part = term_str[/\A[+-]?\d+/]
        vars_part = term_str[coeff_part.size..-1]
      else
        coeff_part = nil
        vars_part = term_str
      end
    end

    # Обрабатываем коэффициент
    coefficient = if coeff_part.nil?
                    term_str.start_with?("-") ? -1 : 1
                  else
                    coeff_part.to_i
                  end

    # Обрабатываем переменные
    variables = {}
    unless vars_part.empty?
      vars_part.scan(/([a-z])(?:\^(\d+))?/) do |var, power|
        power = power ? power.to_i : 1
        variables[var.to_sym] = power
      end
    end

    Term.new(variables, coefficient)
  end
end