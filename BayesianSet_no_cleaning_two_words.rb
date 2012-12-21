class BayesianSet
	attr_accessor :p_word_counts, :n_word_counts, :num_p_tweets, :num_n_tweets, :p_text, :n_text,
	             :p_bigrams, :n_bigrams, :prob_of_n
	
	
	def initialize(p_file_name, n_file_name)
		@p_word_counts = {}
		@n_word_counts = {}
		@num_p_tweets = 0
		@num_n_tweets = 0
		@p_text = ""
		@n_text = ""
		@p_bigrams = {}
		@n_bigrams = {}
		@prob_of_n = {}
		
		File.new(p_file_name, "r").each_line do |line|
			@p_text = @p_text + " " + line.chomp
			@num_p_tweets += 1
		end
		
		File.new(n_file_name, "r").each_line do |line|
			@n_text = @n_text + " " + line.chomp
			@num_n_tweets += 1
		end
		
		#clean_texts
		create_tables
		calculate_probabilities_using_bigrams
	end
	
	
	def clean_texts
		@p_text.gsub!(/(.)\1\1\1*/, '\1\1') #turns sooo, sooooo -> soo
		@p_text.gsub!(/http:\S*/, ' ') #removes urls
		@p_text.gsub!(/@\w+/, ' ') #removes user tags
		@p_text.gsub!(/\W/, ' ') #removes non-word characters
		@p_text.gsub!(/RT\s/, ' ') #removes RT
		
		@n_text.gsub!(/(.)\1\1\1*/, '\1\1')
		@n_text.gsub!(/http:\S*/, ' ')
		@n_text.gsub!(/@\w+/, ' ')
		@n_text.gsub!(/\W/, ' ')
		@n_text.gsub!(/RT\s/, ' ')
	end
	
	
	def create_tables
		words = []
		#@p_text.downcase.scan(/\w+/) {|word| words << word} #adds each word to word array
		@p_text.downcase.split(" ").map {|word| words << word}
		
		for i in 0..words.length - 2
			add_word(words[i], words[i + 1], @p_word_counts, @p_bigrams)
		end
		
		add_word(words.last, :end_file, @p_word_counts, @p_bigrams)
		
		words.clear
		#@n_text.downcase.scan(/\w+/) {|word| words << word}
		@n_text.downcase.split(" ").map {|word| words << word}

		for i in 0..words.length - 2
			add_word(words[i], words[i + 1], @n_word_counts, @n_bigrams)
		end
		
		add_word(words.last, :end_file, @n_word_counts, @n_bigrams)
	end
	
	
	def add_word(word, next_word, count_table, bigram_table)
		bigram_table[word] ||= {}
    bigram_table[word][next_word] ||=0
    bigram_table[word][next_word] +=1
    count_table[word] ||= 0
    count_table[word] += 1
	end
	
	
	def calculate_probabilities
		words = (@p_word_counts.keys + @n_word_counts.keys).uniq
		
		for i in 0..words.length - 1
			p = @p_word_counts[words[i]] 
			if(p == nil) 
				p = 0 
			end
			
			n = @n_word_counts[words[i]]
			if(n == nil)
				n = 0
			end
			
			@prob_of_n[words[i]] = [0.01, [0.99, [1.0, n.to_f / @num_n_tweets.to_f].min / ([1.0, p.to_f / @num_p_tweets.to_f].min + [1.0, n.to_f / @num_n_tweets.to_f].min)].min].max
		end
	end
	
	
	def calculate_probabilities_using_bigrams
		words = (@p_bigrams.keys + @n_bigrams.keys).uniq
		
		for i in 0..words.length - 1
			next_p_words = @p_bigrams[words[i]]
			next_n_words = @n_bigrams[words[i]]
			
			if(next_p_words == nil and next_n_words == nil)
				p = 0
				n = 0
			elsif(next_p_words == nil and next_n_words != nil)
				next_words = next_n_words.keys.uniq
				p = 0
			elsif(next_p_words != nil and next_n_words == nil)
				next_words = next_p_words.keys.uniq
				n = 0
			else
				next_words = (next_p_words.keys + next_n_words.keys).uniq
			end
				
		
			#next_words = (@p_bigrams[words[i]].keys + @n_bigrams[words[i]].keys).uniq
			
			for j in 0..next_words.length - 1
				if(@p_bigrams[words[i]] == nil)
					p = 0
				else
					p = @p_bigrams[words[i]][next_words[j]]
					if(p == nil)
						p = 0
					end
				end
				
				if(@n_bigrams[words[i]] == nil)
					n = 0
				else
					n = @n_bigrams[words[i]][next_words[j]]
					if(n == nil)
						n = 0
					end
				end
				
				@prob_of_n[words[i].to_s+ " " + next_words[j].to_s] = [0.01, [0.99, [1.0, n.to_f / @num_n_tweets.to_f].min / ([1.0, p.to_f / @num_p_tweets.to_f].min + [1.0, n.to_f / @num_n_tweets.to_f].min)].min].max
			end
		end
	end
	
end