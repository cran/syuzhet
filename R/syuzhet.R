#' Load Text from a File
#' @description
#' Loads a file as a single text string. 
#' @param path_to_file file path
#' @export
#' @return A character vector of length 1 containing the text of the file in the path_to_file argument.
#' 
get_text_as_string <- function(path_to_file){
  text_of_file <- readLines(path_to_file)
  return(NLP::as.String(paste(text_of_file, collapse = " ")))
}

#' Word Tokenization
#' @description
#' Parses a string into a vector of word tokens.
#' @param text_of_file A Text String
#' @param pattern A regular expression for token breaking
#' @param lowercase should tokens be converted to lowercase. Default equals TRUE
#' @return A Character Vector of Words
#' @export
#' 
get_tokens <- function(text_of_file, pattern = "\\W", lowercase = TRUE){
  if(lowercase){
    text_of_file <- tolower(text_of_file)
  }
  tokens <- unlist(strsplit(text_of_file, pattern))
  tokens[which(tokens != "")]
}

#' Sentence Tokenization
#' @description
#' Parses a string into a vector of sentences.
#' @param text_of_file A Text String
#' @param fix_curly_quotes logical.  If \code{TRUE} curly quotes will be 
#' converted to ASCII representation before splitting.
#' @param as_vector If \code{TRUE} the result is unlisted.  If \code{FALSE}
#' the result stays as a list of the original text string elements split into 
#' sentences.
#' @return A Character Vector of Sentences
#' @export
#' @examples
#' (x <- c(paste0(
#'     "Mr. Brown comes! He says hello. i give him coffee.  i will ",
#'     "go at 5 p. m. eastern time.  Or somewhere in between!go there"
#' ),
#' paste0(
#'     "Marvin K. Mooney Will You Please Go Now!", "The time has come.",
#'     "The time has come. The time is now. Just go. Go. GO!",
#'     "I don't care how."
#' )))
#' 
#' get_sentences(x)
#' get_sentences(x, as_vector = FALSE)
#' 
#' 

get_sentences <- function(text_of_file, fix_curly_quotes = TRUE, as_vector = TRUE){
  if (!is.character(text_of_file)) stop("Data must be a character vector.")
  if (isTRUE(fix_curly_quotes)) text_of_file <- replace_curly(text_of_file)
  splits <- textshape::split_sentence(text_of_file)
  if (isTRUE(as_vector)) splits <- unlist(splits)
  splits
}

## helper curly quote replacement function
replace_curly <- function(x, ...){
    replaces <- c('\x91', '\x92', '\x93', '\x94')
    Encoding(replaces) <- "latin1"
    for (i in 1:4) {
        x <- gsub(replaces[i], c("'", "'", "\"", "\"")[i], x, fixed = TRUE)
    }
    x
}


