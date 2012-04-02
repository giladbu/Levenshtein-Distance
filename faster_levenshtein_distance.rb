require 'set'
require 'pp'
require 'parallel'

class String
  INFINITY = 1.0/0
  def levenshtein_distance b, threshold=1
    a = self
    # for all i and j, d[i,j] will hold the Levenshtein distance between
    # the first i characters of s and the first j characters of t;
  # note that d has (m+1)x(n+1) values

    if a.length < b.length
      tmp = a
      a = b
      b = tmp
    end

    pre  = Array.new(b.length + 1) {|i| i < threshold + 1 ? i : INFINITY}
    dis = Array.new(b.length + 1) { INFINITY }
    for j in (1 .. a.length)
      dis[0] = j
      min_idx = [j - threshold, 1].max
      max_idx = [j + threshold, b.length].min
      #since we are reusing array, we should initialize it correctly
      if min_idx > 1
        dis[min_idx - 1] = INFINITY
      end
      min_val = INFINITY
      for i in (min_idx..max_idx)
        if a[j-1] == b[i-1]
          dis[i] = pre[i-1]
        else
          dis[i] = [
            pre[i] + 1,  # a deletion
            dis[i-1] + 1,  # an insertion
            pre[i-1] + 1 # a substitution
          ].min
        end
        min_val = dis[i] if dis[1] < min_val
      end
      #swap arrays
      d_ = pre
      pre = dis
      dis = d_
      break if min_val > threshold
    end
    pre[b.length]
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
    while !queue.empty?
      next_word = queue.shift
      #p next_word
      result.add(next_word) unless next_word == word
      friend_words = friends(next_word)
      queue += (friend_words).to_a
      #p "#{queue.size} - q"
      #p result.size
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
        all_friends += (friend_set - result)
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
    f = File.open('faster_result.txt', 'w')
    net.each do |w|
      f.write("#{w.str}\n")
    end
    f.close
    net.length
  end
end

if __FILE__ == $PROGRAM_NAME
  world = WordWorld.new(File.new(ARGV[0]))
  puts world.network_size_for "hello"
end
