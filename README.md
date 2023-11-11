<div align="center">
 <img src="https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipscrawl.png"></img>
 </div>
 
 ##### create your own web-crawlers with toolips!
This package builds a web-scraping and web-crawling library atop the [toolips](https://github.com/ChifiSource/Toolips.jl) web-development framework. 

### usage
- [scraping](#scraping)
- [crawling](#crawling)
- [filtering](#filtering)
- [collecting](#collecting)
- [notes](#notes)

`ToolipsCrawl` usage centers around the `Crawler` type. This constructor is never called directly in conventional usage of the package, **instead** we use the high-level methods for `scrape` and `crawl`.
- `scrape(f::Function, address::String)` -> `::Crawler`
- `scrape(f::Function, address::String, components::String ...)` -> `::Crawler`
- `crawl(f::Function, address::String)` -> `::Crawler`
- `crawl(f::Function, [addresses::Vector{String}])` -> `::Crawler`


Each of these functions returns a `Crawler`. A `Crawler` is used for two things -- firstly, to turn an HTML page into a `Vector{Servable}`. Secondly, find any URLs within that page and crawl to them. The former is done with both `scrape` and `crawl`, whereas the latter is exclusively done with `crawl`. **Scraping** will give us an easy way to view one page and aggregate its data, **crawling** will give us an easy way to collect data from pages indefinitely -- or until we run out of links, at which point our `Crawler` will `kill!` itself.
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
##### crawling

##### notes
This project relies heavily on `htmlcomponent` from `ToolipsSession`. In its current form, the `::String, ::Vector{String}` version of this function works **really** well. The regular version of this function is still a **work in progress** to get to perfection. That being said, note that scraping or crawling in instances where the IDs are not known is likely to be less reliable.