#' Get Sentiment Values for a String
#' @description
#' Iterates over a vector of strings and returns sentiment values based on user supplied method. The default method, "syuzhet" is a custom sentiment dictionary developed in the Nebraska Literary Lab.  The default dictionary should be better tuned to fiction as the terms were extracted from a collection of 165,000 human coded sentences taken from a small corpus of contemporary novels.   
#' At the time of this release, Syuzhet will only work with languages that use Latin character sets.  This effectively means that "Arabic", "Bengali", "Chinese_simplified", "Chinese_traditional", "Greek", "Gujarati", "Hebrew", "Hindi", "Japanese", "Marathi", "Persian", "Russian", "Tamil", "Telugu", "Thai", "Ukranian", "Urdu", "Yiddish" are not supported even though these languages are part of the extended NRC dictionary.
#' 
#' @param char_v A vector of strings for evaluation.
#' @param method A string indicating which sentiment method to use. Options include "syuzhet", "bing", "afinn", "nrc" and "stanford."  See references for more detail on methods.
#' @param language A string. Only works for "nrc" method
#' @param cl Optional, for parallel sentiment analysis.
#' @param path_to_tagger local path to location of Stanford CoreNLP package
#' @param lexicon a data frame with at least two columns labeled "word" and "value."
#' @param regex A regular expression for splitting words.  Default is "[^A-Za-z']+"
#' @param lowercase should tokens be converted to lowercase. Default equals TRUE
#' @references Bing Liu, Minqing Hu and Junsheng Cheng. "Opinion Observer: Analyzing and Comparing Opinions on the Web." Proceedings of the 14th International World Wide Web conference (WWW-2005), May 10-14, 2005, Chiba, Japan.  
#' 
#' @references Minqing Hu and Bing Liu. "Mining and Summarizing Customer Reviews." Proceedings of the ACM SIGKDD International Conference on Knowledge Discovery and Data Mining (KDD-2004), Aug 22-25, 2004, Seattle, Washington, USA.  See: http://www.cs.uic.edu/~liub/FBS/sentiment-analysis.html#lexicon
#' 
#' @references Saif Mohammad and Peter Turney.  "Emotions Evoked by Common Words and Phrases: Using Mechanical Turk to Create an Emotion Lexicon." In Proceedings of the NAACL-HLT 2010 Workshop on Computational Approaches to Analysis and Generation of Emotion in Text, June 2010, LA, California.  See: http://saifmohammad.com/WebPages/lexicons.html
#' 
#' @references Finn Årup Nielsen. "A new ANEW: Evaluation of a word list for sentiment analysis in microblogs", Proceedings of the ESWC2011 Workshop on 'Making Sense of Microposts':Big things come in small packages 718 in CEUR Workshop Proceedings : 93-98. 2011 May. http://arxiv.org/abs/1103.2903. See: http://www2.imm.dtu.dk/pubdb/views/publication_details.php?id=6010
#' 
#' @references Manning, Christopher D., Surdeanu, Mihai, Bauer, John, Finkel, Jenny, Bethard, Steven J., and McClosky, David. 2014. The Stanford CoreNLP Natural Language Processing Toolkit. In Proceedings of 52nd Annual Meeting of the Association for Computational Linguistics: System Demonstrations, pp. 55-60.  See: http://nlp.stanford.edu/software/corenlp.shtml
#' 
#' @references Richard Socher, Alex Perelygin, Jean Wu, Jason Chuang, Christopher Manning, Andrew Ng and Christopher Potts.  "Recursive Deep Models for Semantic Compositionality Over a Sentiment Treebank Conference on Empirical Methods in Natural Language Processing" (EMNLP 2013).  See: http://nlp.stanford.edu/sentiment/
#' 
#' @return Return value is a numeric vector of sentiment values, one value for each input sentence.
#' @importFrom rlang .data
#' @export
#' 
get_sentiment <- function(char_v, method = "syuzhet", path_to_tagger = NULL, cl=NULL, language = "english", lexicon = NULL, regex = "[^A-Za-z']+", lowercase = TRUE){
  if(lowercase == TRUE){
    char_v <- tolower(char_v)
  }
  language <- tolower(language)
  if(is.na(pmatch(method, c("syuzhet", "afinn", "bing", "nrc", "stanford", "custom")))) stop("Invalid Method")
  if(!is.character(char_v)) stop("Data must be a character vector.")
  if(!is.null(cl) && !inherits(cl, 'cluster')) stop("Invalid Cluster")
  if(language %in% tolower(c("Arabic", "Bengali", "Chinese_simplified", "Chinese_traditional", "Greek", "Gujarati", "Hebrew", "Hindi", "Japanese", "Marathi", "Persian", "Russian", "Tamil", "Telugu", "Thai", "Ukranian", "Urdu", "Yiddish"))) stop ("Sorry, your language choice is not yet supported.")
  if(method == "syuzhet"){
    char_v <- gsub("-", "", char_v) # syuzhet lexicon removes hyphens from compound words.
  }
  if(method == "afinn" || method == "bing" || method == "syuzhet"){
    word_l <- strsplit(char_v, regex)
    if(is.null(cl)){
      result <- unlist(lapply(word_l, get_sent_values, method))
    }
    else {
      result <- unlist(parallel::parLapply(cl=cl, word_l, get_sent_values, method))
    }
  }
  else if(method == "nrc"){ 
    # TODO Try parallelize nrc sentiment
    word_l <- strsplit(char_v, regex)
    # lexicon <- nrc[which(nrc$lang == language & nrc$sentiment %in% c("positive", "negative")),]
    lexicon <- dplyr::filter(nrc, .data$lang == tolower(language), .data$sentiment %in% c("positive", "negative"))
    lexicon[which(lexicon$sentiment == "negative"), "value"] <- -1
    if(lowercase){
      lexicon$word <- tolower(lexicon$word)
    }
    result <- unlist(lapply(word_l, get_sent_values, method, lexicon))
  } 
  else if(method == "custom"){
    word_l <- strsplit(char_v, regex)
    result <- unlist(lapply(word_l, get_sent_values, method, lexicon))
  }
  else if(method == "stanford") {
    if(is.null(path_to_tagger)) stop("You must include a path to your installation of the coreNLP package.  See http://nlp.stanford.edu/software/corenlp.shtml")
    result <- get_stanford_sentiment(char_v, path_to_tagger)
  }
  return(result)
}

