=begin
I have created 3 rb files for classes Gene, Seed_stock and Cross, which are located in the same folder as this program.
I have asked my classmates for help to define the function of chi_square and how to print the linked genes
=end
require './Gene'
require './Seed_stock'
require './Cross'

#Gene file: generate matrix with all gene data and create instances
gfile = File.open("gene_information.tsv", "r")
geneID = Array.new 
genename = Array.new 
mutantph = Array.new
gfile.each do |line| 
  line = line.split"\t" 
  unless line[0] =~ /Gene/ #excludes the header
    geneID << line[0] #filling arrays
    genename << line[1]
    mutantph << line[2]
  end
end
gfile.close

gmatrix=[geneID, genename, mutantph] #matrix that contains all the gene_information data

ginstances = Array.new #this will contain the instances of class Gene
i=0
while i < (geneID.length).to_int
  ginstances[i]= Gene.new(
    :gene_ID => gmatrix[0][i],
    :gene_name => gmatrix[1][i],
    :mutant_phenotype => gmatrix[2][i],
    )
  i += 1
end


#Seed_stock file: generate matrix with all stock data and create instances
sfile = File.open("seed_stock_data.tsv", "r")
seedID = Array.new
mutantID = Array.new
lastplanted = Array.new
storage = Array.new
grams_remaining = Array.new
sfile.each do |line|
  line = line.split"\t"
  unless line[0] =~ /Seed/
    seedID << line[0]
    mutantID << line[1]
    lastplanted << line[2]
    storage << line [3]
    grams_remaining << line [4]
  end
end
sfile.close

smatrix=[seedID, mutantID, lastplanted, storage, grams_remaining] #matrix that contains all data about seed_stock

sinstances = Array.new #contains instances of Seed_stock
j=0
while j < (seedID.length).to_int
  sinstances[j]= Seed_stock.new(
    :seedstock_ID => smatrix[0][j],
    :mutantgene_ID => smatrix[1][j],
    :last_planted => smatrix[2][j],
    :storage => smatrix[3][j],
    :grams_remaining => smatrix[4][j]
    )
  j += 1
end

#Cross file: generate matrix with all cross data and create instances
cfile = File.open("cross_data.tsv", "r")
p1 = Array.new
p2 = Array.new
f2w = Array.new
f2p1 = Array.new
f2p2 = Array.new
f2p1p2 = Array.new

cfile.each do |line|
  line = line.split"\t"
  unless line[0] =~ /Parent/
    p1 << line[0]
    p2 << line[1]
    f2w << line[2]
    f2p1 << line [3]
    f2p2 << line [4]
    f2p1p2 << line [5]
  end
end
cfile.close
cmatrix = [p1, p2, f2w, f2p1, f2p2, f2p1p2] #matrix that contains cross_data 

cinstances = Array.new #instances of class Cross
k=0
while k < (p1.length).to_int
  cinstances[k]= Cross.new(
    :parent1 => cmatrix[0][k],
    :parent2 => cmatrix[1][k],
    :f2_wild => cmatrix[2][k],
    :f2_p1 => cmatrix[3][k],
    :f2_p2 => cmatrix[4][k],
    :f2_p1p2 => cmatrix[5][k],
    )
  k += 1
end

#Using plant_seed function, defined in Seed_stock.rb, let's update the seed stock data 
a = 0
while a < sinstances.length
	test = sinstances[a].plant_seed
	if test == "Let's plant"
		sinstances[a].grams_remaining = sinstances[a].grams_remaining.to_i - 7
		smatrix[4][a]= smatrix[4][a].to_i - 7
	else
		puts "WARNING: We have run out of Seed Stock #{test}"
		sinstances[a].grams_remaining = 0
		smatrix[4][a]=0
	end
	a +=1
end

#puts sinstances[4].grams_remaining

#new_stock.tsv for the new seed stock data
sfile = File.open("seed_stock_data.tsv", "r")
  header = sfile.readlines[0]
  header = header.split("\t")
  ndata =  [header] + smatrix.transpose
nfile= File.open("new_stock.tsv", "w+")
i=0
while i <= smatrix.length
  nfile.puts("#{ndata[i][0]} \t #{ndata[i][1]} \t #{ndata[i][2]} \t #{ndata[i][3]} \t #{ndata[i][4]}")
  i+=1
end
sfile.close
nfile.close

#Chi-square test for F2 defined in Cross.rb
a=0
while a < cinstances.length
  chi= cinstances[a].chi_square
  if chi > 7.8
    b = 0
    while b < sinstances.length
      if sinstances[b].seedstock_ID == cinstances[a].parent1
        geneid1=sinstances[b].mutantgene_ID
        c = 0
        while c < ginstances.length
          if ginstances[c].gene_ID == geneid1
            genename1=ginstances[c].gene_name
          end
          c+=1
        end
      end
      
      if sinstances[b].seedstock_ID == cinstances[a].parent2
        geneid2=sinstances[b].mutantgene_ID
        c = 0
        while c < ginstances.length
          if ginstances[c].gene_ID == geneid2
            genename2=ginstances[c].gene_name
          end
          c+=1
        end
      end 
      b += 1
    end
    puts "Recording: #{genename1} is genetically linked to #{genename2} with chi-square score #{chi}#"
    puts
    puts "Final Report:"
    puts "#{genename1} is linked to #{genename2}" 
    puts "#{genename2} is linked to #{genename1}" 
  end
  a += 1
end