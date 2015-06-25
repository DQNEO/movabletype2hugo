# MovableType2Hugo

It's a convert tool for migration from MovableType to Hugo.

# Concept

Thiis tool extracts entries text from MySQL and generate static files.

Assume that a permalink of an article on MT is like this:
http://example.com/YYYY/MM/foobar.html

This tool get articles data and make files

* YYYY@MM@foobar/toml
* YYYY@MM@foobar/body
* YYYY@MM@foobar/more

Then you can review them and modify texts as you like.

And finaly you can get the Hugo style content files by compiling them.

* content/YYYY/MM/foobar.html

# Usagee

TBD