#' Assigns Sentiment Values
#' @description
#' Assigns sentiment values to words based on preloaded dictionary. The default is the syuzhet dictionary.
#' @param char_v A string
#' @param method A string indicating which sentiment dictionary to use
#' @param lexicon A data frame with with at least two columns named word and value. Works with "nrc" or "custom" method.  If using custom method, you must load a custom lexicon as a data frame with aforementioend columns.
#' @return A single numerical value (positive or negative)
#' based on the assessed sentiment in the string
#' @export
#' @importFrom rlang .data
#' 
get_sent_values <- function(char_v, method = "syuzhet", lexicon = NULL){
  if(method == "bing") {
    result <- sum(bing[which(bing$word %in% char_v), "value"])
  }
  else if(method == "afinn"){
    result <- sum(afinn[which(afinn$word %in% char_v), "value"])
  }
  else if(method == "syuzhet"){
    char_v <- gsub("-", "", char_v)
    result <- sum(syuzhet_dict[which(syuzhet_dict$word %in% char_v), "value"])
  }
  else if(method == "nrc" || method == "custom") {
    data <- dplyr::filter(lexicon, .data$word %in% char_v)
    result <- sum(data$value)
  }
  return(result)
}

#' Get Emotions and Valence from NRC Dictionary
#' @description
#' Calls the NRC sentiment dictionary to calculate the presence of eight different emotions and their corresponding valence in a text file.
#' @param char_v A character vector
#' @param language A string
#' @param cl Optional, for parallel analysis
#' @param lowercase should tokens be converted to lowercase. Default equals TRUE
#' @param lexicon a custom lexicon provided by the user and formatted as a data frame containing two columns labeled as "word" and "sentiment". The "sentiment" column must indicate either the valence of the word (using either the term "positive" or "negative") or the emotional category of the word, using one of the following terms: "anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise", "trust".  For example: the English word "abandon" may appear in your lexicon twice, first with a emotional category of "fear" and again with a value of "negative."  Not all words necessarily need to have a valence indicator.  See example section below
#' @return A data frame where each row represents a sentence From the original file.  The columns include one for each emotion type as well as a positive or negative valence. The ten columns are as follows: "anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise", "trust", "negative", "positive." 
#' @references Saif Mohammad and Peter Turney.  "Emotions Evoked by Common Words and Phrases: Using Mechanical Turk to Create an Emotion Lexicon." In Proceedings of the NAACL-HLT 2010 Workshop on Computational Approaches to Analysis and Generation of Emotion in Text, June 2010, LA, California.  See: http://saifmohammad.com/WebPages/lexicons.html
#' @importFrom rlang .data
#' @examples  
#' my_lexicon <- data.frame(
#' word = c("love","love", "hate", "hate"), 
#' sentiment = c("positive", "joy", "negative", "anger")
#' )
#' my_example_text <- "I am in love with R programming.  
#'   I hate writing code in C."
#' s_v <- get_sentences(my_example_text)
#' get_nrc_sentiment(s_v, lexicon=my_lexicon)
#' @export
get_nrc_sentiment <- function(char_v, cl=NULL, language = "english", lowercase = TRUE, lexicon = NULL){
  if (!is.character(char_v)) stop("Data must be a character vector.")
  if(!is.null(cl) && !inherits(cl, 'cluster')) stop("Invalid Cluster")
  if(is.null(lexicon)){
    lexicon <- dplyr::filter(nrc, .data$lang == language) # select the built in NRC lexicon and filter to language
  } else { # check that the user's custom dictionary meets specs and bind a value column so format matches that of the NRC dictionary.
    if (! all(c("word", "sentiment") %in% colnames(lexicon)))
      stop("custom lexicon must have a 'word', a 'sentiment' and a 'value' column")
    lexicon <- dplyr::bind_cols(lexicon, value = 1) # to match the formatting of the NRC lexicon
  }
  if(lowercase){
    char_v <- tolower(char_v)
  }
  word_l <- strsplit(char_v, "[^A-Za-z']+")
  
  if(is.null(cl)){
    nrc_data <- lapply(word_l, get_nrc_values, lexicon = lexicon)
  }
  else{
    nrc_data <- parallel::parLapply(cl=cl, word_l, lexicon = lexicon, get_nrc_values)
  }
  result_df <- as.data.frame(do.call(rbind, nrc_data), stringsAsFactors=F)
  # reorder the columns
  my_col_order <- c(
    "anger", 
    "anticipation", 
    "disgust", 
    "fear", 
    "joy", 
    "sadness", 
    "surprise", 
    "trust", 
    "negative", 
    "positive"
  )
  missing_cols <- setdiff(my_col_order, names(result_df))
  result_df[missing_cols] <- 0
  result_df[, my_col_order]
}

