Description

Two words are friends if they have a Levenshtein distance of 1 (For details see http://en.wikipedia.org/wiki/Levenshtein_distance). That is, you can add, remove, or substitute exactly one letter in word X to create word Y. A word’s social network consists of all of its friends, plus all of their friends, and all of their friends’ friends, and so on. Write a program to tell us how big the social network for the word 'hello' is, using this word list https://raw.github.com/codeeval/Levenshtein-Distance-Challenge/master/input_levenshtein_distance.txt

Input sample:

Your program should accept as its first argument a path to a filename.The input file contains the word list. This list is also available at https://raw.github.com/codeeval/Levenshtein-Distance-Challenge master/input_levenshtein_distance.txt .

Output sample:

Print out how big the social network for the word 'hello' is. e.g. The social network for the words 'causes' and 'abcde' is 7630 and 7632 respectively.
