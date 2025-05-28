#requires -Module Xml
filter Find-Movie {
    <#
    .DESCRIPTION
        Find the IMDb URL for a movie, given the title
        Uses the DuckDuckGo Answers API
    #>
    [CmdletBinding()]
    param(
        # The name of the movie to search for
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, ValueFromPipeline)]
        [string[]]$Name
    )
    Write-Verbose "Searching for IMDB information for $Name"
    $wikiTitle = (Get-Culture).TextInfo.ToTitleCase("$Name".ToLower()) -replace " ", "_"

    $queue = @(
        "${wikiTitle}_(film)"
        $wikiTitle
        "$Name"
        "${Name} (film)"
    )

    while ($queue) {
        $title, $queue = $queue
        Write-Debug "Searching $title"
        $json = Invoke-RestMethod "https://duckduckgo.com/${title}?ia=web&format=json" -Verbose:$false
        $id = $json.infobox.content.where{ $_.data_type -eq "imdb_id" }.value

        if ($Id) {
            "https://www.imdb.com/title/$Id/"
            return
        } elseif ($json.meta.description -ne "testing") {
            Write-Warning "No IMDb ID found for $title but we found some JSON"
            $global:imdb_json = $json
            $oneMoreTry = (([uri]$imdb_json.RelatedTopics[0].FirstURL)).Segments[-1]
            if ($oneMoreTry -ne $title -and @($queue) -notlike "*$oneMoreTry*") {
                Write-Debug "Adding $oneMoreTry to the queue"
                $queue = @(
                    "${oneMoreTry}_(film)"
                    "${oneMoreTry}"
                ) + @($queue)
            }
        }
    }

    Write-Error "No IMDB ID found for $wikiTitle, please provide the IMDb id or full url"

}

filter Get-Movie {
    <#
.DESCRIPTION
    Get information about a movie from IMDb
.EXAMPLE
    Find-Movie The Fifth Element
    | Get-Movie
.EXAMPLE
    Get-Movie https://www.imdb.com/title/tt0120201/
}

#>
    [CmdletBinding()]
    param(
        # The IMDb URL of the movie
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [uri]$Url,

        [switch]$NoImages
    )
    process {
        Write-Verbose "Getting movie information for $Url"
        $movie = ConvertFrom-Html (Invoke-RestMethod $Url -Verbose:$false) -ov html
        | Select-Xml "//script[@type = 'application/ld+json']" -ov data
        | ConvertFrom-Json -Input { $_."#cdata-section" }

        if (!$movie) {
            throw "No ld+json found at $url"
        }

        $movie.PSTypeNames.Insert(0, "schema.org/Movie")

        if (!$NoImages) {
            Write-Verbose "Adding extra images from $($movie.name)"
            $data = $html | Select-Xml "//script[@type = 'application/json']"
            | ConvertFrom-Json -In { $_."#cdata-section" } -AsHashtable

            $media = $data.props.pageProps.aboveTheFoldData.images.edges.node.id

            $images = ConvertFrom-Html (Invoke-RestMethod "${url}mediaviewer/${media}/" -Verbose:$false) -ov mediaviewer
            | Select-Xml "//script[@type = 'application/json']" -ov data
            | ConvertFrom-Json -In { $_."#cdata-section" } -AsHashtable

            $movie | Add-Member NoteProperty additionalImages $images.props.pageProps.initialQueryData.title.images.edges.node

        }

        $movie
    }
}

