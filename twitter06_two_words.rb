$LOAD_PATH << "/Users/gray/Documents/cs370/twitter_project/github_project"

#some things to try--word bigrams
#not sanitizing the input--should wash out

require "BayesianSet_no_cleaning_two_words.rb"
require "rubygems"
require "twitter"

#-------Global Variables-----
@num_focus_words = 10
@default_for_unseen_words = 0.4
@trends = nil
@num_trends = nil
@search_term = nil

#-------Helper Methods-------

def Boolean(string)
    return true if string == true || string =~ /^true$/i
    return false if string == false || string.nil? || string =~ /^false$/i
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
end


def clean_text(text)
	text.gsub!(/(.)\1\1\1*/, '\1\1') #turns sooo, sooooo -> soo
	text.gsub!(/http:\S*/, ' ') #removes urls
	text.gsub!(/@\w+/, ' ') #removes user tags
	text.gsub!(/\W/, ' ') #removes non-word characters
	text.gsub!(/RT\s/, ' ') #removes RT
	
	return text
end


def find_focus_words(tweet, set)
	clean_tweet = clean_text(tweet.dup)
	words = []
	probs = []
	focus_words = []
	
	clean_tweet.downcase.scan(/\w+/) {|word| words << word}
	
	words.uniq!
	
	for i in 0..words.length - 1
		if(set.prob_of_n[words[i]] == nil)
			probs[i] = @default_for_unseen_words #default if we've never seen the word before
		else
			probs[i] = (0.5 - set.prob_of_n[words[i]]).abs
		end
	end
	
	for i in 1..@num_focus_words
		unless(words.length == 0 or probs.length == 0)
			index = probs.index(probs.max)
			focus_words << words[index]
		
			words.delete_at(index)
			probs.delete_at(index)
		end
	end
	
	return focus_words
end


def find_focus_words_using_bigrams(tweet, set)
	words = []
	bigrams = []
	probs = []
	focus_words = []
	
	clean_tweet = clean_text(tweet.dup)
	
	clean_tweet.downcase.scan(/\w+/) {|word| words << word}
	
	for i in 0..words.length - 2
		bigrams << words[i].to_s + " " + words[i+1].to_s
	end
	
	bigrams.uniq!
	
	for i in 0..bigrams.length - 1
		if(set.prob_of_n[bigrams[i]] == nil)
			probs[i] = @default_for_unseen_words #default if we've never seen the word before
		else
			probs[i] = (0.5 - set.prob_of_n[bigrams[i]]).abs
		end
	end
	
	for i in 1..@num_focus_words
		unless(bigrams.length == 0 or probs.length == 0)
			index = probs.index(probs.max)
			focus_words << bigrams[index]
		
			bigrams.delete_at(index)
			probs.delete_at(index)
		end
	end
	
	return focus_words
	
end


def calc_probability_of_n(tweet, set)
	focus_words= find_focus_words(tweet, set)
	
	n = 1.0
	d = 1.0
	
	for i in 0..focus_words.length - 1
		if(set.prob_of_n[focus_words[i]] == nil)
			n = n * @default_for_unseen_words
			d = d * @default_for_unseen_words
			
		else 
			n = n * set.prob_of_n[focus_words[i]]
			d = d * (1.0 - set.prob_of_n[focus_words[i]])
		end
	end
	
	return n / (n + d)
end


def calc_probability_of_n_using_bigrams(tweet, set)
	focus_words = find_focus_words_using_bigrams(tweet, set)
	
	print_focus_words(focus_words, set)
	
	n = 1.0
	d = 1.0
	
	for i in 0..focus_words.length - 1
		if(set.prob_of_n[focus_words[i]] == nil)
			n = n * @default_for_unseen_words
			d = d * @default_for_unseen_words
			
		else 
			n = n * set.prob_of_n[focus_words[i]]
			d = d * (1.0 - set.prob_of_n[focus_words[i]])
		end
	end
	
	return n / (n + d)
end


def print_focus_words(focus_words, set)
	for i in 0..focus_words.length - 1
		puts focus_words[i].to_s + "    " + set.prob_of_n[focus_words[i]].to_s
	end
	
	puts
end


def print_results(results)
	keys = results.keys
	
	for i in 0..keys.length - 1
		puts keys[i] + ": "
		
		value = results[keys[i]]
		
		for j in 0..value.length - 2
			puts "  " + value[j][0]
			puts "  " + value[j][1].to_s
		end
		
		puts "  Average: " + value.last.to_s
		puts
	end
end


def calc_average(results)
	keys = results.keys
	
	for i in 0..keys.length - 1
		total = 0.0
		value = results[keys[i]]
		
		for j in 0..value.length - 1
			total += value[j][1]
		end
		
		value << total / value.length.to_f
		results[keys[i]] = value
	end
end


#borrowing keys from language_clout
def configure_twitter
  Twitter.configure do |config|
    config.consumer_key = "VowhzjVm7OWLZmHGxosVyg"
    config.consumer_secret = "Pwkd1J2rxWVaejWdvg1MOW2qHmP6lAncP0EDTXWvZM"
    config.oauth_token = "109484472-I0kSWE9FnpxjlzUrDmL0eIFxkcDxnkLyIaZskQhf"
    config.oauth_token_secret = "1PmK1OlThcRsiYgHYwOdRHXVEboog5jukq35nIUNauA"
  end
end


#-----------Begin-----------
configure_twitter

if(ARGV.length != 2)
	abort("Error: takes two arguments")
end

@trends = Boolean(ARGV[0])

if(@trends)
	@num_trends = ARGV[1].to_i
else
	@search_term = ARGV[1]
end

set = BayesianSet.new("positive_tweets_20111115.txt", "negative_tweets_20111115.txt")

results = {}

if(@trends)
	trends = []

  a = Twitter.trends(1) #global trends

  for i in 0...a.length
    trends << a[i].name
  end
	
	for i in 0...@num_trends
		tweets = []
		results_entry = []
		positive = 0
		negative = 0
		
		index = rand(trends.length)

    Twitter.search(trends[index], :lang => "en").results.each do |t|
      tweets << t.text
    end
	
		for j in 0..tweets.length - 1
		
			p = calc_probability_of_n_using_bigrams(tweets[j], set)
		
			results_entry << [tweets[j], p] 
		end
	
		results[trends[index]] = results_entry
	end
else
	tweets = []
	results_entry = []
	positive = 0
	negative = 0

  Twitter.search(@search_term, :lang => "en").results.each do |t|
    tweets << t.text
  end
	
	for i in 0..tweets.length - 1
		p = calc_probability_of_n_using_bigrams(tweets[i], set)
		
		results_entry << [tweets[i], p]
	end
	
	results[@search_term] = results_entry
end

calc_average(results)
print_results(results)