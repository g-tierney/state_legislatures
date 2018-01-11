require(RWordPress)
library(knitr)

# Tell RWordPress how to set the user name, password, and URL for your WordPress site.
options(WordpressLogin = c(ticktocksaythehandsoftheclock = 'chimera24'),
        WordpressURL = 'https://ticktocksaythehandsoftheclock.wordpress.com/xmlrpc.php')

# Tell knitr to create the html code and upload it to your WordPress site
knit2wp('writeup2.Rmd', title = 'Blog Posting from R Markdown to WordPress',publish = FALSE)
