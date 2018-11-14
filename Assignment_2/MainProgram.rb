# It takes A LOT of time to run this program. Only interactors from the gene list are included.

require 'net/http'  
require 'json'  
require "./InteractionNetworkClass.rb" 

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
     

def reduce(array) # in a multidimensional array, this merges arrays containing one or more similar items
  h = Hash.new {|h,k| h[k] = []}
  array.each_with_index do |x, i| 
    x.each do |j|
      h[j] << i
      if h[j].size > 1
        array[h[j][0]].replace((array[h[j][0]] | array[h[j][1]]).sort) # merge the two sub arrays
        array.delete_at(h[j][1]) # delete the one we don't need
        return reduce(array) # recurse until nothing needs to be merged
      end
    end
  end
  array
end

locus_codes = IO.readlines("ArabidopsisSubNetwork_GeneList.txt") # read the list and store it into an array
intntwk_obj_list = [] #array in which we'll store the interaction network objects

#Getting gene ids and protein ids
locus_codes.each do |x| # for each code of the list we create a gene object and search the protein ids on uniprot
  uniprot_uri = 'https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprot&format=default&style=raw&id='
  x = x.chomp
  uniprot_uri = uniprot_uri + x # add the code to the uri
  uniprot_res = fetch(uniprot_uri); # now we get the uniprot info
  uniprot_res = uniprot_res.body # and only save the body
  matches = uniprot_res.scan(/^AC\s+(\w+);/) # getting the uniprot ids
  x = InteractionNetwork.new(:gene=>x, :interactors=>matches) # now we create the network object and store the proteins associated
  intntwk_obj_list.push(x) # store the object to an array for later use
  
#Interactors of the proteins
  total_interacts = [] # array to store interactors of the nework
  x.interactors.each do |y|
    togows_uri = "http://togows.dbcls.jp/entry/uniprot/" + y[0].to_s + '/dr.json'
    togows_res = fetch(togows_uri)
    togows_res = JSON.parse(togows_res.body)
    intact = togows_res[0]["IntAct"]
    unless intact.nil? #if there is an Interaction list
      prote = intact[0][0] # get the prot accession which will be used to get the interaction info
      prote = prote.to_s
      intact_uri = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{prote}"
      intact_res = fetch(intact_uri)
      intact_res = intact_res.body
      interacts = intact_res.scan(/^uniprotkb:#{prote}\s+uniprotkb:(\w+)/) # getting the interactors' accessions
    end
    total_interacts = total_interacts.push(*interacts)
  end  
  x.interactors = x.interactors.push(*total_interacts)
  x.interactors = x.interactors.uniq #if there were duplicated interactors, we remove them with uniq
  
##Annotations of KEGG and GO terms
  unip_uri = 'https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprot&format=default&style=raw&id=' # here we'll obtain KEGG IDs and GO terms and IDs
  x.interactors.each do |p| # add the interactors' names to the uri
    unip_uri = unip_uri + p[0].to_s + ','
  end
  unip_res = fetch(unip_uri);
  unip_res = unip_res.body
  kegg_ids = unip_res.scan(/KEGG;\s(ath:\w+);/) # getting the kegg ids
  kegg_ids = kegg_ids.uniq # here we have all the kegg IDs of the network (not duplicated)
  x.kegg_id = kegg_ids 
  
  go_ids = unip_res.scan(/GO;\s(GO:\d{7};\sP.+)$/) # getting GO terms and IDs (just those of the biological_process)
  x.go_id = go_ids
  x.go_id = x.go_id.uniq

  kegg_ids.each do |kegg| #now we search for the kegg PATHWAY ids and descriptions
    path_uri = 'http://togows.org/entry/enzyme/'
    path_uri = path_uri + kegg[0].to_s
    path_res = fetch(path_uri)
    path_res = path_res.body
    kegg_desc = path_res.scan(/(ath\d{5}\s+.+)$/) # getting the kegg pathway id + description
    if not kegg_desc.empty?
      x.kegg_path = x.kegg_path.push(kegg_desc)
    end
  end
end

#Gene interactions through the interaction Network objects
intntwk_obj_list.each do |ntwk| # some formatting of the objects for later comparisson
  ntwk.interactors = (ntwk.interactors.flatten).uniq
  ntwk.kegg_id = (ntwk.kegg_id.flatten).uniq
  ntwk.kegg_path = (ntwk.kegg_path.flatten).uniq
  ntwk.go_id = (ntwk.go_id.flatten).uniq
end

output_file=File.new("interaction_report.txt", "w") #create output file to save the interactions
output_file.puts "Interaction Report\n"
network_file=File.new("networks_report.txt", "w") #create output file to save the networks
network_file.puts "\t\tNetwork Report\nThe networks found are:"

interaction_array = [] # in this array we will store the interacting genes and will use it to define the networks later
intntwk_obj_list.each do |ntwk1| # iterate to find which genes interact
  intntwk_obj_list.each do |ntwk2|
    if not ntwk1.gene == ntwk2.gene # if they are not the same gene, we compare the interactors we've found before
      intersect = ntwk1.interactors & ntwk2.interactors
      if not intersect.empty? # if we find interacting proteins we store that in a file 
        output_file.puts " --- #{ntwk1.gene} interacts with #{ntwk2.gene} --- "
        interaction_array = interaction_array.push([ntwk1.gene,ntwk2.gene])
        output_file.puts "\tcommon interactor(s) are: #{(ntwk1.interactors & ntwk2.interactors).join(",")}"
        output_file.puts "\tGO Terms" # then annotate it with the GO terms
        output_file.puts (ntwk1.go_id | ntwk2.go_id)
        output_file.puts "\tKEGG Pathways" # and the KEGG info
        output_file.puts (ntwk1.kegg_path | ntwk2.kegg_path)
        output_file.puts "\t ****************\n"
      end
    end
  end
end

int_networks = reduce (interaction_array)
int_networks.each do |i|
  network_file.puts "#{i.join(',')}\n" # in another file we store the networks for easier interpretation
end


puts "Process complete"
