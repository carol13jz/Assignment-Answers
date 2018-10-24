class Seed_stock
  attr_accessor :seedstock_ID 
  attr_accessor :mutantgene_ID
  attr_accessor :last_planted
  attr_accessor :storage
  attr_accessor :grams_remaining
  
  def initialize (params = {}) 
    @seedstock_ID = params.fetch(:seedstock_ID, "XXXX")
    @mutantgene_ID = params.fetch(:mutantgene_ID, 'XXXXXXX')
    @last_planted = params.fetch(:last_planted, 'unknown date')
    @storage = params.fetch(:storage, 'unknown')
    @grams_remaining = params.fetch(:grams_remaining, 'unknown')
  end
  
  #Planting 7 seeds for each record of seed_stock_data.tsv
  def plant_seed
    grams_remaining2 = (grams_remaining).to_i - 7
    if grams_remaining2 <= 0
      return "#{seedstock_ID}"
    else
    	return "Let's plant"
    end
  end
end