filter New-MovieSlideShow {
    <#
        .SYNOPSIS
            Create a markdown slidev presentation for movies
        .DESCRIPTION
            Parses a movie list (file) for imdb title URLs and generates a slidev presentation (slides.md, by default)

            Supports passing a file containing imdb URLs, and as long as there's only one URL per line, this will ignore other data in the file ...

            Alternatively, supports passing text containing the the ttIDs from IMDb, or a list of movie names -- but in this case, you need to pass ONLY the names of the movies.
        .EXAMPLE
            New-MovieSlideShow -MovieList @(((sls "^url: " -path slides.md)).Line -replace "url: " | Sort-Object) -Verbose -Debug -Force

            # Rebuild your existing slideshow in IMDB id order
        .EXAMPLE
            New-MovieSlideShow -MovieList @(
                "John Wick"
                "Bottle Rocket"
                "Resevoir Dogs"
                "Thank You for Smoking"
                "Being John Malkovich"
                "Get Out"
                "Citizen Kane"
                "Boyz in the hood"
                "District 9"
                "Deadpool"
            ) -Verbose -Debug -Force

            # Make a slideshow about a bunch of directorial debut movies
    #>
    [OutputType('schema.org/Movie')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to a file containing a list of movies ...
        # Or just a list of movies, or a string containing a list of movies...
        # Ideally, you should pass the imdb URLs, but there is support for the ttID number, or for finding the IMDb id from movie titles
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]$MovieList,

        # The path to the slides.md file (defaults to "slides.md" in the current directory)
        [string]$SlidePath = "slides.md",

        # If set, randomizes the order of the MovieList
        [switch]$RandomOrder,

        # Overwrite the SlidePath if it exists
        [switch]$Force
    )

    if ($MovieList.Count -eq 1 -and (Test-Path $MovieList)) {
        $MovieList = Get-Content $MovieList
    }
    # Make sure we have an array of lines
    $MovieList = @($MovieList) -split "`n"

    $MovieList = @(
        if ($SomeMovies = @($MovieList) -match "https://www.imdb.com/title/tt\d{7,8}/") {
            @($SomeMovies) -replace ".*(https://www.imdb.com/title/tt\d{7,8}/).*", '$1'
        }
        if ($SomeMovies = @($MovieList) -notmatch "https://www.imdb.com/title/tt\d{7,8}/" -match "\btt\d{7,8}\b") {
            Write-Verbose "Converting imdb title ids to URLs $($SomeMovies -join ", ")"
            @($SomeMovies) -replace ".*\b(tt\d{7,8})\b.*", 'https://www.imdb.com/title/$1/'
        }

        if ($SomeMovies = @($MovieList) -notmatch "\btt\d{7,8}\b") {
            Write-Verbose "Some of those are not already imdb title ids: $($SomeMovies -join ", ")"
            @($SomeMovies) | Find-Movie -ErrorAction Continue
        }
    )

    if ($RandomOrder) {
        Write-Verbose "Randomizing the order of the movies"
        $MovieList = $MovieList | Get-Random -Count $MovieList.Count
    }

    # Overwrite the slide file
    New-Item $SlidePath -ItemType File -Force:$Force -ErrorAction Stop -Value (@(
            "---"
            "title: DevOps Movie Madness"
            "info: Everyone picks a movie, we narrow them down, watch them, then vote for a winner, then reveal who picked what!"
            "keywords: Movies"
            "drawings:"
            "    persist: false"
            "mdc: true"
            "theme: ./theme"
            "defaults:"
            "    layout: movie-stills"
            "layout: cover"
            "hideInToc: true"
            "background: images/B08599196B1133A13BF7F4A41EAE96841A9A6EBF79CB7121ACB8A3961469DFF2.jpg"
            "---"
            ""
            "# DevOps Movie Madness"
            ""
        ) -join [Environment]::NewLine)

    Write-Verbose "MovieList: $($MovieList -join "`n")"
    $MovieList | Get-Movie | Add-MovieSlide -SlidePath $SlidePath
}


filter Add-MovieSlide {
    <#
        .SYNOPSIS
            Converts a schema.org/Movie to a markdown slide and adds it to the presentation
        .DESCRIPTION
            Parses a movie list (file) for imdb title URLs and generates a slidev presentation (slides.md, by default)
        .EXAMPLE
            Get-Movie https://www.imdb.com/title/tt0082340/
            | Add-MovieSlide .\slides.md -CustomImageSelection (0..6 + 9..11)

            In Escape From New York, the 7th and 8th images are photos from the anniversary celebration...
        .NOTES
            TODO: this ought to just _replace_ the existing slide if there's already a slide with the same `name` value
    #>
    [CmdletBinding()]
    param(
        # The path to a file containing a list of movies
        # Or a string containing a list of movies
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSTypeName('schema.org/Movie')]
        $Movie,

        # The path to the slides.md file to update
        [Parameter(Mandatory, Position = 0)]
        [string]$SlidePath,

        # An array of image indexes for the movie stills
        # By default, 0..9 (you need to pass 10 images, we add the movie trailer)
        # -- if you want to skip the first image, use 1..10
        # -- if you want to skip the 8 and 9th image, use (0..6 + 9..11)
        [int[]]$CustomImageSelection = 0..9,

        # If set, does not add the trailer as an extra click
        [switch]$NoTrailer
    )
    Write-Verbose "Generating slide for $($movie.name)"

    Add-Content $SlidePath -Value @(
        "---"
        "name: `"$($movie.name)`""
        "url: $($movie.url)"
        "layout: movie-stills"
        "cover: $($movie.image.url ?? $movie.image)"
        if (!$NoTrailer) {
            "trailer: $($movie.trailer.embedUrl -replace "/video/","/videoembed/")"
        }
        "images:"
        foreach ($image in $movie.additionalImages[$CustomImageSelection]) {
            '- url: "' + $image.url + '"'
            '  caption: "' + ($image.caption.plainText ?? $image.caption) + '"'
        }
        "---"
        ""
        "### <a href='$($movie.url)'>$($movie.name) ($(Get-Date $movie.datePublished -f 'yyyy'))</a>"
        ""
        "#### Starring"
        ""
        "- $($movie.actor.name -join "`n- ")"
        ""
        "##### Directed by"
        ""
        "- $($movie.director.name -join "`n-")"
        ""
        "Rated $($movie.contentRating) and $($movie.aggregateRating.ratingValue) stars<br/>"
        "Play time: $($movie.duration -replace "PT" -replace "H",":" -replace "M")"
        ""
        "<!--"
        $movie.description
        ""
        "### " + $movie.review.name
        ""
        $movie.review.reviewBody
        "-->"
        ""
    )
}