#' Summarize NRC Values
#' @description
#' Access the NRC dictionary to compute emotion types and
#' valence for a set of words in the input vector.
#' @param word_vector A character vector.
#' @param language A string
#' @param lexicon A data frame with at least the columns "word", "sentiment" and "value". If NULL, internal data will be taken.
#' @return A vector of values for the emotions and valence
#' detected in the input vector.
#' @importFrom rlang .data
#' @export
get_nrc_values <- function(word_vector, language = "english", lexicon = NULL){
  if (is.null(lexicon)) {
    lexicon <- dplyr::filter(nrc, .data$lang == language)
  }
  if (! all(c("word", "sentiment", "value") %in% colnames(lexicon)))
    stop("custom lexicon must have a 'word', a 'sentiment' and a 'value' column")

  data <- dplyr::filter(lexicon, .data$word %in% word_vector)
  data <- dplyr::group_by(data, .data$sentiment)
  data <- dplyr::summarise_at(data, "value", sum)

  all_sent <- unique(lexicon$sentiment)
  sent_present <- unique(data$sentiment)
  sent_absent  <- setdiff(all_sent, sent_present)
  if (length(sent_absent) > 0) {
    missing_data <- dplyr::tibble(sentiment = sent_absent, value = 0)
    data <- rbind(data, missing_data)
  }
  tidyr::spread(data, "sentiment", "value")
}

