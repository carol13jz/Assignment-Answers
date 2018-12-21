=begin
  Assignment 4 main program, in collaboration with Maksym
Google "blast parameters orthologs" -> the first result is an article about choosing blast options to get orthologs as reciprocal best hits (RBH).
It states that an e-value threshold of 10^-6 and a coverage of at least 50% will result in a high number of orthologs with minimal error rates.
=end

require 'bio'
#require 'stringio'

# First, let's create the dbs using this command:
system "makeblastdb -in pep.fa -dbtype 'prot' -out pep"	#This creates some index files that are used by BLAST to speed-up the search. 
system "makeblastdb -in TAIR10_seq_20110103_representative_gene_model_updated -dbtype 'nucl' -out TAIR10"

#With the dbs, let's establish the factories
## blast is installed globally, so you don't need to include the full path to blastn
pfactory = Bio::Blast.local('blastx', 'pep')   #blastx use translated DNA sequences to search protein dbs
nfactory = Bio::Blast.local('tblastn', 'TAIR10')   # tblastn search translated nt dbs with a protein query

#Now open the txt files and convert one of them to a hash, so the IDs can be easily retrieved
peps = File.open('pep.fa', "r")
tair = File.open('TAIR10_seq_20110103_representative_gene_model_updated', "r")
tair = Bio::FlatFile.auto(tair)
peps = Bio::FlatFile.new(Bio::FastaFormat,peps)

t10_hash = Hash.new 	#ID = key; sequence = value
tair.each do |entry|
  t10_hash[(entry.entry_id).to_s] = (entry.seq).to_s 
end

#Create the files that will store the orthologs
orthologs = File.open('./orthologs.txt', 'w')
orthologs.puts "Putative ortholog pairs: \n" 


#Finally, BLAST time!
i = 1 #just to keep track of the program when running
j = 1 #index number for our orthologs pair
peps.each do |pep| 
  prot_id = (pep.definition.match(/(\w+\.\w+)/)).to_s #Find protein id for later purposes
  blast1 = nfactory.query(pep)
  i+=1
puts "Blasting protein number #{i} : #{prot_id}"

#First Blast
	#If there are hits and they meet the conditions...
	if blast1.hits[0] != nil and blast1.hits[0].evalue <= 10**-6 and blast1.hits[0].overlap.to_i >= 50
    nt_id = (blast1.hits[0].definition.match(/(\w+\.\w+)/)).to_s # we store the ID of the first hit
    puts "FOUND HIT in #{nt_id}! Checking reciprocal hit"
    sequence = t10_hash[nt_id]
    
    #Second Blast
    blast2 = pfactory.query("#{sequence}") 
    if blast2.hits[0] != nil and blast2.hits[0].evalue <= 10**-6 and blast2.hits[0].overlap >= 50 
      hit = (blast2.hits[0].definition.match(/(\w+\.\w+)/)).to_s #will they match???
      if prot_id == hit #if so...
        orthologs.puts "#{j}\t#{prot_id}\t#{nt_id}" #we store them in our txt file!
        #puts "#{prot_id}  is ortholog to #{nt_id}"
        j+=1
      end
    end
	end
end

=begin

According to the literature, there is still a lack of a methodology and of a tool to be completely realiable
in assemblying orthologs. The accumulation of evolutionary dynamics does not help to identify true orthologs
from homologs.

Anyways,there are complementary tools/methods which can be helpful.
Aside from sequence similarity, we can study protein domain architectures, functional motifs or GO annotations.
In this case, for BRH (1:1 inference), GO annotations can be easily compared. For example, we can compare the
GO terms of both orthologs that are related to functional characteristics (although it does not happen every time,
orthologs are likely to share the same function). We can also implement an algorithm to identify motifs and
use them to find functional regions in orthologs. This could be applied not only in a pair of orthologs but
a ortholog group/cluster, which could be built based on a network of BRHs.

=end