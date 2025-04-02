# Movie Madness is a movie slide generator
## By Joel "Jaykul" Bennett

This is a silly [Slidev](https://sli.dev/) presentation generator for movies.

At loanDepot DevOps we have a regular movie challenge where we all pick movies from a theme for the team to watch, and then we vote to pick the best movie, and the winner ... picks the theme for the next challenge.

This is a Slidev theme, and a slide generator PowerShell module to make a quick slide-per-movie presentation with images from the movies.

### Usage

Clone the repo, and then `Import-Module ./MovieMadness/MovieMadness.psm1`

The most reliable thing is to call `New-MovieSlideShow` with a list of IMDb title URLs (the ones that end in a "tt" number, like https://www.imdb.com/title/tt0107290/ for Jurassic Park).  However, there _is_ a `Find-Movie` function which can use DuckDuckGo to determine the IMDb URL for a movie title, which means you _can_ just pass a list of movie names. For my current movie challenge, it found every movie, even with a typo or two.

To start the slide show (you can use `npm`, but I use `bun` instead):

- `bun install`
- `bun run dev`
- visit http://localhost:3030
