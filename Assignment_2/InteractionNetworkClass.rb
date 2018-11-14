class InteractionNetwork
	attr_accessor :gene, :interactors, :kegg_id, :kegg_path, :go_id
	def initialize (params = {})
		@gene = params.fetch(:gene, 'none')
		@interactors = params.fetch(:interactors, [])
		@kegg_id = params.fetch(:kegg_id, [])
        @kegg_path = params.fetch(:kegg_path, [])
        @go_id = params.fetch(:go_id, [])
	end
end

=begin
This class will be used to store the interaction networks.
We will store the code of the original gene (from the list)
then add the members of the network as interactors
We will annotate each network with the relevant GO and KEGG terms and codes.
=end