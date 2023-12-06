<div align="center">
 <img id="mainimage" src="https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipscrawl.png"></img>
 <h6 id="crawlsub">toolips crawl provides web-crawling for all!</h6>
 </div>

This package builds a web-scraping and web-crawling library atop the [toolips](https://github.com/ChifiSource/Toolips.jl) web-development framework. This package prominently features high-level syntax atop the `Toolips` `Component` structure.

### usage
- [scraping](#scraping)
- [crawling](#crawling)
- [collecting](#collecting)
```julia

```

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
In the following example, I scrape the `src` from some images, create new image components out of them, and then put them into a `Vector`.
```julia
images = Vector{Servable}()
scrape("https://github.com/ChifiSource") do c::Crawler
    f = findall(comp -> comp.tag == "img", c.components)
    [begin
        comp = c.components[position]
        if "src" in keys(comp.properties)
              push!(images, img("ex", src = comp["src"]))
        end
    end for position in f]
end
```
##### crawling
Crawling with `ToolipsCrawl` is done using the `crawl` function. The `crawl` function has two methods, one takes a `Function` and an `String` (address) and the other takes
##### collecting

