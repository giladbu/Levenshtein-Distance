import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;


public class levenshtein_distance {

	public class Word {
		private final static int THRESHOLD=1;
		private static final int MAX_VALUE = 100;
		private String str;
		private boolean visited = false;

		public Word(String str) {
			this.str = str;
		}
		
		public String toString() {
			return getStr();
		}

		public void setStr(String str) {
			this.str = str;
		}

		public String getStr() {
			return str;
		}
		
		public int length() {
			return str.length();
		}
		
		public boolean equals(Object other) {
			return this.str.equals(((Word) other).str);
		}
		public int hashCode() {
			return str.hashCode();
		}
		
		public boolean isFriend(Word other){
			int distance = hammingDistance(other);
//			if(other.length() == this.length()) {
//				distance = hammingDistance(other);
//			}else{
//				distance = levenshteinDistance(other);
//			}
			return distance == 1;
		}

		private int levenshteinDistance(Word other) {
			String a = this.str;
			String b = other.str;

			if(a.length() < b.length()) {
				a = b;
				b = this.str;
			}

			int[] pre  = new int[b.length() + 1];
			int[] dis = new int[b.length() + 1];
			int[] tmp = new int[b.length() + 1];
			for(int i = 0 ; i <= THRESHOLD; i++){
				pre[i] = i;
			}
			Arrays.fill(pre, THRESHOLD+1, b.length(), MAX_VALUE);
			Arrays.fill(dis, MAX_VALUE);

			for(int j=1 ; j <= a.length(); j++) {
				dis[0] = j;
				int minIdx = Math.max(j - THRESHOLD, 1);
				int maxIdx = Math.min(j + THRESHOLD, b.length());
				if(minIdx > 1){
					dis[minIdx -1] = MAX_VALUE;
				}
				int minVal = MAX_VALUE;
				for(int i = minIdx ; i <= maxIdx ; i++){
					if(a.charAt(j-1) == b.charAt(i-1)){
						dis[i] = pre[i-1];
					} else {
						dis[i] = Math.min(pre[i], Math.min(dis[i-1], pre[i-1])) + 1;
					}
					if(dis[i] < minVal) minVal = dis[i];
				}
				tmp = pre;
				pre = dis;
				dis = tmp;
				if(minVal > THRESHOLD) break;
			}
			return pre[b.length()];
		}

		private int hammingDistance(Word other) {
			int distance = 0;
			String a = this.str; 
			String b = other.str;
			if(a.length() < b.length()){
				a = b;
				b = this.str;
			}
			int diff = a.length() - b.length();
			int prefix = 0;
			for(int i = 0 ; i < a.length() ; i ++){
				if(i + prefix < b.length() && a.charAt(i) != b.charAt(i + prefix)){
					if(diff > 0 && prefix == 0){
						prefix = -1;
					} else {
						distance +=1;
						if(distance > THRESHOLD) {
							break;
						}
					}
				}
			}
			return distance + diff;
		}
		public void setVisited(boolean visited) {
			this.visited = visited;
		}
		public boolean isVisited() {
			return visited;
		}
	}
	private HashMap<Integer, List<Word>> words;

	public levenshtein_distance(BufferedReader in) throws IOException {
		this.words = new HashMap<Integer, List<Word>>();
		String line;
		while ((line = in.readLine()) != null) {
			Word word = new Word(line.trim());
			List<Word> wordsOfLength = words.get(word.length());
			if(wordsOfLength == null) {
				wordsOfLength = new LinkedList<Word>();
			}
			wordsOfLength.add(word);
			words.put(word.length(), wordsOfLength);
		}
	}

	private List<List<Word>> closeWords(Word word) {
		List<List<Word>> result = new LinkedList<List<Word>>();
		result.add(this.words.get(word.length()));
		if(this.words.containsKey(word.length() - 1)){
			result.add(this.words.get(word.length() - 1));
		}
		if(this.words.containsKey(word.length() + 1)){
			result.add(this.words.get(word.length() + 1));
		}
		return result;
	}

	private int networkSize(String string) throws InterruptedException, ExecutionException {
		Set<Word> net = network(new Word(string));
		return net.size();
	}

	private Set<Word> parallelNetwork(Word word) throws InterruptedException, ExecutionException {
		HashSet<Word> result = new HashSet<Word>();
		LinkedList<Word> queue = new LinkedList<Word>();
		queue.add(word);
		ExecutorService exec = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
		while(!queue.isEmpty()) {
			LinkedList<Callable<List<Word>>> tasks = new LinkedList<Callable<List<Word>>>();
			for(Word otherWord : queue){
				final Word fWord = otherWord;
				tasks.add(new Callable<List<Word>>() {
					
					public List<Word> call() throws Exception {
						return friends(fWord);
					}
				});
			}
			List<Future<List<Word>>> mapperResults = exec.invokeAll(tasks);
			queue.clear();
			for(Future<List<Word>> f : mapperResults) { 
				queue.addAll(f.get());
			}
			queue.removeAll(result);
			result.addAll(queue);
		}
		exec.shutdown();
		return result;
	}
	private Set<Word> network(Word word) throws InterruptedException, ExecutionException {
		if(Runtime.getRuntime().availableProcessors() > 1) return parallelNetwork(word);

		HashSet<Word> result = new HashSet<Word>();
		LinkedList<Word> queue = new LinkedList<Word>();
		queue.add(word);
		while(!queue.isEmpty()) {
			Word nextWord = queue.removeFirst();
			if(nextWord != word) result.add(nextWord);
			queue.addAll(friends(nextWord));
		}
		return result;
	}
	
	private List<Word> friends(Word word) {
		LinkedList<Word> friendSet = new LinkedList<Word>();
		for(List<Word> wordGroup : closeWords(word)) {
			for(Word otherWord : wordGroup) {
				if(otherWord.isVisited()) continue;
				if(word.isFriend(otherWord)) {
					otherWord.setVisited(true);
					friendSet.add(otherWord);
				}
			}
		}
		return friendSet;
	}

	/**
	 * @param args
	 * @throws ExecutionException 
	 * @throws InterruptedException 
	 */
	public static void main(String[] args) throws InterruptedException, ExecutionException {
		try {
			File file = new File(args[0]);
			BufferedReader in = new BufferedReader(new FileReader(file));
			levenshtein_distance world = new levenshtein_distance(in);
			System.out.println(world.networkSize("hello"));
		} catch (IOException e) {
			System.out.println("File Read Error: " + e.getMessage());
		}
	}
}
