class Gene
  attr_accessor :gene_ID 
  attr_accessor :gene_name
  attr_accessor :mutant_phenotype
  
  def initialize (params = {}) 
    @gene_ID = params.fetch(:gene_ID, "ATXXXXXXX")
    @gene_name = params.fetch(:gene_name, 'unknown gene')
    @mutant_phenotype = params.fetch(:mutant_phenotype, 'unknown phenotype')
  end
end

gfile = File.open("gene_information.tsv", "r")
geneID = Array.new #a list for column 1
genename = Array.new #column 2
mutantph = Array.new #column 3
gfile.each do |line| 
  line = line.split"\t" 
  unless line[0] =~ /Gene/ #excludes the header
    geneID << line[0] #filling arrays
    genename << line[1]
    mutantph << line[2]
  end
end
gfile.close

instance = Array.new #will contain the instances of class Gene
i=0
while i < (geneID.length).to_int
  instance[i]= Gene.new(
    :gene_ID => geneID[i],
    :gene_name => genename[i],
    :mutant_phenotype => mutantph[i],
    )
  i += 1
end

#puts instance[0].inspect