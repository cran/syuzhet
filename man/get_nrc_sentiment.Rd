% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/syuzhet.R
\name{get_nrc_sentiment}
\alias{get_nrc_sentiment}
\title{Get Emotions and Valence from NRC Dictionary}
\usage{
get_nrc_sentiment(
  char_v,
  cl = NULL,
  language = "english",
  lowercase = TRUE,
  lexicon = NULL
)
}
\arguments{
\item{char_v}{A character vector}

\item{cl}{Optional, for parallel analysis}

\item{language}{A string}

\item{lowercase}{should tokens be converted to lowercase. Default equals TRUE}

\item{lexicon}{a custom lexicon provided by the user and formatted as a data frame containing two columns labeled as "word" and "sentiment". The "sentiment" column must indicate either the valence of the word (using either the term "positive" or "negative") or the emotional category of the word, using one of the following terms: "anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise", "trust".  For example: the English word "abandon" may appear in your lexicon twice, first with a emotional category of "fear" and again with a value of "negative."  Not all words necessarily need to have a valence indicator.  See example section below}
}
\value{
A data frame where each row represents a sentence From the original file.  The columns include one for each emotion type as well as a positive or negative valence. The ten columns are as follows: "anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise", "trust", "negative", "positive."
}
\description{
Calls the NRC sentiment dictionary to calculate the presence of eight different emotions and their corresponding valence in a text file.
}
\examples{
 
my_lexicon <- data.frame(
word = c("love","love", "hate", "hate"), 
sentiment = c("positive", "joy", "negative", "anger")
)
my_example_text <- "I am in love with R programming.  
  I hate writing code in C."
s_v <- get_sentences(my_example_text)
get_nrc_sentiment(s_v, lexicon=my_lexicon)
}
\references{
Saif Mohammad and Peter Turney.  "Emotions Evoked by Common Words and Phrases: Using Mechanical Turk to Create an Emotion Lexicon." In Proceedings of the NAACL-HLT 2010 Workshop on Computational Approaches to Analysis and Generation of Emotion in Text, June 2010, LA, California.  See: http://saifmohammad.com/WebPages/lexicons.html
}
