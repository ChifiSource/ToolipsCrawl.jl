"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.
### ToolipsCrawl
**ToolipsCrawl** provides a high-level web-scraping and web-crawling interface using the 
`Toolips` web-development framework's requests and `Component` structures. The package also 
featurs `ComponentFilters`, a set of premade filters for scraped components. See `?Crawler` for 
usage
##### Module Composition
- **ToolipsCrawl**
- `AbstractCrawler`
- `Crawler`
- `scrape!`
- `crawl!`
- `scrape`
- `crawl`
- `kill!(::Crawler)`
- **ComponentFilters**
"""
module ToolipsCrawl
using Toolips
using Toolips.Crayons
using Toolips.Components
import Toolips.Components: gen_ref
import Base: getindex, get

"""
```julia
abstract type AbstractCrawler
```
An `AbstractCrawler` is a web-crawler which can be crawled to using `crawl` and scraped using `scrape`.

- addresses::Vector{String}
- crawling::Bool
- components::Vector{Servable}
"""
abstract type AbstractCrawler end

"""
```julia
Crawler <: AbstractCrawler
```
- address**::String**
- crawling**::Bool**
- addresses**::Vector{String}**
- components**::Vector{Servable}**
The `Crawler` is created by the functions `crawl` and `scrape` and stores components from addresses while navigating 
to new ones while crawling.  A `Crawler` will be passed through a `Function` provided to `scrape` or `crawl` as an argument.
```example
using ToolipsCrawl
subtitletxt = scrape("https://github.com/ChifiSource/ToolipsCrawl.jl") do c::Crawler
    text = c["start-of-content"]["class"]
end
```
Indexing with a `String` will yield the `Component` by that name. A `Crawler` may be stopped with `kill!`. 
For more information on `scrape` or `crawl`, see `?scrape` and `?crawl` respectively. Crawlers may also be 
filtered using `ComponentFilters`. We are able to filter by getting index with a filter and a value to filter with.
This allows us to get elements by name, by tag, or elements that contain a certain property.
```example
using ToolipsCrawl
using Toolips
comps = scrape("https://github.com/ChifiSource") do c::Crawler
    comps = c[ComponentFilters.bytag, "img"]
    get(comps, ComponentFilters.has_property, "src")
end
```
For more information on these filters, see `?ComponentFilters`
```julia
Crawler(address::String)
```
"""
mutable struct Crawler <: AbstractCrawler
    address::String
    crawling::Bool
    addresses::Vector{String}
    raw::String
    Crawler(address::String) = new(address, false, Vector{String}(), "")
end

getindex(c::Crawler, name::String) = getindex(c.components, name)

function scrape!(crawler::Crawler)
    crawler.raw = Toolips.get(crawler.address)
    crawler
end

function crawl!(crawler::Crawler)
    allprops = findall("href=\"", crawler.raw)
    for proplocation in allprops
        start = maximum(proplocation) + 1
        href_link_end = findnext("\"", crawler.raw, start)
lnk = try
	crawler.raw[start:prevind(crawler.raw, maximum(href_link_end))]
catch
	try
		crawler.raw[start:prevind(crawler.raw, maximum(href_link_end), 2)]
	catch
		crawler.raw[prevind(crawler.raw, start):prevind(crawler.raw, maximum(href_link_end), 2)]
	end
end

        if contains(lnk, ".jpg") || contains(lnk, ".png")
            continue
        elseif ~(contains(lnk, "http"))
            continue
        end
        push!(crawler.addresses, lnk)
    end
end

"""
```julia
scrape(f::Function, address::String) -> ::Any
```
Scrapes `address`, providing a `Crawler` with components from `Address` to `f`.
```example
subtitletxt = scrape("https://github.com/ChifiSource/ToolipsCrawl.jl") do c::Crawler
    text = c["start-of-content"]["class"]
end

myimage = scrape("https://google.com") do c::Crawler
    googlelogo = findfirst(comp -> comp.tag == "img", c.components)
    img("googlelogo", src = "https://google.com" * c.components[googlelogo]["src"])
end
```
"""
function scrape(f::Function, address::String)
    crawler::Crawler = Crawler(address)
    f(scrape!(crawler))
end

"""
```julia
scrape(f::Function, address::String, components::String ...) -> ::Any
```
Scrapes only component names in `components` at `address`, providing a `Crawler` with components from `Address` to `f`
```example
subtitletxt = scrape("https://github.com/ChifiSource/ToolipsCrawl.jl", "start-of-content") do c::Crawler
    text = c["start-of-content"]["class"]
end
```
"""
function scrape(f::Function, address::String, components::String ...)
    crawler::Crawler = Crawler(address)
    f(scrape!(crawler, [components ...]))
end

function try_scrape_recursive!(crawler::Crawler)
    try
        scrape!(crawler)
    catch
        if length(crawler.addresses) == 1
            return(false)
        end
        deleteat!(crawler.addresses, 1)
        crawler.address = crawler.addresses[1]
        return(try_scrape_recursive!(crawler))
    end
    true
end

"""
```julia
crawl(f::Function, address::String; show_address::Bool = false) -> ::Crawler
```
`crawl` scrapes `address` then calls `f` on a `Crawler` with the scraped components, then crawls to addresses found on 
that page, repeating the function call until `kill!` is used or there are no remaining addresses. We may also provide multiple addresses. 
`show_address` determines whether or not the crawler should print each address on request.
```example
using Toolips
using ToolipsCrawl
# collects images forever
images = Vector{Servable}()
newdiv = div("parentcont"); newdiv[:children] = images
i = 0
@async crawl("https://github.com/ChifiSource") do c::Crawler

end
@async while crawler1.crawling
    display(newdiv)
    sleep(5)
end
```
"""
function crawl(f::Function, address::String; show_address::Bool = false)
    crawler::Crawler = Crawler(address)
    crawler.crawling = true
    println(Crayon(foreground = Symbol("light_magenta"), bold = true), "Crawler: crawler started at $address")
    while crawler.crawling
        if show_address
            println(crawler.address)
        end
        success = try_scrape_recursive!(crawler)
        if ~(success)
            crawler.crawling = false
            println(Crayon(foreground = Symbol("light_red"), bold = true), "Crawler: crawler stopped (out of addresses)")
            break
        end
        crawl!(crawler)
        try
            f(crawler)
        catch e
            crawler.crawling = false
            throw(e)
        end
        if length(crawler.addresses) < 1
            crawler.crawling = false
            println(Crayon(foreground = Symbol("light_red"), bold = true), "Crawler: crawler stopped (out of addresses)")
            break
        end
        crawler.address = crawler.addresses[1]
        deleteat!(crawler.addresses, 1)
    end
end

"""
```julia
crawl(f::Function, address::String ...) -> ::Crawler
```
`crawl` scrapes each `address` then calls `f` on a `Crawler` with the scraped components, then crawls to addresses found on 
that page, repeating the function call until `kill!` is used or there are no remaining addresses.
```example
using Toolips
using ToolipsCrawl
# collects images forever
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
"""
function crawl(f::Function, address::String ...)
    crawler::Crawler = Crawler(address[1])
    crawler.addresses = [add for add in address[2:length(address)]]
    crawler.crawling = true
    println(Crayon(foreground = Symbol("light_magenta"), bold = true), "Crawler: crawler started at $address")
    @async while crawler.crawling
        crawl!(crawler)
        f(crawler)
        if length(crawler.addresses) < 1
            crawler.crawling = false
            println(Crayon(foreground = Symbol("light_red"), bold = true, blink = true), "Crawler: crawler stopped")
            break
        end
        crawler.address = crawler.addresses[1]
        deleteat!(crawler.addresses, 1)
    end
    crawler::Crawler
end

"""
```julia
kill!(crawler::Crawler) -> ::Nothing
```
Stops an active `Crawler`.
"""
kill!(crawler::Crawler) = begin
    crawler.crawling = false
    println(Crayon(foreground = Symbol("light_red"), bold = true, blink = true), "Crawler: crawler stopped")
end

function get_by_tag(crawler::Crawler, tag::String)
    positions = findall("<$tag", crawler.raw)
    tagsymb = Symbol(tag)
    components = Vector{AbstractComponent}()
    for pos in positions
        arg_start = maximum(pos) + 2
        stop_tag::Int64 = maximum(findnext(">", crawler.raw, arg_start))
        tagend = findnext("</$tag>", crawler.raw, stop_tag)
        propsplits = split(crawler.raw[arg_start:stop_tag - 1], "\" ")
        comp = Component{tagsymb}("-")
        for prop in propsplits
            keyval = split(replace(prop, "\"" => ""), "=")
            if length(keyval) == 1
                continue
            end
            push!(comp.properties, Symbol(keyval[1]) => keyval[2])
        end
        push!(components, comp)
    end
    return(components)::Vector{AbstractComponent}
end

function get_by_name(crawler::Crawler, name::String)
    found_positions = findall("id=\"$component_name\"", crawler.raw)
    if isnothing(found_position) || length(found_position) == 0
        return(Vector{AbstractComponent}())
    end
    components = Vector{AbstractComponent}()
    for found_position in found_positions
        tag_begin::UnitRange{Int64} = findprev("<", raw, found_position)
        stop_tag::Int64 = maximum(findnext(">", raw, found_position))
        tag::Symbol = Symbol(raw[minimum(tag_begin) + 1:found_position - 2])
        tagend = findnext("</$tag>", raw, found_position)
        if isnothing(tagend)
            text = ""
        else
            text::String = raw[stop_tag + 1:minimum(tagend) - 1]
        end
        text = rep_in(text)
        splits::Vector{SubString} = split(raw[found_position:stop_tag], "\" ")
        push!(components, Component{tag}(component_name, text = text, [begin
            splits = split(property, "=")
            if length(splits) < 2
                "" => ""
            else
                replace(string(splits[1]), "\"" => "", ">" => "", "<" => "") => replace(string(splits[2]), 
                "\"" => "", ">" => "", "<" => "")
            end
        end for property in splits] ...))
    end
    components::Vector{AbstractComponent}
end
export crawl, scrape, Crawler, get_by_tag, get_by_name
end