<div align="center">
 <img id="mainimage" hidden="hello:)" src="https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipscrawl.png"></img>
 </div>
 
 ##### toolips crawl provides web-crawling for all!
This package builds a web-scraping and web-crawling library atop the [toolips](https://github.com/ChifiSource/Toolips.jl) web-development framework. This package prominently features high-level syntax atop the `Toolips` `Component` structure.

### usage
- [scraping](#scraping)
- [crawling](#crawling)
- [filtering](#filtering)
---
`ToolipsCrawl` usage centers around the `Crawler` type. This constructor is never called directly in conventional usage of the package, **instead** we use the high-level methods for `scrape` and `crawl`.
- `scrape(f::Function, address::String)` -> `::Crawler`
- `scrape(f::Function, address::String, components::String ...)` -> `::Crawler`
- `crawl(f::Function, address::String)` -> `::Crawler`
- `crawl(f::Function, addresses::String ...)` -> `::Crawler`


Each of these functions returns a `Crawler`, and each `f` takes that same `Crawler` as its single positional argument. A `Crawler` is used for two things -- firstly, to turn an HTML page into a `Vector{Servable}`. Secondly, find any URLs within that page and crawl to them. The former is done with both `scrape` and `crawl`, whereas the latter is exclusively done with `crawl`. **Scraping** will give us an easy way to view one page and aggregate its data, **crawling** will give us an easy way to collect data from pages indefinitely -- or until we run out of links, at which point our `Crawler` will `kill!` itself.
##### scraping
Scraping with `ToolipsCrawl` is done using the `scrape` function. There are two `scrape` methods, one takes a `String` (the address) and a `Vector{String}`. This function will grab exclusively the components in this `Vector`. Providing only the address will read all components. Consider the following example,
```julia
julia> mydata = Dict{String, String}()
Dict{String, String}()

julia> ToolipsCrawl.scrape("https://www.accessibility-developer-guide.com/examples/tables/", "main-h1") do c
           push!(mydata, "heading text" => c.components["main-h1"]["text"])
       end
Dict{String, String} with 1 entry:
  "heading text" => "Data tables"
```
We can work with `c.components` directly, or index components by name.
```julia
myimage = scrape("https://google.com") do c::Crawler
    googlelogo = findfirst(comp -> comp.tag == "img", c.components)
    img("googlelogo", src = "https://google.com" * c.components[googlelogo]["src"])
end
```
In the following example, we scrape the `src` from some images, create new image components out of them, and then put them into a `Vector`. I do so using by making a request and then filtering the results into a return using the [ComponentFilters](#filtering) API. 
```julia
comps = scrape("https://github.com/ChifiSource") do c::Crawler
    comps = c[ComponentFilters.bytag, "img"]
    get(comps, ComponentFilters.has_property, "src")
end
```
We could also redo the last example with this filtering syntax, for example.
```julia
comps = scrape("https://google.com") do c::Crawler
    comps = c[ComponentFilters.bytag, "img"]
    get(comps, ComponentFilters.has_property, "src")[1]
end
```
##### crawling
Crawling with `ToolipsCrawl` is done using the `crawl` function. The `crawl` function has two methods, one takes a `Function` and an `String` (address) and the other takes multiple Strings, (addresses). Crawling works the same as scraping, only it is recurring and searches for additional addresses on each page.
```julia
images = Vector{Servable}()
newdiv = div("parentcont"); newdiv[:children] = images
i = 0
crawler1 = crawl("https://github.com/ChifiSource") do c::Crawler
    f = findall(comp -> comp.tag == "img", c.components)
    [begin
        comp = c.components[position]
        if "src" in keys(comp.properties)
            image = img("ex", src = comp["src"], width = 50)
            style!(image, "display" => "inline-block")
            push!(images, image)
        end
    end for position in f]
end
@async while crawler1.crawling
    display(newdiv)
    sleep(5)
end
```
This example will continuously accumulate images and add them to a constantly displaying div.
##### filtering
`ToolipsCrawl` provides a basic filtering API for the `Vector{Servable}` type. This API revolves around the `Toolips.get` `Function`, which we provide with a `Crawler`, a `ComponentFilter`, and a `String`. The `ComponentFilter` determines the operation and the `String` determines the value. This may also be done by simply getting the index of a `Crawler` with a `ComponentFilter`
```julia
comps = scrape("https://github.com/ChifiSource/Olive.jl") do c::Crawler
    codes = c[ComponentFilters.bytag, "code"]
    codes
end
```
This module provides three 
default filters:
- `ComponentFilters.bytag`
- `ComponentFilters.byname`
- `ComponentFilters.has_property`
```example
comps = scrape("https://github.com/ChifiSource") do c::Crawler
    comps = c[ComponentFilters.bytag, "img"]
    get(comps, ComponentFilters.has_property, "src")
end
```
Implementing a new filter is simple; just extend `get(::ComponentFilter{<:Any}, ::Vector{Servable})`.
```example
using Toolips
using ToolipsCrawl
import Toolips: get

function get(f::ComponentFilter{:images}, comps::Vector{Servable})
    comps = get(ComponentFilters.bytag, "img")
    get(CompFilters.has_property, "src")
end
```
