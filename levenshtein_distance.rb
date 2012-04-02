require 'set'
require 'pp'
require 'parallel'

class String
  def levenshtein_distance b
    a = self
    # for all i and j, d[i,j] will hold the Levenshtein distance between
    # the first i characters of s and the first j characters of t;
  # note that d has (m+1)x(n+1) values

    base_arr = Array.new(b.length + 1) {0}
    #the distance of any first string to an empty second string
    d = Array.new(a.length + 1) do |i|
      #the distance of any second string to an empty first string
      if i == 0
        (0..b.length).to_a
      else
        arr = base_arr.dup
        arr[0] = i
        arr
      end
    end

    j = 1
    while j <= b.length
      i = 1
      while i <= a.length
        if a[i-1] == b[j-1]
          d[i][j] = d[i-1][j-1]
        else
          d[i][j] = [
            d[i-1][j] + 1,  # a deletion
            d[i][j-1] + 1,  # an insertion
            d[i-1][j-1] + 1 # a substitution
          ].min
        end
        i += 1
      end
      j += 1
    end
    pp d
    d[-1][-1]
  end

  def hamming_distance(b)
    a = self
    i = 0; diff = 0
    while i < a.length
      diff +=1 unless a[i] == b[i]
      i += 1
    end
    diff
  end

  def friend? b
    if (self.length - b.length).abs <= 1
      if self.length == b.length
        hamming_distance(b) == 1
      else
        levenshtein_distance(b) == 1
      end
    end
  end
end

class Word
  attr_accessor :visited, :str
  def initialize(str)
    @str = str
  end

  def length
    str.length
  end

  def friend? word
    str.friend? (word.str)
  end

  def eql? word
    str.eql? word.str
  end

  def hash
    str.hash
  end
end

class WordWorld
  PARALLEL = false
  def initialize(file)
    @is_parallel = PARALLEL
    @words = {}
    file.each_line do |word|
      word.chomp!
      @words[word.length] ||= []
      @words[word.length]<< Word.new(word)
    end
  end

  def close_words word
    words = []
    words<< @words[word.length]
    words<< @words[word.length - 1] || []
    words<< @words[word.length + 1] || []
    words.compact
  end

  def friends word
    friend_set = Set.new
    close_words(word).each do |word_group|
      word_group.each do |other_word|
        next if other_word.visited
        next if (word.length - other_word.length).abs > 1
        if word.friend?(other_word)
          other_word.visited = true
          friend_set<< other_word 
        end
      end
    end
    friend_set
  end

  def network word
    if @is_parallel
      parallel_network Word.new(word)
    else
      single_thread_network Word.new(word)
    end
  end

  def single_thread_network word
    result = Set.new()
    queue = [word]
    counter = 0
    while !queue.empty?
      next_word = queue.shift
      #p next_word
      result.add(next_word) unless next_word == word
      friend_words = friends(next_word)
      queue += (friend_words).to_a
      #p "#{queue.size} - q"
      #p result.size
      counter +=1
    end
    result
  end

  def parallel_network word
    result = Set.new()
    queue = [word]
    while !queue.empty?
      friend_sets = Parallel.map_with_index(queue) {|current_word, idx|
        print "#{idx}, "
        friends(current_word)
      }
      queue = friend_sets.reduce(Set.new) do |all_friends, friend_set|
        all_friends += friend_set
      end
      result += queue
      #p queue
      #p queue.size
      #p result.size
    end
    result
  end

  def network_size_for word
    net = network(word)
    f = File.open('result.txt', 'w')
    net.each do |w|
      f.write("#{w.str}\n")
    end
    f.close
    net.length
  end
end

if __FILE__ == $PROGRAM_NAME
  world = WordWorld.new(File.new(ARGV[0]))
  p "vexilla".levenshtein_distance "vexing"
  #puts world.network_size_for "causes"
end