#' Fourier Transform and Reverse Transform Values
#' @description 
#' Please Note: This function is maintained for legacy purposes.  Users should consider using get_dct_transform() instead. Converts input values into a standardized set of filtered and reverse transformed values for easy plotting and/or comparison. 
#' @param raw_values the raw sentiment values calculated for each sentence
#' @param low_pass_size The number of components to retain in the low pass filtering. Default = 3
#' @param x_reverse_len the number of values to return. Default = 100
#' @param padding_factor the amount of zero values to pad raw_values with, as a factor of the size of raw_values. Default = 2.
#' @param scale_range Logical determines whether or not to scale the values from -1 to +1.  Default = FALSE.  If set to TRUE, the lowest value in the vector will be set to -1 and the highest values set to +1 and all the values scaled accordingly in between.
#' @param scale_vals Logical determines whether or not to normalize the values using the scale function  Default = FALSE.  If TRUE, values will be scaled by subtracting the means and scaled by dividing by their standard deviations.  See ?scale
#' @return The transformed values
#' @examples 
#' s_v <- get_sentences("I begin this story with a neutral statement. 
#' Now I add a statement about how much I despise cats. 
#' I am allergic to them. 
#' Basically this is a very silly test.")
#' raw_values <- get_sentiment(s_v, method = "bing")
#' get_transformed_values(raw_values)
#' @export 
#' 
get_transformed_values <- function(raw_values, low_pass_size = 2, x_reverse_len = 100, padding_factor = 2, scale_vals = FALSE, scale_range = FALSE){
  warning('This function is maintained for legacy purposes.  Consider using get_dct_transform() instead.')
  if(!is.numeric(raw_values)) stop("Input must be an numeric vector")
  if(low_pass_size > length(raw_values)) stop("low_pass_size must be less than or equal to the length of raw_values input vector")
  raw_values.len <- length(raw_values)
  padding.len <- raw_values.len * padding_factor
  # Add padding, then fft
  values_fft <- stats::fft( c(raw_values, rep(0, padding.len)) )
  low_pass_size <- low_pass_size * (1 + padding_factor)
  keepers <- values_fft[1:low_pass_size]
  # Preserve frequency domain structure
  modified_spectrum <- c(keepers, rep(0, (x_reverse_len * (1+padding_factor)) - (2*low_pass_size) + 1), rev(Conj( keepers[2:(length(keepers))] )))
  inverse_values <- stats::fft(modified_spectrum, inverse=T)
  # Strip padding
  inverse_values <- inverse_values[1:(x_reverse_len)]
  transformed_values <- Re(inverse_values)
  if(scale_vals & scale_range) stop("ERROR: scale_vals and scale_range cannot both be true.")
  if(scale_vals){
    return(scale(transformed_values))
  }
  if(scale_range){
    return(rescale(transformed_values))
  }
  return(transformed_values)
}

#' Chunk a Text and Get Means
#' @description 
#' Chunks text into 100 Percentage based segments and calculates means.
#' @param raw_values Raw sentiment values
#' @param bins The number of bins to split the input vector.
#' Default is 100 bins.
#' @export 
#' @return A vector of mean values from each chunk
#'
get_percentage_values <- function(raw_values, bins = 100){
  if(!is.numeric(raw_values) | !is.numeric(bins)) stop("Input must be a numeric vector")
  if(length(raw_values)/bins < 2){
    stop("Input vector needs to be twice as long as value number to make percentage based segmentation viable")
  }
  chunks <- split(raw_values, cut(1:length(raw_values),bins))
  means <- sapply(chunks, mean)
  names(means) <- 1:bins
  return(means)
}

#' Get Sentiment from the Stanford Tagger
#' @description 
#' Call the Stanford Sentiment tagger with a
#' vector of strings.  The Stanford tagger automatically
#' detects sentence boundaries and treats each sentence as a 
#' distinct instance to measure. As a result, the vector 
#' that gets returned will not be the same length as the
#' input vector.
#' @param text_vector A vector of strings
#' @param path_to_stanford_tagger a local file path indicating 
#' where the coreNLP package is installed.
#' @export 
get_stanford_sentiment <- function(text_vector, path_to_stanford_tagger){
  write(text_vector, file = file.path(getwd(), "temp_text.txt"))
  cmd <- paste("cd ", path_to_stanford_tagger, "; java -cp \"*\" -Xmx5g edu.stanford.nlp.sentiment.SentimentPipeline -file ", file.path(getwd(), "temp_text.txt"), sep = "")
  results <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
  file.remove(file.path(getwd(), "temp_text.txt"))
  values <- results[seq(2, length(results), by = 2)]
  c_results <- gsub(".*Very positive", "1", values)
  c_results <- gsub(".*Very negative", "-1", c_results)
  c_results <- gsub(".*Positive", "0.5", c_results)
  c_results <- gsub(".*Neutral", "0", c_results)
  c_results <- gsub(".*Negative", "-0.5", c_results)
  return(as.numeric(c_results))
}

#' Vector Value Rescaling
#' @description
#' Rescale Transformed values from -1 to 1
#' 
#' @param x A vector of values
#' @export
rescale <- function(x){
  2 * (x - min(x))/( max(x) - min(x)) -1
}

