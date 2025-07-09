# Movie Madness is a movie slide generator
## By Joel "Jaykul" Bennett

This is a silly [Slidev](https://sli.dev/) presentation generator for movies.

At loanDepot DevOps we have a regular movie challenge where we all pick movies from a theme for the team to watch, and then we vote to pick the best movie, and the winner ... picks the theme for the next challenge.

This is a Slidev theme, and a slide generator PowerShell module to make a quick slide-per-movie presentation with images from the movies.

### Usage

The most reliable thing is to use `New-MovieSlideShow` with a list of IMDb title URLs (the ones that end in a "tt" number, like https://www.imdb.com/title/tt0107290/ for Jurassic Park).  However, there _is_ a `Find-Movie` function internally which will use DuckDuckGo to determine the IMDb URL given a movie title. Most of the time it works, but sometimes you need to add the year of release like "Planet of the Apes (1968)" or "Doctor Strange (2016 film)" in order to find a movie.

1. Open a terminal in the repository root
2. `Import-Module ./MovieMadness/MovieMadness.psm1`
3. `New-MovieSlideShow -Movies $Movies -OutputPath slides.md -Force`

Before starting the slide show the first time you need to `install` or `update` the dependencies. You can use `npm`, but I use `bun` instead:

- `bun install` (or `bun update`)
- `bun run dev`

On Windows, this will not only start slidev, it will also open a browser window to the slide show.


### Example:

For this month, we had a list of movies:

```powershell
New-MovieSlideShow -Force -RandomOrder -MovieList ($Movies ??= @"
Pokemon Detective Pikachu
WarGames
Dugeons & Dragons: Honor Among Thieves
Wreck-it Ralph
Warcraft
Sonic the hedgehog
Scott Pilgrim
The Super Mario Brothers Movie
Werewolves within
Last Starfighter
"@ -split "`n" | Find-Movie)
```

This produced one error (for some reason it could not find the D&D movie), so I looked that up and added it by hand:

```powershell
Add-MovieSlide -Movie (Get-Movie https://www.imdb.com/title/tt2906216/) -SlidePath .\slides.md
```