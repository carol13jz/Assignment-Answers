#Assignment 3 main program 
#The program does not work...

require 'net/http'
require 'bio'

def fetch(uri_str)  # fetch that does some error-handling
  address = URI(uri_str)  # create URI
  response = Net::HTTP.get_response(address)  # this is used to call the URI adress
  case response   
    when Net::HTTPSuccess then  # when response is of type Net::HTTPSuccess
      return response  # return that response object
    else
      raise Exception, "Something went wrong... the call to #{uri_str} failed; type #{response.class}"
      response = False
      return response  # now we are returning False
  end 
end

#Using the gene ids, we get the entries
  
  #Step 1. Array of gene ids
genes = File.open("ArabidopsisSubNetwork_GeneList.txt","r")
geneids = genes.read.split() #remove newlines -> we get an array
geneids = geneids.join"," #turns array into a string, each id is separated by a comma
genes.close
#puts geneids
  
   #Step 2. Get the entries
unless File.file?("Genes.embl") #if this file already exists, use it
  ensembl = File.open("Genes.embl", "w") #otherwise we create it
  uri = "https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=" + geneids
  res = fetch(uri)
  data = res.body
  ensembl.write(data) #we add the entries of our genes to the embl file
  ensembl.close
end

#Preparing files
gff = File.open("feats.gff", "w")
nox = File.open("noexons.txt", "w")  
  
#Where are the exons? 
entries = Bio::FlatFile.auto('Genes.embl') #reading the ensembl file: Bioruby autodetects the file format. 
entries.each do |entry|
  unless entry.features[1].nil?
    geneid = entry.features[1].assoc["gene"]
  end
  pos=[] # array to store exon positions
  entry.features do |feature|
    next unless feature.feature == "exon"
    pos = pos.push(feature.position) # store all exon positions in the array
  end
  
  seq = entry.naseq #We get the nucleotide sequence of the entry
  #name = entry.entry_id
  #fasta = seq.to_fasta(name) #method to get fasta format
  bioseq = Bio::Sequence::NA.new(seq) #this is a sequence object
  pos.each do |exon|
    if exon[0].to_i > 0 #the exon is in forward strand. Format: start_pos..end_pos
      start,ends = exon.split".." #we get the start and end position
      #puts start, ends
      d_exon = bioseq.subseq[start.to_i..ends.to_i] #now we have the sequence of the exon
=begin
we are looking for exons that contain the CTTCTT sequence and we want to have the coordinates-> regular expression time!
I used this method to find a match:
      search = Bio::Sequence::NA.new("CTTCTT")
      re = Regexp.new(search.to_re)
      match = d_exon.match(re)
BUT I did not know how to get the coordinates of both forward and reverse strands, so I used a method provided by my classmates:
=end
  forward = Array.new
  reverse = Array.new
      match = d_exon.enum_for(:scan, /cttctt/).map{Regexp.last_match.begin(0)} 
      unless match.nil? ##it keeps storing empty positions into the array, I don't know why! :(
        match.each do |x|
          a = x.to_i + start.to_i 
          b = a + 5
          forward = forward.push([a,b])
        end
        
      match = d_exon.enum_for(:scan, /aagaag/).map{Regexp.last_match.begin(0)} 
      unless match.nil? 
        match.each do |x|
          a = x.to_i + start.to_i 
          b = a + 5
          reverse = reverse.push([a,b])
        end
      end
      end

=begin
this code did not work

    elsif exon[0].to_s == 'c' #the exon is in the reverse strand. Format: complement(XXXXX:start_pos..end_pos)
      complem, pos = exon.split":"
      pos = pos.delete!')' #Program stops here. NoMethodError: undefined method `delete!' for nil:NilClass
      start, ends = pos.split".." #we get the start and end position of the exon
      s = start.to_i 
      e = ends.to_i
      d_exon = bioseq.subseq[e-s..bioseq.length.to_i-e-s] #now we have the sequence of the exon
      match = d_exon.enum_for(:scan, /aagaag/).map{Regexp.last_match.begin(0)} #since this is the reverse strand, we are looking for the complement of CTTCTT
      match.each do |x|
        a = x.to_i + s
        b = a + 5
        reverse = reverse.push(a,b)
      end
    end
=end
      #Let's try to get a gff file at least
      forward.uniq.each do |pos|
        gff.puts"#{geneid}\tEMBL\tCTTCTT\t#{pos[0]}\t#{pos[1]}\t.\t+\t" 
        f1 = Bio::Feature.new('CTTCTT', "#{pos[0]}..#{pos[1]}")
        f1.append(Bio::Feature::Qualifier.new('strand', '+'))
      end
      reverse.uniq.each do |pos|
        gff.puts"#{geneid}\tEMBL\tCTTCTT\t#{pos[0]}\t#{pos[1]}\t.\t-\t"
        f1 = Bio::Feature.new('CTTCTT', "#{pos[0]}..#{pos[1]}")
        f1.append(Bio::Feature::Qualifier.new('strand', '-'))
      end
    end
  end
end
gff.close

gff = File.open("feats.gff", "r")
have_exons = Array.new
gff.each do |line|
  line = line.split"\t" #line to array
  line.each do |text|
    text = text.chomp 
  end
  have_exons << line[0] #array of gene ids that have CTTCTT sequence in their exons
end

gfile = File.open("ArabidopsisSubNetwork_GeneList.txt","r")
genenames = gfile.read.split() #remove newlines -> we get an array of all the gene ids
genenames = genenames.sort.map(&:upcase) #returns an uppercased array
have_exons = have_exons.uniq.sort.map(&:upcase) #same, so we can substract them
no_exons = genenames - have_exons
no_exons.each do |nexon|
  nox.puts nexon
end
gfile.close
nox.close

  