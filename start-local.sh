docker run --rm --volume="$PWD:/srv/jekyll" -p 4000:4000 -it jekyll/builder bash

bundle exec jekyll serve