#' Bi-Directional x and y axis Rescaling
#' @description
#' Rescales input values to two scales (0 to 1 and  -1 to 1) on the y-axis and also creates a scaled vector of x axis values from 0 to 1.  This function is useful for plotting and plot comparison.
#' @param v A vector of values
#' @return A list of three vectors (x, y, z).  x is a vector of values from 0 to 1 equal in length to the input vector v. y is a scaled (from 0 to 1) vector of the input values equal in length to the input vector v. z is a scaled (from -1 to +1) vector of the input values equal in length to the input vector v.
#' @export
rescale_x_2 <- function(v){
  x <- 1:length(v)/length(v)
  y <- v/max(v)
  z <- 2 * (v - min(v))/(max(v) - min(v)) - 1
  return (list(x=x,y=y,z=z))
}

#' Plots simple and rolling shapes overlayed
#' @description A simple function for comparing three smoothers
#' @param raw_values the raw sentiment values
#' calculated for each sentence
#' @param title for resulting image
#' @param legend_pos position for legend
#' @param lps size of the low pass filter. I.e. the number of low frequency components to retain
#' @param window size of the rolling window for the rolling mean expressed as a percentage.
#' @export
simple_plot <- function (raw_values, title = "Syuzhet Plot", legend_pos = "top", lps=10, window = 0.1){
  wdw <- round(length(raw_values) * window)
  rolled <- rescale(zoo::rollmean(raw_values, k = wdw, fill = 0))
  half <- round(wdw/2)
  rolled[1:half] <- NA
  end <- length(rolled) - half
  rolled[end:length(rolled)] <- NA
  trans <- get_dct_transform(raw_values, low_pass_size = lps, x_reverse_len = length(raw_values), 
                             scale_range = T)
  x <- 1:length(raw_values)
  y <- raw_values
  raw_lo <- stats::loess(y ~ x, span = 0.5)
  low_line <- rescale(stats::predict(raw_lo))
  graphics::par(mfrow = c(2, 1))
  graphics::plot(low_line, type = "l", ylim = c(-1, 1), main = title, 
                 xlab = "Full Narrative Time", ylab = "Scaled Sentiment", col="blue", lty = 2)
  graphics::lines(rolled, col = "grey", lty = 2)
  graphics::lines(trans, col = "red")
  graphics::abline(h=0, lty=3)
  graphics::legend(legend_pos, c("Loess Smooth", "Rolling Mean", 
                                 "Syuzhet DCT"), lty = 1, lwd = 1, col = c("blue", "grey", 
                                                                           "red"), bty = "n", cex = 0.75)
  normed_trans <- get_dct_transform(raw_values, scale_range = T, low_pass_size = 5)
  graphics::plot(normed_trans, type = "l", ylim = c(-1, 1), 
                 main = "Simplified Macro Shape", xlab = "Normalized Narrative Time", 
                 ylab = "Scaled Sentiment", col = "red")
  graphics::par(mfrow = c(1, 1))
}

#' Discrete Cosine Transformation with Reverse Transform.
#' @description
#' Converts input values into a standardized
#' set of filtered and reverse transformed values for
#' easy plotting and/or comparison.
#' @param raw_values the raw sentiment values
#' calculated for each sentence
#' @param low_pass_size The number of components
#' to retain in the low pass filtering. Default = 5
#' @param x_reverse_len the number of values to return via decimation. Default = 100
#' @param scale_range Logical determines whether or not to scale the values from -1 to +1.  Default = FALSE.  If set to TRUE, the lowest value in the vector will be set to -1 and the highest values set to +1 and all the values scaled accordingly in between.
#' @param scale_vals Logical determines whether or not to normalize the values using the scale function  Default = FALSE.  If TRUE, values will be scaled by subtracting the means and scaled by dividing by their standard deviations.  See ?scale 
#' @return The transformed values
#' @examples
#' s_v <- get_sentences("I begin this story with a neutral statement.
#' Now I add a statement about how much I despise cats.  
#' I am allergic to them. I hate them. Basically this is a very silly test. But I do love dogs!")
#' raw_values <- get_sentiment(s_v, method = "syuzhet")
#' dct_vals <- get_dct_transform(raw_values)
#' plot(dct_vals, type="l", ylim=c(-0.1,.1))
#' @export
get_dct_transform <- function(raw_values, low_pass_size = 5, x_reverse_len = 100, scale_vals = FALSE, scale_range = FALSE){
  if (!is.numeric(raw_values)) 
    stop("Input must be an numeric vector")
  if (low_pass_size > length(raw_values)) 
    stop("low_pass_size must be less than or equal to the length of raw_values input vector")
  values_dct <- dtt::dct(raw_values, variant = 2)
  keepers <- values_dct[1:low_pass_size]
  padded_keepers <- c(keepers, rep(0, x_reverse_len-low_pass_size))
  dct_out <- dtt::dct(padded_keepers, inverted = T)
  if (scale_vals & scale_range) 
    stop("ERROR: scale_vals and scale_range cannot both be true.")
  if (scale_vals) {
    return(scale(dct_out))
  }
  if(scale_range) {
    return(rescale(dct_out))
  }
  return(dct_out)
}

