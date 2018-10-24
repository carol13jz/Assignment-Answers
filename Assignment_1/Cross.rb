class Cross
  attr_accessor :parent1
  attr_accessor :parent2
  attr_accessor :f2_wild
  attr_accessor :f2_p1
  attr_accessor :f2_p2
  attr_accessor :f2_p1p2
  
  def initialize (params = {}) 
    @parent1 = params.fetch(:parent1, "X000")
    @parent2 = params.fetch(:parent2, "X000")
    @f2_wild = params.fetch(:f2_wild, '000')
    @f2_p1 = params.fetch(:f2_p1, '00')
    @f2_p2 = params.fetch(:f2_p2, '00')
    @f2_p1p2 = params.fetch(:f2_p1p2, '00')
  end
  
  def chi_square #for F2
    total = f2_wild.to_f + f2_p1.to_f + f2_p2.to_f + f2_p1p2.to_f
    ow = ((f2_wild.to_f - (total/16)*9)**2)/((total/16)*9)
    op1 = ((f2_p1.to_f - (total/16)*3)**2)/((total/16)*3)
    op2 = ((f2_p2.to_f - (total/16)*3)**2)/((total/16)*3)
    op12 = ((f2_p1p2.to_f - (total/16))**2)/((total/16))
    sum = ow+op1+op2+op12
    return sum
  end
end
