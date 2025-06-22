<div align="center">
 <img id="mainimage" src="https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipscrawl.png"></img>

[documentation](https://chifidocs.com/toolips/ToolipsCrawl.jl)
 
 <h6 id="crawlsub">toolips crawl provides web-crawling for all!</h6>
 </div>

This package builds a web-scraping and web-crawling library atop the [toolips](https://github.com/ChifiSource/Toolips.jl) web-development framework. This package prominently features high-level syntax atop the `Toolips` `Component` structure.
- [get started](#get-started)
  - [installation](#installation)
  - [documentation](#documentation)
  - [overview](#overview)
- [contributing guidelines](#contributing)
### get started
- To get started with `ToolipsCrawl`, you will need [julia.](https://julialang.org).
###### installation
After installing Julia, `ToolipsCrawl` may be installed with `Pkg`
```julia
using Pkg; Pkg.add("ToolipsCrawl")
```
Alternatively, `Unstable` may be added for the latest (sometimes broken) changes.
```julia
using Pkg; Pkg.add(name = "ToolipsCrawl", rev = "Unstable")
```
##### documentation
Documentation for `ToolipsCrawl` is available on [chifidocs](https://chifidocs.com/toolips/ToolipsCrawl)
## overview
`ToolipsCrawl` usage centers around the `Crawler` type. This constructor is never called directly in conventional usage of the package, **instead** we use the high-level methods for `scrape` and `crawl`.
- `scrape(f::Function, address::String)` -> `::Crawler`
- `scrape(f::Function, address::String, components::String ...)` -> `::Crawler`
- `crawl(f::Function, address::String)` -> `::Crawler`
- `crawl(f::Function, addresses::String ...)` -> `::Crawler`

As of right now, there are two main functions for grabbing components...
- `get_by_name(crawler::Crawler, name::String)` and `get_by_tag(crawler::Crawler, tag::String)`.

These *getters* are used on the `Crawler` within a scraping function provided to `crawl` or `scrape`.
```julia
using ToolipsCrawl
rows = []
scrape("https://github.com/ChifiSource") do c::Crawler
    current_rows = get_by_tag(c, "td")
    for row::ToolipsCrawl.Component{:td} in current_rows
        push!(rows, row[:text])
    end
end
```
```julia
using ToolipsCrawl
titles = []
crawl("https://chifidocs.com") do crawler::Crawler
    title_comps = get_by_tag(crawler, "title")
    if length(title_comps) > 0
        @info "scraped title from " * crawler.address
        push!(titles, title_comps[1][:text])
    end
end
```
### contributing
`chifi` tries to be quite leniant in accepting pull requests, but following these guidelines will help speed up our processes and make merging your pull-request easier. Please consider the following guidelines:
- Ensure the issue or the upgrade is applicable to the current version of the project on the `Unstable` branch.
- **please pull-request to `Unstable`**
- Open  a unique issue for each issues, please do not group multiple problems into a single issue.