#' Sentiment Dictionaries
#' @description
#' Get the sentiment dictionaries used in \pkg{syuzhet}.
#' @param dictionary A string indicating which sentiment dictionary to return.  Options include "syuzhet", "bing", "afinn", and "nrc".
#' @param language A string indicating the language to choose if using the NRC dictionary and a language other than English
#' @return A \code{\link[base]{data.frame}} 
#' @examples
#' get_sentiment_dictionary()
#' get_sentiment_dictionary('bing')
#' get_sentiment_dictionary('afinn')
#' get_sentiment_dictionary('nrc', language = "spanish")
#' @importFrom rlang .data
#' @export
#'
get_sentiment_dictionary <- function(dictionary = 'syuzhet', language = 'english'){
    dict <- switch(dictionary,
        syuzhet = syuzhet_dict,
        bing = bing,
        nrc = nrc,
        afinn = afinn,
        stop("Must be one of: 'syuzhet', 'bing', 'nrc', or 'afinn'")
    )
    if(dictionary == 'nrc'){
      dict <- dplyr::filter(dict, .data$lang == language)
    }
    return(dict)
}

#' Mixed Messages
#' @description
#' This function calculates the "emotional entropy" of a string based on the amount of conflicting valence. Emotional entropy is a measure of unpredictability and surprise based on the consistency or inconsistency of the emotional language in a given string. A string with conflicting emotional language may be said to express a "mixed message."
#' @param string A string of words
#' @param remove_neutral Logical indicating whether or not to remove words with neutral valence before computing the emotional entropy of the string.  Default is TRUE
#' @return A \code{\link[base]{vector}} containing two named values
#' @examples
#' text_v <- "That's the love and the hate of it" 
#' mixed_messages(text_v) # [1] 1.0 0.5 = high (1.0, 0.5) entropy
#' mixed_messages(text_v, TRUE)

#' # Example of a predictable message i.e. no surprise
#' text_v <- "I absolutley love, love, love it." 
#' mixed_messages(text_v) # [1] 0 0 = low entropy e.g. totally consistent emotion, i.e. no surprise
#' mixed_messages(text_v, FALSE)

#' # A more realistic example with a lot of mixed emotion.
#' text_v <- "I loved the way he looked at me but I hated that he was no longer my lover"
#' mixed_messages(text_v) # [1] 0.91829583 0.05101644 pretty high entropy.
#' mixed_messages(text_v, FALSE)

#' # A more realistic example without a lot of mixed emotion.
#' text_v <- "I loved the way he looked at me and I was happy that he was my lover."
#' mixed_messages(text_v) # [1] 0 0 low entropy, no surprise.
#' mixed_messages(text_v, FALSE)

#' # An urealistic example with a lot of mixed emotion.
#' text_v <- "I loved, hated and despised the way he looked at me and 
#' I was happy as hell that he was my white hot lover."
#' mixed_messages(text_v)
#' mixed_messages(text_v, FALSE)
#' @export

mixed_messages <- function(string, remove_neutral = TRUE){
  tokens <- get_tokens(string)
  sen <- sign(get_sentiment(tokens))
  if(remove_neutral){
    sen <- sen[sen != 0] # By default remove neutral values. 
  }
  freqs <- table(sen)/length(sen)
  entropy <- -sum(freqs * log2(freqs)) # shannon-entropy
  metric_entropy <- entropy/length(tokens) # metric-entropy
  c(entropy = entropy, metric_entropy = metric_entropy)
}